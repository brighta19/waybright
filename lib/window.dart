part of "./waybright.dart";

// TODO: maybe split normal (toplevel) windows and popups into separate classes
// TODO: add set bounds method
// TODO: use xdg positioner for popup windows
// TODO: add user events to window events
// TODO: maybe create texture class
// TODO: xwayland support

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

class _WindowData {
  String? applicationId;
  String? title;
  int width = 0;
  int height = 0;
  int textureWidth = 0;
  int textureHeight = 0;
  num offsetX = 0;
  num offsetY = 0;
  num popupX = 0;
  num popupY = 0;
  bool hasTexture = false;
  bool isMaximized = false;
  bool isFullscreen = false;
  bool isActive = false;
  bool isResizing = false;
}

WindowEdge _getEdgeFromWlrResizeEvent(
    Pointer<struct_wlr_xdg_toplevel_resize_event> eventPtr) {
  switch (eventPtr.ref.edges) {
    case enum_wlr_edges.WLR_EDGE_TOP:
      return WindowEdge.top;
    case enum_wlr_edges.WLR_EDGE_TOP | enum_wlr_edges.WLR_EDGE_RIGHT:
      return WindowEdge.topRight;
    case enum_wlr_edges.WLR_EDGE_RIGHT:
      return WindowEdge.right;
    case enum_wlr_edges.WLR_EDGE_BOTTOM | enum_wlr_edges.WLR_EDGE_RIGHT:
      return WindowEdge.bottomRight;
    case enum_wlr_edges.WLR_EDGE_BOTTOM:
      return WindowEdge.bottom;
    case enum_wlr_edges.WLR_EDGE_BOTTOM | enum_wlr_edges.WLR_EDGE_LEFT:
      return WindowEdge.bottomLeft;
    case enum_wlr_edges.WLR_EDGE_LEFT:
      return WindowEdge.left;
    case enum_wlr_edges.WLR_EDGE_TOP | enum_wlr_edges.WLR_EDGE_LEFT:
      return WindowEdge.topLeft;
    default:
      return WindowEdge.none;
  }
}

List<Rect> _getDamagedRegions(Window window) {
  var damagedRegions = <Rect>[];

  var damageRegionPtr = calloc<struct_pixman_region32>();
  var numBoxesPtr = calloc<Int>();

  _wblib.waybright_pixman_region32_init(damageRegionPtr);
  _wblib.wlr_surface_get_effective_damage(
      window._wlrXdgSurfacePtr.ref.surface, damageRegionPtr);

  var boxesPtr =
      _wblib.waybright_pixman_region32_rectangles(damageRegionPtr, numBoxesPtr);
  var numBoxes = numBoxesPtr.value;

  for (var i = 0; i < numBoxes; i++) {
    var boxPtr = boxesPtr.elementAt(i);
    var box = boxPtr.ref;
    damagedRegions.add(Rect(box.x1, box.y1, box.x2 - box.x1, box.y2 - box.y1));
  }

  _wblib.waybright_pixman_region32_fini(damageRegionPtr);
  calloc.free(damageRegionPtr);
  calloc.free(numBoxesPtr);

  return damagedRegions;
}

void _completeAndClearCompleters(List<Completer> completers) {
  for (var completer in completers) {
    completer.complete();
  }
  completers.clear();
}

Window? _getParentOfPopup(Window window) {
  var parentPtr = window._windowPtr.ref.wlr_xdg_toplevel.ref.parent;
  return Window._windowInstances[parentPtr];
}

void _wbWindowDestroyEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.onDestroying?.call(WindowDestroyingEvent(window));
}

void _wbWindowMapEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window._updateData();
  window.onTextureSet?.call(WindowTextureSetEvent(window));
}

void _wbWindowUnmapEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window._updateData();
  window.onTextureUnsetting?.call(WindowTextureUnsettingEvent(window));
}

void _wbWindowNewPopupEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var popupWindowPtr = eventPtr.ref.event as Pointer<struct_waybright_window>;
  var popup = Window._fromPointer(popupWindowPtr);
  window.onPopupCreate?.call(WindowPopupCreateEvent(popup));
}

void _wbWindowCommitEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var wasActive = window._data.isActive;
  var wasMaximized = window._data.isMaximized;
  var wasFullscreen = window._data.isFullscreen;
  var previousTextureWidth = window._data.textureWidth;
  var previousTextureHeight = window._data.textureHeight;

  window._updateData();

  if (wasActive && !window.isActive) {
    window.onDeactivate?.call(WindowDeactivateEvent(window));
    _completeAndClearCompleters(window._deactivateCompleters);
  } else if (!wasActive && window.isActive) {
    window.onActivate?.call(WindowActivateEvent(window));
    _completeAndClearCompleters(window._activateCompleters);
  } else {
    _completeAndClearCompleters(window._deactivateCompleters);
    _completeAndClearCompleters(window._activateCompleters);
  }

  if (wasMaximized && !window.isMaximized) {
    window.onUnmaximize?.call(WindowUnmaximizeEvent(window));
    _completeAndClearCompleters(window._unmaximizeCompleters);
  } else if (!wasMaximized && window.isMaximized) {
    window.onMaximize?.call(WindowMaximizeEvent(window));
    _completeAndClearCompleters(window._maximizeCompleters);
  } else {
    _completeAndClearCompleters(window._unmaximizeCompleters);
    _completeAndClearCompleters(window._maximizeCompleters);
  }

  if (wasFullscreen && !window.isFullscreen) {
    window.onUnfullscreen?.call(WindowUnfullscreenEvent(window));
    _completeAndClearCompleters(window._unfullscreenCompleters);
  } else if (!wasFullscreen && window.isFullscreen) {
    window.onFullscreen?.call(WindowFullscreenEvent(window));
    _completeAndClearCompleters(window._fullscreenCompleters);
  } else {
    _completeAndClearCompleters(window._unfullscreenCompleters);
    _completeAndClearCompleters(window._fullscreenCompleters);
  }

  if (window._resizeCompleters.isNotEmpty) {
    window.onResize?.call(
        WindowResizeEvent(window, previousTextureWidth, previousTextureHeight));
    _completeAndClearCompleters(window._resizeCompleters);
  }

  // This is a workaround to allow completers to complete their futures
  // before the WindowTextureDamagedRegionsEvent handler is called.
  Future(() {
    var damagedRegions = _getDamagedRegions(window);
    window.onTextureDamagedRegions
        ?.call(WindowTextureDamagedRegionsEvent(window, damagedRegions));
  });
}

void _wbWindowRequestMoveEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.onMoveRequest?.call(WindowMoveRequestEvent(window));
}

void _wbWindowRequestResizeEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var wlrEventPtr =
      eventPtr.ref.event as Pointer<struct_wlr_xdg_toplevel_resize_event>;
  WindowEdge edge = _getEdgeFromWlrResizeEvent(wlrEventPtr);
  window.onResizeRequest?.call(WindowResizeRequestEvent(window, edge));
}

void _wbWindowRequestMaximizeEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var hadRequestedMaximzed = window._wlrXdgToplevelPtr.ref.requested.maximized;
  if (hadRequestedMaximzed) {
    window.onMaximizeRequest?.call(WindowMaximizeRequestEvent(window));
  } else {
    window.onUnmaximizeRequest?.call(WindowUnmaximizeRequestEvent(window));
  }
}

void _wbWindowRequestMinimizeEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.onMinimizeRequest?.call(WindowMinimizeRequestEvent(window));
}

void _wbWindowRequestFullscreenEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var hadRequestedFullscreen =
      window._wlrXdgToplevelPtr.ref.requested.fullscreen;
  if (hadRequestedFullscreen) {
    window.onFullscreenRequest?.call(WindowFullscreenRequestEvent(window));
  } else {
    window.onUnfullscreenRequest?.call(WindowUnfullscreenRequestEvent(window));
  }
}

void _wbWindowRequestShowWindowMenuEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  var wlrEventPtr = eventPtr.ref.event
      as Pointer<struct_wlr_xdg_toplevel_show_window_menu_event>;
  window.onWindowMenuRequest?.call(
      WindowMenuRequestEvent(window, wlrEventPtr.ref.x, wlrEventPtr.ref.y));
}

void _wbWindowSetTitleEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.onTitleChange?.call(WindowTitleChangeEvent(window));
}

void _wbWindowSetAppIdEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.onAppIdChange?.call(WindowAppIdChangeEvent(window));
}

void _wbWindowSetParentEvent(
    Pointer<struct_waybright_window_event> eventPtr, Window window) {
  window.parent = _getParentOfPopup(window);
  window.onParentChange?.call(WindowParentChangeEvent(window));
}

final _wbEventCallbacks = {
  enum_wb_event_type.event_type_window_destroy: _wbWindowDestroyEvent,
  enum_wb_event_type.event_type_window_map: _wbWindowMapEvent,
  enum_wb_event_type.event_type_window_unmap: _wbWindowUnmapEvent,
  enum_wb_event_type.event_type_window_new_popup: _wbWindowNewPopupEvent,
  enum_wb_event_type.event_type_window_commit: _wbWindowCommitEvent,
  enum_wb_event_type.event_type_window_request_move: _wbWindowRequestMoveEvent,
  enum_wb_event_type.event_type_window_request_resize:
      _wbWindowRequestResizeEvent,
  enum_wb_event_type.event_type_window_request_maximize:
      _wbWindowRequestMaximizeEvent,
  enum_wb_event_type.event_type_window_request_minimize:
      _wbWindowRequestMinimizeEvent,
  enum_wb_event_type.event_type_window_request_fullscreen:
      _wbWindowRequestFullscreenEvent,
  enum_wb_event_type.event_type_window_request_show_window_menu:
      _wbWindowRequestShowWindowMenuEvent,
  enum_wb_event_type.event_type_window_set_title: _wbWindowSetTitleEvent,
  enum_wb_event_type.event_type_window_set_app_id: _wbWindowSetAppIdEvent,
  enum_wb_event_type.event_type_window_set_parent: _wbWindowSetParentEvent,
};

/// An application's window.
///
/// In wayland, this most closely corresponds to a `xdg_surface` from the
/// `xdg-shell` protocol.
///
/// The compositor could create its own Window class, storing this window as a
/// property while adding additional properties, such as a window position.
class Window {
  static final _windowInstances = <Pointer<struct_waybright_window>, Window>{};

  static void _onEvent(int type, Pointer<Void> data) {
    var eventPtr = data as Pointer<struct_waybright_window_event>;

    var window = _windowInstances[eventPtr.ref.wb_window];
    if (window == null) {
      throw StateError("Internal error: unknown window");
    }

    var callback = _wbEventCallbacks[type];
    if (callback == null) {
      throw ArgumentError("Internal error: unknown event type $type");
    }

    callback(eventPtr, window);

    if (type == enum_wb_event_type.event_type_window_destroy) {
      _windowInstances.remove(window._windowPtr);
    }
  }

  final Pointer<struct_waybright_window> _windowPtr;
  Pointer<struct_wlr_xdg_surface> get _wlrXdgSurfacePtr =>
      _windowPtr.ref.wlr_xdg_surface;
  Pointer<struct_wlr_xdg_toplevel> get _wlrXdgToplevelPtr =>
      _windowPtr.ref.wlr_xdg_toplevel;
  Pointer<struct_wlr_xdg_popup> get _wlrXdgPopupPtr =>
      _windowPtr.ref.wlr_xdg_popup;

  bool get _hasBuffer =>
      _wlrXdgSurfacePtr.ref.surface.ref.buffer.ref.source != nullptr;

  final _data = _WindowData();

  final _activateCompleters = <Completer<void>>[];
  final _deactivateCompleters = <Completer<void>>[];
  final _maximizeCompleters = <Completer<void>>[];
  final _unmaximizeCompleters = <Completer<void>>[];
  final _fullscreenCompleters = <Completer<void>>[];
  final _unfullscreenCompleters = <Completer<void>>[];
  final _resizeCompleters = <Completer<void>>[];

  Window._fromPointer(
    this._windowPtr,
  ) : isPopup = _windowPtr.ref.wlr_xdg_popup != nullptr {
    _windowInstances[_windowPtr] = this;
    _windowPtr.ref.handle_event = Pointer.fromFunction(_onEvent);

    _updateData();
  }

  _updateData() {
    _data.applicationId =
        isPopup ? null : _toDartString(_wlrXdgToplevelPtr.ref.app_id);
    _data.title = isPopup ? null : _toDartString(_wlrXdgToplevelPtr.ref.title);
    _data.width = _wlrXdgSurfacePtr.ref.current.geometry.width;
    _data.height = _wlrXdgSurfacePtr.ref.current.geometry.height;
    _data.textureWidth = _wlrXdgSurfacePtr.ref.surface.ref.current.width;
    _data.textureHeight = _wlrXdgSurfacePtr.ref.surface.ref.current.height;
    _data.offsetX = _wlrXdgSurfacePtr.ref.current.geometry.x;
    _data.offsetY = _wlrXdgSurfacePtr.ref.current.geometry.y;
    _data.popupX = isPopup ? _wlrXdgPopupPtr.ref.current.geometry.x : 0;
    _data.popupY = isPopup ? _wlrXdgPopupPtr.ref.current.geometry.y : 0;
    _data.hasTexture = _wlrXdgSurfacePtr.ref.mapped;
    _data.isMaximized =
        isPopup ? false : _wlrXdgToplevelPtr.ref.current.maximized;
    _data.isFullscreen =
        isPopup ? false : _wlrXdgToplevelPtr.ref.current.fullscreen;
    _data.isActive = isPopup ? false : _wlrXdgToplevelPtr.ref.current.activated;
    _data.isResizing =
        isPopup ? false : _wlrXdgToplevelPtr.ref.current.resizing;
  }

  void _ensureKeyboardFocus(KeyboardDevice keyboard) {
    if (!keyboard.isFocusedOnWindow(this)) {
      keyboard.clearFocus();
      keyboard.focusOnWindow(this);
    }
  }

  void _ensurePointerFocus(PointerDevice pointer, num cursorX, num cursorY) {
    if (!pointer.isFocusedOnWindow(this)) {
      pointer.clearFocus();
      pointer.focusOnWindow(this, cursorX, cursorY);
    }
  }

  void _setMaximizeAttribute(bool value) =>
      _wblib.wlr_xdg_toplevel_set_maximized(_wlrXdgToplevelPtr, value);

  void _setFullscreenAttribute(bool value) =>
      _wblib.wlr_xdg_toplevel_set_fullscreen(_wlrXdgToplevelPtr, value);

  void _setActiveAttribute(bool value) =>
      _wblib.wlr_xdg_toplevel_set_activated(_wlrXdgToplevelPtr, value);

  void _setResizingAttribute(bool value) =>
      _wblib.wlr_xdg_toplevel_set_resizing(_wlrXdgToplevelPtr, value);

  void _setTiledAttribute(List<WindowEdge> edges) {
    var value = 0;
    for (var edge in edges) {
      switch (edge) {
        case WindowEdge.top:
          value |= enum_wlr_edges.WLR_EDGE_TOP;
          break;
        case WindowEdge.bottom:
          value |= enum_wlr_edges.WLR_EDGE_BOTTOM;
          break;
        case WindowEdge.left:
          value |= enum_wlr_edges.WLR_EDGE_LEFT;
          break;
        case WindowEdge.right:
          value |= enum_wlr_edges.WLR_EDGE_RIGHT;
          break;
        default:
          throw ArgumentError("Invalid window edge $edge");
      }
    }

    _wblib.wlr_xdg_toplevel_set_tiled(_wlrXdgToplevelPtr, value);
  }

  void _setSize({int? width, int? height}) {
    width ??= this.width;
    height ??= this.height;

    _wblib.wlr_xdg_toplevel_set_size(_wlrXdgToplevelPtr, width, height);
  }

  /// A handler that is called when this window is being destroyed.
  void Function(WindowDestroyingEvent event)? onDestroying;

  /// A handler that is called when this window's texture is set.
  ///
  /// This means that this window is ready to be rendered using its texture.
  void Function(WindowTextureSetEvent event)? onTextureSet;

  /// A handler that is called when this window's texture is being unset.
  ///
  /// This means that this window won't have a texture to be rendered.
  void Function(WindowTextureUnsettingEvent event)? onTextureUnsetting;

  /// A handler that is called when a new popup window is created.
  ///
  /// Popups can be context menus, tooltips, etc., which are short-lived
  /// windows.
  void Function(WindowPopupCreateEvent event)? onPopupCreate;

  /// A handler that is called when this window has been activated.
  ///
  /// The window may have drawn itself in an active state.
  void Function(WindowActivateEvent event)? onActivate;

  /// A handler that is called when this window has been deactivated.
  ///
  /// The window may have drawn itself in an inactive state.
  void Function(WindowDeactivateEvent event)? onDeactivate;

  /// A handler that is called when this window requests to be moved.
  ///
  /// The move functionality is handled by the compositor, not the window.
  void Function(WindowMoveRequestEvent event)? onMoveRequest;

  /// A handler that is called when this window requests to be resized.
  ///
  /// The resize functionality is handled by the compositor. As the compositor
  /// resizes, it can submit new sizes to this window, which can then resize and
  /// draw itself accordingly.
  ///
  /// The compositor should probably wait for this window to be resized before
  /// repositioning it.
  void Function(WindowResizeRequestEvent event)? onResizeRequest;

  /// A handler that is called when this window has been resized.
  ///
  /// The window has drawn itself in its new size. The compositor can now
  /// reposition this window if it so desires.
  void Function(WindowResizeEvent event)? onResize;

  /// A handler that is called when this window requests to be maximized.
  ///
  /// The maximize functionality is handled by the compositor. The compositor
  /// can submit new sizes to this window, which can then resize and draw itself
  /// accordingly.
  ///
  /// If the compositor wants to reposition this window, it is recommended to
  /// wait for the window to be maximized before repositioning it using the
  /// [onMaximize] handler.
  void Function(WindowMaximizeRequestEvent event)? onMaximizeRequest;

  /// A handler that is called when this window has been maximized.
  ///
  /// The window had resized and drawn itself in its maximized state. The
  /// compositor can now reposition this window if it so desires.
  ///
  /// The [onResize] handler is called after this handler.
  void Function(WindowMaximizeEvent event)? onMaximize;

  /// A handler that is called when this window requests to be unmaximized.
  ///
  /// The unmaximize functionality is handled by the compositor. The compositor
  /// can submit new sizes to this window, which can then resize and draw itself
  /// accordingly.
  ///
  /// If the compositor wants to reposition this window, it is recommended to
  /// wait for the window to be unmaximized before repositioning it using the
  /// [onUnmaximize] handler.
  void Function(WindowUnmaximizeRequestEvent event)? onUnmaximizeRequest;

  /// A handler that is called when this window has been unmaximized.
  ///
  /// The window had resized and drawn itself in its unmaximized state. The
  /// compositor can now reposition this window if it so desires.
  ///
  /// The [onResize] handler is called after this handler.
  void Function(WindowUnmaximizeEvent event)? onUnmaximize;

  /// A handler that is called when this window requests to be minimized.
  ///
  /// The minimize functionality is handled by the compositor, not the window.
  /// The window wouldn't know whether it is actually minimized or not.
  void Function(WindowMinimizeRequestEvent event)? onMinimizeRequest;

  /// A handler that is called when this window requests to be fullscreen.
  ///
  /// The fullscreen functionality is handled by the compositor. The compositor
  /// can submit new sizes to this window, which can then resize and draw itself
  /// accordingly.
  ///
  /// If the compositor wants to reposition this window, it is recommended to
  /// wait for the window to be fullscreen before repositioning it using the
  /// [onFullscreen] handler.
  void Function(WindowFullscreenRequestEvent event)? onFullscreenRequest;

  /// A handler that is called when this window has been fullscreened.
  ///
  /// The window had resized and drawn itself in its fullscreened state. The
  /// compositor can now reposition this window if it so desires.
  ///
  /// The [onResize] handler is called after this handler.
  void Function(WindowFullscreenEvent event)? onFullscreen;

  /// A handler that is called when this window requests to be unfullscreen.
  ///
  /// The unfullscreen functionality is handled by the compositor. The
  /// compositor can submit new sizes to this window, which can then resize and
  /// draw itself accordingly.
  ///
  /// If the compositor wants to reposition this window, it is recommended to
  /// wait for the window to be unfullscreen before repositioning it using the
  /// [onUnfullscreen] handler.
  void Function(WindowUnfullscreenRequestEvent event)? onUnfullscreenRequest;

  /// A handler that is called when this window has been unfullscreened.
  ///
  /// The window had resized and drawn itself in its unfullscreened state. The
  /// compositor can now reposition this window if it so desires.
  ///
  /// The [onResize] handler is called after this handler.
  void Function(WindowUnfullscreenEvent event)? onUnfullscreen;

  /// A handler that is called when this window requests to show a window menu.
  ///
  /// This is if the compositor wants to show a context menu for this window.
  /// A window's own context menu would be a popup window; therefore, it would
  /// not request a window menu.
  void Function(WindowMenuRequestEvent event)? onWindowMenuRequest;

  /// A handler that is called when this window's title changes.
  ///
  /// It has already taken effect by the time this handler is called.
  void Function(WindowTitleChangeEvent event)? onTitleChange;

  /// A handler that is called when this window's application id changes.
  ///
  /// It has already taken effect by the time this handler is called.
  void Function(WindowAppIdChangeEvent event)? onAppIdChange;

  /// A handler that is called when this window's parent changes.
  ///
  /// It has already taken effect by the time this handler is called.
  void Function(WindowParentChangeEvent event)? onParentChange;

  /// A handler that is called when this window submits damaged regions.
  ///
  /// Damaged regions are areas of a texture that have been changed since the
  /// last frame. They can be used to optimize rendering by only rendering the
  /// damaged regions, rather than the entire texture.
  ///
  /// If opting to use damaged regions, the compositor should repaint the
  /// damaged regions of this window when rendering the next frame.
  /// The damaged regions may have to be transformed to the compositor's
  /// coordinate space.
  void Function(WindowTextureDamagedRegionsEvent event)?
      onTextureDamagedRegions;

  /// Whether this window is a popup window.
  ///
  /// Popups are short-lived windows that are usually used for context menus,
  /// tooltips, etc.
  final bool isPopup;

  /// The parent window of this popup window, if applicable.
  ///
  /// The parent itself may be a popup window.
  Window? parent;

  /// The id of the application that owns this window.
  ///
  /// This may be set later using the [onAppIdChange] handler.
  ///
  /// Popups do not have an application id set and will return an empty string.
  String? get applicationId => _data.applicationId;

  /// The title of this window.
  ///
  /// This may be set later using the [onTitleChange] handler.
  ///
  /// Popups do not have a title set and will return an empty string.
  String? get title => _data.title;

  /// The horizontal size of this window's content.
  int get width => _data.width;

  /// The vertical size of this window's content.
  int get height => _data.height;

  /// The horizontal size of this window's texture.
  int get textureWidth => _data.textureWidth;

  /// The vertical size of this window's texture.
  int get textureHeight => _data.textureHeight;

  /// The horizontal offset of this window's content.
  num get offsetX => _data.offsetX;

  /// The vertical offset of this window's content.
  num get offsetY => _data.offsetY;

  /// The horizontal position of this popup window relative to its parent.
  ///
  /// This will always be `0` if not a popup window.
  num get popupX => _data.popupX;

  /// The vertical position of this popup window relative to its parent.
  ///
  /// This will always be `0` if not a popup window.
  num get popupY => _data.popupY;

  /// Whether this window has a texture.
  bool get hasTexture => _data.hasTexture;

  /// Whether this window is considered maximized.
  ///
  /// This will always be `false` if this is a popup window.
  bool get isMaximized => _data.isMaximized;

  /// Whether this window is considered fullscreen.
  ///
  /// This will always be `false` if this is a popup window.
  bool get isFullscreen => _data.isFullscreen;

  /// Whether this window is considered active.
  ///
  /// The window may draw itself to indicate that it is in focus, regardless of
  /// if input devices are focused on it.
  ///
  /// This will always be false if  this is a popup window.
  bool get isActive => _data.isActive;

  /// Whether this window is considered resizing.
  ///
  /// If true, this window will believe that it is being resized by the user and
  /// may draw itself accordingly.
  ///
  /// This will always be `false` if this is a popup window.
  bool get isResizing => _data.isResizing;

  /// Tells this window to maximize.
  ///
  /// If [width] or [height] are provided, this window will also request the new
  /// size.
  ///
  /// If this window successfully maximizes, the [onMaximize] handler will be
  /// called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> maximize({int? width, int? height}) {
    if (isPopup || isMaximized) return Future.value();

    _setMaximizeAttribute(true);
    if (width != null || height != null) {
      requestSize(width: width, height: height);
    }

    var maximizeCompleter = Completer<void>();
    _maximizeCompleters.add(maximizeCompleter);
    return maximizeCompleter.future;
  }

  /// Tells this window to unmaximize.
  ///
  /// If [width] or [height] are provided, this window will also request the new
  /// size.
  ///
  /// If this window successfully unmaximizes, the [onUnmaximize] handler will
  /// be called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> unmaximize({int? width, int? height}) {
    if (isPopup || !isMaximized) return Future.value();

    _setMaximizeAttribute(false);
    if (width != null || height != null) {
      requestSize(width: width, height: height);
    }

    var unmaximizeCompleter = Completer<void>();
    _unmaximizeCompleters.add(unmaximizeCompleter);
    return unmaximizeCompleter.future;
  }

  /// Tells this window to fullscreen.
  ///
  /// If [width] or [height] are provided, this window will also request the new
  /// size.
  ///
  /// If this window successfully fullscreens, the [onFullscreen] handler will
  /// be called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> fullscreen({int? width, int? height}) {
    if (isPopup || isFullscreen) return Future.value();

    _setFullscreenAttribute(true);
    if (width != null || height != null) {
      requestSize(width: width, height: height);
    }

    var fullscreenCompleter = Completer<void>();
    _fullscreenCompleters.add(fullscreenCompleter);
    return fullscreenCompleter.future;
  }

  /// Tells this window to unfullscreen.
  ///
  /// If [width] or [height] are provided, this window will also request the new
  /// size.
  ///
  /// If this window successfully unfullscreens, the [onUnfullscreen] handler
  /// will be called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> unfullscreen({int? width, int? height}) {
    if (isPopup || !isFullscreen) return Future.value();

    _setFullscreenAttribute(false);
    if (width != null || height != null) {
      requestSize(width: width, height: height);
    }

    var unfullscreenCompleter = Completer<void>();
    _unfullscreenCompleters.add(unfullscreenCompleter);
    return unfullscreenCompleter.future;
  }

  /// Tells this window to activate.
  ///
  /// If this window successfully activates, the [onActivate] handler will be
  /// called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> activate() {
    if (isPopup) return Future.value();

    _setActiveAttribute(true);

    var activateCompleter = Completer<void>();
    _activateCompleters.add(activateCompleter);
    return activateCompleter.future;
  }

  /// Tells this window to deactivate.
  ///
  /// If this window successfully deactivates, the [onDeactivate] handler will
  /// be called and the returned [Future] will complete.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> deactivate() {
    if (isPopup) return Future.value();

    _setActiveAttribute(false);

    var deactivateCompleter = Completer<void>();
    _deactivateCompleters.add(deactivateCompleter);
    return deactivateCompleter.future;
  }

  /// Notifies this window about whether is being resized or not.
  ///
  /// The resize functionality is handled by the compositor, but the application
  /// may want to draw itself differently while resizing.
  void notifyResizing(bool isResizing) {
    if (isPopup) return;

    _setResizingAttribute(isResizing);
  }

  /// Noitifies this window about whether it is in a tiled layout or not.
  ///
  /// [tiledEdges] is a list of edges that are considered to be adjacent to
  /// another part of the tiling grid. If empty, the window is not tiled.
  ///
  /// Only the edges [WindowEdge.top], [WindowEdge.bottom], [WindowEdge.left],
  /// [WindowEdge.right], and [WindowEdge.none] are considered. If any other
  /// edge is provided, it will be ignored.
  ///
  /// The tiling functionality is handled by the compositor, but the application
  /// may want to draw itself differently while tiled.
  void notifyTiledEdges(List<WindowEdge> tiledEdges) {
    if (isPopup) return;

    _setTiledAttribute(tiledEdges);
  }

  /// Requests that this window be closed.
  ///
  /// The application may ignore this request for various reasons, including
  /// unsaved data.
  ///
  /// If this window does close, the [onTextureUnsetting] and [onDestroying]
  /// handlers will be called.
  void requestClose() {
    isPopup
        ? _wblib.wlr_xdg_popup_destroy(_wlrXdgPopupPtr)
        : _wblib.wlr_xdg_toplevel_send_close(_wlrXdgToplevelPtr);
  }

  /// Requests a new size for this window.
  ///
  /// If either [width] or [height] are zero, the window's application will
  /// decide its size. If either [width] or [height] are null, the current
  /// window dimensions will be used.
  ///
  /// The application itself may choose to either accept this size or choose a
  /// different size.
  ///
  /// If this window successfully resizes, the [onResize] handler will be
  /// called.
  ///
  /// This method does nothing if this is a popup window.
  Future<void> requestSize({int? width, int? height}) {
    if (isPopup || (width == this.width && height == this.height)) {
      return Future.value();
    }

    _setSize(width: width, height: height);

    var resizeCompleter = Completer<void>();
    _resizeCompleters.add(resizeCompleter);
    return resizeCompleter.future;
  }

  /// Submits pointer movement updates to this window.
  void submitPointerMoveUpdate(PointerUpdate<PointerMoveEvent> update) {
    var cursorX = update.windowCursorX.toInt();
    var cursorY = update.windowCursorY.toInt();

    _ensurePointerFocus(update.pointer, cursorX, cursorY);

    _wblib.waybright_window_submit_pointer_move_event(
      _windowPtr,
      update.event.elapsedTime.inMilliseconds,
      cursorX,
      cursorY,
    );
  }

  /// Submits pointer button updates to this window.
  void submitPointerButtonUpdate(PointerUpdate<PointerButtonEvent> update) {
    _ensurePointerFocus(
        update.pointer, update.windowCursorX, update.windowCursorY);

    // BUG: Crashes from a null pointer dereference if the window is closed
    // TODO: either remove the pointer device focus from the window or ensure
    // that the window pointer is not null before submitting the event
    _wblib.waybright_window_submit_pointer_button_event(
      _windowPtr,
      update.event.elapsedTime.inMilliseconds,
      update.event.code,
      update.event.isPressed ? 1 : 0,
    );
  }

  /// Submits pointer axis updates to this window.
  void submitPointerAxisUpdate(PointerUpdate<PointerAxisEvent> update) {
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
      _windowPtr,
      update.event.elapsedTime.inMilliseconds,
      orientation,
      update.event.delta,
      update.event.notches,
      source,
    );
  }

  /// Submits keyboard key updates to this window.
  void submitKeyboardKeyUpdate(KeyboardUpdate<KeyboardKeyEvent> update) {
    _ensureKeyboardFocus(update.keyboard);

    _wblib.waybright_window_submit_keyboard_key_event(
      _windowPtr,
      update.event.elapsedTime.inMilliseconds,
      update.event.code,
      update.event.isPressed ? 1 : 0,
    );
  }

  /// Submits keyboard modifiers updates to this window.
  void submitKeyboardModifiersUpdate(
      KeyboardUpdate<KeyboardModifiersEvent> update) {
    var keyboardPtr = update.keyboard._keyboardPtr;
    if (keyboardPtr == null) {
      throw StateError("Internal error: keyboardPtr is null");
    }

    _ensureKeyboardFocus(update.keyboard);

    _wblib.waybright_window_submit_keyboard_modifiers_event(
      _windowPtr,
      keyboardPtr,
    );
  }
}
