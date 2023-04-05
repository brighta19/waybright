import 'package:waybright/waybright.dart';

void main(List<String> arguments) async {
  var waybright = Waybright();

  // // protocol setup
  // var protocol = XDGShellProtocol();

  // protocol.on("window-add", (window) {
  //   print("A ${window.type} window has been added");
  // });

  // protocol.on("window-remove", (window) {
  //   print("A ${window.type} window has been removed");
  // });

  // waybright.useProtocol(protocol);

  Monitor? currentMonitor;

  waybright.setEventHandler("monitor-add", (Monitor monitor) {
    print("The monitor '${monitor.name}' has been added!");
    var modes = monitor.modes;
    var preferredMode = monitor.preferredMode;
    print("Monitor '${monitor.name} has ${modes.length} modes. Preferred mode: "
        "${preferredMode == null ? "none" : "$preferredMode"}.");

    if (currentMonitor == null) {
      currentMonitor ??= monitor;
      monitor.trySettingPreferredMode();
      monitor.enable();

      var canvas = monitor.canvas;
      if (canvas != null) {
        var ctx = canvas.renderingContext;
        bool rendered = false;
        monitor.setEventHandler("frame", () {
          if (!rendered) {
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            ctx.fillStyle = 0xff3333;
            ctx.fillRect(200, 200, 100, 100);

            ctx.fillStyle = 0x33ff33;
            ctx.fillRect(300, 150, 100, 100);

            ctx.fillStyle = 0x3333ff;
            ctx.fillRect(250, 250, 100, 100);

            monitor.renderCanvas();
            rendered = true;
          }
        });
      }
    }

    monitor.setEventHandler("remove", () {
      print("A monitor has been removed");

      if (monitor == currentMonitor) {
        currentMonitor = null;
      }
    });
  });

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}");
  socket.runEventLoop();
}
