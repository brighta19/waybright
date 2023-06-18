part of '../waybright.dart';

enum PointerAxisSource {
  wheel,
  finger,
  continuous,
  wheelTilt,
}

enum PointerAxisOrientation {
  vertical,
  horizontal,
}

class _PointerTeleportDetails {
  Monitor monitor;
  double x;
  double y;

  _PointerTeleportDetails(this.monitor, this.x, this.y);
}

class RemovePointerEvent {}

PointerAxisSource _getPointerAxisSourceFromWlrAxisEvent(
    Pointer<struct_wlr_pointer_axis_event> event) {
  switch (event.ref.source) {
    case enum_wlr_axis_source.WLR_AXIS_SOURCE_WHEEL:
      return PointerAxisSource.wheel;
    case enum_wlr_axis_source.WLR_AXIS_SOURCE_FINGER:
      return PointerAxisSource.finger;
    case enum_wlr_axis_source.WLR_AXIS_SOURCE_CONTINUOUS:
      return PointerAxisSource.continuous;
    case enum_wlr_axis_source.WLR_AXIS_SOURCE_WHEEL_TILT:
      return PointerAxisSource.wheelTilt;
    default:
      throw Exception("Unknown axis source");
  }
}

PointerAxisOrientation _getPointerAxisOrientationFromWlrAxisEvent(
    Pointer<struct_wlr_pointer_axis_event> event) {
  switch (event.ref.orientation) {
    case enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_VERTICAL:
      return PointerAxisOrientation.vertical;
    case enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_HORIZONTAL:
      return PointerAxisOrientation.horizontal;
    default:
      throw Exception("Unknown axis orientation");
  }
}

_PointerTeleportDetails? _getMonitorFromWlrTeleportEvent(
    Pointer<struct_wlr_pointer_motion_absolute_event> event) {
  var monitors = Monitor._monitorInstances.values;

// Imagine a layout where new monitors are added to the right.
  var outputWidthSum = 0;
  var maxOutputHeight = 0;
  for (var monitor in monitors.toList()) {
    outputWidthSum += monitor.mode.width;
    if (monitor.mode.height > maxOutputHeight) {
      maxOutputHeight = monitor.mode.height;
    }
  }

  var x = event.ref.x * outputWidthSum;
  var y = event.ref.y * maxOutputHeight;

  var layoutMonitorX = 0;
  for (var monitor in monitors.toList()) {
    if (x >= layoutMonitorX && x < layoutMonitorX + monitor.mode.width) {
      return _PointerTeleportDetails(monitor, x - layoutMonitorX, y);
    }
    layoutMonitorX += monitor.mode.width;
  }
  return null;
}

/// A pointer device.
class PointerDevice extends InputDevice {
  static final _pointerInstances = <PointerDevice>[];

  static void _onEvent(int type, Pointer<Void> data) {
    var pointers = _pointerInstances.toList();
    for (var pointer in pointers) {
      var eventPtr = data as Pointer<struct_waybright_pointer_event>;
      if (pointer._pointerPtr != eventPtr.ref.wb_pointer) continue;

      switch (type) {
        case enum_wb_event_type.event_type_pointer_remove:
          pointer.onRemove?.call(RemovePointerEvent());
          _pointerInstances.remove(pointer);
          break;
        case enum_wb_event_type.event_type_pointer_move:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_pointer_motion_event>;
          pointer.onMove?.call(PointerRelativeMoveEvent(
            pointer,
            wlrEventPtr.ref.delta_x,
            wlrEventPtr.ref.delta_y,
            wlrEventPtr.ref.time_msec,
          ));
          break;
        case enum_wb_event_type.event_type_pointer_teleport:
          var wlrEventPtr = eventPtr.ref.event
              as Pointer<struct_wlr_pointer_motion_absolute_event>;
          var details = _getMonitorFromWlrTeleportEvent(wlrEventPtr);
          if (details == null) return;
          pointer.onTeleport?.call(PointerAbsoluteMoveEvent(
            pointer,
            details.monitor,
            details.x,
            details.y,
            wlrEventPtr.ref.time_msec,
          ));
          break;
        case enum_wb_event_type.event_type_pointer_button:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_pointer_button_event>;
          pointer.onButton?.call(PointerButtonEvent(
            pointer,
            wlrEventPtr.ref.button,
            wlrEventPtr.ref.state == enum_wlr_button_state.WLR_BUTTON_PRESSED,
            wlrEventPtr.ref.time_msec,
          ));
          break;
        case enum_wb_event_type.event_type_pointer_axis:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_pointer_axis_event>;

          PointerAxisSource source =
              _getPointerAxisSourceFromWlrAxisEvent(wlrEventPtr);
          PointerAxisOrientation orientation =
              _getPointerAxisOrientationFromWlrAxisEvent(wlrEventPtr);

          pointer.onAxis?.call(PointerAxisEvent(
            pointer,
            wlrEventPtr.ref.delta,
            wlrEventPtr.ref.delta_discrete,
            source,
            orientation,
            wlrEventPtr.ref.time_msec,
          ));
          break;
      }
    }
  }

  /// This pointer's name.
  String name = "unknown-pointer";

  Pointer<struct_waybright_pointer>? _pointerPtr;

  void Function(RemovePointerEvent)? onRemove;
  void Function(PointerRelativeMoveEvent)? onMove;
  void Function(PointerAbsoluteMoveEvent)? onTeleport;
  void Function(PointerButtonEvent)? onButton;
  void Function(PointerAxisEvent)? onAxis;

  PointerDevice() : super(InputDeviceType.pointer) {
    _pointerInstances.add(this);
  }

  PointerDevice._fromPointer(Pointer<struct_waybright_pointer> this._pointerPtr)
      : super(InputDeviceType.pointer) {
    _pointerInstances.add(this);
    _pointerPtr?.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  bool isFocusedOnAWindow() {
    var pointerPtr = _pointerPtr;
    return pointerPtr == null
        ? false
        : pointerPtr.ref.wb.ref.wlr_seat.ref.pointer_state.focused_surface !=
            nullptr;
  }

  bool isFocusedOnWindow(Window window) {
    var pointerPtr = _pointerPtr;
    if (pointerPtr != null) {
      return _wblib.wlr_seat_pointer_surface_has_focus(
        window._windowPtr.ref.wb.ref.wlr_seat,
        window._windowPtr.ref.wlr_xdg_surface.ref.surface,
      );
    }
    return false;
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
    if (pointerPtr != null) {
      _wblib.waybright_pointer_focus_on_window(
        pointerPtr,
        window._windowPtr,
        windowCursorX.toInt(),
        windowCursorY.toInt(),
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
