import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:waybright/waybright_bindings.dart';

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

class MonitorMode {
  final int width;
  final int height;
  final int refreshRate;
  final bool preferred;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  MonitorMode(this.width, this.height, this.refreshRate, this.preferred);

  @override
  String toString() {
    return "(${width}x$height @ ${refreshRate}mHz${preferred ? ", preferred" : ""})";
  }
}

class Monitor {
  static final _eventTable = {
    'remove': enum_events.events_monitor_remove,
  };

  static final Map<int, Function> _handlers = {};

  static void _handler(int type, Pointer<Void> data) {
    var handler = _handlers[type];
    if (handler == null) return;

    if (type == enum_events.events_monitor_remove) {
      handler();
    }
  }

  final String name;
  final int width;
  final int height;

  final Pointer<struct_waybright_monitor> _monitorPtr;
  final List<MonitorMode> _modes = [];
  bool _iteratedThroughModes = false;
  MonitorMode? _preferredMode;

  // DisplayRenderingContext context = DisplayRenderingContext();

  Monitor(this._monitorPtr, this.name, this.width, this.height) {
    Waybright._wblib.waybright_monitor_set_handler(
        _monitorPtr, Pointer.fromFunction(_handler));
  }

  void setHandler(String event, Function handler) {
    var type = _eventTable[event];
    if (type != null) {
      _handlers[type] = handler;
    }
  }

  // DisplayRenderingContext getRenderingContext() {
  //   return context;
  // }

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
        item.ref.preferred,
      );
      mode._outputModePtr = item;

      // While i find modes, find the preferred mode
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

  MonitorMode? getPreferredMode() {
    if (_iteratedThroughModes) return _preferredMode;
    getModes();
    return _preferredMode;
  }

  void setMode(MonitorMode mode) {
    mode._outputModePtr ??= malloc();
    Waybright._wblib
        .wlr_output_set_mode(_monitorPtr.ref.wlr_output, mode._outputModePtr!);
  }

  void setPreferredMode() {
    var mode = getPreferredMode();
    if (mode != null) {
      setMode(mode);
    }
  }
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
        monitorPtr.ref.wlr_output.ref.width,
        monitorPtr.ref.wlr_output.ref.height,
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

  void setHandler(String event, Function handler) {
    var type = _eventTable[event];
    if (type != null) {
      _handlers[type] = handler;
    }
  }

  // void useProtocol(Protocol protocol) {}

  // List<Monitor> getAvailableMonitors() {
  //   return [];
  // }
}

class Socket {
  final Pointer<struct_waybright> _wlPtr;
  final String name;

  Socket(this._wlPtr, this.name);

  /// This function is synchronous (blocking)
  void run() {
    Waybright._wblib.waybright_run(_wlPtr);
  }
}
