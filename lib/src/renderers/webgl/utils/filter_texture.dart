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
class FilterTexture extends TextureBuffer {
  gl.Framebuffer frameBuffer;

  gl.Texture texture;

  gl.Renderbuffer renderBuffer;

  FilterTexture(gl.RenderingContext context, int width, int
      height, [ScaleModes<int> scaleMode = ScaleModes.DEFAULT]) {
    this.context = context;

    // Next time to create a frame buffer and texture.
    frameBuffer = context.createFramebuffer();
    texture = context.createTexture();

    context.bindTexture(gl.TEXTURE_2D, texture);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, scaleMode ==
        ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, scaleMode ==
        ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);

    context.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
    context.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0,
        gl.TEXTURE_2D, texture, 0);

    // Required for masking a mask??
    renderBuffer = context.createRenderbuffer();
    context.bindRenderbuffer(gl.RENDERBUFFER, renderBuffer);
    context.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT,
        gl.RENDERBUFFER, renderBuffer);

    resize(width, height);
  }

  /// Clears the filter texture.
  @override
  void clear() {
    var context = this.context as gl.RenderingContext;

    context.clearColor(0, 0, 0, 0);
    context.clear(gl.COLOR_BUFFER_BIT);
  }

  /// Resizes the texture to the specified width and height.
  @override
  void resize(int width, int height) {
    if (this.width == width && this.height == height) return;

    this.width = width;
    this.height = height;

    var context = this.context as gl.RenderingContext;

    context.bindTexture(gl.TEXTURE_2D, texture);
    context.texImage2DTyped(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0,
        gl.RGBA, gl.UNSIGNED_BYTE, null);

    // Update the stencil buffer width and height.
    context.bindRenderbuffer(gl.RENDERBUFFER, renderBuffer);
    context.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_STENCIL, width, height
        );
  }

  /// Destroys the filter texture.
  void destroy() {
    var context = this.context as gl.RenderingContext;

    context.deleteFramebuffer(frameBuffer);
    context.deleteTexture(texture);

    frameBuffer = null;
    texture = null;
  }
}
