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
 * A utility class for representing two-dimensional positions with mutable
 * properties.
 */
class Point<T extends num> extends math.Point<T> {
  math.Point<T> _point;

  Point(T x, T y) : super(x, y) {
    _point = new math.Point<T>(super.x, super.y);
  }

  T get x => _point.x;

  void set x(T x) {
    _point = new math.Point<T>(x, _point.y);
  }

  T get y => _point.y;

  void set y(T y) {
    _point = new math.Point<T>(_point.x, y);
  }

  /// Creates a clone of this point.
  Point<T> clone() => new Point<T>(_point.x, _point.y);
}
