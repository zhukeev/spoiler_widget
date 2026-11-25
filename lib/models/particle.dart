import 'dart:math' hide log;
import 'dart:ui' show Color, Offset, Path;

/// Particle class to represent a single particle
///
/// This class is used to represent a single particle in the particle system.
/// It contains the position, size, color, life, speed, angle, and rect of the particle.
class Particle extends Offset {
  /// Unique identifier for tracking particles across updates.
  final int id;

  /// The size of the particle.
  final double size;

  /// The color of the particle.
  final Color color;

  /// Value between 0 and 1 representing the life of the particle.
  final double life;

  /// Value representing the speed of the particle in pixels per frame.
  final double speed;

  /// Value representing the angle of the particle in radians.
  final double angle;

  /// The path of the particle. Used to calculate the next position of the particle.
  final Path path;

  const Particle(
    this.id,
    super.dx,
    super.dy,
    this.size,
    this.color,
    this.life,
    this.speed,
    this.angle,
    this.path,
  );

  static int _nextId = 0;
  static int generateId() => _nextId++;

  /// Copy the particle with new values
  Particle copyWith({
    int? id,
    double? dx,
    double? dy,
    double? size,
    Color? color,
    double? life,
    double? speed,
    double? angle,
    Path? path,
  }) {
    return Particle(
      id ?? this.id,
      dx ?? this.dx,
      dy ?? this.dy,
      size ?? this.size,
      color ?? this.color,
      life ?? this.life,
      speed ?? this.speed,
      angle ?? this.angle,
      path ?? this.path,
    );
  }

  /// Move the particle
  ///
  /// This method is used to move the particle.
  /// It calculates the next position of the particle based on the current position, speed, and angle.
  ///
  /// [random] supplies the jitter source (defaults to a new [Random]).
  /// [step] scales the per-frame motion and life decay; `1.0` matches the
  /// historical 60 fps frame unit.
  Particle moveToRandomAngle([Random? random, double step = 1.0]) {
    final rng = random ?? Random();
    return moveWithAngle(angle, step: step).copyWith(
      // Random angle
      angle: angle + (rng.nextDouble() - 0.5) * step,
    );
  }

  /// Move the particle
  ///
  /// This method is used to move the particle to given angle.
  /// [step] scales distance travelled and life decay per call.
  Particle moveWithAngle(double angle, {double step = 1.0}) {
    final next = this + Offset.fromDirection(angle, speed * step);

    final lifetime = life - 0.01 * step;

    final color = this.color.withValues(alpha: lifetime.clamp(0, 1));

    return copyWith(
      dx: next.dx,
      dy: next.dy,
      life: lifetime,
      color: color,
      // Given angle
      angle: angle,
    );
  }
}
