import 'package:waybright/waybright.dart';

const backgroundColors = [
  0x88ffcc,
  0xffaaaa,
];

var monitors = <Monitor>[];
var windows = <Window>[];
var inputDevices = <InputDevice>[];

Monitor? currentMonitor;
Window? focusedWindow;
Window? hoveredWindow;

var cursor = {
  "x": 0.0,
  "y": 0.0,
};

void focusWindow(Window window) {
  if (focusedWindow != null) {
    focusedWindow?.blur();
  }

  window.focus();
  focusedWindow = window;
}

void blurWindow(Window window) {
  window.blur();
  focusedWindow = null;
}

Window? getWindowAtPoint(int x, int y) {
  for (var window in windows) {
    var windowX = window.x;
    var windowY = window.y;
    var windowWidth = window.width;
    var windowHeight = window.height;

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
  var cursorX = cursor["x"]?.toInt() ?? 0;
  var cursorY = cursor["y"]?.toInt() ?? 0;

  renderer.fillStyle = 0xffffff;
  renderer.fillRect(cursorX - 2, cursorY - 2, 5, 5);
  renderer.fillStyle = 0x000000;
  renderer.fillRect(cursorX - 1, cursorY - 1, 3, 3);
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

    cursor["x"] = monitor.mode.width / 2;
    cursor["y"] = monitor.mode.height / 2;

    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0x6666ff;
      renderer.fillRect(50, 50, 100, 100);

      for (var window in windows) {
        if (window.isVisible) {
          renderer.drawWindow(window, 0, 0);
        }
      }

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

    if (focusedWindow == window) {
      blurWindow(window);
    }
  });
  window.setEventHandler("remove", () {
    windows.remove(window);
    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        "'s 🪟${window.isPopup ? " popup" : ""} window has been removed!");

    if (window == focusedWindow && windows.isNotEmpty) {
      focusWindow(windows.last);
    }
  });
}

void handleNewWindow(Window window) {
  windows.add(window);

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
  var x = cursor["x"]?.toInt();
  var y = cursor["y"]?.toInt();

  if (x == null || y == null) return;

  Window? currentlyHoveredWindow = getWindowAtPoint(x, y);

  if (currentlyHoveredWindow != null) {
    var time = elapsedTimeMilliseconds;

    if (currentlyHoveredWindow != hoveredWindow) {
      pointer.focusOnWindow(currentlyHoveredWindow, x, y);
      hoveredWindow = currentlyHoveredWindow;
    }

    currentlyHoveredWindow.submitPointerMoveEvent(time, x, y);
  } else {
    pointer.clearFocus();

    hoveredWindow = null;
  }
}

void handleNewPointer(PointerDevice pointer) {
  pointer.setEventHandler("move", (PointerMoveEvent event) {
    var monitor = currentMonitor;
    var cursorX = cursor["x"];
    var cursorY = cursor["y"];

    if (monitor == null || cursorX == null || cursorY == null) return;

    var width = monitor.mode.width;
    var height = monitor.mode.height;
    var speed = 0.5; // my preference

    cursorX = (cursorX + event.deltaX * speed).clamp(0.0, width.toDouble());
    cursorY = (cursorY + event.deltaY * speed).clamp(0.0, height.toDouble());

    cursor["x"] = cursorX;
    cursor["y"] = cursorY;

    handlePointerMovement(pointer, event.elapsedTimeMilliseconds);
  });
  pointer.setEventHandler("teleport", (PointerTeleportEvent event) {
    var monitor = currentMonitor;
    if (monitor == null || event.monitor != monitor) return;

    var width = monitor.mode.width;
    var height = monitor.mode.height;

    cursor["x"] = event.x.clamp(0.0, width.toDouble());
    cursor["y"] = event.y.clamp(0.0, height.toDouble());

    handlePointerMovement(pointer, event.elapsedTimeMilliseconds);
  });
  pointer.setEventHandler("button", (PointerButtonEvent event) {
    var cursorX = cursor["x"];
    var cursorY = cursor["y"];

    if (cursorX == null || cursorY == null) return;

    var x = cursorX.toInt();
    var y = cursorY.toInt();

    Window? currentlyHoveredWindow = getWindowAtPoint(x, y);

    if (currentlyHoveredWindow != null) {
      currentlyHoveredWindow.submitPointerButtonEvent(
        event.elapsedTimeMilliseconds,
        event.button,
        event.isPressed,
      );
    }
  });
  pointer.setEventHandler("remove", () {
    inputDevices.remove(pointer);
    print("A 🖱️ pointer has been removed!");
    print("- Name: '${pointer.name}'");
  });
}

void handleNewKeyboard(KeyboardDevice keyboard) {
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
