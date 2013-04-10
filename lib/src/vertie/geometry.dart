part of vertie;

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

class Vector extends Point {
  Vector(x, y) : super(x, y);
  /*  For simplicy we assume vectors have origin (0,0) to (PointX, PointY) */
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


