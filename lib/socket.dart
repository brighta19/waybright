part of 'waybright.dart';

/// A wayland socket.
class Socket {
  final Pointer<struct_waybright> _wlPtr;

  /// The socket name of this wayland server.
  final String name;

  Socket(this._wlPtr, this.name);

  /// Enters the wayland server's event loop.
  ///
  /// This function is synchronous (blocking).
  void runEventLoop() {
    _wblib.waybright_run_event_loop(_wlPtr);
  }
}
