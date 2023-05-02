import 'package:waybright/waybright.dart';

const backgroundColor = 0x111111ff;

Socket? socket;
Monitor? currentMonitor;
Window? focusedWindow;
KeyboardDevice? currentKeyboard;

var windows = WindowList();
var tempWindows = <Window>[];
var cursorX = 10.0;
var cursorY = 10.0;

var cursorXAtGrab = 0.0;
var cursorYAtGrab = 0.0;
var isGrabbingWindow = false;

var isLeftAltPressed = false;
var isRightAltPressed = false;
get isAltPressed => isLeftAltPressed || isRightAltPressed;

var isSwitchingWindows = false;
var windowSwitchIndex = 0;

void main(List<String> args) {
  var waybright = Waybright();

  waybright.setEventHandler("monitor-new", (Monitor monitor) {
    var preferredMode = monitor.preferredMode;
    if (preferredMode == null) {
      socket?.close();
      return;
    }

    monitor.mode = preferredMode;
    monitor.enable();

    var renderer = monitor.renderer;
    renderer.backgroundColor = backgroundColor;

    monitor.setEventHandler("frame", () {
      var list = windows.backToFrontIterable;
      for (var window in list) {
        if (window.isVisible) {
          renderer.drawWindow(window, window.drawingX, window.drawingY);
        }
      }

      renderer.fillStyle = 0xffffffdd;
      renderer.fillRect(cursorX, cursorY, 5, 5);
    });

    cursorX = monitor.mode.width / 2;
    cursorY = monitor.mode.height / 2;
  });

  waybright.setEventHandler("window-new", (Window window) {
    windows.addToFront(window);

    window.setEventHandler("remove", () {
      windows.remove(window);
      if (window == focusedWindow) {
        focusedWindow = null;
      }
    });

    window.setEventHandler("show", () {
      window.drawingX = -window.offsetX;
      window.drawingY = -window.offsetY;

      focusedWindow?.unfocus();
      window.focus();
      focusedWindow = window;
      windows.moveToFront(window);
    });

    window.setEventHandler("hide", () {
      window.unfocus();
    });

    window.setEventHandler("move", () {
      cursorXAtGrab = cursorX;
      cursorYAtGrab = cursorY;
      isGrabbingWindow = true;
    });
  });

  waybright.setEventHandler("input-new", (InputNewEvent event) {
    if (event.pointer != null) {
      var pointer = event.pointer!;

      Window? getHoveredWindow() {
        var list = windows.frontToBackIterable;
        for (var window in list) {
          if (!window.isVisible) continue;

          var windowX = window.contentX;
          var windowY = window.contentY;
          var windowWidth = window.contentWidth;
          var windowHeight = window.contentHeight;

          if (cursorX >= windowX &&
              cursorX < windowX + windowWidth &&
              cursorY >= windowY &&
              cursorY < windowY + windowHeight) {
            return window;
          }
        }
        return null;
      }

      void handleMovement(PointerMoveEvent event) {
        Window? hoveredWindow = getHoveredWindow();

        if (hoveredWindow == null) return;

        var windowCursorX = cursorX - hoveredWindow.drawingX;
        var windowCursorY = cursorY - hoveredWindow.drawingY;

        hoveredWindow.submitPointerMoveUpdate(PointerUpdate(
          pointer,
          event,
          windowCursorX,
          windowCursorY,
        ));
      }

      pointer.setEventHandler("move", (PointerRelativeMoveEvent event) {
        cursorX += event.deltaX;
        cursorY += event.deltaY;

        if (!isGrabbingWindow) handleMovement(event);
      });

      pointer.setEventHandler("teleport", (PointerAbsoluteMoveEvent event) {
        cursorX = event.x;
        cursorY = event.y;

        if (!isGrabbingWindow) handleMovement(event);
      });

      pointer.setEventHandler("button", (PointerButtonEvent event) {
        if (!event.isPressed && isGrabbingWindow) {
          focusedWindow!.drawingX += cursorX - cursorXAtGrab;
          focusedWindow!.drawingY += cursorY - cursorYAtGrab;
          isGrabbingWindow = false;
        }

        var hoveredWindow = getHoveredWindow();
        if (hoveredWindow == null) return;

        if (hoveredWindow != focusedWindow) {
          focusedWindow?.unfocus();
          hoveredWindow.focus();
          focusedWindow = hoveredWindow;
          windows.moveToFront(hoveredWindow);
        }

        var windowCursorX = cursorX - hoveredWindow.drawingX;
        var windowCursorY = cursorY - hoveredWindow.drawingY;

        hoveredWindow.submitPointerButtonUpdate(PointerUpdate(
          pointer,
          event,
          windowCursorX,
          windowCursorY,
        ));
      });

      pointer.setEventHandler("axis", (PointerAxisEvent event) {
        var hoveredWindow = getHoveredWindow();
        if (hoveredWindow == null) return;

        var windowCursorX = cursorX - hoveredWindow.drawingX;
        var windowCursorY = cursorY - hoveredWindow.drawingY;

        hoveredWindow.submitPointerAxisUpdate(PointerUpdate(
          pointer,
          event,
          windowCursorX,
          windowCursorY,
        ));
      });
    }

    if (event.keyboard != null) {
      var keyboard = event.keyboard!;

      keyboard.setEventHandler("modifiers", (KeyboardModifiersEvent event) {
        currentKeyboard = event.keyboard;

        focusedWindow?.submitKeyboardModifiersUpdate(KeyboardUpdate(
          keyboard,
          event,
        ));
      });

      keyboard.setEventHandler("key", (KeyboardKeyEvent event) {
        currentKeyboard = event.keyboard;

        if (event.key == InputDeviceButton.altLeft) {
          isLeftAltPressed = event.isPressed;
        } else if (event.key == InputDeviceButton.altRight) {
          isRightAltPressed = event.isPressed;
        } else if (event.key == InputDeviceButton.escape && event.isPressed) {
          if (isAltPressed) {
            socket!.close();
          }
        } else if (event.key == InputDeviceButton.f1 && event.isPressed) {
          if (isAltPressed) {
            if (!isSwitchingWindows) {
              isSwitchingWindows = true;
              windowSwitchIndex = 0;
              tempWindows = windows.frontToBackIterable.toList();
            }

            windowSwitchIndex = (windowSwitchIndex + 1) % tempWindows.length;

            var i = 0;
            for (var window in tempWindows) {
              if (i == windowSwitchIndex) {
                focusedWindow?.unfocus();
                window.focus();
                focusedWindow = window;
                windows.moveToFront(window);
                break;
              }
              i++;
            }
          }
        }

        if (!isAltPressed && isSwitchingWindows) {
          isSwitchingWindows = false;
          tempWindows = [];
        }

        if (!isSwitchingWindows) {
          focusedWindow?.submitKeyboardKeyUpdate(KeyboardUpdate(
            keyboard,
            event,
          ));
        }
      });
    }
  });

  waybright.openSocket().then((Socket socket0) {
    socket = socket0;

    print("Socket running on WAYLAND_DISPLAY=${socket0.name}");
    socket0.runEventLoop();
  });
}
