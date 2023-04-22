part of '../waybright.dart';

/// A keyboard device.
class KeyboardDevice extends InputDevice {
  static final _keyboardInstances = <KeyboardDevice>[];

  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_keyboard_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var keyboard in _keyboardInstances) {
      var handleEvent = keyboard._eventHandlers[type];
      if (handleEvent == null) return;

      handleEvent();

      if (type == enum_event_type.event_type_keyboard_remove) {
        _keyboardInstances.remove(keyboard);
      }
    }
  }

  /// This keyboard's name.
  String name = "unknown-keyboard";

  Pointer<struct_waybright_keyboard>? _keyboardPtr;
  final Map<int, Function> _eventHandlers = {};

  KeyboardDevice() {
    _keyboardInstances.add(this);
  }

  /// Sets an event handler for this keyboard.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }
}
