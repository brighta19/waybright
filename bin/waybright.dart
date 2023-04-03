import 'package:waybright/waybright.dart';

void main(List<String> arguments) {
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

  waybright.setHandler("monitor-add", () {
    print("A monitor has been added");

    //   if (currentDisplay == null) {
    //     currentDisplay = display;

    //     var modes = display.getAvailableModes();
    //     display.setMode(modes[0]);

    //     var ctx = display.getRenderingContext();

    //     display.on("frame-request", () {
    //       ctx.clearRect(0, 0, display.width, display.height);
    //     });
    //   }
  });

  // waybright.setHandler("monitor-remove", () {
  // print("A monitor has been removed");

  //   var displays = waybright.getAvailableDisplays();
  //   if (displays.isEmpty) {
  //     currentDisplay = null;
  //   }
  // });

  // server setup
  waybright.listen().then((socket) {
    print("Socket opened on ${socket.name}");
    socket.run();
  }).onError((error, stackTrace) {
    print("Failed to run server");
  });
}
