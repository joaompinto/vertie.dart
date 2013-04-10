part of vertie;

class World {
  List<CircleShape> circle_shapes;
  List<Line> lines;
  num width, height;
  num damping, friction;
  Vector gravity;

  World(this.width, this.height,
      [this.damping = 0.9, this.friction = 0]) {
    circle_shapes = [];
    lines = [];
    gravity = new Vector(0,0);
  }

  void collide(preserve_impulse) {
    /// Check all bodies for collisions
    for (var i = 0; i < circle_shapes.length; i++) {
      CircleShape shape1 = circle_shapes[i];
      for (var j = i+1; j < circle_shapes.length; j++) {
        CircleShape shape2 = circle_shapes[j];
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
        Point contact_point = shape.contact_point(line);
        if(contact_point  == null)
          continue;

        // record velocity
        final v1x = (shape.center.x - shape.prev_center.x) * damping;
        final v1y = (shape.center.y - shape.prev_center.y) * damping;

        final x = shape.center.x - contact_point.x;
        final y = shape.center.y - contact_point.y;
        final length = contact_point.distanceTo(shape.center);
        final target = shape.radius;
        final factor = (length-target)/length;
        shape.center.x -= x*factor;
        shape.center.y -= y*factor;

        if(preserve_impulse) {
          final factor_y = shape.radius*sin(atan2(y.toInt(), x.toInt()));
          final factor_x = shape.radius*cos(atan2(y.toInt(), x.toInt()));
          final delta_y = contact_point.y -  shape.center.y;
          if(delta_y.abs() <= shape.radius)
            shape.prev_center.y = contact_point.y+factor_y+v1y;
        }
      }
    }
  }

  void border_collide_preserve_impulse() {
    for(final shape in circle_shapes) {
      final radius = shape.radius;
      final x = shape.center.x;
      final y = shape.center.y;
      var vx = 0, vy = 0;

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
      final radius = shape.radius;
      final x = shape.center.x;
      final y = shape.center.y;
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
    for(final shape in circle_shapes)
      shape.apply_friction(friction);
  }

  void inertia() {
    for(final shape in circle_shapes)
      shape.inertia();
  }

  void accelerate(delta) {
    for(final shape in this.circle_shapes)
      shape.accelerate(delta);
  }

  void step() {
    num steps = 5;
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

