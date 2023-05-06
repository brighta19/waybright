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

  Future<void> _checkEvents() async {
    if (!_isRunning) return;
    _wblib.waybright_check_events(_wbPtr!);
    return Future(() => _checkEvents());
  }

  Future<void> _runEventLoop() async {
    return _checkEvents();
  }

  /// Enters the wayland server's event loop.
  Future<void> runEventLoop() async {
    return _runEventLoop();
  }

  void _close() {
    _isRunning = false;
    _wblib.waybright_close_socket(_wbPtr!);
  }

  /// Closes the wayland server.
  void close() {
    _close();
  }
}
