/// The waybright library.
library;

import 'dart:ffi';
import 'dart:collection';
import 'package:ffi/ffi.dart';
import 'src/generated/waybright_bindings.dart';

part 'events/input_new.dart';
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
part 'devices/pointer.dart';
part 'devices/keyboard.dart';
part 'input_device.dart';
part 'image.dart';
part 'socket.dart';
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

/// A Waybright!
class Waybright {
  static final _waybrightInstances = <Waybright>[];

  static final _eventTypeFromString = {
    'monitor-new': enum_wb_event_type.event_type_monitor_new,
    'window-new': enum_wb_event_type.event_type_window_new,
    'input-new': enum_wb_event_type.event_type_input_new,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var waybright in _waybrightInstances) {
      var handleEvent = waybright._eventHandlers[type];
      if (handleEvent == null) continue;

      if (type == enum_wb_event_type.event_type_monitor_new) {
        var monitorPtr = data as Pointer<struct_waybright_monitor>;

        var renderer = Renderer().._rendererPtr = monitorPtr.ref.wb_renderer;
        var monitor = Monitor(renderer)
          ..name = _toString(monitorPtr.ref.wlr_output.ref.name)
          .._monitorPtr = monitorPtr
          .._monitorPtr?.ref.handle_event =
              Pointer.fromFunction(Monitor._executeEventHandler);

        handleEvent(monitor);
      } else if (type == enum_wb_event_type.event_type_window_new) {
        var windowPtr = data as Pointer<struct_waybright_window>;
        var wlrXdgToplevel = windowPtr.ref.wlr_xdg_toplevel.ref;

        var window = Window(windowPtr.ref.is_popup == 1)
          ..appId = _toString(wlrXdgToplevel.app_id)
          ..title = _toString(wlrXdgToplevel.title)
          .._windowPtr = windowPtr
          .._windowPtr?.ref.handle_event =
              Pointer.fromFunction(Window._executeEventHandler);

        handleEvent(window);
      } else if (type == enum_wb_event_type.event_type_input_new) {
        var inputPtr = data as Pointer<struct_waybright_input>;
        var wlrInputDevice = inputPtr.ref.wlr_input_device.ref;

        var inputEvent = InputNewEvent();

        if (inputPtr.ref.pointer != nullptr) {
          var pointerPtr = inputPtr.ref.pointer;

          var pointer = PointerDevice()
            ..name = _toString(wlrInputDevice.name)
            .._pointerPtr = pointerPtr
            .._pointerPtr?.ref.handle_event =
                Pointer.fromFunction(PointerDevice._executeEventHandler);

          inputEvent.pointer = pointer;
        } else if (inputPtr.ref.keyboard != nullptr) {
          var keyboardPtr = inputPtr.ref.keyboard;

          var keyboard = KeyboardDevice()
            ..name = _toString(wlrInputDevice.name)
            .._keyboardPtr = keyboardPtr
            .._keyboardPtr?.ref.handle_event =
                Pointer.fromFunction(KeyboardDevice._executeEventHandler);

          inputEvent.keyboard = keyboard;
        }

        int capabilities = enum_wl_seat_capability.WL_SEAT_CAPABILITY_POINTER;
        if (KeyboardDevice._keyboardInstances.isNotEmpty) {
          capabilities |= enum_wl_seat_capability.WL_SEAT_CAPABILITY_KEYBOARD;
        }
        _wblib.wlr_seat_set_capabilities(
          waybright._wbPtr.ref.wlr_seat,
          capabilities,
        );

        handleEvent(inputEvent);
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

  Future<Image> loadPngImage(String path) async {
    var pathPtr = path.toNativeUtf8() as Pointer<Char>;
    var imagePtr = _wblib.waybright_load_png_image(_wbPtr, pathPtr);
    if (imagePtr == nullptr) {
      throw Exception("Loading png image failed unexpectedly.");
    }

    return Image().._imagePtr = imagePtr;
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
    return Socket(name).._wbPtr = _wbPtr;
  }
}
