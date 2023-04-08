/// The waybright library.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'src/waybright_bindings.dart';

final WaybrightLibrary _wblib =
    WaybrightLibrary(DynamicLibrary.open("build/waybright.so"));

// enum WindowType { topLevel, popUp }

// class Window {
//   WindowType type;

//   Window(this.type);
// }

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
  final Pointer<struct_waybright_canvas> _canvasPtr;
  Canvas canvas;

  CanvasRenderingContext(this._canvasPtr, this.canvas);

  int get fillStyle {
    // TODO: Implement this method
    return 0;
  }

  set fillStyle(int color) {
    _wblib.waybright_canvas_set_fill_style(_canvasPtr, color);
  }

  void clearRect(int x, int y, int width, int height) {
    _wblib.waybright_canvas_clear_rect(_canvasPtr, x, y, width, height);
  }

  void fillRect(int x, int y, int width, int height) {
    _wblib.waybright_canvas_fill_rect(_canvasPtr, x, y, width, height);
  }
}

/// A canvas used for rendering images on a [Monitor]
class Canvas {
  /// The context to used for modifying the monitor's canvas
  late CanvasRenderingContext renderingContext;

  /// This canvas's width
  final int width;

  /// This canvas's height
  final int height;

  final Pointer<struct_waybright_canvas> _canvasPtr;

  Canvas(this._canvasPtr, this.width, this.height) {
    renderingContext = CanvasRenderingContext(_canvasPtr, this);
  }
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
  final String name;

  /// Whether this monitor is allowed to render or not.
  bool isEnabled = false;

  Canvas? _canvas;

  final Pointer<struct_waybright_monitor> _monitorPtr;
  final List<MonitorMode> _modes = [];
  bool _hasIteratedThroughModes = false;
  MonitorMode? _preferredMode;

  Monitor(this._monitorPtr, this.name) {
    _wblib.waybright_monitor_set_event_handler(
        _monitorPtr, Pointer.fromFunction(_executeEventHandler));
  }

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

    var head = _monitorPtr.ref.wlr_output.ref.modes.next;
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

  /// Attempts to retrieve this monitor's preferred mode.
  MonitorMode? get preferredMode {
    if (_hasIteratedThroughModes) return _preferredMode;
    modes;
    return _preferredMode;
  }

  /// Sets this monitor's resolution and refresh rate.
  void setMode(MonitorMode mode) {
    var outputModePtr = mode._outputModePtr ??= malloc();
    _wblib.wlr_output_set_mode(_monitorPtr.ref.wlr_output, outputModePtr);
  }

  /// If there is a preferred mode, sets this monitor to use it.
  void trySettingPreferredMode() {
    var mode = preferredMode;
    if (mode != null) {
      setMode(mode);
    }
  }

  /// Enables this monitor to start rendering.
  void enable() {
    _wblib.waybright_monitor_enable(_monitorPtr);
    _canvas = Canvas(
      _monitorPtr.ref.wb_canvas,
      _monitorPtr.ref.wlr_output.ref.width,
      _monitorPtr.ref.wlr_output.ref.height,
    );
    isEnabled = true;
  }

  /// Disables this monitor.
  void disable() {
    _wblib.wlr_output_enable(_monitorPtr.ref.wlr_output, false);
    _canvas = null;
    isEnabled = false;
  }

  /// The background color of this monitor.
  int get backgroundColor {
    return _wblib.waybright_monitor_get_background_color(_monitorPtr);
  }

  set backgroundColor(int color) {
    _wblib.waybright_monitor_set_background_color(_monitorPtr, color);
  }

  /// Renders this monitor's canvas.
  ///
  /// Should only be called diring the `frame` event. Calling this function
  /// every `frame` can increase CPU usage.
  // void renderCanvas() {
  //   _wblib.waybright_monitor_render_canvas(_monitorPtr);
  // }
}

class Waybright {
  static final _eventTypeFromString = {
    'monitor-add': enum_event_type.event_type_monitor_add,
  };

  static final Map<int, Function> _eventHandlers = {};

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var handleEvent = _eventHandlers[type];
    if (handleEvent == null) return;

    if (type == enum_event_type.event_type_monitor_add) {
      var monitorPtr = data as Pointer<struct_waybright_monitor>;
      var monitor = Monitor(
        monitorPtr,
        (monitorPtr.ref.wlr_output.ref.name as Pointer<Utf8>).toDartString(),
      );

      handleEvent(monitor);
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

    _wblib.waybright_set_event_handler(
        _wbPtr, Pointer.fromFunction(_executeEventHandler));
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

    var name = (_wbPtr.ref.socket_name as Pointer<Utf8>).toDartString();
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
