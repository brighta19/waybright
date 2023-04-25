part of './waybright.dart';

enum InputDeviceType {
  pointer,
  keyboard,
}

/// An input device
class InputDevice {
  InputDeviceType type;

  InputDevice(this.type);
}
