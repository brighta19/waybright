/// The waybright library.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'src/waybright_bindings.dart';

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

/// A combination of a resolution and refresh rate.
class MonitorMode {
  /// The resolution width.
  final int width;

  /// The resolution height.
  final int height;

  /// The refresh rate.
  final int refreshRate;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  MonitorMode(this.width, this.height, this.refreshRate);

  @override
  String toString() {
    return "(${width}x$height @ ${refreshRate}mHz)";
  }
}

/// A physical or virtual monitor that can render images.
class Monitor {
  static final _eventTable = {
    'remove': enum_events.events_monitor_remove,
    'frame': enum_events.events_monitor_frame,
  };

  static final Map<int, Function> _handlers = {};

  static void _handler(int type, Pointer<Void> data) {
    var handler = _handlers[type];
    if (handler == null) return;

    handler();
  }

  /// This monitor's name.
  final String name;

  /// Whether this monitor is allowed to render or not.
  bool enabled = false;

  final Pointer<struct_waybright_monitor> _monitorPtr;
  final List<MonitorMode> _modes = [];
  bool _iteratedThroughModes = false;
  MonitorMode? _preferredMode;

  // DisplayRenderingContext context = DisplayRenderingContext();

  Monitor(this._monitorPtr, this.name) {
    Waybright._wblib.waybright_monitor_set_handler(
        _monitorPtr, Pointer.fromFunction(_handler));
  }

  /// Sets an event handler for this monitor.
  void setHandler(String event, Function handler) {
    var type = _eventTable[event];
    if (type != null) {
      _handlers[type] = handler;
    }
  }

  /// Retrieves this monitor's modes (resolution + refresh rate).
  List<MonitorMode> getModes() {
    if (_iteratedThroughModes) return _modes;

    Pointer<struct_wl_list> head = _monitorPtr.ref.wlr_output.ref.modes.next;
    Pointer<struct_wl_list> link = head;
    Pointer<struct_wlr_output_mode> item;
    while (link.ref.next != head) {
      item = Waybright._wblib.wl_list_wlr_output_mode_item(link);
      var mode = MonitorMode(
        item.ref.width,
        item.ref.height,
        item.ref.refresh,
      );
      mode._outputModePtr = item;

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

    _iteratedThroughModes = true;
    return _modes;
  }

  /// Attempts to retrieve this monitor's preferred mode.
  MonitorMode? getPreferredMode() {
    if (_iteratedThroughModes) return _preferredMode;
    getModes();
    return _preferredMode;
  }

  /// Sets this monitor's resolution and refresh rate.
  void setMode(MonitorMode mode) {
    mode._outputModePtr ??= malloc();
    Waybright._wblib
        .wlr_output_set_mode(_monitorPtr.ref.wlr_output, mode._outputModePtr!);
  }

  /// If there is a preferred mode, sets this monitor to use it.
  void setPreferredMode() {
    var mode = getPreferredMode();
    if (mode != null) {
      setMode(mode);
    }
  }

  /// Enables this monitor to start rendering.
  void enable() {
    Waybright._wblib.wlr_output_enable(_monitorPtr.ref.wlr_output, true);
    Waybright._wblib.wlr_output_commit(_monitorPtr.ref.wlr_output);
    enabled = true;
  }

  /// Disables this monitor.
  void disable() {
    Waybright._wblib.wlr_output_enable(_monitorPtr.ref.wlr_output, false);
    enabled = false;
  }

  // DisplayRenderingContext getRenderingContext() {
  //   return context;
  // }
}

class Waybright {
  static final WaybrightLibrary _wblib =
      WaybrightLibrary(DynamicLibrary.open("lib/waybright.so"));

  static final _eventTable = {
    'monitor-add': enum_events.events_monitor_add,
  };

  static final Map<int, Function> _handlers = {};

  static void _handler(int type, Pointer<Void> data) {
    var handler = _handlers[type];
    if (handler == null) return;

    if (type == enum_events.events_monitor_add) {
      Pointer<struct_waybright_monitor> monitorPtr = data.cast();
      var monitor = Monitor(
        monitorPtr,
        monitorPtr.ref.wlr_output.ref.name.cast<Utf8>().toDartString(),
      );

      handler(monitor);
    }
  }

  late final Pointer<struct_waybright> _wbPtr;

  Waybright() {
    _wbPtr = _wblib.waybright_create();

    if (_wblib.waybright_init(_wbPtr) != 0) {
      _wblib.waybright_destroy(_wbPtr);
      throw "Creating waybright instance failed.";
    }

    _wblib.waybright_set_handler(_wbPtr, Pointer.fromFunction(_handler));
  }

  /// Sets an event handler for waybright.
  void setHandler(String event, Function handler) {
    var type = _eventTable[event];
    if (type != null) {
      _handlers[type] = handler;
    }
  }

  /// Starts a wayland server.
  ///
  /// Optionally set a [socketName] to specify where the server should run.
  /// Ignore it to automatically select a socket name.
  /// Throws if a socket couldn't be created automatically, or, if specified,
  /// the [socketName] is taken.
  Future<Socket> listen({
    String? socketName,
    bool setEnvironmentVariable = true,
  }) async {
    Pointer<Char> namePtr =
        socketName == null ? nullptr : socketName.toNativeUtf8().cast();
    int statusCode = _wblib.waybright_open_socket(_wbPtr, namePtr);

    if (statusCode == 0) {
      String socketName = _wbPtr.ref.socket_name.cast<Utf8>().toDartString();
      return Socket(_wbPtr, socketName);
    } else {
      throw "Couldn't open socket.";
    }
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
  void run() {
    Waybright._wblib.waybright_run(_wlPtr);
  }
}
