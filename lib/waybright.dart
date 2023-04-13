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

/// A renderer.
class Renderer {
  Pointer<struct_waybright_renderer>? _rendererPtr;

  /// The color used to fill in shapes.
  int get fillStyle {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      return _wblib.waybright_renderer_get_fill_style(rendererPtr);
    }
    return 0;
  }

  set fillStyle(int color) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_set_fill_style(rendererPtr, color);
    }
  }

  /// Sets all pixels to transparent black.
  void clearRect(int x, int y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_clear_rect(rendererPtr, x, y, width, height);
    }
  }

  /// Draws a rectangle filled with the current [fillStyle].
  void fillRect(int x, int y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_fill_rect(rendererPtr, x, y, width, height);
    }
  }

  /// Draws a rectangle.
  void drawWindow(Window window, int x, int y) {
    var rendererPtr = _rendererPtr;
    var windowPtr = window._windowPtr;
    if (rendererPtr != null && windowPtr != null) {
      _wblib.waybright_renderer_draw_window(rendererPtr, windowPtr, x, y);
    }
  }
}

/// A combination of a resolution and refresh rate.
class Mode {
  /// The resolution width.
  final int width;

  /// The resolution height.
  final int height;

  /// The refresh rate.
  final int refreshRate;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  /// Creates a [Mode] instance.
  Mode(this.width, this.height, this.refreshRate);

  @override
  String toString() {
    return "(${width}x$height @ ${refreshRate}mHz)";
  }
}

/// A physical or virtual monitor.
class Monitor {
  static final _monitorInstances = <Monitor>[];

  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_monitor_remove,
    'frame': enum_event_type.event_type_monitor_frame,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var monitor in _monitorInstances) {
      var monitorPtr = data as Pointer<struct_waybright_monitor>;
      if (monitor._monitorPtr != monitorPtr) continue;

      var handleEvent = monitor._eventHandlers[type];
      if (handleEvent == null) return;

      handleEvent();

      if (type == enum_event_type.event_type_monitor_remove) {
        _monitorInstances.remove(monitor);
      }
    }
  }

  /// This monitor's name.
  String name = "unknown-monitor";

  /// This monitor's renderer.
  final Renderer renderer;

  final Map<int, Function> _eventHandlers = {};
  Pointer<struct_waybright_monitor>? _monitorPtr;
  bool _isEnabled = false;
  List<Mode> _modes = [];
  bool _hasIteratedThroughModes = false;
  Mode? _preferredMode;
  Mode _mode = Mode(0, 0, 0);

  Monitor(this.renderer) {
    _monitorInstances.add(this);
  }

  /// Sets an event handler for this monitor.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  /// Whether this monitor is allowed to render or not.
  get isEnabled {
    return _isEnabled;
  }

  /// This monitor's modes (resolution + refresh rate).
  List<Mode> get modes {
    if (_hasIteratedThroughModes) return _modes;

    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      var head = monitorPtr.ref.wlr_output.ref.modes.next;
      var link = head;
      Pointer<struct_wlr_output_mode> item;
      while (link.ref.next != head) {
        item = _wblib.get_wlr_output_mode_from_wl_list(link);
        var mode = Mode(
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

  set modes(List<Mode> modes) {
    _hasIteratedThroughModes = true;
    _modes = modes;
  }

  /// This monitor's preferred mode.
  Mode? get preferredMode {
    if (_hasIteratedThroughModes) return _preferredMode;
    modes;
    return _preferredMode;
  }

  /// This monitor's resolution and refresh rate.
  Mode get mode {
    return _mode;
  }

  set mode(Mode mode) {
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
    }

    _isEnabled = true;
  }

  /// Disables this monitor.
  void disable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_disable(monitorPtr);
    }

    _isEnabled = false;
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
}

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol.
class Window {
  static final _windowInstances = <Window>[];

  static final _eventTypeFromString = {
    'show': enum_event_type.event_type_window_show,
    'hide': enum_event_type.event_type_window_hide,
    'remove': enum_event_type.event_type_window_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var window in _windowInstances) {
      var windowPtr = data as Pointer<struct_waybright_window>;
      if (window._windowPtr != windowPtr) continue;

      var handleEvent = window._eventHandlers[type];
      if (handleEvent == null) return;

      handleEvent();

      if (type == enum_event_type.event_type_window_remove) {
        _windowInstances.remove(window);
      }
    }
  }

  /// The application id of this window.
  String appId = "unknown-application";

  /// The title of this window.
  String title = "untitled";

  /// Whether this window is a popup window.
  bool isPopup;

  final Map<int, Function> _eventHandlers = {};
  Pointer<struct_waybright_window>? _windowPtr;

  Window(this.isPopup) {
    _windowInstances.add(this);
  }

  /// Sets an event handler for this window.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }
}

/// A Waybright!
class Waybright {
  static final _waybrightInstances = <Waybright>[];

  static final _eventTypeFromString = {
    'monitor-add': enum_event_type.event_type_monitor_add,
    'window-add': enum_event_type.event_type_window_add,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var waybright in _waybrightInstances) {
      var handleEvent = waybright._eventHandlers[type];
      if (handleEvent == null) return;

      if (type == enum_event_type.event_type_monitor_add) {
        var monitorPtr = data as Pointer<struct_waybright_monitor>;

        var renderer = Renderer().._rendererPtr = monitorPtr.ref.wb_renderer;
        var monitor = Monitor(renderer)
          ..name = _toString(monitorPtr.ref.wlr_output.ref.name)
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
  }

  final Map<int, Function> _eventHandlers = {};
  final Pointer<struct_waybright> _wbPtr = _wblib.waybright_create();

  /// Creates a [Waybright] instance.
  ///
  /// Throws an [Exception] if an unexpected exception occurs.
  Waybright() {
    if (_wblib.waybright_init(_wbPtr) != 0) {
      _wblib.waybright_destroy(_wbPtr);
      throw Exception("Waybright instance creation failed unexpectedly.");
    }

    _wbPtr.ref.handle_event = Pointer.fromFunction(_executeEventHandler);
    _waybrightInstances.add(this);
  }

  /// Sets an event handler for this [Waybright] instance.
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
}

/// A wayland socket.
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
