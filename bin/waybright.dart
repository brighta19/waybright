import 'package:waybright/waybright.dart';

// Switch windows with Alt+Tab
// Close socket by holding Alt while clicking Escape twice

class Vector {
  num x;
  num y;
  Vector(this.x, this.y);
}

const backgroundColors = [
  0x88ffccff,
  0xffaaaaff,
];

Socket? socket;

var monitors = <Monitor>[];
var windows = WindowList();
var inputDevices = <InputDevice>[];

Monitor? currentMonitor;

Window? focusedWindow;
Window? hoveredWindow;

var isFocusedWindowFocusedFromPointer = false;
var isMovingFocusedWindow = false;
var isMaximizingFocusedWindow = false;
var isUnmaximizingFocusedWindow = false;

var cursor = Vector(0.0, 0.0);
var windowDrawingPositionAtGrab = Vector(0.0, 0.0);
var cursorPositionAtGrab = Vector(0.0, 0.0);

var isLeftAltKeyPressed = false;
var isLeftShiftKeyPressed = false;
var windowSwitchIndex = 0;
var isSwitchingWindows = false;
var hasSwitchedWindows = false;
var tempWindowList = <Window>[];

var readyToQuit = false;

get shouldSubmitPointerMoveEvents => !isSwitchingWindows;

void forEachKeyboard(Function(KeyboardDevice keyboard) callback) {
  for (var inputDevice in inputDevices) {
    if (inputDevice.type != InputDeviceType.keyboard) continue;
    callback(inputDevice as KeyboardDevice);
  }
}

void focusWindow(Window window) {
  if (focusedWindow == window) return;
  print("Redirecting 🪟 window focus...");

  if (focusedWindow != null) {
    focusedWindow?.unfocus();
    forEachKeyboard((keyboard) {
      if (keyboard.focusedWindow == window) keyboard.clearFocus();
    });
  }

  window.focus();
  forEachKeyboard((keyboard) => keyboard.focusOnWindow(window));
  windows.moveToFront(window);
  focusedWindow = window;
}

void unfocusWindow() {
  if (focusedWindow == null) return;
  print("Unfocusing 🪟 window...");

  focusedWindow?.unfocus();
  forEachKeyboard((keyboard) {
    if (keyboard.focusedWindow == focusedWindow) keyboard.clearFocus();
  });
  focusedWindow = null;
}

void startMaximizingWindow(Window window) {
  var monitor = currentMonitor;
  if (monitor == null) return;

  isMaximizingFocusedWindow = true;
  window.maximize(width: monitor.mode.width, height: monitor.mode.height);
}

void startUnmaximizingWindow(Window window) {
  var monitor = currentMonitor;
  if (monitor == null) return;

  isUnmaximizingFocusedWindow = true;
  var width = (monitor.mode.width * 0.5).toInt();
  var height = (monitor.mode.height * 0.5).toInt();
  window.unmaximize(width: width, height: height);
}

Window? getWindowAtPoint(num x, num y) {
  var list = windows.frontToBackIterable;
  for (var window in list) {
    var windowX = window.contentX;
    var windowY = window.contentY;
    var windowWidth = window.contentWidth;
    var windowHeight = window.contentHeight;

    if (x >= windowX &&
        x < windowX + windowWidth &&
        y >= windowY &&
        y < windowY + windowHeight) {
      return window;
    }
  }
  return null;
}

void drawCursor(Renderer renderer) {
  var borderColor = hoveredWindow == null ? 0xffffffff : 0x000000ff;

  int color;
  if (focusedWindow != null && hoveredWindow == focusedWindow) {
    color = 0x88ff88ff;
  } else if (hoveredWindow != null) {
    color = 0xffaa88ff;
  } else {
    color = 0x000000ff;
  }

  renderer.fillStyle = borderColor;
  renderer.fillRect(cursor.x - 2, cursor.y - 2, 5, 5);
  renderer.fillStyle = color;
  renderer.fillRect(cursor.x - 1, cursor.y - 1, 3, 3);
}

void drawBorder(Renderer renderer, num x, num y, int width, int height,
    int color, int borderWidth) {
  renderer.fillStyle = color;

  var x0 = (x - borderWidth).toInt();
  var y0 = (y - borderWidth).toInt();
  var width0 = width + borderWidth * 2;
  var height0 = height + borderWidth * 2;

  renderer.fillRect(x0, y0, width0 - borderWidth, borderWidth);
  renderer.fillRect(
      x0 + width0 - borderWidth, y0, borderWidth, height0 - borderWidth);
  renderer.fillRect(x0 + borderWidth, y0 + height0 - borderWidth,
      width0 - borderWidth, borderWidth);
  renderer.fillRect(x0, y0 + borderWidth, borderWidth, height0 - borderWidth);
}

void drawWindows(Renderer renderer) {
  var borderWidth = 2;
  var numberOfWindows = windows.length;

  if (numberOfWindows == 0) return;

  if (numberOfWindows == 1) {
    var window = windows.first;

    if (window.isVisible) {
      if (!window.isMaximized) {
        drawBorder(
          renderer,
          window.contentX,
          window.contentY,
          window.contentWidth,
          window.contentHeight,
          0xff0000ff,
          borderWidth,
        );
      }
      renderer.drawWindow(window, window.drawingX, window.drawingY);
    }

    return;
  }

  var addend = 0xff ~/ (numberOfWindows - 1);

  var red = 0x00;
  var blue = 0xff;

  var list = windows.backToFrontIterable;
  for (var window in list) {
    if (window.isVisible) {
      if (!window.isMaximized) {
        drawBorder(
          renderer,
          window.contentX,
          window.contentY,
          window.contentWidth,
          window.contentHeight,
          (red << 24) | (blue << 8) | 0x77,
          borderWidth,
        );
      }
      renderer.drawWindow(window, window.drawingX, window.drawingY);
    }
    blue -= addend;
    red += addend;
  }
}

/// Hacky way to (un)maximize a window.
void handleUpdates() {
  var monitor = currentMonitor;
  if (monitor == null) return;

  var monitorWidth = monitor.mode.width;
  var monitorHeight = monitor.mode.height;

  if (isMaximizingFocusedWindow) {
    var window = focusedWindow;
    if (window != null && window.isMaximized) {
      isMaximizingFocusedWindow = false;
      window.drawingX = 0;
      window.drawingY = 0;
      print("Maximized 🪟 window!");
    }
  } else if (isUnmaximizingFocusedWindow) {
    var window = focusedWindow;
    if (window != null && !window.isMaximized) {
      isUnmaximizingFocusedWindow = false;
      var width = monitorWidth * 0.5;
      var height = monitorHeight * 0.5;

      window.drawingX = (monitorWidth - width) / 2;
      window.drawingY = (monitorHeight - height) / 3;
      print("Unmaximized 🪟 window!");
    }
  }
}

void handleCurrentMonitorFrame() {
  var monitor = currentMonitor;
  if (monitor == null) return;

  handleUpdates();

  var renderer = monitor.renderer;

  renderer.fillStyle = 0x6666ffff;
  renderer.fillRect(50, 50, 100, 100);

  drawWindows(renderer);
  drawCursor(renderer);
}

void initializeMonitor(Monitor monitor) {
  var modes = monitor.modes;
  var preferredMode = monitor.preferredMode;

  print("- Name: '${monitor.name}'");
  print("- Number of modes: ${modes.length}");
  if (modes.isNotEmpty) {
    print("- Preferred mode: "
        "${preferredMode == null ? "none" : "$preferredMode"}");
  }

  if (preferredMode != null) monitor.mode = preferredMode;
  monitor.enable();
  monitor.backgroundColor =
      backgroundColors[(monitors.length - 1) % backgroundColors.length];

  monitor.setEventHandler("remove", () {
    monitors.remove(monitor);
    print("A 📺 monitor has been removed!");
    print("- Name: '${monitor.name}'");

    if (monitor == currentMonitor) {
      currentMonitor = monitors.isEmpty ? null : monitors.first;
    }
  });

  if (monitors.length == 1) {
    currentMonitor = monitor;

    cursor.x = monitor.mode.width / 2;
    cursor.y = monitor.mode.height / 2;

    monitor.setEventHandler("frame", handleCurrentMonitorFrame);
  } else {
    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0xffdd66ff;
      renderer.fillRect(50, 50, 100, 100);
    });
  }
}

void handleNewMonitor(Monitor monitor) {
  monitors.add(monitor);

  print("A 📺 monitor has been added!");

  initializeMonitor(monitor);
}

void initializeWindow(Window window) {
  final appId = window.appId;
  final title = window.title;

  window.setEventHandler("show", () {
    print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
        " wants ${title.isEmpty ? "its 🪟 window" : "the 🪟 window '$title'"}"
        " shown!");

    focusWindow(window);
  });
  window.setEventHandler("hide", () {
    print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
        " wants ${title.isEmpty ? "its 🪟 window" : "the 🪟 window '$title'"}"
        " hidden!");

    if (window == focusedWindow) {
      unfocusWindow();

      var nextWindow = windows.getNextWindow(window);
      if (nextWindow != null) focusWindow(nextWindow);
    }
  });
  // The window wants to be moved, which has to be handled manually.
  window.setEventHandler("move", () {
    print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
        " wants ${title.isEmpty ? "its 🪟 window" : "the 🪟 window '$title'"}"
        " moved!");

    if (!window.isMaximized) {
      isMovingFocusedWindow = true;
      cursorPositionAtGrab.x = cursor.x;
      cursorPositionAtGrab.y = cursor.y;
      windowDrawingPositionAtGrab.x = window.drawingX;
      windowDrawingPositionAtGrab.y = window.drawingY;
    }

    focusWindow(window);
  });
  // The window wants to be maximize, which has to be handled manually.
  window.setEventHandler("maximize", () {
    print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
        " wants ${title.isEmpty ? "its 🪟 window" : "the 🪟 window '$title'"}"
        " ${window.isMaximized ? "un" : ""}maximized!");

    if (window.isMaximized) {
      startUnmaximizingWindow(window);
    } else {
      startMaximizingWindow(window);
    }
  });
  window.setEventHandler("remove", () {
    windows.remove(window);

    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        "'s 🪟${window.isPopup ? " popup" : ""} window has been removed!");

    if (window == focusedWindow) unfocusWindow();
  });
}

void handleNewWindow(Window window) {
  windows.addToFront(window);

  final appId = window.appId;
  final title = window.title;

  print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
      "'s 🪟${window.isPopup ? " popup" : ""} window has been added!");

  if (title.isNotEmpty) print("- Title: '$title'");

  initializeWindow(window);
}

void handlePointerMovement(PointerDevice pointer, int elapsedTimeMilliseconds) {
  if (!shouldSubmitPointerMoveEvents) return;

  var window = focusedWindow;
  if (isFocusedWindowFocusedFromPointer && window != null) {
    window.submitPointerMovementEvent(
      PointerMovementEvent(
        pointer,
        cursor.x - window.drawingX,
        cursor.y - window.drawingY,
        elapsedTimeMilliseconds,
      ),
    );
    return;
  }

  Window? currentlyHoveredWindow = getWindowAtPoint(cursor.x, cursor.y);
  if (currentlyHoveredWindow != null) {
    if (currentlyHoveredWindow != hoveredWindow) {
      pointer.focusOnWindow(
        currentlyHoveredWindow,
        cursor.x - currentlyHoveredWindow.drawingX,
        cursor.y - currentlyHoveredWindow.drawingY,
      );
      hoveredWindow = currentlyHoveredWindow;
    }

    currentlyHoveredWindow.submitPointerMovementEvent(
      PointerMovementEvent(
        pointer,
        cursor.x - currentlyHoveredWindow.drawingX,
        cursor.y - currentlyHoveredWindow.drawingY,
        elapsedTimeMilliseconds,
      ),
    );
  } else {
    if (pointer.focusedWindow != null) pointer.clearFocus();

    hoveredWindow = null;
  }
}

void handleWindowGrab() {
  var window = focusedWindow;
  if (window == null) return;

  window.drawingX =
      windowDrawingPositionAtGrab.x + cursor.x - cursorPositionAtGrab.x;
  window.drawingY =
      windowDrawingPositionAtGrab.y + cursor.y - cursorPositionAtGrab.y;
}

void handleNewPointer(PointerDevice pointer) {
  pointer.setEventHandler("move", (PointerMoveEvent event) {
    var monitor = currentMonitor;
    if (monitor == null) return;

    var speed = 0.5; // my preference

    cursor.x = (cursor.x + event.deltaX * speed).clamp(0, monitor.mode.width);
    cursor.y = (cursor.y + event.deltaY * speed).clamp(0, monitor.mode.height);

    if (isMovingFocusedWindow) {
      handleWindowGrab();
    } else {
      handlePointerMovement(pointer, event.elapsedTimeMilliseconds);
    }
  });
  pointer.setEventHandler("teleport", (PointerTeleportEvent event) {
    var monitor = currentMonitor;
    if (monitor == null || event.monitor != monitor) return;

    cursor.x = event.x.clamp(0, monitor.mode.width);
    cursor.y = event.y.clamp(0, monitor.mode.height);

    if (isMovingFocusedWindow) {
      handleWindowGrab();
    } else {
      handlePointerMovement(pointer, event.elapsedTimeMilliseconds);
    }
  });
  pointer.setEventHandler("button", (PointerButtonEvent event) {
    Window? currentlyHoveredWindow = getWindowAtPoint(cursor.x, cursor.y);

    if (currentlyHoveredWindow == null) {
      if (event.isPressed) {
        unfocusWindow();
        print("Removed 🪟 window focus.");
      } else {
        var window = focusedWindow;
        if (window != null) window.submitPointerButtonEvent(event);
      }
    } else {
      if (event.isPressed) {
        if (focusedWindow != currentlyHoveredWindow) {
          focusWindow(currentlyHoveredWindow);

          pointer.focusOnWindow(
            currentlyHoveredWindow,
            cursor.x - currentlyHoveredWindow.drawingX,
            cursor.y - currentlyHoveredWindow.drawingY,
          );
        }

        currentlyHoveredWindow.submitPointerButtonEvent(event);
        isFocusedWindowFocusedFromPointer = true;
      } else {
        var window = focusedWindow;
        if (window != null) {
          if (isMovingFocusedWindow && window.contentY < 0) {
            startMaximizingWindow(window);
          }

          window.submitPointerButtonEvent(event);
        }
      }
    }

    if (!event.isPressed) {
      isMovingFocusedWindow = false;
      isFocusedWindowFocusedFromPointer = false;
    }
  });
  pointer.setEventHandler("axis", (PointerAxisEvent event) {
    Window? currentlyHoveredWindow = getWindowAtPoint(cursor.x, cursor.y);

    if (currentlyHoveredWindow != null) {
      currentlyHoveredWindow.submitPointerAxisEvent(event);
    }
  });
  pointer.setEventHandler("remove", () {
    inputDevices.remove(pointer);
    print("A 🖱️ pointer has been removed!");
    print("- Name: '${pointer.name}'");
  });
}

void handleNewKeyboard(KeyboardDevice keyboard) {
  keyboard.setEventHandler("key", (KeyboardKeyEvent event) {
    if (event.key == InputDeviceButton.altLeft) {
      isLeftAltKeyPressed = event.isPressed;
      if (!isLeftAltKeyPressed) {
        isSwitchingWindows = false;
        readyToQuit = false;
      }
    } else if (event.key == InputDeviceButton.shiftLeft) {
      isLeftShiftKeyPressed = event.isPressed;
    } else if (event.key == InputDeviceButton.escape) {
      if (event.isPressed && readyToQuit) {
        socket?.close();
      } else if (event.isPressed && isLeftAltKeyPressed) {
        readyToQuit = true;
      }
    } else if (event.key == InputDeviceButton.tab) {
      if (event.isPressed) {
        if (isLeftAltKeyPressed) {
          if (!isSwitchingWindows) {
            isSwitchingWindows = true;
            windowSwitchIndex = 0;
            tempWindowList = windows.frontToBackIterable.toList();
          }

          if (focusedWindow != null) {
            var direction = isLeftShiftKeyPressed ? -1 : 1;
            windowSwitchIndex =
                (windowSwitchIndex + direction) % windows.length;
          }

          if (windows.isNotEmpty) {
            var index = 0;
            for (var window in tempWindowList) {
              if (index == windowSwitchIndex) {
                focusWindow(window);
                break;
              }

              index++;
            }
          }
        }
      }
    }

    focusedWindow?.submitKeyboardKeyEvent(event);
  });
  keyboard.setEventHandler("modifiers", (KeyboardModifiersEvent event) {
    var window = focusedWindow;
    if (window == null) return;

    window.submitKeyboardModifiersEvent(event);
  });
  keyboard.setEventHandler("remove", () {
    inputDevices.remove(keyboard);
    print("A ⌨️ keyboard has been removed!");
    print("- Name: '${keyboard.name}'");
  });
}

void handleNewInput(InputNewEvent event) {
  var pointer = event.pointer;
  var keyboard = event.keyboard;

  if (pointer != null) {
    inputDevices.add(pointer);
    print("A 🖱️ pointer has been added!");
    print("- Name: '${pointer.name}'");

    handleNewPointer(pointer);
  } else if (keyboard != null) {
    inputDevices.add(keyboard);
    print("A ⌨️ keyboard has been added!");
    print("- Name: '${keyboard.name}'");

    handleNewKeyboard(keyboard);
  }
}

void main(List<String> arguments) async {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-new", handleNewMonitor);
  waybright.setEventHandler("window-new", handleNewWindow);
  waybright.setEventHandler("input-new", handleNewInput);

  socket = await waybright.openSocket();
  print("~~~ Socket opened on '${socket!.name}' ~~~");
  socket!.runEventLoop();
  print("~~~ Socket closed ~~~");
}
