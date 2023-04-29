part of '../../waybright.dart';

/// A keyboard event.
abstract class KeyboardEvent {
  /// The keyboard.
  final KeyboardDevice keyboard;

  KeyboardEvent(this.keyboard);
}
