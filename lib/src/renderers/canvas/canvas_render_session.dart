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
class CanvasRenderSession extends RenderSession {
  final CanvasMaskManager maskManager;

  ScaleModes<int> scaleMode;

  /**
   * If true Pixi will floor x/y values when rendering, stopping pixel
   * interpolation.
   * Handy for crisp pixel art and speed on legacy devices.
   */
  bool roundPixels = false;

  CanvasRenderSession(CanvasRenderingContext2D
      context, this.maskManager, [this.scaleMode]) : super(context);
}
