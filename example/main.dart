import 'package:waybright/waybright.dart';

const backgroundColor = 0x111111ff;

Monitor? currentMonitor;
Window? focusedWindow;
KeyboardDevice? currentKeyboard;

var windows = WindowList();
var tempWindows = <Window>[];
var cursorX = 10.0;
var cursorY = 10.0;

var cursorXAtGrab = 0.0;
var cursorYAtGrab = 0.0;
var isMovingWindow = false;
var isResizingWindow = false;
bool get isGrabbingWindow => isMovingWindow || isResizingWindow;

var isLeftAltPressed = false;
var isRightAltPressed = false;
get isAltPressed => isLeftAltPressed || isRightAltPressed;

var isSwitchingWindows = false;
var windowSwitchIndex = 0;

final compositor = Waybright();

void onNewMonitor(NewMonitorEvent event) {
  var monitor = event.monitor;
  currentMonitor ??= monitor;

  var preferredMode = monitor.preferredMode;
  if (preferredMode == null) {
    compositor.closeSocket();
    return;
  }

  monitor.mode = preferredMode;
  monitor.enable();

  var renderer = monitor.renderer;
  renderer.backgroundColor = backgroundColor;

  monitor.onRemove = (event) {
    if (monitor == currentMonitor) {
      currentMonitor = null;
    }
  };

  monitor.onFrame = (event) {
    var list = windows.backToFrontIterable;
    for (var window in list) {
      if (window.isVisible) {
        renderer.drawWindow(window, window.drawingX, window.drawingY);
      }
    }

    renderer.fillStyle = 0xffffffdd;
    renderer.fillRect(cursorX, cursorY, 5, 5);
  };

  cursorX = monitor.mode.width / 2;
  cursorY = monitor.mode.height / 2;
}

void onNewWindow(NewWindowEvent event) {
  var window = event.window;

  windows.addToFront(window);

  window.onRemove = (event) {
    windows.remove(window);
    if (window == focusedWindow) focusedWindow = null;
  };

  window.onShow = (event) {
    window.drawingX = -window.offsetX;
    window.drawingY = -window.offsetY;

    focusedWindow?.unfocus();
    window.focus();
    focusedWindow = window;
    windows.moveToFront(window);
  };

  window.onHide = (event) {
    window.unfocus();
  };

  window.onMove = (event) {
    cursorXAtGrab = cursorX;
    cursorYAtGrab = cursorY;
    isMovingWindow = true;
  };

  window.onResize = (event) {
    cursorXAtGrab = cursorX;
    cursorYAtGrab = cursorY;
    isResizingWindow = true;
  };
}

void onNewPointer(PointerDevice pointer) {
  Window? getHoveredWindow() {
    var list = windows.frontToBackIterable;
    for (var window in list) {
      if (!window.isVisible) continue;

      var windowX = window.contentX;
      var windowY = window.contentY;
      var windowWidth = window.contentWidth;
      var windowHeight = window.contentHeight;

      if (cursorX >= windowX &&
          cursorX < windowX + windowWidth &&
          cursorY >= windowY &&
          cursorY < windowY + windowHeight) {
        return window;
      }
    }
    return null;
  }

  void handleMovement(PointerMoveEvent event) {
    Window? hoveredWindow = getHoveredWindow();

    if (hoveredWindow == null) return;

    var windowCursorX = cursorX - hoveredWindow.drawingX;
    var windowCursorY = cursorY - hoveredWindow.drawingY;

    hoveredWindow.submitPointerMoveUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  }

  pointer.onMove = (event) {
    cursorX += event.deltaX;
    cursorY += event.deltaY;

    if (!isGrabbingWindow) handleMovement(event);
  };

  pointer.onTeleport = (event) {
    cursorX = event.x;
    cursorY = event.y;

    if (!isGrabbingWindow) handleMovement(event);
  };

  pointer.onButton = (event) {
    if (!event.isPressed) {
      if (isMovingWindow) {
        focusedWindow!.drawingX += cursorX - cursorXAtGrab;
        focusedWindow!.drawingY += cursorY - cursorYAtGrab;
      } else if (isResizingWindow) {
        // resize
      }
      isMovingWindow = false;
      isResizingWindow = false;
    }

    var hoveredWindow = getHoveredWindow();
    if (hoveredWindow == null) return;

    if (hoveredWindow != focusedWindow) {
      focusedWindow?.unfocus();
      hoveredWindow.focus();
      focusedWindow = hoveredWindow;
      windows.moveToFront(hoveredWindow);
    }

    var windowCursorX = cursorX - hoveredWindow.drawingX;
    var windowCursorY = cursorY - hoveredWindow.drawingY;

    hoveredWindow.submitPointerButtonUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  };

  pointer.onAxis = (event) {
    var hoveredWindow = getHoveredWindow();
    if (hoveredWindow == null) return;

    var windowCursorX = cursorX - hoveredWindow.drawingX;
    var windowCursorY = cursorY - hoveredWindow.drawingY;

    hoveredWindow.submitPointerAxisUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  };
}

void onNewKeyboard(KeyboardDevice keyboard) {
  keyboard.onModifiers = (event) {
    currentKeyboard = event.keyboard;

    focusedWindow?.submitKeyboardModifiersUpdate(KeyboardUpdate(
      keyboard,
      event,
    ));
  };

  keyboard.onKey = (event) {
    currentKeyboard = event.keyboard;

    if (event.key == InputDeviceButton.altLeft) {
      isLeftAltPressed = event.isPressed;
    } else if (event.key == InputDeviceButton.altRight) {
      isRightAltPressed = event.isPressed;
    } else if (event.key == InputDeviceButton.escape && event.isPressed) {
      if (isAltPressed) {
        compositor.closeSocket();
      }
    } else if (event.key == InputDeviceButton.f1 && event.isPressed) {
      if (isAltPressed) {
        if (!isSwitchingWindows) {
          isSwitchingWindows = true;
          windowSwitchIndex = 0;
          tempWindows = windows.frontToBackIterable.toList();
        }

        windowSwitchIndex = (windowSwitchIndex + 1) % tempWindows.length;

        var i = 0;
        for (var window in tempWindows) {
          if (i == windowSwitchIndex) {
            focusedWindow?.unfocus();
            window.focus();
            focusedWindow = window;
            windows.moveToFront(window);
            break;
          }
          i++;
        }
      }
    }

    if (!isAltPressed && isSwitchingWindows) {
      isSwitchingWindows = false;
      tempWindows = [];
    }

    if (!isSwitchingWindows) {
      focusedWindow?.submitKeyboardKeyUpdate(KeyboardUpdate(
        keyboard,
        event,
      ));
    }
  };
}

void onNewInput(NewInputEvent event) {
  if (event.pointer != null) {
    onNewPointer(event.pointer!);
  } else if (event.keyboard != null) {
    onNewKeyboard(event.keyboard!);
  }
}

void main(List<String> args) {
  compositor.onNewMonitor = onNewMonitor;
  compositor.onNewWindow = onNewWindow;
  compositor.onNewInput = onNewInput;

  try {
    var socketName = compositor.openSocket();
    print("Running on WAYLAND_DISPLAY=$socketName");
  } catch (e) {
    print(e);
  }
}
