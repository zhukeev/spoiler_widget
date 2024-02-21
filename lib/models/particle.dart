import 'dart:math';
import 'dart:ui' show Color, Offset, Rect;

/// Particle class to represent a single particle
///
/// This class is used to represent a single particle in the particle system.
/// It contains the position, size, color, life, speed, angle, and rect of the particle.
///
/// [size] is the size of the particle.
/// [color] is the color of the particle.
/// [life] is the life of the particle.
/// [speed] is the speed of the particle.
/// [angle] is the angle which indicates the direction of the particle.
/// [rect] is the rect of the particle.
class Particle extends Offset {
  final double size;
  final Color color;
  final double life;
  final double speed;
  final double angle;
  final Rect rect;

  const Particle(
    super.dx,
    super.dy,
    this.size,
    this.color,
    this.life,
    this.speed,
    this.angle,
    this.rect,
  );

  Particle copyWith({
    double? dx,
    double? dy,
    double? size,
    Color? color,
    double? life,
    double? speed,
    double? angle,
    Rect? rect,
  }) {
    return Particle(
      dx ?? this.dx,
      dy ?? this.dy,
      size ?? this.size,
      color ?? this.color,
      life ?? this.life,
      speed ?? this.speed,
      angle ?? this.angle,
      rect ?? this.rect,
    );
  }

  /// Move the particle
  /// 
  /// This method is used to move the particle.
  /// It calculates the next position of the particle based on the current position, speed, and angle.
  Particle move() {
    final next = this + Offset.fromDirection(angle, speed);

    final lifetime = life - 0.01;
    final color = lifetime > .1 ? this.color.withOpacity(lifetime) : this.color;

    return copyWith(
      dx: next.dx,
      dy: next.dy,
      life: lifetime,
      color: color,
      // Random angle
      angle: angle + (Random().nextDouble() - 0.5),
    );
  }
}
