part of "./waybright.dart";

class RemoveMonitorEvent {}

/// A physical or virtual monitor.
class Monitor {
  static final _monitorInstances = <Monitor>[];

  static void _onEvent(int type, Pointer<Void> data) {
    var monitors = _monitorInstances.toList();
    for (var monitor in monitors) {
      var monitorPtr = data as Pointer<struct_waybright_monitor>;
      if (monitor._monitorPtr != monitorPtr) continue;

      switch (type) {
        case enum_wb_event_type.event_type_monitor_remove:
          monitor.onRemove?.call(RemoveMonitorEvent());
          _monitorInstances.remove(monitor);
          break;
        case enum_wb_event_type.event_type_monitor_frame:
          monitor.onFrame?.call(MonitorFrameEvent(monitor));
          break;
      }
    }
  }

  Pointer<struct_waybright_monitor>? _monitorPtr;
  bool _isEnabled = false;
  List<Mode> _modes = [];
  bool _hasIteratedThroughModes = false;
  Mode? _preferredMode;
  Mode _mode = Mode(0, 0, 0);

  void _enable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_enable(monitorPtr);
    }
    _isEnabled = true;
  }

  void _disable() {
    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      _wblib.waybright_monitor_disable(monitorPtr);
    }
    _isEnabled = false;
  }

  /// This monitor's modes (resolution + refresh rate).
  List<Mode> get modes {
    if (_hasIteratedThroughModes) return _modes;

    var monitorPtr = _monitorPtr;
    if (monitorPtr != null) {
      var head = monitorPtr.ref.wlr_output.ref.modes.next;
      var link = head;
      Pointer<struct_wlr_output_mode> outputModePtr;
      while (link.ref.next != head) {
        outputModePtr = _wblib.waybright_get_wlr_output_mode_from_wl_list(link);
        var mode = Mode._fromPointer(outputModePtr);

        // While I find modes, find the preferred mode
        if (outputModePtr.ref.preferred) {
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

  /// This monitor's name.
  String name = "unknown-monitor";

  /// This monitor's renderer.
  final Renderer renderer;

  void Function(RemoveMonitorEvent)? onRemove;
  void Function(MonitorFrameEvent)? onFrame;

  Monitor(this.renderer) {
    _monitorInstances.add(this);
  }

  Monitor._fromPointer(
    Pointer<struct_waybright_monitor> this._monitorPtr,
    this.renderer,
  ) {
    _monitorInstances.add(this);
    _monitorPtr?.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  /// Whether this monitor is allowed to render or not.
  get isEnabled => _isEnabled;

  /// Enables this monitor to start rendering.
  void enable() {
    if (_isEnabled) return;
    _enable();
  }

  /// Disables this monitor.
  void disable() {
    if (!_isEnabled) return;
    _disable();
  }
}
