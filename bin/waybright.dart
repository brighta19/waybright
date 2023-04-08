import 'package:waybright/waybright.dart';

Monitor? currentMonitor;

void initializeMonitor(Monitor monitor) {
  monitor.trySettingPreferredMode();
  monitor.enable();
  monitor.backgroundColor = 0x88ffcc;

  // monitor.setEventHandler("frame", () {});
}

void handleNewMonitor(Monitor monitor) {
  print("The monitor '${monitor.name}' has been added!");

  var modes = monitor.modes;
  var preferredMode = monitor.preferredMode;
  print("Monitor '${monitor.name} has ${modes.length} modes. Preferred mode: "
      "${preferredMode == null ? "none" : "$preferredMode"}.");

  if (currentMonitor == null) {
    currentMonitor = monitor;
    initializeMonitor(monitor);
  }

  monitor.setEventHandler("remove", () {
    print("A monitor has been removed");

    if (monitor == currentMonitor) {
      currentMonitor = null;
    }
  });
}

void main(List<String> arguments) async {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-add", handleNewMonitor);

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}");
  socket.runEventLoop();
}
