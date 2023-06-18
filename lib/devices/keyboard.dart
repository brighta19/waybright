part of '../waybright.dart';

class RemoveKeyboardEvent {}

/// A keyboard device.
class KeyboardDevice extends InputDevice {
  static final _keyboardInstances = <KeyboardDevice>[];

  static void _onEvent(int type, Pointer<Void> data) {
    var keyboards = _keyboardInstances.toList();
    for (var keyboard in keyboards) {
      var eventPtr = data as Pointer<struct_waybright_keyboard_event>;
      if (keyboard._keyboardPtr != eventPtr.ref.wb_keyboard) continue;

      switch (type) {
        case enum_wb_event_type.event_type_keyboard_remove:
          keyboard.onRemove?.call(RemoveKeyboardEvent());
          _keyboardInstances.remove(keyboard);
          break;
        case enum_wb_event_type.event_type_keyboard_key:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_keyboard_key_event>;

          keyboard.onKey?.call(KeyboardKeyEvent(
            keyboard,
            wlrEventPtr.ref.keycode,
            wlrEventPtr.ref.state ==
                enum_wl_keyboard_key_state.WL_KEYBOARD_KEY_STATE_PRESSED,
            wlrEventPtr.ref.time_msec,
          ));
          break;
        case enum_wb_event_type.event_type_keyboard_modifiers:
          keyboard.onModifiers?.call(KeyboardModifiersEvent(keyboard));
          break;
      }
    }
  }

  /// This keyboard's name.
  String name = "unknown-keyboard";

  Pointer<struct_waybright_keyboard>? _keyboardPtr;

  void Function(RemoveKeyboardEvent)? onRemove;
  void Function(KeyboardKeyEvent)? onKey;
  void Function(KeyboardModifiersEvent)? onModifiers;

  KeyboardDevice() : super(InputDeviceType.keyboard) {
    _keyboardInstances.add(this);
  }

  KeyboardDevice._fromPointer(
    Pointer<struct_waybright_keyboard> this._keyboardPtr,
  ) : super(InputDeviceType.keyboard) {
    _keyboardInstances.add(this);
    _keyboardPtr?.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  // TODO: maybe get focused window?

  bool isFocusedOnAWindow() {
    var keyboardPtr = _keyboardPtr;
    return keyboardPtr == null
        ? false
        : keyboardPtr.ref.wb.ref.wlr_seat.ref.keyboard_state.focused_surface !=
            nullptr;
  }

  bool isFocusedOnWindow(Window window) {
    var keyboardPtr = _keyboardPtr;
    if (keyboardPtr != null) {
      return window._windowPtr.ref.wlr_xdg_surface.ref.surface ==
          window._windowPtr.ref.wb.ref.wlr_seat.ref.keyboard_state
              .focused_surface;
    }
    return false;
  }

  /// Focuses this keyboard on a window.
  ///
  /// Submitting keyboard events to a window will not work unless this method
  /// is called.
  ///
  /// Although unnecessary, it is safe to call this method on the same focused
  /// window multiple times.
  void focusOnWindow(Window window) {
    var keyboardPtr = _keyboardPtr;
    if (keyboardPtr != null) {
      _wblib.waybright_keyboard_focus_on_window(
        keyboardPtr,
        window._windowPtr,
      );
    }
  }

  /// Clears any focus on windows.
  void clearFocus() {
    var keyboardPtr = _keyboardPtr;
    if (keyboardPtr != null) {
      _wblib.waybright_keyboard_clear_focus(keyboardPtr);
    }
  }
}
