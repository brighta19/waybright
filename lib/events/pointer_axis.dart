part of '../waybright.dart';

/// A pointer axis event.
class PointerAxisEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The distance the axis had moved.
  final double delta;

  /// The amount of notches the axis had moved.
  final int notches;

  /// The source of the axis event.
  final PointerAxisSource source;

  /// The axis orientation.
  final PointerAxisOrientation orientation;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerAxisEvent(
    this.pointer,
    this.delta,
    this.notches,
    this.source,
    this.orientation,
    this.elapsedTimeMilliseconds,
  );
}
