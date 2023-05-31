part of "./waybright.dart";

/// A renderer.
class Renderer {
  final Pointer<struct_waybright_renderer>? _rendererPtr;

  Renderer._fromPointer(Pointer<struct_waybright_renderer> this._rendererPtr);

  /// The background color of this monitor.
  int get backgroundColor {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      return _wblib.waybright_renderer_get_background_color(rendererPtr);
    }
    return 0;
  }

  set backgroundColor(int color) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_set_background_color(rendererPtr, color);
    }
  }

  /// The color used to fill in shapes.
  int get fillStyle {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      return _wblib.waybright_renderer_get_fill_style(rendererPtr);
    }
    return 0;
  }

  set fillStyle(int color) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_set_fill_style(rendererPtr, color);
    }
  }

  /// Sets all pixels to transparent black.
  void clearRect(num x, num y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_clear_rect(
          rendererPtr, x.toInt(), y.toInt(), width, height);
    }
  }

  /// Draws a rectangle filled with the current [fillStyle].
  void fillRect(num x, num y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_fill_rect(
          rendererPtr, x.toInt(), y.toInt(), width, height);
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
    var imagePtr = image._imagePtr;
    if (rendererPtr != null && imagePtr != null) {
      _wblib.waybright_renderer_draw_image(
        rendererPtr,
        imagePtr,
        x.toInt(),
        y.toInt(),
        width ?? imagePtr.ref.width,
        height ?? imagePtr.ref.height,
        alpha ?? 1.0,
      );
    }
  }

  Image? captureWindowFrame(Window window) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      var imagePtr = _wblib.waybright_renderer_capture_window_frame(
          rendererPtr, window._windowPtr);
      return imagePtr == nullptr ? null : Image._fromPointer(imagePtr);
    }
    return null;
  }
}
