import 'dart:math';

class EasingFunctions {
  static double constant(double t) => 1.0;
  static double linear(double t) => t;

  static double easeInSine(double t) => 1.0 - cos((t * pi) / 2);
  static double easeOutSine(double t) => sin((t * pi) / 2);
  static double easeInOutSine(double t) => -(cos(pi * t) - 1) / 2;

  static double easeInQuad(double t) => t * t;
  static double easeOutQuad(double t) => 1.0 - (1.0 - t) * (1.0 - t);
  static double easeInOutQuad(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2;

  static double easeInCubic(double t) => t * t * t;
  static double easeOutCubic(double t) => 1.0 - pow(1 - t, 3);
  static double easeInOutCubic(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;

  static double easeInQuart(double t) => t * t * t * t;
  static double easeOutQuart(double t) => 1.0 - pow(1 - t, 4);
  static double easeInOutQuart(double t) =>
      t < 0.5 ? 8 * t * t * t * t : 1 - pow(-2 * t + 2, 4) / 2;

  static double easeInQuint(double t) => t * t * t * t * t;
  static double easeOutQuint(double t) => 1.0 - pow(1 - t, 5);
  static double easeInOutQuint(double t) =>
      t < 0.5 ? 16 * t * t * t * t * t : 1 - pow(-2 * t + 2, 5) / 2;

  static double easeInExpo(double t) =>
      t == 0 ? 0 : pow(2, 10 * t - 10).toDouble();
  static double easeOutExpo(double t) =>
      t == 1 ? 1 : 1 - pow(2, -10 * t).toDouble();
  static double easeInOutExpo(double t) {
    if (t == 0) return 0;
    if (t == 1) return 1;
    if (t < 0.5) return pow(2, 20 * t - 10) / 2;
    return (2 - pow(2, -20 * t + 10)) / 2;
  }

  static double easeInCirc(double t) => 1.0 - sqrt(1 - t * t);
  static double easeOutCirc(double t) => sqrt(1 - pow(t - 1, 2));
  static double easeInOutCirc(double t) => t < 0.5
      ? (1 - sqrt(1 - pow(2 * t, 2))) / 2
      : (sqrt(1 - pow(-2 * t + 2, 2)) + 1) / 2;

  static double easeInBack(double t) {
    var s = 1.70158;
    var u = s + 1;
    return u * t * t * t - s * t * t;
  }

  static double easeOutBack(double t) {
    var s = 1.70158;
    var u = s + 1;
    return 1 + u * pow(t - 1, 3) + s * pow(t - 1, 2);
  }

  static double easeInOutBack(double t) {
    var s = 1.70158;
    var u = s * 1.525;
    return t < 0.5
        ? (pow(2 * t, 2) * ((u + 1) * 2 * t - u)) / 2
        : (pow(2 * t - 2, 2) * ((u + 1) * (t * 2 - 2) + u) + 2) / 2;
  }

  static double easeInElastic(double t) {
    var p = 0.3;
    return pow(2, -10 * t) * sin((t - p / 4) * (2 * pi) / p) + 1;
  }

  static double easeOutElastic(double t) {
    var p = 0.3;
    return 1 - pow(2, -10 * t) * sin((t - p / 4) * (2 * pi) / p);
  }

  static double easeInOutElastic(double t) {
    var p = 0.3 * 1.5;
    return t < 0.5
        ? -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * (2 * pi) / p)) / 2
        : (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * (2 * pi) / p)) / 2 +
            1;
  }

  static double easeInBounce(double t) => 1 - easeOutBounce(1 - t);

  static double easeOutBounce(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      return 7.5625 * (t -= 1.5 / 2.75) * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      return 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375;
    } else {
      return 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375;
    }
  }

  static double easeInOutBounce(double t) =>
      t < 0.5 ? easeInBounce(t * 2) / 2 : easeOutBounce(t * 2 - 1) / 2 + 0.5;
}

class Animation {
  Duration duration;
  Duration? delay;
  Function(double t) easing;
  Function(double t) onUpdate;
  Function? onDone;

  final DateTime _startTime;
  Duration get timeDifference => DateTime.now().difference(_startTime);
  double get _t =>
      (timeDifference.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  bool get isDone => _t == 1.0;

  Animation({
    required this.duration,
    this.delay,
    Function(double t)? easing,
    required this.onUpdate,
    this.onDone,
  })  : easing = easing ?? ((t) => t),
        _startTime = DateTime.now().add(delay ?? Duration.zero);

  update() {
    onUpdate(easing(_t));

    if (_t == 1.0) {
      onDone?.call();
    }
  }
}
