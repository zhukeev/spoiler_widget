import 'dart:math' hide log;
import 'dart:ui' show Color, Offset, Path;

/// Particle class to represent a single particle
///
/// This class is used to represent a single particle in the particle system.
/// It contains the position, size, color, life, speed, angle, and rect of the particle.
class Particle extends Offset {
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
    super.dx,
    super.dy,
    this.size,
    this.color,
    this.life,
    this.speed,
    this.angle,
    this.path,
  );

  /// Copy the particle with new values
  Particle copyWith({
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
  Particle moveToRandomAngle() {
    return moveWithAngle(angle).copyWith(
      // Random angle
      angle: angle + (Random().nextDouble() - 0.5),
    );
  }

  /// Move the particle
  ///
  /// This method is used to move the particle to given angle.
  Particle moveWithAngle(double angle) {
    final next = this + Offset.fromDirection(angle, speed);

    final lifetime = life - 0.01;

    final color = lifetime > .1 ? this.color.withOpacity(lifetime.clamp(0, 1)) : this.color;

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
