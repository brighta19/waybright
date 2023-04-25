part of '../waybright.dart';

/// A pointer axis event.
class PointerAxisEvent {
  /// The pointer.
  PointerDevice pointer;

  /// The distance the axis had moved.
  double delta;

  /// The amount of notches the axis had moved.
  int notches;

  /// The source of the axis event.
  PointerAxisSource source;

  /// The axis orientation.
  PointerAxisOrientation orientation;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  PointerAxisEvent(
    this.pointer,
    this.delta,
    this.notches,
    this.source,
    this.orientation,
    this.elapsedTimeMilliseconds,
  );
}
