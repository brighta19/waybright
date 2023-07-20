part of '../../waybright.dart';

/// A pointer axis event.
class PointerAxisEvent extends PointerEvent {
  /// The distance the axis had moved.
  final double delta;

  /// The amount of notches the axis had moved.
  final int notches;

  /// The source of the axis event.
  final PointerAxisSource source;

  /// The axis orientation.
  final PointerAxisOrientation orientation;

  PointerAxisEvent(
    PointerDevice pointer,
    this.delta,
    this.notches,
    this.source,
    this.orientation,
    Duration elapsedTime,
  ) : super(pointer, elapsedTime);
}
