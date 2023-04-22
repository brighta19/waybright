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
        var eventPtr = data as Pointer<struct_wlr_event_pointer_motion>;

        var event = PointerMoveEvent(
          eventPtr.ref.delta_x,
          eventPtr.ref.delta_y,
          eventPtr.ref.time_msec,
        );

        handleEvent(event);
      } else if (type == enum_event_type.event_type_pointer_remove) {
        handleEvent();
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

  /// Focuses this pointer on a window.
  ///
  /// [windowCursorX] and [windowCursorY] specifies where the pointer would
  /// enter the window.
  ///
  /// Submitting pointer events to a window will not work unless this method
  /// is called.
  ///
  /// Although unnecessary, it is safe to call this method on the same focused
  /// window multiple times.
  void focusOnWindow(Window window, int windowCursorX, int windowCursorY) {
    var pointerPtr = _pointerPtr;
    var windowPtr = window._windowPtr;
    if (pointerPtr != null && windowPtr != null) {
      _wblib.waybright_pointer_focus_on_window(
        pointerPtr,
        windowPtr,
        windowCursorX,
        windowCursorY,
      );
    }
  }

  /// Clears any focus on windows.
  void clearFocus() {
    var pointerPtr = _pointerPtr;
    if (pointerPtr != null) {
      _wblib.waybright_pointer_clear_focus(pointerPtr);
    }
  }
}
