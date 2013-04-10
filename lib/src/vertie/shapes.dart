part of vertie;

class CircleShape {
  num radius;
  Point center;
  Point prev_center;
  num ax, ay;

  /* Circle shape centered at point P */
  CircleShape(this.center, this.radius) {
    ax = 0; ay = 0;
    prev_center = new Point(center.x, center.y);
  }

  bool hit(Point point) {
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
    center = new Point(x, y);
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
  
  Point contact_point(Line L){
    /*  Returns the contact point with a line */
    Intersection vi;
    num distance;
    Point p;
    vi = L.intersection_point(center);
    p = vi.point;
    if(!vi.in_segment)
      p = center.nearest([L.A, L.B]);
    distance = p.distanceTo(center);
    if(distance > radius)
      return null;
    else
      return p;
  }
}
