part of '../waybright.dart';

// TODO: create custom pointers

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

class _PointerAbsoluteMoveDetails {
  Monitor monitor;
  double x;
  double y;

  _PointerAbsoluteMoveDetails(this.monitor, this.x, this.y);
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

_PointerAbsoluteMoveDetails? _getMonitorFromWlrAbsoluteMovetEvent(
    Pointer<struct_wlr_pointer_motion_absolute_event> event) {
  var monitors = Monitor._monitorInstances.values;
  if (monitors.isEmpty) return null;

  // Imagine a layout where new monitors are added to the right.
  var outputWidthSum = 0;
  var maxOutputHeight = 0;
  for (var monitor in monitors.toList()) {
    outputWidthSum += monitor.resolutionWidth;
    if (monitor.resolutionHeight > maxOutputHeight) {
      maxOutputHeight = monitor.resolutionHeight;
    }
  }

  var x = event.ref.x * outputWidthSum;
  var y = event.ref.y * maxOutputHeight;

  if (x < 0) {
    return _PointerAbsoluteMoveDetails(monitors.first, x, y);
  } else if (x > outputWidthSum) {
    return _PointerAbsoluteMoveDetails(
        monitors.last, x - outputWidthSum + monitors.last.resolutionWidth, y);
  }

  var layoutMonitorX = 0;
  for (var monitor in monitors.toList()) {
    if (x >= layoutMonitorX && x < layoutMonitorX + monitor.resolutionWidth) {
      return _PointerAbsoluteMoveDetails(monitor, x - layoutMonitorX, y);
    }
    layoutMonitorX += monitor.resolutionWidth;
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
        case enum_wb_event_type.event_type_pointer_relative_move:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_pointer_motion_event>;
          pointer.onRelativeMove?.call(PointerRelativeMoveEvent(
            pointer,
            wlrEventPtr.ref.delta_x,
            wlrEventPtr.ref.delta_y,
            Duration(milliseconds: wlrEventPtr.ref.time_msec),
          ));
          break;
        case enum_wb_event_type.event_type_pointer_absolute_move:
          var wlrEventPtr = eventPtr.ref.event
              as Pointer<struct_wlr_pointer_motion_absolute_event>;
          var details = _getMonitorFromWlrAbsoluteMovetEvent(wlrEventPtr);
          if (details == null) return;
          pointer.onAbsoluteMove?.call(PointerAbsoluteMoveEvent(
            pointer,
            details.monitor,
            details.x,
            details.y,
            Duration(milliseconds: wlrEventPtr.ref.time_msec),
          ));
          break;
        case enum_wb_event_type.event_type_pointer_button:
          var wlrEventPtr =
              eventPtr.ref.event as Pointer<struct_wlr_pointer_button_event>;
          pointer.onButton?.call(PointerButtonEvent(
            pointer,
            wlrEventPtr.ref.button,
            wlrEventPtr.ref.state == enum_wlr_button_state.WLR_BUTTON_PRESSED,
            Duration(milliseconds: wlrEventPtr.ref.time_msec),
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
            Duration(milliseconds: wlrEventPtr.ref.time_msec),
          ));
          break;
      }
    }
  }

  /// This pointer's name.
  String name = "unknown-pointer";

  Pointer<struct_waybright_pointer>? _pointerPtr;

  void Function(RemovePointerEvent event)? onRemove;
  void Function(PointerRelativeMoveEvent event)? onRelativeMove;
  void Function(PointerAbsoluteMoveEvent event)? onAbsoluteMove;
  void Function(PointerButtonEvent event)? onButton;
  void Function(PointerAxisEvent event)? onAxis;

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
      return _wblib.waybright_window_has_pointer_focus(window._windowPtr) == 1;
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
