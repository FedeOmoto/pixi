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
class Rope extends Strip {
  List<Point<num>> points;

  Rope(Texture texture, this.points) : super(texture) {
    refresh();
  }

  void _init() {
    // Set up the main bits.
    vertices = new Float32List(points.length * 4);
    uvs = new Float32List(points.length * 4);
    colors = new Float32List(points.length * 2);
    indices = new Uint16List(points.length * 2);
  }

  void refresh() {
    if (points.isEmpty) return;

    uvs[0] = 0.0;
    uvs[1] = 0.0;
    uvs[2] = 0.0;
    uvs[3] = 1.0;

    colors[0] = 1.0;
    colors[1] = 1.0;

    indices[0] = 0;
    indices[1] = 1;

    Point<num> point;
    int index;
    double amount;

    for (var i = 1; i < points.length; i++) {
      point = points[i];
      index = i * 4;
      // Time to do some smart drawing!
      amount = i / (points.length - 1);

      if (i.isOdd) {
        uvs[index] = amount;
        uvs[index + 1] = 0.0;

        uvs[index + 2] = amount;
        uvs[index + 3] = 1.0;
      } else {
        uvs[index] = amount;
        uvs[index + 1] = 0.0;

        uvs[index + 2] = amount;
        uvs[index + 3] = 1.0;
      }

      index = i * 2;
      colors[index] = 1.0;
      colors[index + 1] = 1.0;

      index = i * 2;
      indices[index] = index;
      indices[index + 1] = index + 1;
    }
  }

  // Updates the object transform for rendering.
  @override
  void _updateTransform() {
    if (points.isEmpty) return;

    Point<num> lastPoint = points.first;
    Point<num> nextPoint;
    Point<double> perp = new Point<double>(0.0, 0.0);

    int total = points.length;
    Point<num> point;
    int index;
    double ratio, perpLength, number;

    for (int i = 0; i < total; i++) {
      point = points[i];
      index = i * 4;

      if (i < points.length - 1) {
        nextPoint = points[i + 1];
      } else {
        nextPoint = point;
      }

      perp.y = -(nextPoint.x - lastPoint.x).toDouble();
      perp.x = (nextPoint.y - lastPoint.y).toDouble();

      ratio = (1 - (i / (total - 1))) * 10;

      if (ratio > 1) ratio = 1.0;

      perpLength = math.sqrt(perp.x * perp.x + perp.y * perp.y);
      number = texture._height / 2;
      perp.x /= perpLength;
      perp.y /= perpLength;

      perp.x *= number;
      perp.y *= number;

      vertices[index] = point.x + perp.x;
      vertices[index + 1] = point.y + perp.y;
      vertices[index + 2] = point.x - perp.x;
      vertices[index + 3] = point.y - perp.y;

      lastPoint = point;
    }

    super._updateTransform();
  }
}
