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

  // // display setup
  // Display? currentDisplay;

  waybright.setEventHandler("monitor-add", (monitor) {
    print("The monitor '${monitor.name}' has been added!");
    var modes = monitor.modes;
    var preferredMode = monitor.preferredMode;
    print("Monitor '${monitor.name} has ${modes.length} modes. Preferred mode: "
        "${preferredMode == null ? "none" : "$preferredMode"}.");

    //   if (currentDisplay == null) {
    //     currentDisplay = display;

    monitor.trySettingPreferredMode();
    monitor.enable();

    monitor.setEventHandler("remove", () {
      print("A monitor has been removed");

      //   var displays = waybright.getAvailableDisplays();
      //   if (displays.isEmpty) {
      //     currentDisplay = null;
      //   }
    });

    //     var ctx = display.getRenderingContext();

    monitor.setEventHandler("frame", () {
      print("frame");
      //       ctx.clearRect(0, 0, display.width, display.height);
    });
  });

  var socket = await waybright.openSocket();
  print("Socket opened on ${socket.name}");
  socket.runEventLoop();
}
