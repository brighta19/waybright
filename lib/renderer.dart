part of "./waybright.dart";

/// A renderer.
class Renderer {
  Pointer<struct_waybright_renderer>? _rendererPtr;

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
  void clearRect(int x, int y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_clear_rect(rendererPtr, x, y, width, height);
    }
  }

  /// Draws a rectangle filled with the current [fillStyle].
  void fillRect(int x, int y, int width, int height) {
    var rendererPtr = _rendererPtr;
    if (rendererPtr != null) {
      _wblib.waybright_renderer_fill_rect(rendererPtr, x, y, width, height);
    }
  }

  /// Draws a rectangle.
  void drawWindow(Window window, int x, int y) {
    var rendererPtr = _rendererPtr;
    var windowPtr = window._windowPtr;
    if (rendererPtr != null && windowPtr != null) {
      _wblib.waybright_renderer_draw_window(rendererPtr, windowPtr, x, y);
    }
  }
}
