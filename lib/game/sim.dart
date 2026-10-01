import 'dart:math' as math;
import 'dart:ui';

import 'package:forge2d/forge2d.dart' hide Transform;

import 'geometry.dart';
import 'levels.dart';

const double kLineR = 0.42; // half thickness of the drawn ink line
const double kGravity = 95;

enum SimState { ready, drawing, running, won, failed }

class _Tag {
  final String name;
  const _Tag(this.name);
}

const _blueTag = _Tag('blue');
const _pinkTag = _Tag('pink');
const _lineTag = _Tag('line');

/// Physics + rules for a single attempt at a level.
class Sim extends ContactListener {
  final Level level;
  late final World world;
  late final Body blue;
  late final Body pink;
  Body? line;

  SimState state = SimState.ready;
  final List<Offset> stroke = []; // points in paper space while drawing
  List<Vector2> _lineLocal = [];
  double inkUsed = 0;
  double winTime = 0;
  double failTime = 0;
  double time = 0;
  Offset kiss = Offset.zero;
  double _acc = 0;
  bool _blocked = false;

  Sim(this.level) {
    world = World(Vector2(0, kGravity));
    world.setContactListener(this);
    final ground = world.createBody(BodyDef(type: BodyType.static));
    for (final g in level.geos) {
      if (!g.solid) continue;
      switch (g.kind) {
        case GeoKind.circle:
          ground.createFixture(FixtureDef(
              CircleShape()
                ..radius = g.r
                ..position.setValues(g.c.dx, g.c.dy),
              friction: 0.6));
        case GeoKind.poly:
          for (final t in triangulate(g.pts)) {
            final a = (t[1] - t[0]), b = (t[2] - t[0]);
            // Box2D merges near-collinear vertices; skip slivers it can't build.
            if ((a.dx * b.dy - a.dy * b.dx).abs() < 0.05) continue;
            if (a.distance < 0.03 || b.distance < 0.03 || (t[2] - t[1]).distance < 0.03) {
              continue;
            }
            ground.createFixture(FixtureDef(
                PolygonShape()..set(t.map((e) => Vector2(e.dx, e.dy)).toList()),
                friction: 0.6));
          }
        case GeoKind.bar:
          _addBar(ground, g.pts, g.w / 2, g.closed, 0.6);
      }
    }
    blue = _ball(level.blue, _blueTag);
    pink = _ball(level.pink, _pinkTag);
  }

  Body _ball(Offset p, _Tag tag) {
    final b = world.createBody(BodyDef(
      type: BodyType.static,
      position: Vector2(p.dx, p.dy),
      userData: tag,
      bullet: true,
      angularDamping: 0.04,
    ));
    b.createFixture(FixtureDef(CircleShape()..radius = kBallR,
        density: 0.5, friction: 0.5, restitution: 0.12));
    return b;
  }

  static void _addBar(Body body, List<Offset> pts, double hw, bool closed,
      double friction, {double density = 0}) {
    final n = pts.length;
    final segs = n - 1 + (closed ? 1 : 0);
    for (var i = 0; i < segs; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      final d = b - a;
      final len = d.distance;
      if (len < 1e-3) continue;
      final nrm = Offset(-d.dy, d.dx) / len * hw;
      body.createFixture(FixtureDef(
          PolygonShape()
            ..set([
              Vector2(a.dx + nrm.dx, a.dy + nrm.dy),
              Vector2(b.dx + nrm.dx, b.dy + nrm.dy),
              Vector2(b.dx - nrm.dx, b.dy - nrm.dy),
              Vector2(a.dx - nrm.dx, a.dy - nrm.dy),
            ]),
          friction: friction,
          density: density));
    }
    for (var i = 0; i < n; i++) {
      body.createFixture(FixtureDef(
          CircleShape()
            ..radius = hw
            ..position.setValues(pts[i].dx, pts[i].dy),
          friction: friction,
          density: density));
    }
  }

  double get inkLeft => (1 - inkUsed / level.ink).clamp(0.0, 1.0);

  int get starsNow => 1 + (inkLeft >= 0.40 ? 1 : 0) + (inkLeft >= 0.73 ? 1 : 0);

  bool _free(Offset p) {
    if (p.dx < kLineR || p.dx > kPaperW - kLineR) return false;
    if (p.dy < kLineR || p.dy > kPaperH - kLineR) return false;
    for (final g in level.geos) {
      if (geoHits(g, p, kLineR)) return false;
    }
    if ((p - level.blue).distance < kBallR + kLineR) return false;
    if ((p - level.pink).distance < kBallR + kLineR) return false;
    return true;
  }

  bool _segFree(Offset a, Offset b) {
    final len = (b - a).distance;
    final n = math.max(1, (len / 0.25).ceil());
    for (var i = 1; i <= n; i++) {
      if (!_free(Offset.lerp(a, b, i / n)!)) return false;
    }
    return true;
  }

  /// Begin a stroke; returns false when the touch can't start a line.
  bool begin(Offset p) {
    if (state != SimState.ready) return false;
    if (!_free(p)) return false;
    state = SimState.drawing;
    stroke
      ..clear()
      ..add(p);
    _blocked = false;
    return true;
  }

  void extend(Offset p) {
    if (state != SimState.drawing || _blocked) return;
    final last = stroke.last;
    final d = (p - last).distance;
    if (d < 0.6) return;
    if (inkLeft <= 0) return;
    if (!_segFree(last, p)) {
      // The line stops where it meets an obstacle.
      _blocked = true;
      return;
    }
    final allowed = level.ink - inkUsed;
    if (d > allowed) {
      final q = last + (p - last) * (allowed / d);
      inkUsed = level.ink;
      stroke.add(q);
      return;
    }
    inkUsed += d;
    stroke.add(p);
  }

  /// Finish the stroke: the ink becomes a physical body and the world starts.
  void end() {
    if (state != SimState.drawing) return;
    if (stroke.length == 1) inkUsed += 0.5;
    final pts = _simplify(stroke);
    final body = world.createBody(BodyDef(
      type: BodyType.dynamic,
      position: Vector2.zero(),
      userData: _lineTag,
      bullet: true,
      angularDamping: 0.05,
    ));
    _addBar(body, pts, kLineR, false, 0.7, density: 3.0);
    line = body;
    _lineLocal = pts.map((e) => Vector2(e.dx, e.dy)).toList();
    blue.setType(BodyType.dynamic);
    pink.setType(BodyType.dynamic);
    blue.setAwake(true);
    pink.setAwake(true);
    state = SimState.running;
  }

  List<Offset> _simplify(List<Offset> pts) {
    if (pts.length < 3) return List.of(pts);
    final out = [pts.first];
    for (var i = 1; i < pts.length - 1; i++) {
      if ((pts[i] - out.last).distance >= 0.9) out.add(pts[i]);
    }
    if ((pts.last - out.last).distance > 0.2) {
      out.add(pts.last);
    } else {
      out[out.length - 1] = pts.last;
    }
    return out;
  }

  /// Current shape of the ink line in paper space.
  List<Offset> get linePoints {
    if (line == null) return stroke;
    return _lineLocal.map((v) {
      final w = line!.worldPoint(v);
      return Offset(w.x, w.y);
    }).toList();
  }

  Offset get bluePos => Offset(blue.position.x, blue.position.y);
  Offset get pinkPos => Offset(pink.position.x, pink.position.y);

  void step(double dt) {
    time += dt;
    if (state == SimState.won) winTime += dt;
    if (state == SimState.failed) failTime += dt;
    if (state != SimState.running && state != SimState.won) return;
    _acc += math.min(dt, 0.05);
    const h = 1 / 120;
    while (_acc >= h) {
      world.stepDt(h);
      _acc -= h;
      // Once they kiss the balls stay together (bodies can't change type
      // inside the contact callback, so it happens after the step).
      if (state == SimState.won && blue.bodyType != BodyType.static) {
        blue.setType(BodyType.static);
        pink.setType(BodyType.static);
      }
    }
    if (state == SimState.running) {
      for (final b in [blue, pink]) {
        final p = b.position;
        if (p.y > kPaperH + 6 || p.x < -6 || p.x > kPaperW + 6) {
          state = SimState.failed;
          failTime = 0;
        }
      }
    }
  }

  @override
  void beginContact(Contact contact) {
    final a = contact.bodyA.userData, b = contact.bodyB.userData;
    if (state == SimState.running &&
        ((a == _blueTag && b == _pinkTag) || (a == _pinkTag && b == _blueTag))) {
      state = SimState.won;
      winTime = 0;
      kiss = Offset.lerp(bluePos, pinkPos, 0.5)!;
    }
  }

  @override
  void endContact(Contact contact) {}
  @override
  void preSolve(Contact contact, Manifold oldManifold) {}
  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}
}
