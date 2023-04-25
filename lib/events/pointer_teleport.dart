part of '../waybright.dart';

/// A pointer teleport event.
class PointerTeleportEvent {
  /// The pointer.
  PointerDevice pointer;

  /// The monitor that the pointer teleported to.
  Monitor monitor;

  /// The pointer's horizontal position on the [monitor].
  double x;

  /// The pointer's vertical position on the [monitor].
  double y;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  PointerTeleportEvent(
    this.pointer,
    this.monitor,
    this.x,
    this.y,
    this.elapsedTimeMilliseconds,
  );
}
