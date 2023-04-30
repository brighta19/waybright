part of '../../waybright.dart';

class WindowResizeEvent extends WindowEvent {
  WindowEdge edge;

  WindowResizeEvent(window, this.edge) : super(window);
}
