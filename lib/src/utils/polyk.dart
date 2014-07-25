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

/**
 * A class for working with polygons.
 * Based on the Polyk library http://polyk.ivank.net released under MIT licence.
 */
class PolyK {
  /// Answer the singleton instance of the CanvasGraphics class.
  static PolyK get current => PolyK._singleton;

  static final PolyK _singleton = new PolyK._internal();

  factory PolyK() {
    throw new UnsupportedError('PolyK cannot be instantiated, use PolyK.current'
        );
  }

  PolyK._internal();

  /// Triangulates shapes for webGL graphic fills.
  List<int> triangulate(List<num> points) {
    bool sign = true;

    int n = points.length >> 1;

    if (n < 3) return new List<int>();

    List<int> tgs = new List<int>();
    List<int> avl = new List<int>();

    for (int i = 0; i < n; i++) avl.add(i);

    int i = 0;
    int al = n;

    while (al > 3) {
      var i0 = avl[(i + 0) % al];
      var i1 = avl[(i + 1) % al];
      var i2 = avl[(i + 2) % al];

      var ax = points[2 * i0],
          ay = points[2 * i0 + 1];
      var bx = points[2 * i1],
          by = points[2 * i1 + 1];
      var cx = points[2 * i2],
          cy = points[2 * i2 + 1];

      var earFound = false;

      if (_convex(ax, ay, bx, by, cx, cy, sign)) {
        earFound = true;

        for (int j = 0; j < al; j++) {
          var vi = avl[j];

          if (vi == i0 || vi == i1 || vi == i2) continue;

          if (_pointInTriangle(points[2 * vi], points[2 * vi + 1], ax, ay, bx,
              by, cx, cy)) {
            earFound = false;
            break;
          }
        }
      }

      if (earFound) {
        tgs.addAll([i0, i1, i2]);
        avl.removeAt((i + 1) % al);
        al--;
        i = 0;
      } else if (i++ > 3 * al) {
        // Need to flip flip reverse it!
        // Reset!
        if (sign) {
          tgs.clear();
          avl.clear();

          for (i = 0; i < n; i++) avl.add(i);

          i = 0;
          al = n;

          sign = false;
        } else {
          print("PIXI Warning: shape too complex to fill.");
          return new List<int>();
        }
      }
    }

    tgs.addAll([avl[0], avl[1], avl[2]]);

    return tgs;
  }

  // Checks whether a point is within a triangle.
  bool _pointInTriangle(int px, int py, int ax, int ay, int bx, int by, int
      cx, int cy) {
    var v0x = cx - ax;
    var v0y = cy - ay;
    var v1x = bx - ax;
    var v1y = by - ay;
    var v2x = px - ax;
    var v2y = py - ay;

    var dot00 = v0x * v0x + v0y * v0y;
    var dot01 = v0x * v1x + v0y * v1y;
    var dot02 = v0x * v2x + v0y * v2y;
    var dot11 = v1x * v1x + v1y * v1y;
    var dot12 = v1x * v2x + v1y * v2y;

    var invDenom = 1 / (dot00 * dot11 - dot01 * dot01);
    var u = (dot11 * dot02 - dot01 * dot12) * invDenom;
    var v = (dot00 * dot12 - dot01 * dot02) * invDenom;

    // Check if point is in triangle.
    return (u >= 0) && (v >= 0) && (u + v < 1);
  }

  // Checks whether a shape is convex.
  bool _convex(int ax, int ay, int bx, int by, int cx, int cy, bool sign) {
    return ((ay - by) * (cx - bx) + (bx - ax) * (cy - by) >= 0) == sign;
  }
}
