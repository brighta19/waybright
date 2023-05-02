part of "./waybright.dart";

enum WindowEdge {
  none,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
  topLeft,
}

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol.
class Window {
  static final _windowInstances = <Window>[];

  static final _eventTypeFromString = {
    'remove': enum_wb_event_type.event_type_window_remove,
    'show': enum_wb_event_type.event_type_window_show,
    'hide': enum_wb_event_type.event_type_window_hide,
    'move': enum_wb_event_type.event_type_window_move,
    'resize': enum_wb_event_type.event_type_window_resize,
    'maximize': enum_wb_event_type.event_type_window_maximize,
    'fullscreen': enum_wb_event_type.event_type_window_fullscreen,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var windows = _windowInstances.toList();
    for (var window in windows) {
      var eventPtr = data as Pointer<struct_waybright_window_event>;
      if (window._windowPtr != eventPtr.ref.wb_window) continue;

      var handleEvent = window._eventHandlers[type];
      if (handleEvent == null) continue;

      if (type == enum_wb_event_type.event_type_window_show ||
          type == enum_wb_event_type.event_type_window_hide) {
        handleEvent();
      } else if (type == enum_wb_event_type.event_type_window_move) {
        // var wlrEventPtr =
        //     eventPtr.ref.event as Pointer<struct_wlr_xdg_toplevel_move_event>;

        var event = WindowMoveEvent(window);

        handleEvent(event);
      } else if (type == enum_wb_event_type.event_type_window_resize) {
        var wlrEventPtr =
            eventPtr.ref.event as Pointer<struct_wlr_xdg_toplevel_resize_event>;

        WindowEdge edge;
        switch (wlrEventPtr.ref.edges) {
          case enum_wlr_edges.WLR_EDGE_TOP:
            edge = WindowEdge.top;
            break;
          case enum_wlr_edges.WLR_EDGE_TOP | enum_wlr_edges.WLR_EDGE_RIGHT:
            edge = WindowEdge.topRight;
            break;
          case enum_wlr_edges.WLR_EDGE_RIGHT:
            edge = WindowEdge.right;
            break;
          case enum_wlr_edges.WLR_EDGE_BOTTOM | enum_wlr_edges.WLR_EDGE_RIGHT:
            edge = WindowEdge.bottomRight;
            break;
          case enum_wlr_edges.WLR_EDGE_BOTTOM:
            edge = WindowEdge.bottom;
            break;
          case enum_wlr_edges.WLR_EDGE_BOTTOM | enum_wlr_edges.WLR_EDGE_LEFT:
            edge = WindowEdge.bottomLeft;
            break;
          case enum_wlr_edges.WLR_EDGE_LEFT:
            edge = WindowEdge.left;
            break;
          case enum_wlr_edges.WLR_EDGE_TOP | enum_wlr_edges.WLR_EDGE_LEFT:
            edge = WindowEdge.topLeft;
            break;
          default:
            edge = WindowEdge.none;
        }

        var event = WindowResizeEvent(
          window,
          edge,
        );

        handleEvent(event);
      } else if (type == enum_wb_event_type.event_type_window_maximize) {
        handleEvent(WindowMaximizeEvent(window));
      } else if (type == enum_wb_event_type.event_type_window_fullscreen) {
        handleEvent(WindowFullscreenEvent(window));
      } else if (type == enum_wb_event_type.event_type_window_remove) {
        handleEvent();
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

  void _ensureKeyboardFocus(KeyboardDevice keyboard) {
    if (keyboard.focusedWindow != this) {
      keyboard.clearFocus();
      keyboard.focusOnWindow(this);
    }
  }

  void _ensurePointerFocus(PointerDevice pointer, num cursorX, num cursorY) {
    if (pointer.focusedWindow != this) {
      pointer.clearFocus();
      pointer.focusOnWindow(this, cursorX, cursorY);
    }
  }

  void _setMaximizeAttribute(bool value) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.wlr_xdg_toplevel_set_maximized(
          windowPtr.ref.wlr_xdg_surface, value);
    }
  }

  void _setFullscreenAttribute(bool value) {
    var windowPtr = _windowPtr;
    if (windowPtr != null) {
      _wblib.wlr_xdg_toplevel_set_fullscreen(
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

  /// Whether this window is considered fullscreen.
  bool get isFullscreen =>
      _windowPtr?.ref.wlr_xdg_toplevel.ref.current.fullscreen ?? false;

  /// Whether this window is focused.
  bool get isFocused =>
      _windowPtr?.ref.wlr_xdg_toplevel.ref.current.activated ?? false;

  /// Tells this window to maximize.
  ///
  /// It will *not* consider itself maximized until the compositor has confirmed
  /// the maximize change. Track the [isMaximized] property to know when it is
  /// maximized.
  ///
  /// If [width] or [height] are provided, the window will submit the new size.
  void maximize({int? width, int? height}) {
    _setMaximizeAttribute(true);
    if (width != null || height != null) {
      submitNewSize(width: width, height: height);
    }
  }

  /// Tells this window to unmaximize.
  ///
  /// It will *not* consider itself unmaximized until the compositor has
  /// confirmed the maximize change. Track the [isMaximized] property to know when
  /// it is unmaximized.
  ///
  /// If [width] or [height] are provided, the window will submit the new size.
  void unmaximize({int? width, int? height}) {
    _setMaximizeAttribute(false);
    if (width != null || height != null) {
      submitNewSize(width: width, height: height);
    }
  }

  /// Tells this window to fullscreen.
  ///
  /// It will *not* consider itself fullscreen until the compositor has
  /// confirmed the fullscreen change. Track the [isFullscreen] property to know
  /// when it is fullscreened.
  ///
  /// If [width] or [height] are provided, the window will submit the new size.
  void fullscreen({int? width, int? height}) {
    _setFullscreenAttribute(true);
    if (width != null || height != null) {
      submitNewSize(width: width, height: height);
    }
  }

  /// Tells this window to unfullscreen.
  ///
  /// It will *not* consider itself unfullscreen until the compositor has
  /// confirmed the focus change. Track the [isFullscreen] property to know when
  /// it is unfullscreened.
  ///
  /// If [width] or [height] are provided, the window will submit the new size.
  void unfullscreen({int? width, int? height}) {
    _setFullscreenAttribute(false);
    if (width != null || height != null) {
      submitNewSize(width: width, height: height);
    }
  }

  /// Tells this window to focus.
  ///
  /// It will *not* consider itself focused until the compositor has confirmed
  /// the focus change. Track the [isFocused] property to know when it is
  /// focused.
  void focus() => _setFocusedAttribute(true);

  /// Tells this window to unfocus.
  ///
  /// It will *not* consider itself unfocused
  /// until the compositor has confirmed the focus change. Track the
  /// [isFocused] property to know when it is unfocused.
  void unfocus() => _setFocusedAttribute(false);

  /// Submits a new size for this window.
  ///
  /// The window itself may choose to either
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

  /// Submits pointer movement updates to this window. The coordinates in
  /// [update] are relative to the window's content area.
  void submitPointerMoveUpdate(PointerUpdate<PointerMoveEvent> update) {
    var windowPtr = _windowPtr;
    if (windowPtr == null) return;

    var cursorX = update.windowCursorX.toInt();
    var cursorY = update.windowCursorY.toInt();

    _ensurePointerFocus(update.pointer, cursorX, cursorY);

    _wblib.waybright_window_submit_pointer_move_event(
      windowPtr,
      update.event.elapsedTimeMilliseconds,
      cursorX,
      cursorY,
    );
  }

  /// Submits pointer button updates to this window.
  void submitPointerButtonUpdate(PointerUpdate<PointerButtonEvent> update) {
    var windowPtr = _windowPtr;
    if (windowPtr == null) return;

    _ensurePointerFocus(
        update.pointer, update.windowCursorX, update.windowCursorY);

    _wblib.waybright_window_submit_pointer_button_event(
      windowPtr,
      update.event.elapsedTimeMilliseconds,
      update.event.code,
      update.event.isPressed ? 1 : 0,
    );
  }

  /// Submits pointer axis updates to this window.
  void submitPointerAxisUpdate(PointerUpdate<PointerAxisEvent> update) {
    var windowPtr = _windowPtr;
    if (windowPtr == null) return;

    _ensurePointerFocus(
        update.pointer, update.windowCursorX, update.windowCursorY);

    int source;
    switch (update.event.source) {
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
    switch (update.event.orientation) {
      case PointerAxisOrientation.vertical:
        orientation = enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_VERTICAL;
        break;
      case PointerAxisOrientation.horizontal:
        orientation = enum_wlr_axis_orientation.WLR_AXIS_ORIENTATION_HORIZONTAL;
        break;
    }

    _wblib.waybright_window_submit_pointer_axis_event(
      windowPtr,
      update.event.elapsedTimeMilliseconds,
      orientation,
      update.event.delta,
      update.event.notches,
      source,
    );
  }

  /// Submits keyboard key updates to this window.
  void submitKeyboardKeyUpdate(KeyboardUpdate<KeyboardKeyEvent> update) {
    var windowPtr = _windowPtr;
    if (windowPtr == null) return;

    _ensureKeyboardFocus(update.keyboard);

    _wblib.waybright_window_submit_keyboard_key_event(
      windowPtr,
      update.event.elapsedTimeMilliseconds,
      update.event.code,
      update.event.isPressed ? 1 : 0,
    );
  }

  /// Submits keyboard modifiers updates to this window.
  void submitKeyboardModifiersUpdate(
      KeyboardUpdate<KeyboardModifiersEvent> update) {
    var windowPtr = _windowPtr;
    var keyboardPtr = update.keyboard._keyboardPtr;
    if (windowPtr == null || keyboardPtr == null) return;

    _ensureKeyboardFocus(update.keyboard);

    _wblib.waybright_window_submit_keyboard_modifiers_event(
      windowPtr,
      keyboardPtr,
    );
  }
}
