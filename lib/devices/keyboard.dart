part of '../waybright.dart';

/// A keyboard device.
class KeyboardDevice extends InputDevice {
  static final _keyboardInstances = <KeyboardDevice>[];

  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_keyboard_remove,
    'key': enum_event_type.event_type_keyboard_key,
    'modifiers': enum_event_type.event_type_keyboard_modifiers,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var keyboard in _keyboardInstances) {
      var eventPtr = data as Pointer<struct_waybright_keyboard_event>;
      if (keyboard._keyboardPtr != eventPtr.ref.wb_keyboard) continue;

      var handleEvent = keyboard._eventHandlers[type];
      if (handleEvent == null) continue;

      if (type == enum_event_type.event_type_keyboard_remove) {
        handleEvent();
        _keyboardInstances.remove(keyboard);
      } else if (type == enum_event_type.event_type_keyboard_key) {
        var wlrEventPtr =
            eventPtr.ref.event as Pointer<struct_wlr_event_keyboard_key>;

        var event = KeyboardKeyEvent(
          keyboard,
          wlrEventPtr.ref.keycode,
          wlrEventPtr.ref.state ==
              enum_wl_keyboard_key_state.WL_KEYBOARD_KEY_STATE_PRESSED,
          wlrEventPtr.ref.time_msec,
        );

        handleEvent(event);
      } else if (type == enum_event_type.event_type_keyboard_modifiers) {
        // var wlrEventPtr =
        //     eventPtr.ref.event as Pointer<struct_wlr_keyboard_modifiers>;

        var event = KeyboardModifiersEvent(keyboard);

        handleEvent(event);
      }
    }
  }

  /// This keyboard's name.
  String name = "unknown-keyboard";

  /// The window this keyboard is focusing on.
  Window? focusedWindow;

  Pointer<struct_waybright_keyboard>? _keyboardPtr;
  final Map<int, Function> _eventHandlers = {};

  KeyboardDevice() : super(InputDeviceType.keyboard) {
    _keyboardInstances.add(this);
  }

  /// Sets an event handler for this keyboard.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  /// Focuses this keyboard on a window.
  ///
  /// [windowCursorX] and [windowCursorY] specifies where the keyboard would
  /// enter the window.
  ///
  /// Submitting keyboard events to a window will not work unless this method
  /// is called.
  ///
  /// Although unnecessary, it is safe to call this method on the same focused
  /// window multiple times.
  void focusOnWindow(Window window) {
    var keyboardPtr = _keyboardPtr;
    var windowPtr = window._windowPtr;
    if (keyboardPtr != null && windowPtr != null) {
      _wblib.waybright_keyboard_focus_on_window(
        keyboardPtr,
        windowPtr,
      );
      focusedWindow = window;
    }
  }

  /// Clears any focus on windows.
  void clearFocus() {
    var keyboardPtr = _keyboardPtr;
    if (keyboardPtr != null) {
      _wblib.waybright_keyboard_clear_focus(keyboardPtr);
      focusedWindow = null;
    }
  }
}
