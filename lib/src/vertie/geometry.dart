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

/* 2D Point */
class Point {
  num x;
  num y;

  Point(this.x, this.y);

  num distanceTo(Point other) {
    return sqrt(squaredDistanceTo(other));
  }

  num squaredDistanceTo(Point other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return dx * dx + dy * dy;
  }

  /* Return the neareast point from a list of points */
  Point nearest(List<Point> points) {
    Point nearest_point = points[0];
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

/* 2D Vector with origin at (0, 0) */
class Vector extends Point {
  Vector(x, y) : super(x, y);
}


class Intersection {
  Point point;
  bool in_segment;

  Intersection(this.point, this.in_segment);
}

class Line {
  /* Line between point A and B */
  Point A;
  Point B;

  Line(this.A, this.B) {
    assert(A.x != B.x || A.y != B.y); // don't accept zero length line
  }

  // http://paulbourke.net/geometry/pointlineplane/
  Intersection intersection_point(Point C) {
    /*
    Returns (point, in_segement)
      point - the point from the line which is closer to point C
      in_segement - True if the point is contained in the line seg
    Math from http://paulbourke.net/geometry/pointline/
    */
    var intersection_x;
    var intersection_y;
    var in_segment;

    num line_length = A.distanceTo(B);
    num u = (((C.x - A.x ) * ( B.x - A.x )) +
        ((C.y - A.y) * (B.y - A.y))) / ( line_length * line_length);

    in_segment = !(u < 0 || u > 1);

    // Determine point of intersection
    intersection_x = A.x + u * ( B.x - A.x);
    intersection_y = A.y + u * ( B.y - A.y);

    return new Intersection(new Point(intersection_x, intersection_y), in_segment);
  }


}


