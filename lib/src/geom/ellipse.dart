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

/// The [Ellipse] object can be used to specify a hit area for [DisplayObject]s.
class Ellipse implements Shape {
  int x;
  int y;
  int width;
  int height;

  Ellipse([this.x = 0, this.y = 0, this.width = 0, this.height = 0]);

  /// Creates a clone of this [Ellipse] instance.
  Ellipse clone() => new Ellipse(x, y, width, height);

  /// Checks whether [point] is contained within this ellipse.
  bool containsPoint(Point<num> point) {
    if (width <= 0 || height <= 0) return false;

    // Normalize the coords to an ellipse with center 0,0.
    double normx = (point.x - x) / width,
        normy = (point.y - y) / height;

    normx *= normx;
    normy *= normy;

    return (normx + normy <= 1);
  }

  /// Returns the framing rectangle of the ellipse as a [Rectangle] object.
  Rectangle<int> getBounds() {
    return new Rectangle(x - width, y - height, width, height);
  }
}
