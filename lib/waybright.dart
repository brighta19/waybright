/// The waybright library.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'src/generated/waybright_bindings.dart';

export 'animation.dart';

part 'events/cursor/cursor_image.dart';
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
part 'events/window_events.dart';
part 'events/monitor/monitor_frame.dart';
part 'devices/pointer.dart';
part 'devices/keyboard.dart';
part 'input_device.dart';
part 'image.dart';
part 'mode.dart';
part 'monitor.dart';
part 'renderer.dart';
part 'window.dart';

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

        var renderer = Renderer._fromPointer(monitorPtr.ref.wb_renderer);
        var monitor = Monitor._fromPointer(monitorPtr, renderer)
          ..name = _toString(monitorPtr.ref.wlr_output.ref.name);

        waybright.onNewMonitor?.call(NewMonitorEvent(monitor));
      } else if (type == enum_wb_event_type.event_type_window_new) {
        var windowPtr = data as Pointer<struct_waybright_window>;

        var window = Window._fromPointer(windowPtr);

        waybright.onWindowCreate?.call(WindowCreateEvent(window));
      } else if (type == enum_wb_event_type.event_type_input_new) {
        var inputPtr = data as Pointer<struct_waybright_input>;
        var wlrInputDevice = inputPtr.ref.wlr_input_device.ref;

        PointerDevice? pointer;
        KeyboardDevice? keyboard;

        if (inputPtr.ref.pointer != nullptr) {
          var pointerPtr = inputPtr.ref.pointer;

          pointer = PointerDevice._fromPointer(pointerPtr)
            ..name = _toString(wlrInputDevice.name);
        } else if (inputPtr.ref.keyboard != nullptr) {
          var keyboardPtr = inputPtr.ref.keyboard;

          keyboard = KeyboardDevice._fromPointer(keyboardPtr)
            ..name = _toString(wlrInputDevice.name);
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
      } else if (type == enum_wb_event_type.event_type_cursor_image) {
        var imagePtr = data as Pointer<struct_waybright_image>;

        if (imagePtr == nullptr) {
          waybright.onCursorImage?.call(CursorImageEvent(null));
        } else {
          var image = Image._fromPointer(imagePtr);
          waybright.onCursorImage?.call(CursorImageEvent(image));
        }
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

    _waybrightInstances.add(this);
    _wbPtr.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  Future<Image> _loadPngImage(String path) async {
    var pathPtr = path.toNativeUtf8() as Pointer<Char>;
    var imagePtr = _wblib.waybright_load_png_image(_wbPtr, pathPtr);
    if (imagePtr == nullptr) {
      throw Exception("Loading png image failed unexpectedly.");
    }

    return Image._fromPointer(imagePtr);
  }

  void _checkEvents() {
    if (!_isRunning) return;
    _wblib.waybright_check_events(_wbPtr);
    Future(() => _checkEvents());
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
  void Function(WindowCreateEvent event)? onWindowCreate;
  void Function(NewInputEvent event)? onNewInput;
  void Function(CursorImageEvent event)? onCursorImage;

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
