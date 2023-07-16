/// The waybright library.
library;

import 'dart:ffi';
import 'dart:async';
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
part 'events/image_events.dart';
part 'events/window_events.dart';
part 'events/monitor_events.dart';
part 'devices/pointer.dart';
part 'devices/keyboard.dart';
part 'input_device.dart';
part 'image.dart';
part 'mode.dart';
part 'monitor.dart';
part 'renderer.dart';
part 'window.dart';
part 'rect.dart';

final WaybrightLibrary _wblib =
    WaybrightLibrary(DynamicLibrary.open("./waybright.so"));

String? _toDartString(Pointer<Char> stringPtr) {
  if (stringPtr == nullptr) return null;
  return (stringPtr as Pointer<Utf8>).toDartString();
}

Pointer<Char> _toCString(String? string) {
  if (string == null) return nullptr;
  return string.toNativeUtf8() as Pointer<Char>;
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

        waybright.onMonitorAdd?.call(
          MonitorAddEvent(Monitor._fromPointer(monitorPtr)),
        );
      } else if (type == enum_wb_event_type.event_type_window_new) {
        var windowPtr = data as Pointer<struct_waybright_window>;

        waybright.onWindowCreate?.call(
          WindowCreateEvent(Window._fromPointer(windowPtr)),
        );
      } else if (type == enum_wb_event_type.event_type_input_new) {
        var inputPtr = data as Pointer<struct_waybright_input>;
        var wlrInputDevice = inputPtr.ref.wlr_input_device.ref;

        PointerDevice? pointer;
        KeyboardDevice? keyboard;

        if (inputPtr.ref.pointer != nullptr) {
          var pointerPtr = inputPtr.ref.pointer;

          pointer = PointerDevice._fromPointer(pointerPtr)
            ..name = _toDartString(wlrInputDevice.name) ?? "";
        } else if (inputPtr.ref.keyboard != nullptr) {
          var keyboardPtr = inputPtr.ref.keyboard;

          keyboard = KeyboardDevice._fromPointer(keyboardPtr)
            ..name = _toDartString(wlrInputDevice.name) ?? "";
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
        var eventPtr = data as Pointer<struct_waybright_image_event>;
        var wlrEventPtr = eventPtr.ref.event
            as Pointer<struct_wlr_seat_pointer_request_set_cursor_event>;
        var image = eventPtr.ref.wb_image == nullptr
            ? null
            : Image._fromPointer(eventPtr.ref.wb_image);

        waybright.onCursorImage?.call(CursorImageEvent(
          image,
          wlrEventPtr.ref.hotspot_x,
          wlrEventPtr.ref.hotspot_y,
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

    _waybrightInstances.add(this);
    _wbPtr.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  Future<Image> _loadImage(String path) async {
    var errorTypePtr = calloc<Int>();

    var imagePtr =
        _wblib.waybright_load_image(_wbPtr, _toCString(path), errorTypePtr);
    int errorType = errorTypePtr.value;

    calloc.free(errorTypePtr);

    if (imagePtr == nullptr) {
      switch (errorType) {
        case enum_wb_image_error_type.image_error_type_image_not_found:
          throw Exception("Image not found.");
        case enum_wb_image_error_type.image_error_type_image_load_failed:
          throw Exception("Loading image failed.");
        default:
          throw Exception("An unknown error occurred.");
      }
    }

    return Image._fromPointer(imagePtr);
  }

  void _checkEvents() {
    if (!_isRunning) return;
    _wblib.waybright_check_events(_wbPtr);
    Future(_checkEvents);
  }

  void _runEventLoop() {
    _isRunning = true;
    _checkEvents();
  }

  String _openSocket([String? socketName]) {
    var namePtr = _toCString(socketName);

    if (_wblib.waybright_open_socket(_wbPtr, namePtr) != 0) {
      throw Exception("Opening wayland socket failed unexpectedly.");
    }

    this.socketName = _toDartString(_wbPtr.ref.socket_name);
    _runEventLoop();
    return this.socketName!;
  }

  void _closeSocket() {
    _isRunning = false;
    _wblib.waybright_close_socket(_wbPtr);
  }

  String? socketName;

  void Function(MonitorAddEvent event)? onMonitorAdd;
  void Function(WindowCreateEvent event)? onWindowCreate;
  void Function(NewInputEvent event)? onNewInput;
  // TODO: move handler to window?
  void Function(CursorImageEvent event)? onCursorImage;

  get isRunning => _isRunning;

  /// Creates a [Waybright] instance.
  ///
  /// Throws an [Exception] if an unexpected exception occurs.
  Waybright() {
    _initialize();
  }

  Future<Image> loadImage(String path) async => _loadImage(path);
  String openSocket([String? socketName]) => _openSocket(socketName);
  void closeSocket() => _closeSocket();
}
