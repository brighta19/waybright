part of "./waybright.dart";

/// An application window.
///
/// In wayland, this contains an xdg-surface from the xdg-shell protocol.
class Window {
  static final _windowInstances = <Window>[];

  static final _eventTypeFromString = {
    'show': enum_event_type.event_type_window_show,
    'hide': enum_event_type.event_type_window_hide,
    'remove': enum_event_type.event_type_window_remove,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    for (var window in _windowInstances) {
      var windowPtr = data as Pointer<struct_waybright_window>;
      if (window._windowPtr != windowPtr) continue;

      var handleEvent = window._eventHandlers[type];
      if (handleEvent == null) return;

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
      return _wblib.waybright_window_focus(windowPtr);
    }
    isFocused = false;
  }
}
