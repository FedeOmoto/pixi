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

/// Creates a Canvas element of the given size.
class CanvasBuffer extends TextureBuffer {
  CanvasElement canvas;

  CanvasBuffer(int width, int height) {
    this.width = width;
    this.height = height;

    canvas = new CanvasElement(width: width, height: height);
    context = canvas.context2D;
  }

  /// Clears the canvas that was created by the [CanvasBuffer] class.
  @override
  void clear() {
    (context as CanvasRenderingContext2D).clearRect(0, 0, width, height);
  }

  /**
   * Resizes the canvas that was created by the [CanvasBuffer] class to the
   * specified width and height.
   */
  @override
  void resize(int width, int height) {
    this.width = canvas.width = width;
    this.height = canvas.height = height;
  }
}
