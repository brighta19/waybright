part of '../waybright.dart';

/// A window event.
abstract class WindowEvent {
  /// The window.
  final Window window;

  WindowEvent(this.window);
}

/// A window create event.
class WindowCreateEvent extends WindowEvent {
  WindowCreateEvent(super.window);
}

/// A window destroying event.
class WindowDestroyingEvent extends WindowEvent {
  WindowDestroyingEvent(super.window);
}

/// A window texture set event.
class WindowTextureSetEvent extends WindowEvent {
  WindowTextureSetEvent(super.window);
}

/// A window texture unsetting event.
class WindowTextureUnsettingEvent extends WindowEvent {
  WindowTextureUnsettingEvent(super.window);
}

/// A window popup create event.
class WindowPopupCreateEvent extends WindowEvent {
  WindowPopupCreateEvent(super.window);
}

/// A window activate event.
class WindowActivateEvent extends WindowEvent {
  WindowActivateEvent(super.window);
}

/// A window deactivate event.
class WindowDeactivateEvent extends WindowEvent {
  WindowDeactivateEvent(super.window);
}

/// A window move request event.
class WindowMoveRequestEvent extends WindowEvent {
  WindowMoveRequestEvent(super.window);
}

/// A window resize request event.
class WindowResizeRequestEvent extends WindowEvent {
  final WindowEdge edge;

  WindowResizeRequestEvent(super.window, this.edge);
}

/// A window resize event.
class WindowResizeEvent extends WindowEvent {
  /// The old width.
  final int oldWidth;

  /// The old height.
  final int oldHeight;

  WindowResizeEvent(super.window, this.oldWidth, this.oldHeight);
}

/// A window maximize request event.
class WindowMaximizeRequestEvent extends WindowEvent {
  WindowMaximizeRequestEvent(super.window);
}

/// A window maximize event.
class WindowMaximizeEvent extends WindowEvent {
  WindowMaximizeEvent(super.window);
}

/// A window unmaximize request event.
class WindowUnmaximizeRequestEvent extends WindowEvent {
  WindowUnmaximizeRequestEvent(super.window);
}

/// A window unmaximize event.
class WindowUnmaximizeEvent extends WindowEvent {
  WindowUnmaximizeEvent(super.window);
}

/// A window minimize request event.
class WindowMinimizeRequestEvent extends WindowEvent {
  WindowMinimizeRequestEvent(super.window);
}

/// A window fullscreen request event.
class WindowFullscreenRequestEvent extends WindowEvent {
  WindowFullscreenRequestEvent(super.window);
}

/// A window fullscreen event.
class WindowFullscreenEvent extends WindowEvent {
  WindowFullscreenEvent(super.window);
}

/// A window unfullscreen request event.
class WindowUnfullscreenRequestEvent extends WindowEvent {
  WindowUnfullscreenRequestEvent(super.window);
}

/// A window unfullscreen event.
class WindowUnfullscreenEvent extends WindowEvent {
  WindowUnfullscreenEvent(super.window);
}

/// A window menu request event.
class WindowMenuRequestEvent extends WindowEvent {
  /// The requested x coordinate.
  final num x;

  /// The requested y coordinate.
  final num y;

  WindowMenuRequestEvent(super.window, this.x, this.y);
}

/// A window title change event.
class WindowTitleChangeEvent extends WindowEvent {
  WindowTitleChangeEvent(super.window);
}

/// A window app id change event.
class WindowAppIdChangeEvent extends WindowEvent {
  WindowAppIdChangeEvent(super.window);
}

/// A window parent change event.
class WindowParentChangeEvent extends WindowEvent {
  WindowParentChangeEvent(super.window);
}

/// A window damaged regions event.
class WindowTextureDamagedRegionsEvent extends WindowEvent {
  /// The damaged regions.
  final List<Rect> damagedRegions;

  WindowTextureDamagedRegionsEvent(super.window, this.damagedRegions);
}
