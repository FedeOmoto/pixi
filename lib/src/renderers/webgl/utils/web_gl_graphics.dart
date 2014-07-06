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
 * This class provides a set of methods used by the WebGL renderer to draw the
 * primitive graphics data.
 */
class WebGLGraphics {
  // TODO

  /// Answer the singleton instance of the CanvasGraphics class.
  static WebGLGraphics get current => WebGLGraphics._singleton;

  static final WebGLGraphics _singleton = new WebGLGraphics._internal();

  factory WebGLGraphics() {
    throw new UnsupportedError(
        'WebGLGraphics cannot be instantiated, use WebGLGraphics.current');
  }

  WebGLGraphics._internal();
}
