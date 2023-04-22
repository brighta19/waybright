part of '../waybright.dart';

/// A pointer device.
class PointerDevice extends InputDevice {
  static final _pointerInstances = <PointerDevice>[];

  static final _eventTypeFromString = {
    'move': enum_event_type.event_type_pointer_move,
    'remove': enum_event_type.event_type_pointer_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var pointer in _pointerInstances) {
      var handleEvent = pointer._eventHandlers[type];
      if (handleEvent == null) return;

      if (type == enum_event_type.event_type_pointer_move) {
        var wbPointerMoveEvent =
            data as Pointer<struct_waybright_pointer_move_event>;
        var event = PointerMoveEvent(
            wbPointerMoveEvent.ref.delta_x, wbPointerMoveEvent.ref.delta_y);

        handleEvent(event);
        return;
      }

      handleEvent();

      if (type == enum_event_type.event_type_pointer_remove) {
        _pointerInstances.remove(pointer);
      }
    }
  }

  /// This pointer's name.
  String name = "unknown-pointer";

  Pointer<struct_waybright_pointer>? _pointerPtr;
  final Map<int, Function> _eventHandlers = {};

  PointerDevice() {
    _pointerInstances.add(this);
  }

  /// Sets an event handler for this pointer.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }
}
