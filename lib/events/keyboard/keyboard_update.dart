part of '../../waybright.dart';

/// A structure containing update information for a keyboard.
class KeyboardUpdate<KeyboardEvent> {
  /// The keyboard.
  final KeyboardDevice keyboard;

  /// The event containing the update.
  final KeyboardEvent event;

  KeyboardUpdate(
    this.keyboard,
    this.event,
  );
}
