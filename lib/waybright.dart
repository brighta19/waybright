import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:waybright/waybright_bindings.dart';

enum WindowType { topLevel, popUp }

class Window {
  WindowType type;

  Window(this.type);
}

class WindowStack {
  addToFront(Window window) {}
  moveToFront() {}
  remove(Window window) {}

  // [Symbol.iterator]() {}
  get reverse {}
}

abstract class Protocol {
  static int nextId = 0;

  int id = nextId++;

  on(String event, Function callback);
  emit() {}
}

class XDGShellProtocol extends Protocol {
  @override
  on(String event, Function callback) {}
}

class DisplayRenderingContext {
  clearRect(int x, int y, int width, int height) {}
}

class DisplayResolution {
  int width;
  int height;

  DisplayResolution(this.width, this.height);
}

class DisplayMode {
  DisplayResolution resolution;
  int rate;

  DisplayMode(this.resolution, this.rate);
}

class Display {
  int width;
  int height;
  DisplayRenderingContext context = DisplayRenderingContext();

  Display(this.width, this.height);

  void on(String event, Function callback) {}

  DisplayRenderingContext getRenderingContext() {
    return context;
  }

  List<DisplayMode> getAvailableModes() {
    return [];
  }

  setMode(DisplayMode mode) {}
}

class Waybright {
  final WaybrightLibrary wblib =
      WaybrightLibrary(DynamicLibrary.open("lib/waybright.so"));

  late Pointer<waybright> wbPtr;

  Waybright() {
    wbPtr = wblib.waybright_create();

    if (wblib.waybright_init(wbPtr) != 0) {
      throw "Creating waybright instance failed.";
    }
  }

  Future<Socket> listen({String? socketName}) async {
    int statusCode;
    if (socketName == null) {
      statusCode = wblib.waybright_open_socket(wbPtr);
    } else {
      Pointer<Char> namePtr = socketName.toNativeUtf8().cast();
      statusCode = wblib.waybright_open_socket_with_name(wbPtr, namePtr);
    }

    if (statusCode == 0) {
      String socketName = wbPtr.ref.socket_name.cast<Utf8>().toDartString();
      return Socket(wblib, wbPtr, socketName);
    } else {
      throw "Couldn't open socket.";
    }
  }

  void on(String event, Function callback) {}

  void useProtocol(Protocol protocol) {}

  List<Display> getAvailableDisplays() {
    return [];
  }
}

class Socket {
  final WaybrightLibrary wblib;
  Pointer<waybright> wlPtr;
  String socketName;

  Socket(this.wblib, this.wlPtr, this.socketName);

  run() {
    wblib.waybright_run(wlPtr);
  }
}
