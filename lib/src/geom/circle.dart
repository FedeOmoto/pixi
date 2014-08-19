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

/// The [Circle] object can be used to specify a hit area for [DisplayObject]s.
class Circle implements Shape {
  int x;
  int y;
  double radius;

  Circle([this.x = 0, this.y = 0, this.radius = 0.0]);

  /// Creates a clone of this [Circle] instance.
  Circle clone() => new Circle(x, y, radius);

  /// Checks whether [point] is contained within this circle.
  bool containsPoint(Point<num> point) {
    if (radius <= 0) return false;

    int dx = (x - point.x),
        dy = (y - point.y);
    double r2 = radius * radius;

    dx *= dx;
    dy *= dy;

    return (dx + dy <= r2);
  }

  /// Returns the framing rectangle of the circle as a [Rectangle] object.
  Rectangle<double> getBounds() {
    return new Rectangle(x - radius, y - radius, radius * 2, radius * 2);
  }
}
