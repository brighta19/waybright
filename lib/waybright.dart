/// The waybright library.
library;

import 'dart:ffi';
import 'dart:collection';
import 'package:ffi/ffi.dart';
import 'src/generated/waybright_bindings.dart';

export 'animation.dart';

part 'events/pointer/pointer_event.dart';
part 'events/pointer/pointer_move.dart';
part 'events/pointer/pointer_relative_move.dart';
part 'events/pointer/pointer_absolute_move.dart';
part 'events/pointer/pointer_button.dart';
part 'events/pointer/pointer_axis.dart';
part 'events/pointer/pointer_update.dart';
part 'events/keyboard/keyboard_event.dart';
part 'events/keyboard/keyboard_key.dart';
part 'events/keyboard/keyboard_modifiers.dart';
part 'events/keyboard/keyboard_update.dart';
part 'events/window/window_event.dart';
part 'events/window/window_move.dart';
part 'events/window/window_resize.dart';
part 'events/window/window_maximize.dart';
part 'events/window/window_fullscreen.dart';
part 'events/window/window_newpopup.dart';
part 'events/monitor/monitor_frame.dart';
part 'devices/pointer.dart';
part 'devices/keyboard.dart';
part 'input_device.dart';
part 'image.dart';
part 'mode.dart';
part 'monitor.dart';
part 'renderer.dart';
part 'window.dart';
part 'windowlist.dart';

final WaybrightLibrary _wblib =
    WaybrightLibrary(DynamicLibrary.open("./waybright.so"));

String _toString(Pointer<Char> stringPtr) {
  if (stringPtr == nullptr) return "";
  return (stringPtr as Pointer<Utf8>).toDartString();
}

class NewMonitorEvent {
  final Monitor monitor;

  NewMonitorEvent(this.monitor);
}

class NewWindowEvent {
  final Window window;

  NewWindowEvent(this.window);
}

class NewInputEvent {
  PointerDevice? pointer;
  KeyboardDevice? keyboard;

  NewInputEvent({this.pointer, this.keyboard});
}

/// A Waybright!
class Waybright {
  static final _waybrightInstances = <Waybright>[];

  static void _onEvent(int type, Pointer<Void> data) {
    for (var waybright in _waybrightInstances) {
      if (type == enum_wb_event_type.event_type_monitor_new) {
        var monitorPtr = data as Pointer<struct_waybright_monitor>;

        var renderer = Renderer().._rendererPtr = monitorPtr.ref.wb_renderer;
        var monitor = Monitor(renderer)
          ..name = _toString(monitorPtr.ref.wlr_output.ref.name)
          .._monitorPtr = monitorPtr
          .._monitorPtr?.ref.handle_event =
              Pointer.fromFunction(Monitor._onEvent);

        waybright.onNewMonitor?.call(NewMonitorEvent(monitor));
      } else if (type == enum_wb_event_type.event_type_window_new) {
        var windowPtr = data as Pointer<struct_waybright_window>;
        var wlrXdgToplevel = windowPtr.ref.wlr_xdg_toplevel.ref;

        var window = Window(false)
          .._windowPtr = windowPtr
          .._windowPtr?.ref.handle_event = Pointer.fromFunction(Window._onEvent)
          ..appId = _toString(wlrXdgToplevel.app_id)
          ..title = _toString(wlrXdgToplevel.title);

        waybright.onNewWindow?.call(NewWindowEvent(window));
      } else if (type == enum_wb_event_type.event_type_input_new) {
        var inputPtr = data as Pointer<struct_waybright_input>;
        var wlrInputDevice = inputPtr.ref.wlr_input_device.ref;

        PointerDevice? pointer;
        KeyboardDevice? keyboard;

        if (inputPtr.ref.pointer != nullptr) {
          var pointerPtr = inputPtr.ref.pointer;

          pointer = PointerDevice()
            ..name = _toString(wlrInputDevice.name)
            .._pointerPtr = pointerPtr
            .._pointerPtr?.ref.handle_event =
                Pointer.fromFunction(PointerDevice._onEvent);
        } else if (inputPtr.ref.keyboard != nullptr) {
          var keyboardPtr = inputPtr.ref.keyboard;

          keyboard = KeyboardDevice()
            ..name = _toString(wlrInputDevice.name)
            .._keyboardPtr = keyboardPtr
            .._keyboardPtr?.ref.handle_event =
                Pointer.fromFunction(KeyboardDevice._onEvent);
        }

        int capabilities = enum_wl_seat_capability.WL_SEAT_CAPABILITY_POINTER;
        if (KeyboardDevice._keyboardInstances.isNotEmpty) {
          capabilities |= enum_wl_seat_capability.WL_SEAT_CAPABILITY_KEYBOARD;
        }
        _wblib.wlr_seat_set_capabilities(
          waybright._wbPtr.ref.wlr_seat,
          capabilities,
        );

        waybright.onNewInput?.call(NewInputEvent(
          pointer: pointer,
          keyboard: keyboard,
        ));
      }
    }
  }

  final Pointer<struct_waybright> _wbPtr = _wblib.waybright_create();
  var _isRunning = false;

  _initialize() {
    if (_wblib.waybright_init(_wbPtr) != 0) {
      _wblib.waybright_destroy(_wbPtr);
      throw Exception("Waybright instance creation failed unexpectedly.");
    }

    _wbPtr.ref.handle_event = Pointer.fromFunction(_onEvent);
    _waybrightInstances.add(this);
  }

  Future<Image> _loadPngImage(String path) async {
    var pathPtr = path.toNativeUtf8() as Pointer<Char>;
    var imagePtr = _wblib.waybright_load_png_image(_wbPtr, pathPtr);
    if (imagePtr == nullptr) {
      throw Exception("Loading png image failed unexpectedly.");
    }

    return Image()
      .._imagePtr = imagePtr
      .._imagePtr?.ref.handle_event = Pointer.fromFunction(Image._onEvent);
  }

  Future<void> _checkEvents() async {
    if (!_isRunning) return;
    _wblib.waybright_check_events(_wbPtr);
    return Future(() => _checkEvents());
  }

  void _runEventLoop() {
    _isRunning = true;
    Future(() => _checkEvents());
  }

  String _openSocket([String? socketName]) {
    var namePtr = socketName == null
        ? nullptr
        : socketName.toNativeUtf8() as Pointer<Char>;

    if (_wblib.waybright_open_socket(_wbPtr, namePtr) != 0) {
      throw Exception("Opening wayland socket failed unexpectedly.");
    }

    this.socketName = _toString(_wbPtr.ref.socket_name);
    _runEventLoop();
    return this.socketName!;
  }

  void _closeSocket() {
    _isRunning = false;
    _wblib.waybright_close_socket(_wbPtr);
  }

  String? socketName;

  void Function(NewMonitorEvent event)? onNewMonitor;
  void Function(NewWindowEvent event)? onNewWindow;
  void Function(NewInputEvent event)? onNewInput;

  get isRunning => _isRunning;

  /// Creates a [Waybright] instance.
  ///
  /// Throws an [Exception] if an unexpected exception occurs.
  Waybright() {
    _initialize();
  }

  Future<Image> loadPngImage(String path) async => _loadPngImage(path);
  String openSocket([String? socketName]) => _openSocket(socketName);
  void closeSocket() => _closeSocket();
}
