/// The waybright library.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'src/waybright_bindings.dart';

final WaybrightLibrary _wblib =
    WaybrightLibrary(DynamicLibrary.open("build/waybright.so"));

String _toString(Pointer<Char> stringPtr) {
  if (stringPtr == nullptr) return "";
  return (stringPtr as Pointer<Utf8>).toDartString();
}

// class WindowStack {
//   addToFront(Window window) {}
//   moveToFront() {}
//   remove(Window window) {}

//   // [Symbol.iterator]() {}
//   get reverse {}
// }

// abstract class Protocol {
//   static int nextId = 0;

//   int id = nextId++;

//   on(String event, Function callback);
//   emit() {}
// }

// class XDGShellProtocol extends Protocol {
//   @override
//   on(String event, Function callback) {}
// }

// class DisplayRenderingContext {
//   clearRect(int x, int y, int width, int height) {}
// }

// class DisplayResolution {
//   int width;
//   int height;

//   DisplayResolution(this.width, this.height);
// }

class CanvasRenderingContext {
  Pointer<struct_waybright_canvas>? _canvasPtr;
  final Canvas canvas;

  CanvasRenderingContext(this.canvas);

  int get fillStyle {
    // TODO: Implement this method
    return 0;
  }

  set fillStyle(int color) {
    var canvasPtr = _canvasPtr;
    if (canvasPtr != null) {
      _wblib.waybright_canvas_set_fill_style(canvasPtr, color);
    }
  }

  void clearRect(int x, int y, int width, int height) {
    var canvasPtr = _canvasPtr;
    if (canvasPtr != null) {
      _wblib.waybright_canvas_clear_rect(canvasPtr, x, y, width, height);
    }
  }

  void fillRect(int x, int y, int width, int height) {
    var canvasPtr = _canvasPtr;
    if (canvasPtr != null) {
      _wblib.waybright_canvas_fill_rect(canvasPtr, x, y, width, height);
    }
  }
}

/// A canvas used for rendering images on a [Monitor]
class Canvas {
  /// The context to used for modifying the monitor's canvas
  CanvasRenderingContext? renderingContext;

  /// This canvas's width
  final int width;

  /// This canvas's height
  final int height;

  Pointer<struct_waybright_canvas>? _canvasPtr;

  Canvas(this.width, this.height);
}

/// A combination of a resolution and refresh rate.
class MonitorMode {
  /// The resolution width.
  final int width;

  /// The resolution height.
  final int height;

  /// The refresh rate.
  final int refreshRate;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  /// Creates a MonitorMode instance
  MonitorMode(this.width, this.height, this.refreshRate);

  @override
  String toString() {
    return "(${width}x$height @ ${refreshRate}mHz)";
  }
}

/// A physical or virtual monitor that can render a [Canvas].
class Monitor {
  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_monitor_remove,
    'frame': enum_event_type.event_type_monitor_frame,
  };

  static final Map<int, Function> _eventHandlers = {};

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var handleEvent = _eventHandlers[type];
    if (handleEvent == null) return;

    handleEvent();
  }

  /// This monitor's name.
  String name = "unknown-monitor";

  /// Whether this monitor is allowed to render or not.
  bool isEnabled = false;

  Canvas? _canvas;

  Pointer<struct_waybright_monitor>? _monitorPtr;
  List<MonitorMode> _modes = [];
  bool _hasIteratedThroughModes = false;
  MonitorMode? _preferredMode;
  MonitorMode _mode = MonitorMode(0, 0, 0);

  Monitor();

  /// The canvas that this monitor will render.
  ///
  /// It becomes available when this monitor is enabled.
  Canvas? get canvas {
    return _canvas;
  }

  /// Sets an event handler for this monitor.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  /// Retrieves this monitor's modes (resolution + refresh rate).
  List<MonitorMode> get modes {
    if (_hasIteratedThroughModes) return _modes;

    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      var head = monitorPtr.ref.wlr_output.ref.modes.next;
      var link = head;
      Pointer<struct_wlr_output_mode> item;
      while (link.ref.next != head) {
        item = _wblib.get_wlr_output_mode_from_wl_list(link);
        var mode = MonitorMode(
          item.ref.width,
          item.ref.height,
          item.ref.refresh,
        ).._outputModePtr = item;

        // While I find modes, find the preferred mode
        if (item.ref.preferred) {
          _preferredMode = mode;
        }

        _modes.add(mode);

        link = link.ref.next;
      }

      if (_preferredMode == null && _modes.isNotEmpty) {
        _preferredMode = _modes[0];
      }

      _hasIteratedThroughModes = true;
      return _modes;
    }

    return [];
  }

  set modes(List<MonitorMode> modes) {
    _hasIteratedThroughModes = true;
    _modes = modes;
  }

  /// Attempts to retrieve this monitor's preferred mode.
  MonitorMode? get preferredMode {
    if (_hasIteratedThroughModes) return _preferredMode;
    modes;
    return _preferredMode;
  }

  /// Sets this monitor's resolution and refresh rate.
  MonitorMode get mode {
    return _mode;
  }

  set mode(MonitorMode mode) {
    var monitorPtr = _monitorPtr;
    var outputModePtr = mode._outputModePtr;
    if (_monitorPtr != null && mode._outputModePtr != null) {
      _wblib.wlr_output_set_mode(monitorPtr!.ref.wlr_output, outputModePtr!);
    }

    _mode = mode;
  }

  /// If there is a preferred mode, sets this monitor to use it.
  void trySettingPreferredMode() {
    var mode = preferredMode;
    if (mode != null) {
      this.mode = mode;
    }
  }

  /// Enables this monitor to start rendering.
  void enable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_enable(monitorPtr);

      var canvas = Canvas(
        monitorPtr.ref.wlr_output.ref.width,
        monitorPtr.ref.wlr_output.ref.height,
      );
      var renderingContext = CanvasRenderingContext(canvas)
        .._canvasPtr = monitorPtr.ref.wb_canvas;
      canvas.renderingContext = renderingContext;
      _canvas = canvas;
    }

    isEnabled = true;
  }

  /// Disables this monitor.
  void disable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.wlr_output_enable(monitorPtr.ref.wlr_output, false);
    }

    _canvas = null;
    isEnabled = false;
  }

  /// The background color of this monitor.
  int get backgroundColor {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      return _wblib.waybright_monitor_get_background_color(monitorPtr);
    }

    return 0;
  }

  set backgroundColor(int color) {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_set_background_color(monitorPtr, color);
    }
  }

  /// Renders this monitor's canvas.
  ///
  /// Should only be called during the `frame` event. Calling this function
  /// every `frame` can increase CPU usage.
  // void renderCanvas() {
  //   _wblib.waybright_monitor_render_canvas(_monitorPtr);
  // }
}

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol
class Window {
  static final _eventTypeFromString = {
    'show': enum_event_type.event_type_window_show,
    'hide': enum_event_type.event_type_window_hide,
    'remove': enum_event_type.event_type_window_remove,
  };

  static final Map<int, Function> _eventHandlers = {};

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var handleEvent = _eventHandlers[type];
    if (handleEvent == null) return;

    handleEvent();
  }

  /// The application id of this window.
  String appId = "unknown-application";

  /// The title of this window.
  String title = "untitled";

  /// Whether this window is a popup window.
  bool isPopup;

  Pointer<struct_waybright_window>? _windowPtr;

  Window(this.isPopup);

  /// Sets an event handler for this window.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }
}

class Waybright {
  static final _eventTypeFromString = {
    'monitor-add': enum_event_type.event_type_monitor_add,
    'window-add': enum_event_type.event_type_window_add,
  };

  static final Map<int, Function> _eventHandlers = {};

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var handleEvent = _eventHandlers[type];
    if (handleEvent == null) return;

    if (type == enum_event_type.event_type_monitor_add) {
      var monitorPtr = data as Pointer<struct_waybright_monitor>;
      var wlrOutput = monitorPtr.ref.wlr_output.ref;

      var monitor = Monitor()
        ..name = _toString(wlrOutput.name)
        .._monitorPtr = monitorPtr
        .._monitorPtr?.ref.handle_event =
            Pointer.fromFunction(Monitor._executeEventHandler);

      handleEvent(monitor);
    } else if (type == enum_event_type.event_type_window_add) {
      var windowPtr = data as Pointer<struct_waybright_window>;
      var wlrXdgToplevel = windowPtr.ref.wlr_xdg_toplevel.ref;

      var window = Window(windowPtr.ref.is_popup == 1)
        ..appId = _toString(wlrXdgToplevel.app_id)
        ..title = _toString(wlrXdgToplevel.title)
        .._windowPtr = windowPtr
        .._windowPtr?.ref.handle_event =
            Pointer.fromFunction(Window._executeEventHandler);

      handleEvent(window);
    }
  }

  final Pointer<struct_waybright> _wbPtr = _wblib.waybright_create();

  /// Creates a Waybright instance
  ///
  /// Throws an [Exception] if an unexpected exception occurs.
  Waybright() {
    if (_wblib.waybright_init(_wbPtr) != 0) {
      _wblib.waybright_destroy(_wbPtr);
      throw Exception("Waybright instance creation failed unexpectedly.");
    }

    _wbPtr.ref.handle_event = Pointer.fromFunction(_executeEventHandler);
  }

  /// Sets an event handler for waybright.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  /// Open a socket for the wayland server.
  ///
  /// If [socketName] is not set, a name will automatically be chosen.
  /// Throws an [Exception] if a socket couldn't be created automatically, or, if
  /// specified, the [socketName] is taken.
  Future<Socket> openSocket([String? socketName]) async {
    var namePtr = socketName == null
        ? nullptr
        : socketName.toNativeUtf8() as Pointer<Char>;
    var statusCode = _wblib.waybright_open_socket(_wbPtr, namePtr);

    if (statusCode != 0) {
      throw Exception("Opening wayland socket failed unexpectedly.");
    }

    var name = _toString(_wbPtr.ref.socket_name);
    return Socket(_wbPtr, name);
  }

  // void useProtocol(Protocol protocol) {}

  // List<Monitor> getAvailableMonitors() {
  //   return [];
  // }
}

class Socket {
  final Pointer<struct_waybright> _wlPtr;

  /// The socket name of this wayland server.
  final String name;

  Socket(this._wlPtr, this.name);

  /// Enters the wayland server's event loop.
  ///
  /// This function is synchronous (blocking).
  void runEventLoop() {
    _wblib.waybright_run_event_loop(_wlPtr);
  }
}
