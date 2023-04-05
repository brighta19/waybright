import 'package:waybright/waybright.dart';

Monitor? currentMonitor;

void drawPic(CanvasRenderingContext ctx, int x, int y) {
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

  ctx.fillStyle = 0x333333; // a dark color
  ctx.fillRect(x, y, 300, 300);

  ctx.fillStyle = 0xff3333; // red
  ctx.fillRect(x + 50, y + 100, 100, 100);

  ctx.fillStyle = 0x33ff33; // green
  ctx.fillRect(x + 100, y + 150, 100, 100);

  ctx.fillStyle = 0x3333ff; // blue
  ctx.fillRect(x + 150, y + 100, 100, 100);

  ctx.fillStyle = 0xffff33; // yellow
  ctx.fillRect(x + 100, y + 50, 100, 50);
  ctx.fillRect(x + 150, y + 100, 50, 50);
}

void render(CanvasRenderingContext ctx) {
  drawPic(ctx, 150, 100);
}

void initializeMonitor(Monitor monitor) {
  monitor.trySettingPreferredMode();
  monitor.enable();

  var canvas = monitor.canvas;
  if (canvas != null) {
    var ctx = canvas.renderingContext;
    bool rendered = false;

    monitor.setEventHandler("frame", () {
      if (!rendered) {
        render(ctx);
        monitor.renderCanvas();
        rendered = true;
      }
    });
  }
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
