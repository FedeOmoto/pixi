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
class WebGLBlendModeManager {
  gl.RenderingContext context;

  BlendModes<int> currentBlendMode = const BlendModes(99999);

  WebGLBlendModeManager(this.context);

  /// Sets-up the given blendMode from WebGL's point of view.
  bool setBlendMode(BlendModes<int> blendMode) {
    if (currentBlendMode == blendMode) return false;

    currentBlendMode = blendMode;

    var blendModeWebGL = WebGLRenderer.BLEND_MODES[currentBlendMode.value];
    context.blendFunc(blendModeWebGL[0], blendModeWebGL[1]);

    return true;
  }

  void destroy() => context = null;
}
