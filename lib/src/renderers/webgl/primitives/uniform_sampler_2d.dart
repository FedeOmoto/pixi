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
class UniformSampler2D extends Uniform {
  static int _textureCount = 0;

  Texture value;
  bool _init = false;

  UniformSampler2D(String name, this.value) : super(gl.SAMPLER_2D, name);

  /// Initialises this uniform.
  void init(gl.RenderingContext context) {
    if (value == null || value.baseTexture == null ||
        !value.baseTexture._hasLoaded) {
      return;
    }

    var contextId = WebGLContextManager.current.id(context);

    context.activeTexture(gl.TEXTURE0 + ++_textureCount);
    context.bindTexture(gl.TEXTURE_2D, value.baseTexture._glTextures[contextId]
        );

    // TODO: Extended texture data -> ???

    context.uniform1i(location, _textureCount);

    _init = true;
  }

  @override
  void sync(gl.RenderingContext context) {
    if (!_init) return init(context);

    var contextId = WebGLContextManager.current.id(context);
    var texture = value.baseTexture._glTextures[contextId];

    if (texture == null) {
      texture = WebGLRenderer._createWebGLTexture(value.baseTexture, context);
    }

    context.activeTexture(gl.TEXTURE0 + ++_textureCount);
    context.bindTexture(gl.TEXTURE_2D, texture);
    context.uniform1i(location, _textureCount);
  }
}
