part of "./waybright.dart";

/// A combination of a resolution and refresh rate.
class Mode {
  /// The resolution width.
  final int width;

  /// The resolution height.
  final int height;

  /// The refresh rate in millihertz. May be zero.
  final int refreshRate;

  Pointer<struct_wlr_output_mode>? _outputModePtr;

  /// Creates a [Mode] instance.
  Mode(this.width, this.height, this.refreshRate);

  Mode._fromPointer(Pointer<struct_wlr_output_mode> this._outputModePtr)
      : width = _outputModePtr.ref.width,
        height = _outputModePtr.ref.height,
        refreshRate = _outputModePtr.ref.refresh;

  @override
  String toString() => "(${width}x$height @ ${refreshRate}mHz)";
}
