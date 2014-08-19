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
 * The base class for all objects that are rendered on the screen. 
 * This is an abstract class and should not be used on its own rather it should
 * be extended.
 */
abstract class DisplayObject {
  /**
   * The coordinate of the object relative to the local coordinates of the
   * parent.
   */
  Point<num> position = new Point<num>(0, 0);

  /// The scale factor of the object.
  Point<double> scale = new Point<double>(1.0, 1.0);

  /// The pivot point of the displayObject that it rotates around.
  Point<int> pivot = new Point<int>(0, 0);

  /// The rotation of the object in radians.
  double rotation = 0.0;

  // Cached rotation.
  double _rotationCache;

  /// The opacity of the object.
  double alpha = 1.0;

  /// The visibility of the object.
  bool visible = true;

  /**
   * This is the defined area that will pick up mouse / touch events. It is null
   * by default.
   * Setting it is a neat way of optimising the hitTest function that the
   * interactionManager will use (as it will not need to hit test all the
   * children).
   */
  Shape hitArea;

  /**
   * This is used to indicate if the displayObject should display a mouse hand
   * cursor on rollover.
   */
  bool buttonMode = false;

  /// Can this object be rendered.
  bool renderable = false;

  DisplayObjectContainer _parent;
  Stage _stage;
  double _worldAlpha = 1.0;
  bool _interactive = false;

  /**
   * This is the cursor that will be used when the mouse is over this object. To
   * enable this the element must have interaction = true and buttonMode = true.
   */
  String defaultCursor = 'pointer';

  Matrix _worldTransform = new Matrix();

  // cached sin rotation and cos rotation
  double _sr = 0.0;
  double _cr = 1.0;

  /**
   * The area the filter is applied to like the hitArea this is used as more of
   * an optimisation. Rather than figuring out the dimensions of the
   * displayObject each frame you can set this rectangle
   */
  Rectangle<int> filterArea;

  // The original, cached bounds of the object
  Rectangle<num> _bounds = new Rectangle<num>(0, 0, 1, 1);

  // The most up-to-date bounds of the object
  Rectangle<num> _currentBounds;

  // The original, cached mask of the object
  Graphics _mask;

  FilterBlock _filterBlock;
  List<Filter> _filters;
  Sprite _cachedSprite;

  bool _cacheAsBitmap = false;
  bool _cacheIsDirty = false;

  /// The display object container that contains this display object.
  DisplayObjectContainer get parent => _parent;

  /**
   * The stage the display object is connected to, or null if it is not
   * connected to the stage.
   */
  Stage get stage => _stage;

  /// The multiplied alpha of the displayObject
  double get worldAlpha => _worldAlpha;

  /**
   * Indicates if the sprite will have touch and mouse interactivity. It is
   * false by default.
   */
  bool get interactive => _interactive;

  /// Indicate if the sprite will have touch and mouse interactivity.
  void set interactive(bool value) {
    _interactive = value;

    // TODO: more to be done here...
    // Need to sort out a re-crawl!
    if (stage != null) stage._dirty = true;
  }

  /// Current transform of the object based on world (parent) factors.
  Matrix get worldTransform => _worldTransform;

  /// Indicates if the sprite is globally visible.
  bool get worldVisible {
    var item = this;

    do {
      if (!item.visible) return false;
      item = item._parent;
    } while (item != null);

    return true;
  }

  /// Returns the mask for this displayObject.
  Graphics get mask => _mask;

  /**
   * Sets a mask for the displayObject. A mask is an object that limits the
   * visibility of an object to the shape of the mask applied to it.
   * In PIXI a regular mask must be a [Graphics] object. This allows for much
   * faster masking in canvas as it utilises shape clipping.
   * To remove a mask, set this property to null.
   */
  void set mask(Graphics value) {
    if (_mask != null) _mask.isMask = false;
    _mask = value;
    if (_mask != null) _mask.isMask = true;
  }

  /// Returns the filters for this displayObject.
  List<Filter> get filters => _filters;

  /**
   * Sets the filters for the displayObject.
   * 
   * **IMPORTANT:** This is a webGL only feature and will be ignored by the
   * canvas renderer. To remove filters simply set this property to `null`.
   */
  void set filters(List<Filter> value) {
    if (value != null) {
      // Now put all the passes in one place...
      var passes = new List<Filter>();

      value.forEach((filter) {
        var filterPasses = filter._passes;

        filterPasses.forEach((filterPass) {
          passes.add(filterPass);
        });
      });

      // TODO: change this as it is legacy.
      _filterBlock = new FilterBlock(this, passes);
    }

    _filters = value;
  }

  /// Returns weather or not a the display objects is cached as a bitmap.
  bool get cacheAsBitmap => _cacheAsBitmap;

  /**
   * Set weather or not a the display objects is cached as a bitmap.
   * This basically takes a snap shot of the display object as it is at that
   * moment. It can provide a performance benefit for complex static
   * displayObjects.
   * To remove filters simply set this property to `null`.
   */
  void set cacheAsBitmap(bool value) {
    if (_cacheAsBitmap == value) return;

    if (value) {
      _generateCachedSprite();
    } else {
      _destroyCachedSprite();
    }

    _cacheAsBitmap = value;
  }

  // Updates the object transform for rendering.
  void _updateTransform() {
    // TODO: OPTIMIZE THIS!! with dirty.
    if (rotation != _rotationCache) {
      _rotationCache = rotation;
      _sr = math.sin(rotation);
      _cr = math.cos(rotation);
    }

    var parentTransform = _parent._worldTransform;
    var worldTransform = _worldTransform;

    var px = pivot.x;
    var py = pivot.y;

    var a00 = _cr * scale.x,
        a01 = -_sr * scale.y,
        a10 = _sr * scale.x,
        a11 = _cr * scale.y,
        a02 = position.x - a00 * px - py * a01,
        a12 = position.y - a11 * py - px * a10,
        b00 = parentTransform.a,
        b01 = parentTransform.b,
        b10 = parentTransform.c,
        b11 = parentTransform.d;

    worldTransform.a = b00 * a00 + b01 * a10;
    worldTransform.b = b00 * a01 + b01 * a11;
    worldTransform.tx = b00 * a02 + b01 * a12 + parentTransform.tx;

    worldTransform.c = b10 * a00 + b11 * a10;
    worldTransform.d = b10 * a01 + b11 * a11;
    worldTransform.ty = b10 * a02 + b11 * a12 + parentTransform.ty;

    _worldAlpha = alpha * _parent._worldAlpha;
  }

  /// Retrieves the bounds of the displayObject as a rectangle object.
  Rectangle<num> getBounds([Matrix matrix]) => new Rectangle<num>(0, 0, 0, 0);

  /// Retrieves the local bounds of the displayObject as a rectangle object.
  Rectangle<num> get getLocalBounds => getBounds(Matrix.identity);

  /// Sets the object's stage reference, the stage this object is connected to.
  void set setStageReference(Stage stage) {
    _stage = stage;
    if (_interactive) _stage._dirty = true;
  }

  /// Removes the current stage reference from the container.
  void removeStageReference();

  RenderTexture generateTexture(Renderer renderer) {
    var bounds = getLocalBounds;

    var renderTexture = new RenderTexture(bounds.width.truncate(),
        bounds.height.truncate(), renderer);
    renderTexture.render(this, new Point<int>(-bounds.left, -bounds.top));

    return renderTexture;
  }

  void updateCache() => _generateCachedSprite();

  void _renderCachedSprite(RenderSession renderSession) {
    _cachedSprite._worldAlpha = _worldAlpha;

    if (renderSession.context is gl.RenderingContext) {
      _cachedSprite._renderWebGL(renderSession);
    } else {
      _cachedSprite._renderCanvas(renderSession);
    }
  }

  void _generateCachedSprite() {
    _cacheAsBitmap = false;
    var bounds = getLocalBounds;

    if (_cachedSprite == null) {
      var renderTexture = new RenderTexture(bounds.width.truncate(),
          bounds.height.truncate());

      _cachedSprite = new Sprite(renderTexture);
      _cachedSprite._worldTransform = _worldTransform;
    } else {
      (_cachedSprite.texture as RenderTexture).resize(bounds.width.truncate(),
          bounds.height.truncate());
    }

    // REMOVE filter!
    var tempFilters = _filters;
    _filters = null;

    _cachedSprite.filters = tempFilters;
    (_cachedSprite.texture as RenderTexture).render(this, new Point<num>(
        -bounds.left, -bounds.top));

    _cachedSprite.anchor.x = -(bounds.left / bounds.width);
    _cachedSprite.anchor.y = -(bounds.top / bounds.height);

    _filters = tempFilters;

    _cacheAsBitmap = true;
  }

  void _destroyCachedSprite() {
    if (_cachedSprite == null) return;

    _cachedSprite.texture.destroy(true);
    // Let the gc collect the unused sprite.
    // TODO: could be object pooled!
    _cachedSprite = null;
  }

  // Renders the object using the WebGL renderer.
  void _renderWebGL(RenderSession renderSession);

  // Renders the object using the Canvas renderer
  void _renderCanvas(RenderSession renderSession);

  /**
   * Returns the position of the displayObject on the x axis relative to the
   * local coordinates of the parent.
   */
  num get x => position.x;

  /**
   * Sets the position of the displayObject on the x axis relative to the
   * local coordinates of the parent.
   */
  void set x(num value) {
    position.x = value;
  }

  /**
   * Returns the position of the displayObject on the y axis relative to the
   * local coordinates of the parent.
   */
  num get y => position.y;

  /**
   * Sets the position of the displayObject on the y axis relative to the
   * local coordinates of the parent.
   */
  void set y(num value) {
    position.y = value;
  }
}
