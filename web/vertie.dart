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
    num min_length = this.squaredDistanceTo(points[0]);
    for (var point in points) {
      num length = this.squaredDistanceTo(point);
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
  
  VertieLine(this.A, this.B);
   

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
    
    A = this.A; B = this.B;
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
    vi = this.intersection_point(C.center);
    p = vi.point;
    if(!vi.in_segment)
      p = C.center.nearest([this.A, this.B]);       
    distance = p.distanceTo(C.center);
    if(distance > C.radius) return null; else return p;
  }
}


class VertieCircleShape {
  num radius;
  VertiePoint center;
  VertiePoint prev_center;
  num ax, ay;
  
  /* Circle shape centered at point P */
  VertieCircleShape(this.center, this.radius) {
    this.ax = 0; this.ay = 0;
    this.prev_center = new VertiePoint(this.center.x, this.center.y);
  }
  
  bool hit(VertiePoint point) {
    num length = this.center.distanceTo(point);
    return length < this.radius;
  }
  
  void accelerate(num delta) {
    num x, y;
    x = this.center.x; y = this.center.y;
    
    this.center.x += this.ax * delta * delta;
    this.center.y += this.ay * delta * delta;
    this.ax = 0; this.ay = 0;
  }

  void inertia() {
    num x,y;
    x = this.center.x*2 - this.prev_center.x; y = this.center.y*2 - this.prev_center.y;
    this.prev_center = this.center;
    this.center = new VertiePoint(x, y);
   }
  
  void apply_friction(num friction) {
    num x = (this.prev_center.x - this.center.x);
    num y = (this.prev_center.y - this.center.y);
    num length = sqrt(x*x + y*y);
    if(x != 0) {      
      this.ax += (x/length)*friction;
      if(x.abs() < 0.04) { // stop on residual acceleration
        this.ax = 0;
        this.prev_center.x = this.center.x;
      }
    }
    if(y !=  0) {
      this.ay += (y/length)*friction;
      if(y.abs() < 0.04) {  // stop on residual acceleration
        this.ay = 0;
        this.prev_center.y = this.center.y;
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
    this.circle_shapes = [];
    this.lines = [];
    this.gravity = new VertieVector(0,0);    
  }
  
  void collide(preserve_impulse) {
    /// Check all bodies for collisions
    for (var i = 0; i < this.circle_shapes.length; i++) {
      VertieCircleShape shape1 = this.circle_shapes[i];
      for (var j = i+1; j < this.circle_shapes.length; j++) {
        VertieCircleShape shape2 = this.circle_shapes[j];
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
            num f1 = (this.damping*(x*v1x+y*v1y))/slength;
            num f2 = (this.damping*(x*v2x+y*v2y))/slength;

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
    for(final line in this.lines) { 
      for(VertieCircleShape shape in this.circle_shapes) {              
        VertiePoint contact_point = line.contact_point(shape);
        if(contact_point  == null)
          continue;
        
        // record velocity
        num v1x = (shape.center.x - shape.prev_center.x) * this.damping;
        num v1y = (shape.center.y - shape.prev_center.y) * this.damping;

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
    width = this.width; height = this.height;
    for(VertieCircleShape shape in this.circle_shapes) {
      num radius = shape.radius;
      num x = shape.center.x;
      num y = shape.center.y;
      num vx, vy;

      if(shape.center.x-radius < 0) {
        vx = (shape.prev_center.x - shape.center.x)*this.damping;
        shape.center.x = radius;
        shape.prev_center.x = shape.center.x - vx;     
      } 
      else if (x + radius > width) {
        vx = (shape.prev_center.x- shape.center.x)*this.damping;
        shape.center.x = width-radius;
        shape.prev_center.x = shape.center.x - vx;
      }
      if(y-radius < 0) {
        vy = (shape.prev_center.y - shape.center.y)*this.damping;
        shape.center.y = radius;
        shape.prev_center.y = shape.center.y - vy;
      }
      else if (y + radius > height) {
        vy = (shape.prev_center.y - shape.center.y)*this.damping;
        shape.center.y = height-radius;
        shape.prev_center.y = shape.center.y - vy;
      }
    }
  } 
  
  void border_collide() {
    width = this.width; height = this.height;
    for(VertieCircleShape shape in this.circle_shapes) {
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
    for(VertieCircleShape shape in this.circle_shapes) {
      shape.ay += this.gravity.y;
      shape.ax += this.gravity.x;
    }
  }
  
  void apply_friction() {
    for(VertieCircleShape shape in this.circle_shapes)
      shape.apply_friction(this.friction);
  }
  
  void inertia() {
    for(VertieCircleShape shape in this.circle_shapes)
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
      if(this.friction != 0) 
        this.apply_friction();
      this.apply_gravity();
      this.accelerate(delta);
      this.colide_with_lines(true);
      this.collide(false);
      this.border_collide();     
      this.inertia();
      this.collide(true);
      this.border_collide_preserve_impulse();
    }
  }
  
  void add_circle_shape(shape) {
    /* Add a shape to the world */
    this.circle_shapes.add(shape);
  }
  
  void remove_circle_shape(shape) {
    this.circle_shapes.remove(shape);
  }
}