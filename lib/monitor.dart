part of "./waybright.dart";

/// A physical or virtual monitor.
class Monitor {
  static final _monitorInstances = <Monitor>[];

  static final _eventTypeFromString = {
    'remove': enum_event_type.event_type_monitor_remove,
    'frame': enum_event_type.event_type_monitor_frame,
  };

  static void _executeEventHandler(int type, Pointer<Void> data) {
    var monitors = _monitorInstances.toList();
    for (var monitor in monitors) {
      var monitorPtr = data as Pointer<struct_waybright_monitor>;
      if (monitor._monitorPtr != monitorPtr) continue;

      var handleEvent = monitor._eventHandlers[type];
      if (handleEvent == null) continue;

      handleEvent();

      if (type == enum_event_type.event_type_monitor_remove) {
        _monitorInstances.remove(monitor);
      }
    }
  }

  /// This monitor's name.
  String name = "unknown-monitor";

  /// This monitor's renderer.
  final Renderer renderer;

  final Map<int, Function> _eventHandlers = {};
  Pointer<struct_waybright_monitor>? _monitorPtr;
  bool _isEnabled = false;
  List<Mode> _modes = [];
  bool _hasIteratedThroughModes = false;
  Mode? _preferredMode;
  Mode _mode = Mode(0, 0, 0);

  Monitor(this.renderer) {
    _monitorInstances.add(this);
  }

  /// Sets an event handler for this monitor.
  void setEventHandler(String event, Function handler) {
    var type = _eventTypeFromString[event];
    if (type != null) {
      _eventHandlers[type] = handler;
    }
  }

  /// Whether this monitor is allowed to render or not.
  get isEnabled => _isEnabled;

  /// This monitor's modes (resolution + refresh rate).
  List<Mode> get modes {
    if (_hasIteratedThroughModes) return _modes;

    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      var head = monitorPtr.ref.wlr_output.ref.modes.next;
      var link = head;
      Pointer<struct_wlr_output_mode> item;
      while (link.ref.next != head) {
        item = _wblib.get_wlr_output_mode_from_wl_list(link);
        var mode = Mode(
          item.ref.width,
          item.ref.height,
          item.ref.refresh,
        ).._outputModePtr = item;

        // While I find modes, find the preferred mode
        if (item.ref.preferred) {
          _preferredMode = mode;
        }

        _modes.add(mode);

        link = link.ref.next;
      }

      if (_preferredMode == null && _modes.isNotEmpty) {
        _preferredMode = _modes[0];
      }

      _hasIteratedThroughModes = true;
      return _modes;
    }

    return [];
  }

  set modes(List<Mode> modes) {
    _hasIteratedThroughModes = true;
    _modes = modes;
  }

  /// This monitor's preferred mode.
  Mode? get preferredMode {
    if (_hasIteratedThroughModes) return _preferredMode;
    modes;
    return _preferredMode;
  }

  /// This monitor's resolution and refresh rate.
  Mode get mode => _mode;
  set mode(Mode mode) {
    var monitorPtr = _monitorPtr;
    var outputModePtr = mode._outputModePtr;
    if (_monitorPtr != null && mode._outputModePtr != null) {
      _wblib.wlr_output_set_mode(monitorPtr!.ref.wlr_output, outputModePtr!);
    }

    _mode = mode;
  }

  /// Enables this monitor to start rendering.
  void enable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_enable(monitorPtr);
    }
    _isEnabled = true;
  }

  /// Disables this monitor.
  void disable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_disable(monitorPtr);
    }
    _isEnabled = false;
  }

  /// The background color of this monitor.
  int get backgroundColor {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      return _wblib.waybright_monitor_get_background_color(monitorPtr);
    }
    return 0;
  }

  set backgroundColor(int color) {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_set_background_color(monitorPtr, color);
    }
  }
}
