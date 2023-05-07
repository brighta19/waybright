part of '../../waybright.dart';

class ResizeWindowEvent extends WindowEvent {
  WindowEdge edge;

  ResizeWindowEvent(window, this.edge) : super(window);
}
