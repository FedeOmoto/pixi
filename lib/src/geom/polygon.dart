// Copyright 2014 Federico Omoto
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of pixi;

// TODO: document.
class Polygon implements Shape {
  /// The list of vertex [Point]s.
  List<Point<num>> points;

  /// Creates a new Polygon. You have to provide a list of points.
  Polygon(this.points);

  /// Creates a clone of this polygon.
  Polygon clone() {
    var points = new List<Point<int>>();

    this.points.forEach((point) => points.add(point.clone()));

    return new Polygon(points);
  }

  /// Checks whether [point] is contained within this polygon.
  bool containsPoint(Point<num> point) {
    bool inside = false;

    // Use some raycasting to test hits.
    for (int i = 0,
        j = points.length - 1; i < points.length; j = i++) {
      num xi = points[i].x,
          yi = points[i].y,
          xj = points[j].x,
          yj = points[j].y;

      bool intersect =
          ((yi > point.y) != (yj > point.y)) &&
          (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }
}
