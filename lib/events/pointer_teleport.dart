part of '../waybright.dart';

/// A pointer teleport event.
class PointerTeleportEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The monitor that the pointer teleported to.
  final Monitor monitor;

  /// The pointer's horizontal position on the [monitor].
  final double x;

  /// The pointer's vertical position on the [monitor].
  final double y;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerTeleportEvent(
    this.pointer,
    this.monitor,
    this.x,
    this.y,
    this.elapsedTimeMilliseconds,
  );
}
