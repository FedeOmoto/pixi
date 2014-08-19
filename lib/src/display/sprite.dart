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
 * The Sprite object is the base for all textured objects that are rendered to
 * the screen.
 */
class Sprite extends DisplayObjectContainer {
  /**
   * The anchor sets the origin point of the texture.
   * The default is 0,0 this means the texture's origin is the top left.
   * Setting than anchor to 0.5,0.5 means the textures origin is centred.
   * Setting the anchor to 1,1 would mean the textures origin points will be the
   * bottom right corner.
   */
  Point<double> anchor = new Point<double>(0.0, 0.0);

  /// The texture that the sprite is using.
  Texture texture;

  // The width of the sprite (this is initially set by the texture).
  int _width = 0;

  // The height of the sprite (this is initially set by the texture)
  int _height = 0;

  /// The tint applied to the sprite.
  Color tint = Color.white;

  /// The blend mode to be applied to the sprite.
  BlendModes<int> blendMode = BlendModes.NORMAL;

  /// Whether this sprite is renderable or not.
  bool renderable = true;

  bool _textureChange = false;

  Color _cachedTint;

  CanvasElement _tintedTexture;

  CanvasBuffer buffer;

  /**
   * A sprite can be created directly from an image like this: 
   * 
   *     var sprite = new Sprite.fromImage('assets/image.png');
   *     yourStage.addChild(sprite);
   * 
   * then obviously don't forget to add it to the stage you have already
   * created.
   */
  Sprite(this.texture) {
    if (texture.baseTexture._hasLoaded) {
      _onTextureUpdate();
    } else {
      texture.addEventListener('update', _onTextureUpdate);
    }
  }

  /**
   * Creates a sprite that will contain a texture from the TextureCache based on
   * the frameId.
   * The frame ids are created when a Texture packer file has been loaded.
   */
  factory Sprite.fromFrame(String frameId) {
    var texture = Texture._cache[frameId];

    if (texture == null) {
      throw new StateError(
          'The frameId "$frameId" does not exist in the texture cache.');
    }

    return new Sprite(texture);
  }

  /**
   * Creates a sprite that will contain a texture based on an image url.
   * If the image is not in the texture cache it will be loaded.
   */
  factory Sprite.fromImage(String imageId, [bool crossorigin, ScaleModes<int>
      scaleMode = ScaleModes.DEFAULT]) {
    var texture = new Texture.fromImage(imageId, crossorigin, scaleMode);
    return new Sprite(texture);
  }

  /// The width of the sprite.
  int get width => (scale.x * texture.frame.width).toInt();

  /**
   * The width of the sprite, setting this will actually modify the scale to
   * achieve the value set.
   */
  void set width(int value) {
    scale.x = value / texture.frame.width;
    _width = value;
  }

  /// The height of the sprite.
  int get height => (scale.y * texture.frame.height).toInt();

  /**
   * The height of the sprite, setting this will actually modify the scale to
   * achieve the value set.
   */
  void set height(int value) {
    scale.y = value / texture.frame.height;
    _height = value;
  }

  /// Sets the texture of the sprite.
  void setTexture(Texture texture) {
    this.texture = texture;
    _cachedTint = Color.white;
  }

  // When the texture is updated, this event will fire to update the scale and
  // frame.
  void _onTextureUpdate([CustomEvent event]) {
    // So if _width is 0 then width was not set...
    if (_width != 0) scale.x = _width / texture.frame.width;
    if (_height != 0) scale.y = _height / texture.frame.height;
  }

  /// Returns the framing rectangle of the sprite as a [Rectangle] object.
  @override
  Rectangle<num> getBounds([Matrix matrix]) {
    var w0 = texture.frame.width * (1 - anchor.x);
    var w1 = texture.frame.width * -anchor.x;

    var h0 = texture.frame.height * (1 - anchor.y);
    var h1 = texture.frame.height * -anchor.y;

    var worldTransform = matrix == null ? _worldTransform : matrix;

    var a = worldTransform.a;
    var b = worldTransform.c;
    var c = worldTransform.b;
    var d = worldTransform.d;
    var tx = worldTransform.tx;
    var ty = worldTransform.ty;

    var x1 = a * w1 + c * h1 + tx;
    var y1 = d * h1 + b * w1 + ty;

    var x2 = a * w0 + c * h1 + tx;
    var y2 = d * h1 + b * w0 + ty;

    var x3 = a * w0 + c * h0 + tx;
    var y3 = d * h0 + b * w0 + ty;

    var x4 = a * w1 + c * h0 + tx;
    var y4 = d * h0 + b * w1 + ty;

    var maxX = double.NEGATIVE_INFINITY;
    var maxY = double.NEGATIVE_INFINITY;

    var minX = double.INFINITY;
    var minY = double.INFINITY;

    minX = x1 < minX ? x1 : minX;
    minX = x2 < minX ? x2 : minX;
    minX = x3 < minX ? x3 : minX;
    minX = x4 < minX ? x4 : minX;

    minY = y1 < minY ? y1 : minY;
    minY = y2 < minY ? y2 : minY;
    minY = y3 < minY ? y3 : minY;
    minY = y4 < minY ? y4 : minY;

    maxX = x1 > maxX ? x1 : maxX;
    maxX = x2 > maxX ? x2 : maxX;
    maxX = x3 > maxX ? x3 : maxX;
    maxX = x4 > maxX ? x4 : maxX;

    maxY = y1 > maxY ? y1 : maxY;
    maxY = y2 > maxY ? y2 : maxY;
    maxY = y3 > maxY ? y3 : maxY;
    maxY = y4 > maxY ? y4 : maxY;

    _bounds.left = minX;
    _bounds.width = maxX - minX;

    _bounds.top = minY;
    _bounds.height = maxY - minY;

    // Store a reference so that if this function gets called again in the
    // render cycle we do not have to recalculate.
    _currentBounds = _bounds;

    return _bounds;
  }

  // Renders the object using the WebGL renderer.
  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    // If the sprite is not visible or the alpha is 0 then no need to render
    // this element.
    if (!visible || alpha <= 0) return;

    // Do a quick check to see if this element has a mask or a filter.
    if (_mask != null || _filters != null) {
      var spriteBatch = renderSession.spriteBatch;

      // Push filter first as we need to ensure the stencil buffer is correct
      // for any masking
      if (_filters != null) {
        spriteBatch.flush();
        renderSession.filterManager.pushFilter(_filterBlock);
      }

      if (_mask != null) {
        spriteBatch.stop();
        renderSession.maskManager.pushMask(_mask, renderSession);
        spriteBatch.start();
      }

      // Add this sprite to the batch.
      spriteBatch.render(this);

      // Now loop through the children and make sure they get rendered.
      _children.forEach((child) => child._renderWebGL(renderSession));

      // Time to stop the sprite batch as either a mask element or a filter draw
      // will happen next.
      spriteBatch.stop();

      if (_mask != null) renderSession.maskManager.popMask(_mask, renderSession
          );
      if (_filters != null) renderSession.filterManager.popFilter();

      spriteBatch.start();
    } else {
      renderSession.spriteBatch.render(this);

      // Simple render children!
      _children.forEach((child) => child._renderWebGL(renderSession));
    }

    // TODO: Check culling.
  }

  // Renders the object using the Canvas renderer.
  @override
  void _renderCanvas(CanvasRenderSession renderSession) {
    // If the sprite is not visible or the alpha is 0 then no need to render
    // this element.
    if (visible == false || alpha == 0) return;

    var context = renderSession.context as CanvasRenderingContext2D;

    if (blendMode != renderSession.currentBlendMode) {
      renderSession.currentBlendMode = blendMode;
      context.globalCompositeOperation =
          CanvasRenderer.BLEND_MODES[renderSession.currentBlendMode.value];
    }

    if (_mask != null) renderSession.maskManager.pushMask(_mask, renderSession);

    // Ignore null sources.
    if (texture._valid) {
      context.globalAlpha = _worldAlpha;

      // Allow for pixel rounding.
      if (renderSession.roundPixels) {
        context.setTransform(_worldTransform.a, _worldTransform.c,
            _worldTransform.b, _worldTransform.d, _worldTransform.tx.truncate(),
            _worldTransform.ty.truncate());
      } else {
        context.setTransform(_worldTransform.a, _worldTransform.c,
            _worldTransform.b, _worldTransform.d, _worldTransform.tx, _worldTransform.ty);
      }

      // If we need to change the smoothing property for this texture.
      if (renderSession.scaleMode != texture.baseTexture.scaleMode) {
        renderSession.scaleMode = texture.baseTexture.scaleMode;
        context.imageSmoothingEnabled = (renderSession.scaleMode ==
            ScaleModes.LINEAR);
      }

      //  If the texture is trimmed we offset by the trim x/y, otherwise we use
      // the frame dimensions.
      double dx = (texture.trim != null) ? texture.trim.left - anchor.x *
          texture.trim.width : anchor.x * -texture.frame.width;
      double dy = (texture.trim != null) ? texture.trim.top - anchor.y *
          texture.trim.height : anchor.y * -texture.frame.height;

      if (tint != Color.white) {
        if (_cachedTint != tint) {
          _cachedTint = tint;

          // TODO: clean up caching - how to clean up the caches?
          _tintedTexture = CanvasTinter.current.getTintedTexture(this, tint);
        }

        context.drawImageScaledFromSource(_tintedTexture, 0, 0,
            texture.crop.width, texture.crop.height, dx, dy, texture.crop.width,
            texture.crop.height);
      } else {
        context.drawImageScaledFromSource(texture.baseTexture.source,
            texture.crop.left, texture.crop.top, texture.crop.width, texture.crop.height,
            dx, dy, texture.crop.width, texture.crop.height);
      }
    }

    // OVERWRITE
    _children.forEach((child) => child._renderCanvas(renderSession));

    if (_mask != null) renderSession.maskManager.popMask(renderSession);
  }
}
