import 'package:waybright/waybright.dart';

Monitor? currentMonitor;

var colors = [
  0xff3333,
  0x33ff33,
  0x3333ff,
  0xffff33,
];

var a = 0;
var b = 0;

void drawPic(CanvasRenderingContext ctx, int x, int y) {
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);

  ctx.fillStyle = 0x333333; // a dark color
  ctx.fillRect(x, y, 300, 300);

  ctx.fillStyle = colors[(a) % 4];
  ctx.fillRect(x + 50, y + 100, 100, 100);

  ctx.fillStyle = colors[(a + 1) % 4];
  ctx.fillRect(x + 100, y + 150, 100, 100);

  ctx.fillStyle = colors[(a + 2) % 4];
  ctx.fillRect(x + 150, y + 100, 100, 100);

  ctx.fillStyle = colors[(a + 3) % 4];
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

    monitor.setEventHandler("frame", () {
      b++;
      if (b == 120) {
        a = (a + 1) % 4;
        b = 0;
      }
      render(ctx);
      monitor.renderCanvas();
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
