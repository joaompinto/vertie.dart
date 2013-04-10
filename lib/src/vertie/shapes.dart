/*
Copyright (c) 2013, Vertie.Dart Developers
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

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
    return center.distanceTo(point) < radius;
  }

  void accelerate(num delta) {
    final x = center.x, y=center.y;

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


  /*
   * Return the list of points for the intersection with line
   * http://stackoverflow.com/a/1090772/401041
   */
  List<Point> intersect_line(Line line) {
    final A = line.A, B = line.B, C = center;

    // compute the triangle area times 2 (area = area2/2)
    final area2 = ((B.x-A.x)*(C.y-A.y) - (C.x-A.x)*(B.y-A.y)).abs();
    // compute the AB segment length
    final LAB = A.distanceTo(B);
    // compute the triangle height
    final  h = area2/LAB;
    // compute the line AB direction vector components
    final  Dx = (B.x-A.x)/LAB;
    final  Dy = (B.y-A.y)/LAB;
    // compute the distance from A toward B of closest point to C
    final t = Dx*(C.x-A.x) + Dy*(C.y-A.y);
    // compute the intersection point distance from t
    final dt = sqrt(pow(radius,2) - pow(h,2));
    // compute first intersection point coordinate
    final Ex = A.x + (t-dt)*Dx;
    final Ey = A.y + (t-dt)*Dy;
    // compute second intersection point coordinate
    final Fx = A.x + (t+dt)*Dx;
    final Fy = A.y + (t+dt)*Dy;
    return [new Point(Ex, Ey), new Point(Fx, Fy)];
  }

  /* Returns the contact point with a line
   *
   */
  Point contact_point(Line L) {

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
