import 'package:waybright/waybright.dart';

const backgroundColors = [
  0x88ffcc,
  0xffaaaa,
];

var monitors = <Monitor>[];
var windows = <Window>[];
var pointers = <PointerDevice>[];
var keyboards = <KeyboardDevice>[];

Window? focusedWindow;

var cursor = {
  "x": 50.0,
  "y": 50.0,
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

void initializeMonitor(Monitor monitor) {
  var modes = monitor.modes;
  var preferredMode = monitor.preferredMode;

  print("- Monitor '${monitor.name} has ${modes.length} modes.");
  if (modes.isNotEmpty) {
    print("- Preferred mode: "
        "${preferredMode == null ? "none" : "$preferredMode"}.");
  }

  monitor.trySettingPreferredMode();
  monitor.enable();
  monitor.backgroundColor =
      backgroundColors[(monitors.length - 1) % backgroundColors.length];

  monitor.setEventHandler("remove", () {
    monitors.remove(monitor);
    print("The monitor `${monitor.name}` has been removed!");
  });

  if (monitors.length == 1) {
    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0x6666ff;
      renderer.fillRect(50, 50, 100, 100);

      for (var window in windows) {
        if (window.isVisible) {
          renderer.drawWindow(window, 0, 0);
        }
      }

      renderer.fillStyle = 0x000000;
      var cursorX = cursor["x"]?.toInt() ?? 0;
      var cursorY = cursor["y"]?.toInt() ?? 0;
      renderer.fillRect(cursorX, cursorY, 10, 10);
    });
  } else {
    var renderer = monitor.renderer;

    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0xffdd66;
      renderer.fillRect(50, 50, 100, 100);

      for (var window in windows) {
        if (window.isVisible) {
          renderer.drawWindow(window, 0, 0);
        }
      }
    });
  }
}

void handleNewMonitor(Monitor monitor) {
  monitors.add(monitor);

  print("The monitor '${monitor.name}' has been added!");

  initializeMonitor(monitor);
}

void initializeWindow(Window window) {
  final appId = window.appId;
  final title = window.title;

  window.setEventHandler("show", () {
    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        " wants ${title.isEmpty ? "its window" : "the window '$title'"}"
        " shown!");

    focusWindow(window);
  });
  window.setEventHandler("hide", () {
    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        " wants ${title.isEmpty ? "its window" : "the window '$title'"}"
        " hidden!");

    if (focusedWindow == window) {
      blurWindow(window);
    }
  });
  window.setEventHandler("remove", () {
    windows.remove(window);
    print("${window.isPopup ? "A popup" : "A"} window from "
        "${appId.isEmpty ? "an application" : "application `$appId`"}"
        " has been removed!");

    if (window == focusedWindow && windows.isNotEmpty) {
      focusWindow(windows.last);
    }
  });
}

void handleNewWindow(Window window) {
  windows.add(window);

  final appId = window.appId;
  final title = window.title;

  print("${window.isPopup ? "A popup" : "A"} window from "
      "${appId.isEmpty ? "an application" : "application `$appId`"}"
      " has been added!");

  if (title.isNotEmpty) {
    print("- Title: '$title'");
  }

  initializeWindow(window);
}

void handleNewPointer(PointerDevice pointer) {
  pointer.setEventHandler("move", (PointerMoveEvent event) {
    var x = cursor["x"];
    var y = cursor["y"];

    if (x == null || y == null) return;

    cursor["x"] = (x + event.deltaX).clamp(0, 500);
    cursor["y"] = (y + event.deltaY).clamp(0, 400);
  });
  pointer.setEventHandler("remove", () {
    pointers.remove(pointer);
    print("A pointer has been removed!");
  });
}

void handleNewKeyboard(KeyboardDevice keyboard) {
  keyboard.setEventHandler("remove", () {
    keyboards.remove(keyboard);
    print("A keyboard has been removed!");
  });
}

void handleNewInput(InputDevice inputDevice) {
  var pointer = inputDevice.pointer;
  var keyboard = inputDevice.keyboard;

  if (pointer != null) {
    pointers.add(pointer);
    print("The pointer '${pointer.name}' has been added!");

    handleNewPointer(pointer);
  } else if (keyboard != null) {
    keyboards.add(keyboard);
    print("The keyboard '${keyboard.name}' has been added!");

    handleNewKeyboard(keyboard);
  }
}

void main(List<String> arguments) async {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-new", handleNewMonitor);
  waybright.setEventHandler("window-new", handleNewWindow);
  waybright.setEventHandler("input-new", handleNewInput);

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}.");
  socket.runEventLoop();
}
