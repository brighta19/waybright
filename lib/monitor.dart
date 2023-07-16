part of "./waybright.dart";

Iterable<Pointer<struct_wlr_output_mode>> _getModeIterator(
    Pointer<struct_waybright_monitor> monitorPtr) sync* {
  var head = monitorPtr.ref.wlr_output.ref.modes.next;
  var link = head;
  Pointer<struct_wlr_output_mode> outputModePtr;
  while (link.ref.next != head) {
    outputModePtr = _wblib.waybright_get_wlr_output_mode_from_wl_list(link);
    yield outputModePtr;
    link = link.ref.next;
  }
}

/// A physical or virtual monitor.
class Monitor {
  static final _monitorInstances =
      <Pointer<struct_waybright_monitor>, Monitor>{};

  static void _onEvent(int type, Pointer<Void> data) {
    var monitorPtr = data as Pointer<struct_waybright_monitor>;
    var monitor = _monitorInstances[monitorPtr];
    if (monitor == null) return;

    switch (type) {
      case enum_wb_event_type.event_type_monitor_remove:
        monitor.onRemoving?.call(MonitorRemovingEvent(monitor));
        _monitorInstances.remove(monitor);
        break;
      case enum_wb_event_type.event_type_monitor_frame:
        monitor.onFrame?.call(MonitorFrameEvent(monitor));
        break;
      default:
        throw ArgumentError("Internal error: unknown event type $type");
    }
  }

  final Pointer<struct_waybright_monitor> _monitorPtr;
  final _modes = <Mode>[];
  final List<Rect> _damagedBufferRegions = [];
  final List<Rect> _damagedFrameRegions = [];

  bool _isEnabled = false;
  bool _hasIteratedThroughModes = false;
  Mode? _preferredMode;
  Mode _mode = Mode(0, 0, 0);

  Monitor._fromPointer(
    this._monitorPtr,
  ) : renderer = Renderer._fromPointer(_monitorPtr.ref.wb_renderer) {
    renderer._monitor = this;
    _monitorInstances[_monitorPtr] = this;
    _monitorPtr.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  void _enable() {
    _wblib.waybright_monitor_enable(_monitorPtr);
    _isEnabled = true;
  }

  void _disable() {
    _wblib.waybright_monitor_disable(_monitorPtr);
    _isEnabled = false;
  }

  void _updateDamagedRegions() {
    _damagedBufferRegions.clear();
    _damagedBufferRegions.addAll(_damagedFrameRegions);
    _damagedFrameRegions.clear();
  }

  /// A handler that is called when this monitor is being removed.
  void Function(MonitorRemovingEvent event)? onRemoving;

  /// A handler that is called when this monitor is ready for a new frame.
  void Function(MonitorFrameEvent event)? onFrame;

  /// This monitor's renderer.
  final Renderer renderer;

  /// This monitor's name.
  String get name => _toDartString(_monitorPtr.ref.wlr_output.ref.name) ?? "";
  set name(String value) =>
      _wblib.wlr_output_set_name(_monitorPtr.ref.wlr_output, _toCString(value));

  /// This monitor's description.
  String? get description =>
      _toDartString(_monitorPtr.ref.wlr_output.ref.description);
  set description(String? value) => _wblib.wlr_output_set_description(
      _monitorPtr.ref.wlr_output, _toCString(value));

  /// This monitor's make.
  String? get make => _toDartString(_monitorPtr.ref.wlr_output.ref.make);

  /// This monitor's model.
  String? get model => _toDartString(_monitorPtr.ref.wlr_output.ref.model);

  /// This monitor's serial number.
  String? get serialNumber =>
      _toDartString(_monitorPtr.ref.wlr_output.ref.serial);

  /// This monitor's physical width in millimeters.
  int get physicalWidth => _monitorPtr.ref.wlr_output.ref.phys_width;

  /// This monitor's physical height in millimeters.
  int get physicalHeight => _monitorPtr.ref.wlr_output.ref.phys_height;

  /// Whether this monitor is on and rendering or not.
  bool get isEnabled => _isEnabled;

  // TODO: Custom modes?

  /// Whether this monitor has a custom mode set or not.
  bool get hasCustomModeSet => mode._outputModePtr == null;

  /// This monitor's available modes.
  List<Mode> get modes {
    if (_hasIteratedThroughModes) return _modes;

    var iterator = _getModeIterator(_monitorPtr);
    for (var outputModePtr in iterator) {
      var mode = Mode._fromPointer(outputModePtr);

      // While I find modes, find the preferred mode
      if (outputModePtr.ref.preferred) {
        _preferredMode = mode;
      }

      _modes.add(mode);
    }

    if (_preferredMode == null && _modes.isNotEmpty) {
      _preferredMode = _modes.first;
    }

    _hasIteratedThroughModes = true;
    return _modes;
  }

  /// This monitor's preferred mode.
  Mode? get preferredMode {
    modes;
    return _preferredMode;
  }

  /// This monitor's current resolution and refresh rate.
  Mode get mode => _mode;
  set mode(Mode mode) {
    var outputModePtr = mode._outputModePtr;

    if (outputModePtr == null) {
      _wblib.wlr_output_set_custom_mode(_monitorPtr.ref.wlr_output, mode.width,
          mode.height, mode.refreshRate);
    } else {
      _wblib.wlr_output_set_mode(_monitorPtr.ref.wlr_output, outputModePtr);
    }

    _mode = mode;
  }

  /// This monitor's damaged regions.
  ///
  /// This includes both frame and buffer regions. The damaged frame regions
  /// are added manually, while the damaged buffer regions are updated
  /// automatically.
  List<Rect> get damagedRegions => _damagedFrameRegions + _damagedBufferRegions;

  bool get isDamaged =>
      _damagedFrameRegions.isNotEmpty || _damagedBufferRegions.isNotEmpty;

  /// Enables this monitor for rendering.
  void enable() {
    if (isEnabled) return;
    _enable();
  }

  /// Disables this monitor from rendering.
  void disable() {
    if (!isEnabled) return;
    _disable();
  }

  /// Schedule a frame event for this monitor.
  void scheduleFrame() {
    _wblib.wlr_output_schedule_frame(_monitorPtr.ref.wlr_output);
  }

  /// Damage a region of this monitor.
  void damageRegion(Rect area) => _damagedFrameRegions.add(area);

  /// Damage multiple regions of this monitor.
  void damageRegions(List<Rect> areas) => _damagedFrameRegions.addAll(areas);

  /// Damage this monitor's whole region.
  void damageWholeRegion() =>
      _damagedFrameRegions.add(Rect(0, 0, mode.width, mode.height));
}
