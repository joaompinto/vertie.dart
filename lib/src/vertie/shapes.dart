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
