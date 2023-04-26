part of "./waybright.dart";

/// A combination of a resolution and refresh rate.
class Mode {
  /// The resolution width.
  final int width;

  /// The resolution height.
  final int height;

  /// The refresh rate.
  final int refreshRate;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  /// Creates a [Mode] instance.
  Mode(this.width, this.height, this.refreshRate);

  @override
  String toString() => "(${width}x$height @ ${refreshRate}mHz)";
}
