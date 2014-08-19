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

/// A tiling sprite is a fast way of rendering a tiling image.
class TilingSprite extends Sprite {
  /// The scaling of the image that is being tiled.
  Point<double> tileScale = new Point<double>(1.0, 1.0);

  /// A point that represents the scale of the texture object.
  Point<double> tileScaleOffset = new Point<double>(1.0, 1.0);

  /// The offset position of the image that is being tiled.
  Point<num> tilePosition = new Point<num>(0, 0);

  bool _refreshTexture = false;
  Texture tilingTexture;
  TextureUvs _uvs;
  CanvasPattern _tilePattern;

  TilingSprite(Texture texture, [int width = 100, int height = 100]) : super(
      texture) {
    _width = width;
    _height = height;
  }

  /// The width of the sprite.
  @override
  int get width => _width;

  /**
   * The width of the sprite, setting this will actually modify the scale to
   * achieve the value set.
   */
  @override
  void set width(int value) {
    _width = value;
  }

  /// The height of the sprite.
  @override
  int get height => _height;

  /**
   * The height of the sprite, setting this will actually modify the scale to
   * achieve the value set.
   */
  @override
  void set height(int value) {
    _height = value;
  }

  @override
  void setTexture(Texture texture) {
    if (this.texture == texture) return;
    this.texture = texture;
    _refreshTexture = true;
    _cachedTint = Color.white;
  }

  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    if (visible == false || alpha == 0) return;

    if (_mask != null) {
      renderSession.spriteBatch.stop();
      renderSession.maskManager.pushMask(_mask, renderSession);
      renderSession.spriteBatch.start();
    }

    if (_filters != null) {
      renderSession.spriteBatch.flush();
      renderSession.filterManager.pushFilter(_filterBlock);
    }

    if (tilingTexture == null || _refreshTexture) {
      generateTilingTexture(true);

      if (tilingTexture != null && tilingTexture._needsUpdate) {
        // TODO: tweaking.
        WebGLRenderer._updateWebGLTexture(tilingTexture.baseTexture,
            renderSession.context);
        tilingTexture._needsUpdate = false;
      }
    } else {
      renderSession.spriteBatch.renderTilingSprite(this);
    }

    // Simple render children!
    _children.forEach((child) => child._renderWebGL(renderSession));

    renderSession.spriteBatch.stop();

    if (_filters != null) renderSession.filterManager.popFilter();
    if (_mask != null) renderSession.maskManager.popMask(_mask, renderSession);

    renderSession.spriteBatch.start();
  }

  @override
  void _renderCanvas(CanvasRenderSession renderSession) {
    if (visible == false || alpha == 0) return;

    var context = renderSession.context as CanvasRenderingContext2D;

    if (_mask != null) renderSession.maskManager.pushMask(_mask, renderSession);

    context.globalAlpha = _worldAlpha;

    context.setTransform(_worldTransform.a, _worldTransform.c,
        _worldTransform.b, _worldTransform.d, _worldTransform.tx, _worldTransform.ty);

    if (_tilePattern == null || _refreshTexture) {
      generateTilingTexture(false);

      if (tilingTexture != null) {
        _tilePattern = context.createPatternFromImage(
            tilingTexture.baseTexture.source, 'repeat');
      } else {
        return;
      }
    }

    // Check blend mode.
    if (blendMode != renderSession.currentBlendMode) {
      renderSession.currentBlendMode = blendMode;
      context.globalCompositeOperation =
          CanvasRenderer.BLEND_MODES[renderSession.currentBlendMode.value];
    }

    tilePosition.x %= tilingTexture.baseTexture.width;
    tilePosition.y %= tilingTexture.baseTexture.height;

    // Offset.
    context.scale(tileScale.x, tileScale.y);
    context.translate(tilePosition.x, tilePosition.y);

    context.fillStyle = _tilePattern;

    // Make sure to account for the anchor point.
    context.fillRect(-tilePosition.x + (anchor.x * -_width), -tilePosition.y +
        (anchor.y * -_height), _width / tileScale.x, _height / tileScale.y);

    context.scale(1 / tileScale.x, 1 / tileScale.y);
    context.translate(-tilePosition.x, -tilePosition.y);

    if (_mask != null) renderSession.maskManager.popMask(renderSession);

    _children.forEach((child) => child._renderCanvas(renderSession));

  }

  @override
  Rectangle<num> getBounds([Matrix matrix]) {
    var w0 = _width * (1 - anchor.x);
    var w1 = _width * -anchor.x;

    var h0 = _height * (1 - anchor.y);
    var h1 = _height * -anchor.y;

    var a = _worldTransform.a;
    var b = _worldTransform.c;
    var c = _worldTransform.b;
    var d = _worldTransform.d;
    var tx = _worldTransform.tx;
    var ty = _worldTransform.ty;

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

  // When the texture is updated, this event will fire to update the scale and
  // frame.
  @override
  void _onTextureUpdate([CustomEvent event]) {
    // Overriding the sprite version of this!
  }

  void generateTilingTexture(bool forcePowerOfTwo) {
    if (!texture.baseTexture._hasLoaded) return;

    var baseTexture = texture.baseTexture;
    var frame = texture.frame;

    var targetWidth, targetHeight;

    var newTextureRequired = false;

    if (!forcePowerOfTwo) {
      // Check that the frame is the same size as the base texture.
      if (frame.width != baseTexture.width || frame.height !=
          baseTexture.height) {
        targetWidth = frame.width;
        targetHeight = frame.height;

        newTextureRequired = true;
      }
    } else {
      targetWidth = math.pow(2, (math.log(frame.width) / math.log(2)).ceil());
      targetHeight = math.pow(2, (math.log(frame.height) / math.log(2)).ceil());

      if (frame.width != targetWidth || frame.height != targetHeight) {
        newTextureRequired = true;
      }
    }

    if (newTextureRequired) {
      var canvasBuffer;

      if (tilingTexture != null && tilingTexture._isTiling) {
        canvasBuffer = tilingTexture._canvasBuffer;
        canvasBuffer.resize(targetWidth, targetHeight);
        tilingTexture.baseTexture._width = targetWidth;
        tilingTexture.baseTexture._height = targetHeight;
        tilingTexture._needsUpdate = true;
      } else {
        canvasBuffer = new CanvasBuffer(targetWidth, targetHeight);

        tilingTexture = new Texture.fromCanvas(canvasBuffer.canvas);
        tilingTexture._canvasBuffer = canvasBuffer;
        tilingTexture._isTiling = true;
      }

      (canvasBuffer.context as
          CanvasRenderingContext2D).drawImageScaledFromSource(texture.baseTexture.source,
          texture.crop.left, texture.crop.top, texture.crop.width, texture.crop.height, 0,
          0, targetWidth, targetHeight);

      tileScaleOffset.x = frame.width / targetWidth;
      tileScaleOffset.y = frame.height / targetHeight;
    } else {
      // TODO: switching?
      if (tilingTexture != null && tilingTexture._isTiling) {
        // Destroy the tiling texture!
        // TODO: could store this somewhere?
        tilingTexture.destroy(true);
      }

      tileScaleOffset.x = 1.0;
      tileScaleOffset.y = 1.0;
      tilingTexture = texture;
    }

    _refreshTexture = false;
    tilingTexture.baseTexture._powerOf2 = true;
  }
}
