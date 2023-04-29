part of '../../waybright.dart';

/// A pointer event.
abstract class PointerEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerEvent(this.pointer, this.elapsedTimeMilliseconds);
}
