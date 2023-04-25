part of "./waybright.dart";

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol.
class Window {
  static final _windowInstances = <Window>[];

  static final _eventTypeFromString = {
    'show': enum_event_type.event_type_window_show,
    'hide': enum_event_type.event_type_window_hide,
    'move': enum_event_type.event_type_window_move,
    'remove': enum_event_type.event_type_window_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var window in _windowInstances) {
      var windowPtr = data as Pointer<struct_waybright_window>;
      if (window._windowPtr != windowPtr) continue;

      var handleEvent = window._eventHandlers[type];
      if (handleEvent == null) continue;

      if (type == enum_event_type.event_type_window_show) {
        window.isVisible = true;
      } else if (type == enum_event_type.event_type_window_hide) {
        window.isVisible = false;
      }

      handleEvent();

      if (type == enum_event_type.event_type_window_remove) {
        _windowInstances.remove(window);
      }
    }
  }

  /// The application id of this window.
  String appId = "unknown-application";

  /// The title of this window.
  String title = "untitled";

  /// Whether this window is a popup window.
  bool isPopup;

  /// Whether this window is visible.
  bool isVisible = false;

  /// Whether this window is focused.
  bool isFocused = false;

  final Map<int, Function> _eventHandlers = {};
  Pointer<struct_waybright_window>? _windowPtr;

  Window(this.isPopup) {
    _windowInstances.add(this);
  }

  /// Sets an event handler for this window.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  // TODO: Add setters for width and height

  /// The horizontal position of this window's drawing area.
  num drawingX = 0;

  /// The vertical position of this window's drawing area.
  num drawingY = 0;

  /// The horizontal size of this window's drawing area.
  int get drawingWidth {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return windowPtr.ref.wlr_xdg_surface.ref.surface.ref.current.width;
    }
    return 0;
  }

  /// The vertical size of this window's drawing area.
  int get drawingHeight {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return windowPtr.ref.wlr_xdg_surface.ref.surface.ref.current.height;
    }
    return 0;
  }

  /// The horizontal position of this window's content.
  num get contentX {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return drawingX + windowPtr.ref.wlr_xdg_surface.ref.current.geometry.x;
    }
    return 0;
  }

  /// The vertical position of this window's content.
  num get contentY {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return drawingY + windowPtr.ref.wlr_xdg_surface.ref.current.geometry.y;
    }
    return 0;
  }

  /// The horizontal size of this window's content.
  int get contentWidth {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return windowPtr.ref.wlr_xdg_surface.ref.current.geometry.width;
    }
    return 0;
  }

  /// The vertical size of this window's content.
  int get contentHeight {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return windowPtr.ref.wlr_xdg_surface.ref.current.geometry.height;
    }
    return 0;
  }

  /// Applies focus to this window.
  void focus() {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return _wblib.waybright_window_focus(windowPtr);
    }
    isFocused = true;
  }

  /// Removes focus from this window.
  void blur() {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      return _wblib.waybright_window_blur(windowPtr);
    }
    isFocused = false;
  }

  /// Submits pointer movement events to this window.
  void submitPointerMovementEvent(PointerMovementEvent event) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.waybright_window_submit_pointer_move_event(
        windowPtr,
        event.elapsedTimeMilliseconds,
        event.windowCursorX.toInt(),
        event.windowCursorY.toInt(),
      );
    }
  }

  /// Submits pointer button events to this window.
  void submitPointerButtonEvent(PointerButtonEvent event) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.waybright_window_submit_pointer_button_event(
        windowPtr,
        event.elapsedTimeMilliseconds,
        event.button,
        event.isPressed ? 1 : 0,
      );
    }
  }

  /// Submits pointer axis events to this window.
  void submitPointerAxisEvent(PointerAxisEvent event) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      int source;
      switch (event.source) {
        case PointerAxisSource.wheel:
          source = enum_wlr_axis_source.WLR_AXIS_SOURCE_WHEEL;
          break;
        case PointerAxisSource.finger:
          source = enum_wlr_axis_source.WLR_AXIS_SOURCE_FINGER;
          break;
        case PointerAxisSource.continuous:
          source = enum_wlr_axis_source.WLR_AXIS_SOURCE_CONTINUOUS;
          break;
        case PointerAxisSource.wheelTilt:
          source = enum_wlr_axis_source.WLR_AXIS_SOURCE_WHEEL_TILT;
          break;
      }

      int orientation;
      switch (event.orientation) {
        case PointerAxisOrientation.vertical:
          orientation = enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_VERTICAL;
          break;
        case PointerAxisOrientation.horizontal:
          orientation =
              enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_HORIZONTAL;
          break;
      }

      _wblib.waybright_window_submit_pointer_axis_event(
        windowPtr,
        event.elapsedTimeMilliseconds,
        orientation,
        event.delta,
        event.notches,
        source,
      );
    }
  }

  void submitKeyboardKeyEvent(KeyboardKeyEvent event) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.waybright_window_submit_keyboard_key_event(
        windowPtr,
        event.elapsedTimeMilliseconds,
        event.keyCode,
        event.isPressed ? 1 : 0,
      );
    }
  }

  void submitKeyboardModifiersEvent(KeyboardModifiersEvent event) {
    var windowPtr = _windowPtr;
    var keyboardPtr = event.keyboard._keyboardPtr;
    if (windowPtr != null && keyboardPtr != null) {
      _wblib.waybright_window_submit_keyboard_modifiers_event(
        windowPtr,
        keyboardPtr,
      );
    }
  }
}
