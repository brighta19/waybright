import 'dart:collection';

import 'package:waybright/waybright.dart';

class MyWindow {
  final Window w;
  MyWindow? parent;

  num textureX = 0;
  num textureY = 0;

  num get x => textureX + w.offsetX;
  num get y => textureY + w.offsetY;
  set x(num x) => textureX = x - w.offsetX;
  set y(num y) => textureY = y - w.offsetY;

  int get width => w.width;
  int get height => w.height;
  num get textureWidth => w.textureWidth;
  num get textureHeight => w.textureHeight;

  MyWindow(this.w);
}

const backgroundColor = 0x111111ff;

Monitor? currentMonitor;
MyWindow? focusedWindow;
KeyboardDevice? currentKeyboard;
Image? cursorImage;

var windows = Queue<MyWindow>();
var popupWindows = <MyWindow, Queue<MyWindow>>{};
var tempWindows = <MyWindow>[];
var cursorX = 10.0;
var cursorY = 10.0;
var cursorImageHotspotX = 0;
var cursorImageHotspotY = 0;

var cursorXAtGrab = 0.0;
var cursorYAtGrab = 0.0;
var isMovingWindow = false;
var isResizingWindow = false;
bool get isGrabbingWindow => isMovingWindow || isResizingWindow;

var isLeftAltPressed = false;
var isRightAltPressed = false;
bool get isAltPressed => isLeftAltPressed || isRightAltPressed;

var isSwitchingWindows = false;
var windowSwitchIndex = 0;

MyWindow? getHoveredWindowFromList(Queue<MyWindow> windows) {
  for (var window in windows) {
    if (!window.w.hasTexture) continue;

    var popupList = popupWindows[window];
    if (popupList != null) {
      var popup = getHoveredWindowFromList(popupList);
      if (popup != null) return popup;
    }

    var windowX = window.x;
    var windowY = window.y;
    var windowWidth = window.width;
    var windowHeight = window.height;

    if (cursorX >= windowX &&
        cursorX < windowX + windowWidth &&
        cursorY >= windowY &&
        cursorY < windowY + windowHeight) {
      return window;
    }
  }
  return null;
}

MyWindow? getHoveredWindow() {
  return getHoveredWindowFromList(windows);
}

void onNewMonitor(MonitorAddEvent event) {
  var monitor = event.monitor;
  if (currentMonitor != null) return;
  currentMonitor = monitor;

  initializeCurrentMonitor();
}

void initializeCurrentMonitor() {
  var monitor = currentMonitor;
  if (monitor == null) return;

  var preferredMode = monitor.preferredMode;
  if (preferredMode != null) {
    monitor.mode = preferredMode;
  }

  monitor.enable();

  var renderer = monitor.renderer;
  renderer.clearColor = backgroundColor;

  monitor.onRemoving = (event) {
    currentMonitor = null;
  };

  monitor.onFrame = (event) {
    renderer.begin();

    renderer.clear();

    var list = windows.toList().reversed;
    for (var window in list) {
      if (window.w.hasTexture) {
        renderer.drawWindow(window.w, window.textureX, window.textureY);

        var popupList = popupWindows[window];
        if (popupList != null) {
          for (var popup in popupList.toList().reversed) {
            if (popup.w.hasTexture) {
              renderer.drawWindow(popup.w, popup.textureX, popup.textureY);
            }
          }
        }
      }
    }

    if (cursorImage == null && getHoveredWindow() == null) {
      renderer.fillColor = 0xffffffdd;
      renderer.fillRect(cursorX, cursorY, 5, 5);
    } else if (cursorImage != null && cursorImage!.isLoaded) {
      renderer.drawImage(
        cursorImage!,
        cursorX - cursorImageHotspotX,
        cursorY - cursorImageHotspotY,
      );
    }

    renderer.end();

    renderer.render();
  };

  cursorX = monitor.resolutionWidth / 2;
  cursorY = monitor.resolutionHeight / 2;
}

void onNewPopupWindow(MyWindow window) {
  var parent = window.parent;
  if (parent == null) return;

  var popupList = popupWindows[parent];
  if (popupList == null) {
    popupList = Queue<MyWindow>();
    popupWindows[parent] = popupList;
  }

  popupList.addFirst(window);

  window.w.onDestroying = (event) {
    popupList?.remove(window);
  };

  window.w.onTextureSet = (event) {
    window.x = window.w.popupX + parent.x;
    window.y = window.w.popupY + parent.y;
  };
}

void onWindowCreate(WindowCreateEvent event) {
  var window = MyWindow(event.window);
  windows.addFirst(window);

  window.w.onDestroying = (event) {
    windows.remove(window);
    popupWindows.remove(window);
    if (window == focusedWindow) focusedWindow = null;
  };

  window.w.onTextureSet = (event) {
    window.x = 0;
    window.y = 0;

    focusedWindow?.w.deactivate();
    window.w.activate();
    focusedWindow = window;
    windows.remove(window);
    windows.addFirst(window);
  };

  window.w.onTextureUnsetting = (event) {
    window.w.deactivate();
  };

  window.w.onMoveRequest = (event) {
    cursorXAtGrab = cursorX;
    cursorYAtGrab = cursorY;
    isMovingWindow = true;
  };

  window.w.onResizeRequest = (event) {
    cursorXAtGrab = cursorX;
    cursorYAtGrab = cursorY;
    isResizingWindow = true;
  };

  window.w.onPopupCreate = (event) {
    var popup = MyWindow(event.window)..parent = window;
    onNewPopupWindow(popup);
  };
}

void onNewPointer(PointerDevice pointer) {
  void handleMovement(PointerMoveEvent event) {
    MyWindow? hoveredWindow = getHoveredWindow();

    if (hoveredWindow == null) {
      cursorImage = null;
      return;
    }

    var windowCursorX = cursorX - hoveredWindow.textureX;
    var windowCursorY = cursorY - hoveredWindow.textureY;

    hoveredWindow.w.submitPointerMoveUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  }

  pointer.onMove = (event) {
    cursorX += event.deltaX;
    cursorY += event.deltaY;

    if (!isGrabbingWindow) handleMovement(event);
  };

  pointer.onTeleport = (event) {
    cursorX = event.x;
    cursorY = event.y;

    if (!isGrabbingWindow) handleMovement(event);
  };

  pointer.onButton = (event) {
    if (!event.isPressed) {
      if (isMovingWindow) {
        focusedWindow!.textureX += cursorX - cursorXAtGrab;
        focusedWindow!.textureY += cursorY - cursorYAtGrab;
      } else if (isResizingWindow) {
        // resize
      }
      isMovingWindow = false;
      isResizingWindow = false;
    }

    var hoveredWindow = getHoveredWindow();
    if (hoveredWindow == null) return;

    if (!hoveredWindow.w.isPopup && hoveredWindow != focusedWindow) {
      focusedWindow?.w.deactivate();
      hoveredWindow.w.activate();
      focusedWindow = hoveredWindow;
      windows.remove(hoveredWindow);
      windows.addFirst(hoveredWindow);
    }

    var windowCursorX = cursorX - hoveredWindow.textureX;
    var windowCursorY = cursorY - hoveredWindow.textureY;

    hoveredWindow.w.submitPointerButtonUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  };

  pointer.onAxis = (event) {
    var hoveredWindow = getHoveredWindow();
    if (hoveredWindow == null) return;

    var windowCursorX = cursorX - hoveredWindow.textureX;
    var windowCursorY = cursorY - hoveredWindow.textureY;

    hoveredWindow.w.submitPointerAxisUpdate(PointerUpdate(
      pointer,
      event,
      windowCursorX,
      windowCursorY,
    ));
  };
}

void onNewKeyboard(KeyboardDevice keyboard) {
  keyboard.onModifiers = (event) {
    currentKeyboard = event.keyboard;

    focusedWindow?.w.submitKeyboardModifiersUpdate(KeyboardUpdate(
      keyboard,
      event,
    ));
  };

  keyboard.onKey = (event) {
    currentKeyboard = event.keyboard;

    if (event.key == InputDeviceButton.altLeft) {
      isLeftAltPressed = event.isPressed;
    } else if (event.key == InputDeviceButton.altRight) {
      isRightAltPressed = event.isPressed;
    } else if (event.key == InputDeviceButton.escape && event.isPressed) {
      if (isAltPressed) {
        compositor.closeSocket();
      }
    } else if (event.key == InputDeviceButton.f1 && event.isPressed) {
      if (isAltPressed) {
        if (!isSwitchingWindows) {
          isSwitchingWindows = true;
          windowSwitchIndex = 0;
          tempWindows = windows.toList();
        }

        windowSwitchIndex = (windowSwitchIndex + 1) % tempWindows.length;

        var i = 0;
        for (var window in tempWindows) {
          if (i == windowSwitchIndex) {
            focusedWindow?.w.deactivate();
            window.w.activate();
            focusedWindow = window;
            windows.remove(window);
            windows.addFirst(window);
            break;
          }
          i++;
        }
      }
    }

    if (!isAltPressed && isSwitchingWindows) {
      isSwitchingWindows = false;
    }

    if (!isSwitchingWindows) {
      focusedWindow?.w.submitKeyboardKeyUpdate(KeyboardUpdate(
        keyboard,
        event,
      ));
    }
  };
}

void onNewInput(NewInputEvent event) {
  if (event.pointer != null) {
    onNewPointer(event.pointer!);
  } else if (event.keyboard != null) {
    onNewKeyboard(event.keyboard!);
  }
}

void onCursorImage(CursorImageEvent event) {
  cursorImage = event.image;
  cursorImageHotspotX = event.hotspotX;
  cursorImageHotspotY = event.hotspotY;
}

final compositor = Waybright();

void main(List<String> args) {
  compositor.onMonitorAdd = onNewMonitor;
  compositor.onWindowCreate = onWindowCreate;
  compositor.onNewInput = onNewInput;
  compositor.onCursorImage = onCursorImage;

  try {
    var socketName = compositor.openSocket();
    print("Running on WAYLAND_DISPLAY=$socketName");
  } catch (e) {
    print(e);
  }
}
