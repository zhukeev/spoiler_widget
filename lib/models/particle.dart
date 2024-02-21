import 'dart:math';
import 'dart:ui' show Color, Offset, Rect;

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
