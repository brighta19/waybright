part of '../waybright.dart';

/// A pointer device.
class PointerDevice extends InputDevice {
  static final _pointerInstances = <PointerDevice>[];

  static final _eventTypeFromString = {
    'move': enum_event_type.event_type_pointer_move,
    'teleport': enum_event_type.event_type_pointer_teleport,
    'button': enum_event_type.event_type_pointer_button,
    'remove': enum_event_type.event_type_pointer_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var pointer in _pointerInstances) {
      var eventPtr = data as Pointer<struct_waybright_pointer_event>;
      if (pointer._pointerPtr != eventPtr.ref.wb_pointer) continue;

      var handleEvent = pointer._eventHandlers[type];
      if (handleEvent == null) continue;

      if (type == enum_event_type.event_type_pointer_move) {
        var wlrEventPtr =
            eventPtr.ref.event as Pointer<struct_wlr_event_pointer_motion>;

        var event = PointerMoveEvent(
          pointer,
          wlrEventPtr.ref.delta_x,
          wlrEventPtr.ref.delta_y,
          wlrEventPtr.ref.time_msec,
        );

        handleEvent(event);
      } else if (type == enum_event_type.event_type_pointer_teleport) {
        var wlrEventPtr = eventPtr.ref.event
            as Pointer<struct_wlr_event_pointer_motion_absolute>;

        // Imagine a layout where new monitors are added to the right.
        var outputWidthSum = 0;
        var maxOutputHeight = 0;
        for (var monitor in Monitor._monitorInstances) {
          outputWidthSum += monitor.mode.width;
          if (monitor.mode.height > maxOutputHeight) {
            maxOutputHeight = monitor.mode.height;
          }
        }

        var x = wlrEventPtr.ref.x * outputWidthSum;
        var y = wlrEventPtr.ref.y * maxOutputHeight;

        var layoutMonitorX = 0;
        Monitor? activeMonitor;
        for (var monitor in Monitor._monitorInstances) {
          if (x >= layoutMonitorX && x < layoutMonitorX + monitor.mode.width) {
            activeMonitor = monitor;
            break;
          }
          layoutMonitorX += monitor.mode.width;
        }

        if (activeMonitor == null) return;

        var event = PointerTeleportEvent(
          pointer,
          activeMonitor,
          x - layoutMonitorX,
          y,
          wlrEventPtr.ref.time_msec,
        );

        handleEvent(event);
      } else if (type == enum_event_type.event_type_pointer_button) {
        var wlrEventPtr =
            eventPtr.ref.event as Pointer<struct_wlr_event_pointer_button>;

        var event = PointerButtonEvent(
          pointer,
          wlrEventPtr.ref.button,
          wlrEventPtr.ref.state == enum_wlr_button_state.WLR_BUTTON_PRESSED,
          wlrEventPtr.ref.time_msec,
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

  /// The window this pointer is focusing on.
  Window? focusedWindow;

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
  void focusOnWindow(Window window, num windowCursorX, num windowCursorY) {
    var pointerPtr = _pointerPtr;
    var windowPtr = window._windowPtr;
    if (pointerPtr != null && windowPtr != null) {
      _wblib.waybright_pointer_focus_on_window(
        pointerPtr,
        windowPtr,
        windowCursorX.toInt(),
        windowCursorY.toInt(),
      );
      focusedWindow = window;
    }
  }

  /// Clears any focus on windows.
  void clearFocus() {
    var pointerPtr = _pointerPtr;
    if (pointerPtr != null) {
      _wblib.waybright_pointer_clear_focus(pointerPtr);
      focusedWindow = null;
    }
  }
}
