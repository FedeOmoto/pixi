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

typedef void RenderMethod(DisplayObjectContainer displayObject, [Point<int>
    position, bool clear]);

/**
 * A RenderTexture is a special texture that allows any pixi displayObject to be
 * rendered to it.
 *
 * **Hint**: All DisplayObjects (exmpl. Sprites) that render on RenderTexture
 * should be preloaded. Otherwise black rectangles will be drawn instead.
 *
 * RenderTexture takes snapshot of [DisplayObjectContainer] passed to render
 * method. If DisplayObjectContainer is passed to render method, position and
 * rotation of it will be ignored. For example:
 *
 *     var renderTexture = new RenderTexture(800, 600);
 *     var sprite = new Sprite.fromImage('spinObj_01.png');
 *     sprite.position.x = 800 / 2;
 *     sprite.position.y = 600 / 2;
 *     sprite.anchor.x = 0.5;
 *     sprite.anchor.y = 0.5;
 *     renderTexture.render(sprite);
 *
 * [Sprite] in this case will be rendered to 0,0 position. To render this sprite
 * at center [DisplayObjectContainer] should be used:
 *
 *     var doc = new DisplayObjectContainer();
 *     doc.addChild(sprite);
 *     renderTexture.render(doc); // Renders to center of renderTexture
 */
class RenderTexture extends Texture {
  static Matrix _tempMatrix = new Matrix();

  Renderer renderer;
  TextureBuffer textureBuffer;
  Point<double> projection;

  /// This method will draw the display object to the texture.
  RenderMethod render;

  RenderTexture([int width = 100, int height = 100, Renderer
      renderer, ScaleModes<int> scaleMode]) : super(new BaseTexture(),
      new Rectangle<int>(0, 0, width, height)) {
    _width = frame.width;
    _height = frame.height;

    crop.width = _width;
    crop.height = _height;

    baseTexture._width = _width;
    baseTexture._height = _height;
    baseTexture._hasLoaded = true;

    // Each render texture can only belong to one renderer at the moment if its
    // webGL.
    this.renderer = renderer == null ? Renderer._defaultRenderer : renderer;

    if (this.renderer.type == Renderer.WEBGL_RENDERER) {
      textureBuffer = new FilterTexture(this.renderer.context as
          gl.RenderingContext, _width, _height, baseTexture.scaleMode);
      baseTexture._glTextures[(this.renderer as WebGLRenderer).contextId] =
          (textureBuffer as FilterTexture).texture;

      render = _renderWebGL;
      projection = new Point<double>(_width / 2, -_height / 2);
    } else {
      render = _renderCanvas;
      textureBuffer = new CanvasBuffer(_width, _height);
      baseTexture.source = (textureBuffer as CanvasBuffer).canvas;
    }

    _valid = true;

    Texture._frameUpdates.add(this);
  }

  /// Resize the [RenderTexture].
  void resize(int width, int height, [bool updateBase = false]) {
    if (width == _width && height == _height) return;

    _width = frame.width = crop.width = width;
    _height = frame.height = crop.height = height;

    if (updateBase) {
      baseTexture._width = _width;
      baseTexture._height = _height;
    }

    if (renderer.type == Renderer.WEBGL_RENDERER) {
      projection.x = _width / 2;
      projection.y = -_height / 2;
    }

    textureBuffer.resize(_width, _height);
  }

  /// Clears the [RenderTexture].
  void clear() {
    if (renderer.type == Renderer.WEBGL_RENDERER) {
      var context = renderer.context as gl.RenderingContext;
      var textureBuffer = this.textureBuffer as FilterTexture;
      context.bindFramebuffer(gl.FRAMEBUFFER, textureBuffer.frameBuffer);
    }

    textureBuffer.clear();
  }

  // This method will draw the display object to the texture.
  void _renderWebGL(DisplayObjectContainer displayObject, [Point<num>
      position, bool clear = false]) {
    // TODO: replace position with matrix...
    var context = this.renderer.context as gl.RenderingContext;

    var textureBuffer = this.textureBuffer as FilterTexture;

    context.colorMask(true, true, true, true);

    context.viewport(0, 0, _width, _height);

    context.bindFramebuffer(gl.FRAMEBUFFER, textureBuffer.frameBuffer);

    if (clear) textureBuffer.clear();

    // TODO: -? create a new one??? dont think so!
    var originalWorldTransform = displayObject._worldTransform;
    displayObject._worldTransform = _tempMatrix;
    // Modify to flip...
    displayObject._worldTransform.d = -1.0;
    displayObject._worldTransform.ty = projection.y * -2;

    if (position != null) {
      displayObject._worldTransform.tx = position.x.toDouble();
      displayObject._worldTransform.ty -= position.y;
    }

    displayObject._children.forEach((child) => child._updateTransform());

    // Update the textures!
    WebGLRenderer._updateTextures();

    var renderer = this.renderer as WebGLRenderer;

    renderer.spriteBatch._dirty = true;

    renderer._renderDisplayObject(displayObject, projection,
        textureBuffer.frameBuffer);

    displayObject._worldTransform = originalWorldTransform;

    renderer.spriteBatch._dirty = true;
  }

  // This method will draw the display object to the texture.
  void _renderCanvas(DisplayObjectContainer displayObject, [Point<num>
      position, bool clear = false]) {
    var originalWorldTransform = displayObject._worldTransform;

    displayObject._worldTransform = _tempMatrix;

    if (position != null) {
      displayObject._worldTransform.tx = position.x.toDouble();
      displayObject._worldTransform.ty = position.y.toDouble();
    } else {
      displayObject._worldTransform.tx = 0.0;
      displayObject._worldTransform.ty = 0.0;
    }

    displayObject._children.forEach((child) => child._updateTransform());

    if (clear) textureBuffer.clear();

    var context = textureBuffer.context as CanvasRenderingContext2D;

    (renderer as CanvasRenderer)._renderDisplayObject(displayObject, context);

    context.setTransform(1, 0, 0, 1, 0, 0);

    displayObject._worldTransform = originalWorldTransform;
  }
}
