part of '../../waybright.dart';

/// A pointer event.
abstract class PointerEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The time elapsed.
  final Duration elapsedTime;

  PointerEvent(this.pointer, this.elapsedTime);
}
