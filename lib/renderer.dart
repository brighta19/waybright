part of "./waybright.dart";

/// A renderer.
class Renderer {
  final Pointer<struct_waybright_renderer>? _rendererPtr;

  /// This renderer's monitor.
  Monitor? _monitor;

  Renderer._fromPointer(Pointer<struct_waybright_renderer> this._rendererPtr);

  /// The clear color of this monitor.
  int clearColor = 0x00000000;

  /// The color used to fill in shapes.
  int fillColor = 0xFFFFFFFF;

  /// Clears all pixels on the monitor with the current [clearColor].
  void clear() {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_clear(rendererPtr, clearColor);
    }
  }

  /// Draws a rectangle filled with the current [fillColor].
  void fillRect(num x, num y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_fill_rect(
          rendererPtr, x.toInt(), y.toInt(), width, height, fillColor);
    }
  }

  /// Draws a rectangle.
  void drawWindow(Window window, num x, num y,
      {int? width, int? height, double? alpha}) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_draw_window(
        rendererPtr,
        window._windowPtr,
        x.toInt(),
        y.toInt(),
        width ?? window.textureWidth,
        height ?? window.textureHeight,
        alpha ?? 1.0,
      );
    }
  }

  /// Draws an image.
  void drawImage(Image image, num x, num y,
      {int? width, int? height, double? alpha}) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_draw_image(
        rendererPtr,
        image._imagePtr,
        x.toInt(),
        y.toInt(),
        width ?? image._imagePtr.ref.width,
        height ?? image._imagePtr.ref.height,
        alpha ?? 1.0,
      );
    }
  }

  Image? captureWindowFrame(Window window) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null && window._hasBuffer) {
      var imagePtr = _wblib.waybright_renderer_capture_window_frame(
          rendererPtr, window._windowPtr);
      return imagePtr == nullptr ? null : Image._fromPointer(imagePtr);
    }
    return null;
  }

  void begin() {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_begin(rendererPtr);
    }
  }

  void end() {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_end(rendererPtr);
    }
  }

  void render() {
    var rendererPtr = _rendererPtr;
    var monitor = _monitor;
    if (rendererPtr != null && monitor != null) {
      _wblib.waybright_renderer_render(rendererPtr);

      if (monitor.isDamaged) {
        monitor._updateDamagedRegions();
      }
    }
  }

  void scissor(num x, num y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_scissor(
          rendererPtr, x.toInt(), y.toInt(), width, height);
    }
  }
}
