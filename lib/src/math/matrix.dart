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
 * An affine transformation matrix.
 * 
 * Here is a representation of it:
 * | a | b | tx|
 * | c | d | ty|
 * | 0 | 0 | 1 |
 */
class Matrix {
  static Matrix identity = new Matrix();

  /// Position (0, 0) in a 3x3 affine transformation matrix.
  double a;

  /// Position (0, 1) in a 3x3 affine transformation matrix.
  double b;

  /// Position (1, 0) in a 3x3 affine transformation matrix.
  double c;

  /// Position (1, 1) in a 3x3 affine transformation matrix.
  double d;

  /// Position (2, 0) in a 3x3 affine transformation matrix.
  double tx;

  /// Position (2, 1) in a 3x3 affine transformation matrix.
  double ty;

  Matrix([this.a = 1.0, this.b = 0.0, this.c = 0.0, this.d = 1.0, this.tx =
      0.0, this.ty = 0.0]);

  /// Creates a matrix and initializes it using the contents of [iterable].
  Matrix.from(Iterable iterable) {
    a = iterable.elementAt(0);
    b = iterable.elementAt(1);
    c = iterable.elementAt(3);
    d = iterable.elementAt(4);
    tx = iterable.elementAt(2);
    ty = iterable.elementAt(5);
  }

  /// Creates a list from the current [Matrix] object.
  Float32List asList() {
    return new Float32List.fromList([a, b, tx, c, d, ty, 0.0, 0.0, 1.0]);
  }

  /// Creates a list from the transpose of the current [Matrix] object.
  Float32List asListTransposed() {
    return new Float32List.fromList([a, c, 0.0, b, d, 0.0, tx, ty, 1.0]);
  }
}
