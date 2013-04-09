library vertie;

import 'dart:math';

class VertiePoint {
  num x;
  num y;

  VertiePoint(this.x, this.y);

  num distanceTo(VertiePoint other) {
    return sqrt(squaredDistanceTo(other));
  }

  num squaredDistanceTo(VertiePoint other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return dx * dx + dy * dy;
  }

  /* Return the neareast point from a list of points */
  VertiePoint nearest(List<VertiePoint> points) {
    VertiePoint nearest_point = points[0];
    num min_length = squaredDistanceTo(points[0]);
    for (final point in points) {
      num length = squaredDistanceTo(point);
      if (length < min_length) {
        nearest_point = point;
      }
    }
    return nearest_point;
  }
}

class VertieVector extends VertiePoint {
  VertieVector(x, y) : super(x, y);
  /*  For simplicy we assume vectors have origin (0,0) to (PointX, PointY) */
}


class VertieIntersection {
  VertiePoint point;
  bool in_segment;

  VertieIntersection(this.point, this.in_segment);
}

class VertieLine {
  /* Line between point A and B */
  VertiePoint A;
  VertiePoint B;

  VertieLine(this.A, this.B) {
    assert(A.x != B.x || A.y != B.y); // don't accept zero length line
  }


  VertieIntersection intersection_point(VertiePoint C) {
    /*
    Returns (point, in_segement)
      point - the point from the line which is closer to point C
      in_segement - True if the point is contained in the line seg
    Math from http://paulbourke.net/geometry/pointline/
    */
    num intersection_x;
    num intersection_y;
    bool in_segment;

    num line_length = A.squaredDistanceTo(B);
    num u = (((C.x - A.x ) * ( B.x - A.x )) +
        ((C.y - A.y) * (B.y - A.y))) / ( line_length * line_length);

    in_segment = !(u < 0 || u > 1);

    // Determine point of intersection
    intersection_x = A.x + u * ( B.x - A.x);
    intersection_y = A.y + u * ( B.y - A.y);

    return new VertieIntersection(new VertiePoint(intersection_x, intersection_y), in_segment);
  }

  VertiePoint contact_point(VertieCircleShape C){
    /*  Returns the contact point with a circle */
    VertieIntersection vi;
    num distance;
    VertiePoint p;
    vi = intersection_point(C.center);
    p = vi.point;
    if(!vi.in_segment)
      p = C.center.nearest([A, B]);
    distance = p.distanceTo(C.center);
    if(distance > C.radius)
      return null;
    else
      return p;
  }
}


class VertieCircleShape {
  num radius;
  VertiePoint center;
  VertiePoint prev_center;
  num ax, ay;

  /* Circle shape centered at point P */
  VertieCircleShape(this.center, this.radius) {
    ax = 0; ay = 0;
    prev_center = new VertiePoint(center.x, center.y);
  }

  bool hit(VertiePoint point) {
    num length = center.distanceTo(point);
    return length < radius;
  }

  void accelerate(num delta) {
    num x, y;
    x = center.x; y = center.y;

    center.x += ax * delta * delta;
    center.y += ay * delta * delta;
    ax = 0; ay = 0;
  }

  void inertia() {
    num x,y;
    x = center.x*2 - prev_center.x; y = center.y*2 - prev_center.y;
    prev_center = center;
    center = new VertiePoint(x, y);
   }

  void apply_friction(num friction) {
    final x = (prev_center.x - center.x);
    final y = (prev_center.y - center.y);
    final length = sqrt(x*x + y*y);
    if(x != 0) {
      ax += (x/length)*friction;
      if(x.abs() < 0.04) { // stop on residual acceleration
        ax = 0;
        prev_center.x = center.x;
      }
    }
    if(y !=  0) {
      ay += (y/length)*friction;
      if(y.abs() < 0.04) {  // stop on residual acceleration
        ay = 0;
        prev_center.y = center.y;
      }
    }
  }
}


class VertieWorld {
  List<VertieCircleShape> circle_shapes;
  List<VertieLine> lines;
  num width, height;
  num damping, friction;
  VertieVector gravity;

  VertieWorld(this.width, this.height,
      [this.damping = 0.95, this.friction = 0]) {
    circle_shapes = [];
    lines = [];
    gravity = new VertieVector(0,0);
  }

  void collide(preserve_impulse) {
    /// Check all bodies for collisions
    for (var i = 0; i < circle_shapes.length; i++) {
      VertieCircleShape shape1 = circle_shapes[i];
      for (var j = i+1; j < circle_shapes.length; j++) {
        VertieCircleShape shape2 = circle_shapes[j];
        num x = shape1.center.x - shape2.center.x;
        num y = shape1.center.y - shape2.center.y;
        num slength = x*x+y*y;
        num length = sqrt(slength);
        num target = shape1.radius + shape2.radius;
        if(length < target) { // Colision detected
          // record previous velocityy
          num v1x = shape1.center.x - shape1.prev_center.x;
          num v1y = shape1.center.y - shape1.prev_center.y;
          num v2x = shape2.center.x - shape2.prev_center.x;
          num v2y = shape2.center.y - shape2.prev_center.y;

          // resolve the shape overlap conflict
          num factor = (length-target)/length;
          shape1.center.x -= x*factor*0.5;
          shape1.center.y -= y*factor*0.5;
          shape2.center.x += x*factor*0.5;
          shape2.center.y += y*factor*0.5;

          if(preserve_impulse) {
            // compute the projected component factors
            num f1 = (damping*(x*v1x+y*v1y))/slength;
            num f2 = (damping*(x*v2x+y*v2y))/slength;

            // swap the projected components
            v1x += f2*x - f1*x;
            v2x += f1*x - f2*x;
            v1y += f2*y - f1*y;
            v2y += f1*y - f2*y;

            // the previous position is adjusted
            // to represent the new velocity
            shape1.prev_center.x = shape1.center.x - v1x;
            shape1.prev_center.y = shape1.center.y - v1y;
            shape2.prev_center.x = shape2.center.x - v2x;
            shape2.prev_center.y = shape2.center.y - v2y;
          }
        }
      }
    }
  }

  void colide_with_lines(bool preserve_impulse) {
    for(final line in lines) {
      for(final shape in circle_shapes) {
        VertiePoint contact_point = line.contact_point(shape);
        if(contact_point  == null)
          continue;

        // record velocity
        num v1x = (shape.center.x - shape.prev_center.x) * damping;
        num v1y = (shape.center.y - shape.prev_center.y) * damping;

        num x = shape.center.x - contact_point.x;
        num y = shape.center.y - contact_point.y;
        num length = contact_point.distanceTo(shape.center);
        num target = shape.radius;
        num factor = (length-target)/length;
        shape.center.x -= x*factor;
        shape.center.y -= y*factor;

        if(preserve_impulse) {
          num factor_y = shape.radius*sin(atan2(x.toInt(), y.toInt()));
          num factor_x = shape.radius*cos(atan2(y..toInt(), x.toInt()));
          num delta_y = contact_point.y -  shape.center.y;
          if(delta_y.abs() <= shape.radius)
            shape.prev_center.y = contact_point.y+factor_y+v1y;
        }
      }
    }
  }

  void border_collide_preserve_impulse() {
    for(final shape in circle_shapes) {
      num radius = shape.radius;
      num x = shape.center.x;
      num y = shape.center.y;
      num vx, vy;

      if(shape.center.x-radius < 0) {
        vx = (shape.prev_center.x - shape.center.x)*damping;
        shape.center.x = radius;
        shape.prev_center.x = shape.center.x - vx;
      }
      else if (x + radius > width) {
        vx = (shape.prev_center.x- shape.center.x)*damping;
        shape.center.x = width-radius;
        shape.prev_center.x = shape.center.x - vx;
      }
      if(y-radius < 0) {
        vy = (shape.prev_center.y - shape.center.y)*damping;
        shape.center.y = radius;
        shape.prev_center.y = shape.center.y - vy;
      }
      else if (y + radius > height) {
        vy = (shape.prev_center.y - shape.center.y)*damping;
        shape.center.y = height-radius;
        shape.prev_center.y = shape.center.y - vy;
      }
    }
  }

  void border_collide() {
    for(final shape in circle_shapes) {
      num radius = shape.radius;
      num x = shape.center.x;
      num y = shape.center.y;
      if(x-radius < 0)
        shape.center.x = radius;
      else if(x + radius > width)
        shape.center.x = width-radius;
      if(y-radius < 0)
        shape.center.y = radius;
      else if(y + radius > height)
        shape.center.y = height-radius;
    }
  }

  void apply_gravity() {
    for(final shape in circle_shapes) {
      shape.ay += gravity.y;
      shape.ax += gravity.x;
    }
  }

  void apply_friction() {
    for(VertieCircleShape shape in circle_shapes)
      shape.apply_friction(friction);
  }

  void inertia() {
    for(VertieCircleShape shape in circle_shapes)
      shape.inertia();
  }

  void accelerate(delta) {
    for(VertieCircleShape shape in this.circle_shapes)
      shape.accelerate(delta);
  }

  void step() {
    num steps = 2;
    num delta = 1.0/steps;
    for (var i = 0; i < steps; i++) {
      if(friction != 0)
        apply_friction();
      apply_gravity();
      accelerate(delta);
      colide_with_lines(true);
      collide(false);
      border_collide();
      inertia();
      collide(true);
      border_collide_preserve_impulse();
    }
  }

  void add_circle_shape(shape) {
    /* Add a shape to the world */
    circle_shapes.add(shape);
  }

  void remove_circle_shape(shape) {
    circle_shapes.remove(shape);
  }
}