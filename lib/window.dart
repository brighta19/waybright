part of "./waybright.dart";

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol.
class Window {
  static final _windowInstances = <Window>[];

  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_window_remove,
    'show': enum_event_type.event_type_window_show,
    'hide': enum_event_type.event_type_window_hide,
    'move': enum_event_type.event_type_window_move,
    'maximize': enum_event_type.event_type_window_maximize,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var window in _windowInstances) {
      var windowPtr = data as Pointer<struct_waybright_window>;
      if (window._windowPtr != windowPtr) continue;

      var handleEvent = window._eventHandlers[type];
      if (handleEvent == null) continue;

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

  void _setMaximizeAttribute(bool value) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.wlr_xdg_toplevel_set_maximized(
          windowPtr.ref.wlr_xdg_surface, value);
    }
  }

  void _setFocusedAttribute(bool value) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.wlr_xdg_toplevel_set_activated(
          windowPtr.ref.wlr_xdg_surface, value);
    }
  }

  /// The horizontal position of this window's drawing area.
  num drawingX = 0;

  /// The vertical position of this window's drawing area.
  num drawingY = 0;

  /// The horizontal size of this window's drawing area.
  int get drawingWidth =>
      _windowPtr?.ref.wlr_xdg_surface.ref.surface.ref.current.width ?? 0;

  /// The vertical size of this window's drawing area.
  int get drawingHeight =>
      _windowPtr?.ref.wlr_xdg_surface.ref.surface.ref.current.height ?? 0;

  /// The horizontal offset of this window's content.
  num get offsetX =>
      _windowPtr?.ref.wlr_xdg_surface.ref.current.geometry.x ?? 0;

  /// The vertical offset of this window's content.
  num get offsetY =>
      _windowPtr?.ref.wlr_xdg_surface.ref.current.geometry.y ?? 0;

  /// The horizontal position of this window's content.
  num get contentX => drawingX + offsetX;

  /// The vertical position of this window's content.
  num get contentY => drawingY + offsetY;

  /// The horizontal size of this window's content.
  int get contentWidth =>
      _windowPtr?.ref.wlr_xdg_surface.ref.current.geometry.width ?? 0;

  /// The vertical size of this window's content.
  int get contentHeight =>
      _windowPtr?.ref.wlr_xdg_surface.ref.current.geometry.height ?? 0;

  /// Whether this window is considered visible.
  bool get isVisible => _windowPtr?.ref.wlr_xdg_surface.ref.mapped ?? false;

  /// Whether this window is considered maximized.
  bool get isMaximized =>
      _windowPtr?.ref.wlr_xdg_toplevel.ref.current.maximized ?? false;

  /// Whether this window is focused.
  bool get isFocused =>
      _windowPtr?.ref.wlr_xdg_toplevel.ref.current.activated ?? false;

  /// Tells this window to maximize. It will *not* consider itself maximized
  /// iuntil the compositor has confirmed the focus change. Track the
  /// [isMaximized] property to know when it is maximized.
  void maximize() => _setMaximizeAttribute(true);

  /// Tells this window to unmaximize. It will *not* consider itself maximized
  /// until the compositor has confirmed the focus change. Track the
  /// [isMaximized] property to know when it is unmaximized.
  void unmaximize() => _setMaximizeAttribute(false);

  /// Tells this window to focus. It will *not* consider itself focused until
  /// the compositor has confirmed the focus change. Track the [isFocused]
  /// property to know when it is focused.
  void focus() => _setFocusedAttribute(true);

  /// Tells this window to unfocus. It will *not* consider itself unfocused
  /// until the compositor has confirmed the focus change. Track the
  /// [isFocused] property to know when it is unfocused.
  void unfocus() => _setFocusedAttribute(false);

  /// Submits a new size for this window. The window itself may choose to either
  /// accept this size or choose a different size, so track the [contentWidth]
  /// and [contentHeight] properties to know the actual size.
  void submitNewSize({int? width, int? height}) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      var width0 = width ?? contentWidth;
      var height0 = height ?? contentHeight;

      _wblib.wlr_xdg_toplevel_set_size(
          windowPtr.ref.wlr_xdg_surface, width0, height0);
    }
  }

  /// Submits pointer movement events to this window. The coordinates in [event]
  /// are relative to the window's content area.
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

  /// Submits keyboard key events to this window.
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

  /// Submits keyboard modifiers events to this window.
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
