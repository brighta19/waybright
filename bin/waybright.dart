import 'package:waybright/waybright.dart';

class Vector {
  num x;
  num y;
  Vector(this.x, this.y);
}

const backgroundColors = [
  0x88ffcc,
  0xffaaaa,
];

var monitors = <Monitor>[];
var windows = WindowList();
var inputDevices = <InputDevice>[];

Monitor? currentMonitor;

Window? focusedWindow;
Window? hoveredWindow;
Window? pointerButtonFocusedWindow;

var isMovingWindow = false;
var shouldSubmitPointerMoveEvents = true;

var cursor = Vector(0.0, 0.0);
var windowDrawingPositionAtGrab = Vector(0.0, 0.0);
var cursorPositionAtGrab = Vector(0.0, 0.0);

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
    focusedWindow?.blur();
    forEachKeyboard((keyboard) {
      if (keyboard.focusedWindow == window) keyboard.clearFocus();
    });
  }

  window.focus();
  forEachKeyboard((keyboard) => keyboard.focusOnWindow(window));
  windows.moveToFront(window);
  focusedWindow = window;
}

void blurFocusedWindow() {
  var window = focusedWindow;
  if (window == null) return;

  window.blur();
  forEachKeyboard((keyboard) {
    if (keyboard.focusedWindow == window) keyboard.clearFocus();
  });
  focusedWindow = null;
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
  renderer.fillStyle = 0xffffff;
  renderer.fillRect(cursor.x - 2, cursor.y - 2, 5, 5);
  renderer.fillStyle = 0x000000;
  renderer.fillRect(cursor.x - 1, cursor.y - 1, 3, 3);
}

void drawWindows(Renderer renderer) {
  var list = windows.backToFrontIterable;
  for (var window in list) {
    if (window.isVisible) {
      renderer.drawWindow(window, window.drawingX, window.drawingY);
    }
  }
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
      if (monitors.isEmpty) {
        currentMonitor = null;
      } else {
        currentMonitor = monitors.first;
      }
    }
  });

  if (monitors.length == 1) {
    currentMonitor = monitor;

    cursor.x = monitor.mode.width / 2;
    cursor.y = monitor.mode.height / 2;

    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0x6666ff;
      renderer.fillRect(50, 50, 100, 100);

      drawWindows(renderer);
      drawCursor(renderer);
    });
  } else {
    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0xffdd66;
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
      blurFocusedWindow();

      var nextWindow = windows.getNextWindow(window);
      if (nextWindow != null) {
        focusWindow(nextWindow);
      }
    }
  });
  // The window wants to be moved, which has to be handled manually.
  window.setEventHandler("move", () {
    print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
        " wants ${title.isEmpty ? "its 🪟 window" : "the 🪟 window '$title'"}"
        " moved!");

    isMovingWindow = true;
    cursorPositionAtGrab.x = cursor.x;
    cursorPositionAtGrab.y = cursor.y;
    windowDrawingPositionAtGrab.x = window.drawingX;
    windowDrawingPositionAtGrab.y = window.drawingY;

    focusWindow(window);
  });
  window.setEventHandler("remove", () {
    windows.remove(window);

    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        "'s 🪟${window.isPopup ? " popup" : ""} window has been removed!");

    if (window == focusedWindow) {
      blurFocusedWindow();
    }
  });
}

void handleNewWindow(Window window) {
  windows.addToFront(window);

  final appId = window.appId;
  final title = window.title;

  print("${appId.isEmpty ? "An application" : "Application '$appId'"}"
      "'s 🪟${window.isPopup ? " popup" : ""} window has been added!");

  if (title.isNotEmpty) {
    print("- Title: '$title'");
  }

  initializeWindow(window);
}

void handlePointerMovement(PointerDevice pointer, int elapsedTimeMilliseconds) {
  if (!shouldSubmitPointerMoveEvents) return;

  var buttonFocusedWindow = pointerButtonFocusedWindow;
  if (buttonFocusedWindow != null) {
    buttonFocusedWindow.submitPointerMovementEvent(
      PointerMovementEvent(
        pointer,
        cursor.x - buttonFocusedWindow.drawingX,
        cursor.y - buttonFocusedWindow.drawingY,
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
    if (pointer.focusedWindow == currentlyHoveredWindow) {
      pointer.clearFocus();
    }

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

    if (isMovingWindow) {
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

    if (isMovingWindow) {
      handleWindowGrab();
    } else {
      handlePointerMovement(pointer, event.elapsedTimeMilliseconds);
    }
  });
  pointer.setEventHandler("button", (PointerButtonEvent event) {
    Window? currentlyHoveredWindow = getWindowAtPoint(cursor.x, cursor.y);

    if (currentlyHoveredWindow == null) {
      if (event.isPressed) {
        blurFocusedWindow();
        shouldSubmitPointerMoveEvents = false;
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

        pointerButtonFocusedWindow = currentlyHoveredWindow;
      } else {
        var window = focusedWindow;
        if (window != null) {
          window.submitPointerButtonEvent(event);
        }
      }
    }

    if (!event.isPressed) {
      isMovingWindow = false;
      shouldSubmitPointerMoveEvents = true;
      pointerButtonFocusedWindow = null;
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
    var window = focusedWindow;
    if (window == null) return;

    window.submitKeyboardKeyEvent(event);
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

  var socket = await waybright.openSocket();
  print("~~~ Socket opened on '${socket.name}' ~~~");
  socket.runEventLoop();
}
