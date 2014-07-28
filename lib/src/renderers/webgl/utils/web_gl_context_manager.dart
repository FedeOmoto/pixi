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
class WebGLContextManager {
  /// Answer the singleton instance of the CanvasGraphics class.
  static WebGLContextManager get current => WebGLContextManager._singleton;

  static final WebGLContextManager _singleton =
      new WebGLContextManager._internal();

  // This is where we store the webGL contexts for easy access.
  Map<int, gl.RenderingContext> _glContexts = new Map<int, gl.RenderingContext>(
      );

  int _glContextId = 0;

  Expando _ids = new Expando('ids');

  factory WebGLContextManager() {
    throw new UnsupportedError(
        'WebGLContextManager cannot be instantiated, use WebGLContextManager.current');
  }

  WebGLContextManager._internal();

  int add(gl.RenderingContext context) {
    _ids[context] = _glContextId;
    _glContexts[_glContextId] = context;
    return _glContextId++;
  }

  gl.RenderingContext remove(int contextId) {
    var context = _glContexts.remove(contextId);
    _ids[context] = null;
    return context;
  }

  int id(gl.RenderingContext context) => _ids[context];

  gl.RenderingContext context(int contextId) => _glContexts[contextId];
}
