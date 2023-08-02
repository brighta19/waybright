part of 'waybright.dart';

class Rect {
  num x;
  num y;
  int width;
  int height;

  Rect(this.x, this.y, this.width, this.height);

  @override
  String toString() => "Rect($x, $y, $width, $height)";
}
