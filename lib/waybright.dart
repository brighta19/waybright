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

// class DisplayMode {
//   DisplayResolution resolution;
//   int rate;

//   DisplayMode(this.resolution, this.rate);
// }

class Monitor {
  // int width;
  // int height;
  // DisplayRenderingContext context = DisplayRenderingContext();

  // Monitor(this.width, this.height);

  // void on(String event, Function callback) {}

  // DisplayRenderingContext getRenderingContext() {
  //   return context;
  // }

  // List<DisplayMode> getAvailableModes() {
  //   return [];
  // }

  // setMode(DisplayMode mode) {}
}

class Waybright {
  static final WaybrightLibrary wblib =
      WaybrightLibrary(DynamicLibrary.open("lib/waybright.so"));

  static Map<String, Function> handlers = {};

  static void handlerMonitorAdd() {
    handlers.forEach((event, handler) {
      if (event == "monitor-add") {
        handler();
      }
    });
  }

  late Pointer<struct_waybright> wbPtr;

  Waybright() {
    wbPtr = wblib.waybright_create();

    if (wblib.waybright_init(wbPtr) != 0) {
      wblib.waybright_destroy(wbPtr);
      throw "Creating waybright instance failed.";
    }

    wblib.waybright_set_handler(
      wbPtr,
      enum_events.events_monitor_add,
      Pointer.fromFunction(handlerMonitorAdd),
    );
  }

  Future<Socket> listen({
    String? socketName,
    bool setEnvironmentVariable = true,
  }) async {
    Pointer<Char> namePtr =
        socketName == null ? nullptr : socketName.toNativeUtf8().cast();
    int statusCode = wblib.waybright_open_socket(wbPtr, namePtr);

    if (statusCode == 0) {
      String socketName = wbPtr.ref.socket_name.cast<Utf8>().toDartString();
      return Socket(wblib, wbPtr, socketName);
    } else {
      throw "Couldn't open socket.";
    }
  }

  void setHandler(String event, void Function() handler) {
    handlers[event] = handler;
  }

  // void useProtocol(Protocol protocol) {}

  // List<Monitor> getAvailableMonitors() {
  //   return [];
  // }
}

class Socket {
  final WaybrightLibrary wblib;
  Pointer<struct_waybright> wlPtr;
  String name;

  Socket(this.wblib, this.wlPtr, this.name);

  /// This function is synchronous (blocking)
  run() {
    wblib.waybright_run(wlPtr);
  }
}
