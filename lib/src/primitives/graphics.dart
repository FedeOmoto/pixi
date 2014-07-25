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
 * The Graphics class contains a set of methods that you can use to create
 * primitive shapes and lines.
 * It is important to know that with the webGL renderer only simple polygons can
 * be filled at this stage.
 * Complex polygons will not be filled. [Here](http://www.goodboydigital.com/
 * wp-content/uploads/2013/06/complexPolygon.png) is an example of a complex
 * polygon. 
 */
class Graphics extends DisplayObjectContainer {
  static const int POLY = 0;
  static const int RECT = 1;
  static const int CIRC = 2;
  static const int ELIP = 3;

  /// The alpha of the fill of this graphics object.
  double fillAlpha = 1.0;

  /// The width of any lines drawn.
  int lineWidth = 0;

  /// The color of any lines drawn.
  Color lineColor = Color.black;

  double lineAlpha;

  /// Graphics data.
  List<Path> graphicsData = new List<Path>();

  /// The tint applied to the graphic shape.
  Color tint = Color.white;

  /// The blend mode to be applied to the graphic shape.
  BlendModes<int> blendMode = BlendModes.NORMAL;

  /// Current path.
  Path currentPath = new Path();

  /// Map containing some WebGL-related properties used by the WebGL renderer.
  Map<int, WebGLProperties> _webGL = new Map<int, WebGLProperties>();

  /// Whether this shape is being used as a mask.
  bool isMask = false;

  /// The bounds of the graphic shape as rectangle object.
  Rectangle<int> bounds;

  /// The bounds' padding used for bounds calculation.
  int boundsPadding = 10;

  bool _dirty = false;
  bool _filling = false;
  Color _fillColor;
  bool _clearDirty = false;

  Graphics() {
    renderable = true;
  }

  /**
   * If cacheAsBitmap is true the graphics object will then be rendered as if it
   * was a sprite.
   * This is useful if your graphics element does not change often as it will
   * speed up the rendering of the object.
   * It is also usful as the graphics object will always be antialiased because
   * it will be rendered using canvas.
   * Not recommended if you are constanly redrawing the graphics element.
   */
  @override
  void set cacheAsBitmap(bool value) {
    bool oldValue = _cacheAsBitmap;

    super.cacheAsBitmap = value;
    if (!value && oldValue != value) _dirty = true;
  }

  /**
   * Specifies the line style used for subsequent calls to Graphics methods such
   * as the [lineTo] method or the [drawCircle] method.
   */
  Graphics lineStyle([int width = 0, Color color, double alpha = 1.0]) {
    if (currentPath.points.isEmpty) {
      if (graphicsData.isNotEmpty) graphicsData.removeLast();
    }

    lineWidth = width;
    lineColor = color == null ? Color.black : color;
    lineAlpha = alpha;

    currentPath = new Path(Path.POLY, lineWidth, lineColor, lineAlpha,
        _fillColor, fillAlpha, _filling);

    graphicsData.add(currentPath);

    return this;
  }

  /// Moves the current drawing position to (x, y).
  Graphics moveTo(int x, int y) {
    if (currentPath.points.isEmpty) {
      if (graphicsData.isNotEmpty) graphicsData.removeLast();
    }

    currentPath = new Path(Path.POLY, lineWidth, lineColor, lineAlpha,
        _fillColor, fillAlpha, _filling);

    currentPath.points.addAll([x, y]);

    graphicsData.add(currentPath);

    return this;
  }

  /**
   * Draws a line using the current line style from the current drawing position
   * to (x, y); the current drawing position is then set to (x, y).
   */
  Graphics lineTo(int x, int y) {
    currentPath.points.addAll([x, y]);
    _dirty = true;

    return this;
  }

  /**
   * Specifies a simple one-color fill that subsequent calls to other Graphics
   * methods (such as [lineTo] or [drawCircle]) use when drawing.
   */
  Graphics beginFill([Color color, double alpha = 1.0]) {
    _filling = true;
    _fillColor = color == null ? Color.black : color;
    fillAlpha = alpha;

    return this;
  }

  /**
   * Applies a fill to the lines and shapes that were added since the last call
   * to the [beginFill] method.
   */
  Graphics endFill() {
    _filling = false;
    _fillColor = null;
    fillAlpha = 1.0;

    return this;
  }

  /// Draws a rectangle.
  Graphics drawRect(int x, int y, int width, int height) {
    if (currentPath.points.isEmpty) {
      if (graphicsData.isNotEmpty) graphicsData.removeLast();
    }

    currentPath = new Path(Path.RECT, lineWidth, lineColor, lineAlpha,
        _fillColor, fillAlpha, _filling, [x, y, width, height]);

    graphicsData.add(currentPath);
    _dirty = true;

    return this;
  }

  /// Draws a circle.
  Graphics drawCircle(int x, int y, int radius) {
    if (currentPath.points.isEmpty) {
      if (graphicsData.isNotEmpty) graphicsData.removeLast();
    }

    currentPath = new Path(Path.CIRC, lineWidth, lineColor, lineAlpha,
        _fillColor, fillAlpha, _filling, [x, y, radius, radius]);

    graphicsData.add(currentPath);
    _dirty = true;

    return this;
  }

  /// Draws an ellipse.
  Graphics drawEllipse(int x, int y, int width, int height) {
    if (currentPath.points.isEmpty) {
      if (graphicsData.isNotEmpty) graphicsData.removeLast();
    }

    currentPath = new Path(Path.ELIP, lineWidth, lineColor, lineAlpha,
        _fillColor, fillAlpha, _filling, [x, y, width, height]);

    graphicsData.add(currentPath);
    _dirty = true;

    return this;
  }

  /**
   * Clears the graphics that were drawn to this Graphics object, and resets
   * fill and line style settings.
   */
  Graphics clear() {
    lineWidth = 0;
    _filling = false;

    _dirty = true;
    _clearDirty = true;
    graphicsData = new List<Path>();

    bounds = null;

    return this;
  }

  /**
   * Returns a texture of the graphics object that can then be used to create
   * sprites.
   * This can be quite useful if your geometry is complicated and needs to be
   * reused multiple times.
   */
  @override
  Texture generateTexture([Renderer renderer]) {
    var bounds = getBounds();

    var canvasBuffer = new CanvasBuffer(bounds.width, bounds.height);
    var texture = new Texture.fromCanvas(canvasBuffer.canvas);

    canvasBuffer.context.translate(-bounds.left, -bounds.top);

    CanvasGraphics.current._renderGraphics(this, canvasBuffer.context);

    return texture;
  }

  // Renders the object using the WebGL renderer.
  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    // If the sprite is not visible or the alpha is 0 then no need to render
    // this element.
    if (visible == false || alpha == 0 || isMask == true) return;

    if (_cacheAsBitmap) {
      if (_dirty) {
        _generateCachedSprite();

        // We will also need to update the texture on the GPU too!
        WebGLRenderer._updateWebGLTexture(_cachedSprite.texture.baseTexture,
            renderSession.context);

        _dirty = false;
      }

      _cachedSprite.alpha = alpha;
      _cachedSprite._renderWebGL(renderSession);

      return;
    } else {
      renderSession.spriteBatch.stop();

      if (_mask != null) {
        renderSession.maskManager.pushMask(_mask, renderSession);
      }

      if (_filters != null) {
        renderSession.filterManager.pushFilter(_filterBlock);
      }

      // Check blend mode.
      if (blendMode != renderSession.spriteBatch.currentBlendMode) {
        renderSession.spriteBatch.currentBlendMode = blendMode;
        var blendModeWebGL = WebGLRenderer.BLEND_MODES[blendMode.value];
        renderSession.spriteBatch.context.blendFunc(blendModeWebGL[0],
            blendModeWebGL[1]);
      }

      WebGLGraphics.current._renderGraphics(this, renderSession);

      // Only render if it has children!
      if (_children.isNotEmpty) {
        renderSession.spriteBatch.start();

        // Simple render children!
        _children.forEach((child) {
          child._renderWebGL(renderSession);
        });

        renderSession.spriteBatch.stop();
      }

      if (_filters != null) renderSession.filterManager.popFilter();
      if (_mask != null) renderSession.maskManager.popMask(renderSession);

      renderSession.drawCount++;

      renderSession.spriteBatch.start();
    }
  }

  // Renders the object using the Canvas renderer.
  @override
  void _renderCanvas(CanvasRenderSession renderSession) {
    // If the sprite is not visible or the alpha is 0 then no need to render
    // this element.
    if (visible == false || alpha == 0 || isMask == true) return;

    var context = renderSession.context;
    var transform = _worldTransform;

    if (blendMode != renderSession.currentBlendMode) {
      renderSession.currentBlendMode = blendMode;
      context.globalCompositeOperation =
          CanvasRenderer.BLEND_MODES[blendMode.value];
    }

    context.setTransform(transform.a, transform.c, transform.b, transform.d,
        transform.tx, transform.ty);
    CanvasGraphics.current._renderGraphics(this, context);

    // Simple render children!
    _children.forEach((child) {
      child._renderCanvas(renderSession);
    });
  }

  /// Retrieves the bounds of the graphic shape as a rectangle object.
  @override
  Rectangle<num> getBounds([Matrix matrix]) {
    if (bounds == null) updateBounds();

    var w0 = bounds.left;
    var w1 = bounds.width + bounds.left;

    var h0 = bounds.top;
    var h1 = bounds.height + bounds.top;

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

    var maxX = x1;
    var maxY = y1;

    var minX = x1;
    var minY = y1;

    minX = x2 < minX ? x2 : minX;
    minX = x3 < minX ? x3 : minX;
    minX = x4 < minX ? x4 : minX;

    minY = y2 < minY ? y2 : minY;
    minY = y3 < minY ? y3 : minY;
    minY = y4 < minY ? y4 : minY;

    maxX = x2 > maxX ? x2 : maxX;
    maxX = x3 > maxX ? x3 : maxX;
    maxX = x4 > maxX ? x4 : maxX;

    maxY = y2 > maxY ? y2 : maxY;
    maxY = y3 > maxY ? y3 : maxY;
    maxY = y4 > maxY ? y4 : maxY;

    _bounds.left = minX;
    _bounds.width = maxX - minX;

    _bounds.top = minY;
    _bounds.height = maxY - minY;

    return _bounds;
  }

  /// Update the bounds of the object.
  void updateBounds() {
    var minX = double.INFINITY;
    var maxX = double.NEGATIVE_INFINITY;

    var minY = double.INFINITY;
    var maxY = double.NEGATIVE_INFINITY;

    var points, x, y, w, h;

    graphicsData.forEach((data) {
      var type = data.type;
      var lineWidth = data.lineWidth;

      points = data.points;

      if (type == RECT) {
        x = points[0] - lineWidth / 2;
        y = points[1] - lineWidth / 2;
        w = points[2] + lineWidth;
        h = points[3] + lineWidth;

        minX = x < minX ? x : minX;
        maxX = x + w > maxX ? x + w : maxX;

        minY = y < minY ? x : minY;
        maxY = y + h > maxY ? y + h : maxY;
      } else if (type == CIRC || type == ELIP) {
        x = points[0];
        y = points[1];
        w = points[2] + lineWidth / 2;
        h = points[3] + lineWidth / 2;

        minX = x - w < minX ? x - w : minX;
        maxX = x + w > maxX ? x + w : maxX;

        minY = y - h < minY ? y - h : minY;
        maxY = y + h > maxY ? y + h : maxY;
      } else {
        // POLY.
        for (var j = 0; j < points.length; j += 2) {
          x = points[j];
          y = points[j + 1];
          minX = x - lineWidth < minX ? x - lineWidth : minX;
          maxX = x + lineWidth > maxX ? x + lineWidth : maxX;

          minY = y - lineWidth < minY ? y - lineWidth : minY;
          maxY = y + lineWidth > maxY ? y + lineWidth : maxY;
        }
      }
    });

    var padding = boundsPadding;
    bounds = new Rectangle(minX - padding, minY - padding, (maxX - minX) +
        padding * 2, (maxY - minY) + padding * 2);
  }

  // Generates the cached sprite when the sprite has cacheAsBitmap = true.
  void _generateCachedSprite() {
    var bounds = getLocalBounds;

    if (_cachedSprite == null) {
      var canvasBuffer = new CanvasBuffer(bounds.width, bounds.height);
      var texture = new Texture.fromCanvas(canvasBuffer.canvas);

      _cachedSprite = new Sprite(texture);
      _cachedSprite.buffer = canvasBuffer;

      _cachedSprite._worldTransform = _worldTransform;
    } else {
      _cachedSprite.buffer.resize(bounds.width, bounds.height);
    }

    // Leverage the anchor to account for the offset of the element.
    _cachedSprite.anchor.x = -(bounds.left / bounds.width);
    _cachedSprite.anchor.y = -(bounds.top / bounds.height);

    (_cachedSprite.buffer.context as CanvasRenderingContext2D).translate(
        -bounds.left, -bounds.top);

    CanvasGraphics.current._renderGraphics(this, _cachedSprite.buffer.context);
    _cachedSprite.alpha = alpha;
  }

  void destroyCachedSprite() {
    _cachedSprite.texture.destroy(true);

    // Let the GC collect the unused sprite.
    // TODO: could be object pooled!
    _cachedSprite = null;
  }
}
