import 'package:waybright/waybright.dart';

const backgroundColors = [
  0x88ffcc,
  0xffaaaa,
];

var monitors = <Monitor>[];

void initializeMonitor(Monitor monitor, int number) {
  var modes = monitor.modes;
  var preferredMode = monitor.preferredMode;
  print("Monitor '${monitor.name} has ${modes.length} modes. Preferred mode: "
      "${preferredMode == null ? "none" : "$preferredMode"}.");

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
}

void main(List<String> arguments) async {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-add", handleNewMonitor);

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}");
  socket.runEventLoop();
}
