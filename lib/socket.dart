part of 'waybright.dart';

/// A wayland socket.
class Socket {
  Pointer<struct_waybright>? _wbPtr;
  bool _isRunning = true;

  /// The socket name of this wayland server.
  final String name;

  /// Whether the wayland server is running or not.
  bool get isRunning => _isRunning;

  Socket(this.name);

  /// Enters the wayland server's event loop.
  ///
  /// This function is synchronous (blocking).
  void runEventLoop() {
    var wbPtr = _wbPtr;
    if (wbPtr != null && _isRunning) {
      _wblib.waybright_run_event_loop(wbPtr);
    }
  }

  /// Closes the wayland server,
  void close() {
    var wbPtr = _wbPtr;
    if (wbPtr != null && _isRunning) {
      _wblib.waybright_close_socket(wbPtr);
      _isRunning = false;
    }
  }
}
