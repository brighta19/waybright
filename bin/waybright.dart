import 'package:waybright/waybright.dart';

const backgroundColors = [
  0x88ffcc,
  0xffaaaa,
];

var monitors = <Monitor>[];
var windows = <Window>[];

void initializeMonitor(Monitor monitor, int number) {
  var modes = monitor.modes;
  var preferredMode = monitor.preferredMode;
  print("- Monitor '${monitor.name} has ${modes.length} modes.");
  if (modes.isNotEmpty) {
    print("- Preferred mode: "
        "${preferredMode == null ? "none" : "$preferredMode"}.");
  }

  monitor.trySettingPreferredMode();
  monitor.enable();
  monitor.backgroundColor = backgroundColors[number % backgroundColors.length];
}

void handleNewMonitor(Monitor monitor) {
  monitors.add(monitor);
  print("The monitor '${monitor.name}' has been added!");

  initializeMonitor(monitor, monitors.length - 1);

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
        renderer.drawWindow(window, 0, 0);
      }
    });
  } else {
    var renderer = monitor.renderer;
    monitor.setEventHandler("frame", () {
      renderer.fillStyle = 0xffdd66;
      renderer.fillRect(50, 50, 100, 100);

      for (var window in windows) {
        renderer.drawWindow(window, 0, 0);
      }
    });
  }
}

void handleNewWindow(Window window) {
  windows.add(window);

  final appId = window.appId;
  final title = window.title;

  print("${window.isPopup ? "A popup" : "A"} window from "
      "${appId.isEmpty ? "an application" : "application `$appId`"}"
      " has been added!");

  if (window.title.isNotEmpty) print("- Title: '$title'");

  window.setEventHandler("show", () {
    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        " wants ${title.isEmpty ? "its window" : "the window '$title'"}"
        " shown!");
  });
  window.setEventHandler("hide", () {
    print("${appId.isEmpty ? "An application" : "Application `$appId`"}"
        " wants ${title.isEmpty ? "its window" : "the window '$title'"}"
        " hidden!");
  });
  window.setEventHandler("remove", () {
    windows.remove(window);
    print("${window.isPopup ? "A popup" : "A"} window from "
        "${appId.isEmpty ? "an application" : "application `$appId`"}"
        " has been removed!");
  });
}

void main(List<String> arguments) async {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-add", handleNewMonitor);
  waybright.setEventHandler("window-add", handleNewWindow);

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}.");
  socket.runEventLoop();
}
