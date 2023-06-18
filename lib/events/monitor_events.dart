part of '../waybright.dart';

/// A monitor event.
abstract class MonitorEvent {
  /// The monitor.
  final Monitor monitor;

  MonitorEvent(this.monitor);
}

/// A monitor add event.
class MonitorAddEvent extends MonitorEvent {
  MonitorAddEvent(super.monitor);
}

/// A monitor removing event.
class MonitorRemovingEvent extends MonitorEvent {
  MonitorRemovingEvent(super.image);
}

/// A monitor frame event.
class MonitorFrameEvent extends MonitorEvent {
  MonitorFrameEvent(super.monitor);
}
