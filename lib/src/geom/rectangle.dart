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
 * A class for representing two-dimensional axis-aligned rectangles with mutable
 * properties.
 */
class Rectangle<T extends num> extends math.MutableRectangle<T> implements Shape
    {
  /**
   * Create a mutable rectangle spanned by `(left, top)` and
   * `(left+width, top+height)`.
   *
   * The rectangle contains the points
   * with x-coordinate between `left` and `left + width`, and
   * with y-coordinate between `top` and `top + height`, both inclusive.
   *
   * The `width` and `height` should be non-negative.
   * If `width` or `height` are negative, they are clamped to zero.
   *
   * If `width` and `height` are zero, the "rectangle" comprises only the single
   * point `(left, top)`.
   */
  Rectangle(T left, T top, T width, T height) : super(left, top, width, height);

  /// Creates a clone of this Rectangle.
  Rectangle<T> clone() => new Rectangle<T>(left, top, width, height);
}
