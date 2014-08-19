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
 * A DisplayObjectContainer represents a collection of display objects.
 * It is the base class of all display objects that act as a container for other
 * objects.
 */
class DisplayObjectContainer extends DisplayObject {
  List<DisplayObject> _children = new List<DisplayObject>();

  /// The array of children of this container.
  List<DisplayObject> get children => _children;

  /// Stream of `mouseover` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onMouseOver = new InteractionEventStream(
      'mouseover');

  /// Stream of `mouseout` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onMouseOut = new InteractionEventStream(
      'mouseout');

  /// Stream of `mousemove` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onMouseMove = new InteractionEventStream(
      'mousemove');

  /// Stream of `mousedown` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onMouseDown = new InteractionEventStream(
      'mousedown');

  /// Stream of `mouseup` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onMouseUp = new InteractionEventStream('mouseup'
      );

  /**
   * Stream of `mouseupoutside` events handled by this [DisplayObjectContainer].
   */
  final InteractionEventStream onMouseUpOutside = new InteractionEventStream(
      'mouseup');

  /// Stream of `click` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onClick = new InteractionEventStream('mouseup');

  /// Stream of `touchmove` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onTouchMove = new InteractionEventStream(
      'touchmove');

  /// Stream of `touchstart` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onTouchStart = new InteractionEventStream(
      'touchstart');

  /// Stream of `touchend` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onTouchEnd = new InteractionEventStream(
      'touchend');

  /**
   * Stream of `touchendoutside` events handled by this
   * [DisplayObjectContainer].
   */
  final InteractionEventStream onTouchEndOutside = new InteractionEventStream(
      'touchend');

  /// Stream of `tap` events handled by this [DisplayObjectContainer].
  final InteractionEventStream onTap = new InteractionEventStream('touchend');

  bool _interactiveChildren = false;

  bool _hit = false;

  bool _isOver = false;

  bool _mouseIsDown = false;

  bool _isDown = false;

  Map<int, InteractionData> _touchData = new Map<int, InteractionData>();

  num _width;
  num _height;

  /// Returns the width of the [DisplayObjectContainer].
  num get width => scale.x * getLocalBounds.width;

  /**
   * Sets the width of the [DisplayObjectContainer], setting this will actually
   * modify the scale to achieve the value set.
   */
  void set width(num value) {
    num width = getLocalBounds.width;

    if (width != 0) {
      scale.x = value / (width / scale.x);
    } else {
      scale.x = 1.0;
    }

    _width = value;
  }

  /// Returns the height of the [DisplayObjectContainer].
  num get height => scale.y * getLocalBounds.height;

  /**
   * Sets the height of the [DisplayObjectContainer], setting this will actually
   * modify the scale to achieve the value set.
   */
  void set height(num value) {
    num height = getLocalBounds.height;

    if (height != 0) {
      scale.y = value / (height / scale.y);
    } else {
      scale.y = 1.0;
    }

    _height = value;
  }

  /// Adds a child to the container.
  DisplayObject addChild(DisplayObject child) {
    return addChildAt(child, _children.length);
  }

  /**
   * Adds a child to the container at a specified index. If the index is out of
   * bounds a [RangeError] will be thrown.
   */
  DisplayObject addChildAt(DisplayObject child, int index) {
    if (index >= 0 && index <= _children.length) {
      if (child._parent != null) child._parent.removeChild(child);
      child._parent = this;
      _children.insert(index, child);
      if (_stage != null) child.setStageReference = _stage;
      return child;
    } else {
      throw new RangeError(
          'The index $index supplied is out of bounds ${_children.length}.');
    }
  }

  /// Swaps the depth of 2 displayObjects.
  void swapChildren(DisplayObject child1, DisplayObject child2) {
    if (child1 == child2) return;

    var index1 = _children.indexOf(child1);
    var index2 = _children.indexOf(child2);

    if (index1 < 0 || index2 < 0) {
      throw new RangeError(
          'swapChildren: Both the supplied DisplayObjects must be a child of the caller.'
          );
    }

    _children[index1] = child2;
    _children[index2] = child1;
  }

  /// Returns the child at the specified index.
  DisplayObject getChildAt(int index) {
    if (index >= 0 && index < _children.length) {
      return _children[index];
    } else {
      throw new RangeError(
          'Supplied index does not exist in the child list, or the supplied DisplayObject must be a child of the caller.'
          );
    }
  }

  /// Removes a child from the container.
  DisplayObject removeChild(DisplayObject child) {
    return removeChildAt(_children.indexOf(child));
  }

  /**
   * Removes a child from the specified index position in the child list of the
   * container.
   */
  DisplayObject removeChildAt(int index) {
    var child = getChildAt(index);
    if (_stage != null) child.removeStageReference();
    child._parent = null;
    _children.removeAt(index);

    return child;
  }

  /// Removes all child instances from the child list of the container.
  Iterable<DisplayObject> removeChildren([int beginIndex = 0, int endIndex]) {
    endIndex = endIndex == null ? _children.length : endIndex;
    var range = endIndex - beginIndex;

    if (range > 0 && range <= endIndex) {
      var removed = _children.getRange(beginIndex, range);

      removed.forEach((child) {
        if (stage != null) child.removeStageReference();
        child._parent = null;
      });

      return removed;
    } else {
      throw new RangeError(
          'Range Error, numeric values are outside the acceptable range.');
    }
  }

  // Updates the container's childrens transform for rendering.
  @override
  void _updateTransform() {
    if (!visible) return;
    super._updateTransform();
    if (_cacheAsBitmap) return;

    _children.forEach((child) => child._updateTransform());
  }

  /// Retrieves the bounds of the displayObjectContainer as a rectangle object.
  @override
  Rectangle<num> getBounds([Matrix matrix]) {
    if (_children.isEmpty) return new Rectangle<num>(0, 0, 0, 0);

    // TODO: the bounds have already been calculated this render session so
    // return what we have.
    if (matrix != null) {
      var matrixCache = _worldTransform;
      _worldTransform = matrix;
      _updateTransform();
      _worldTransform = matrixCache;
    }

    var minX = double.INFINITY;
    var minY = double.INFINITY;

    var maxX = double.NEGATIVE_INFINITY;
    var maxY = double.NEGATIVE_INFINITY;

    var childBounds;
    var childMaxX;
    var childMaxY;

    var childVisible = false;

    for (var child in _children) {
      if (!child.visible) continue;

      childVisible = true;

      childBounds = child.getBounds(matrix);

      minX = minX < childBounds.left ? minX : childBounds.left;
      minY = minY < childBounds.top ? minY : childBounds.top;

      childMaxX = childBounds.width + childBounds.left;
      childMaxY = childBounds.height + childBounds.top;

      maxX = maxX > childMaxX ? maxX : childMaxX;
      maxY = maxY > childMaxY ? maxY : childMaxY;
    }

    if (!childVisible) return new Rectangle<num>(0, 0, 0, 0);

    _bounds.left = minX;
    _bounds.top = minY;
    _bounds.width = maxX - minX;
    _bounds.height = maxY - minY;

    // TODO: store a reference so that if this function gets called again in
    // the render cycle we do not have to recalculate.
    // this._currentBounds = _bounds;

    return _bounds;
  }

  @override
  Rectangle<num> get getLocalBounds {
    var matrixCache = _worldTransform;
    _worldTransform = Matrix.identity;

    _children.forEach((child) => child._updateTransform());

    var bounds = getBounds();
    _worldTransform = matrixCache;

    return bounds;
  }

  @override
  void set setStageReference(Stage stage) {
    super.setStageReference = stage;
    _children.forEach((child) => child.setStageReference = stage);
  }

  @override
  void removeStageReference() {
    _children.forEach((child) => child.removeStageReference());

    if (_interactive) _stage._dirty = true;

    _stage = null;
  }

  // Renders the object using the WebGL renderer.
  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    if (!visible || alpha <= 0) return;

    if (_cacheAsBitmap) {
      _renderCachedSprite(renderSession);
      return;
    }

    if (_mask != null || _filters != null) {
      // Push filter first as we need to ensure the stencil buffer is correct
      // for any masking.
      if (_filters != null) {
        renderSession.spriteBatch.flush();
        renderSession.filterManager.pushFilter(_filterBlock);
      }

      if (_mask != null) {
        renderSession.spriteBatch.stop();
        renderSession.maskManager.pushMask(_mask, renderSession);
        renderSession.spriteBatch.start();
      }

      // Simple render children!
      _children.forEach((child) => child._renderWebGL(renderSession));

      renderSession.spriteBatch.stop();

      if (_mask != null) {
        renderSession.maskManager.popMask(_mask, renderSession);
      }

      if (_filters != null) renderSession.filterManager.popFilter();

      renderSession.spriteBatch.start();
    } else {
      // Simple render children!
      _children.forEach((child) => child._renderWebGL(renderSession));
    }
  }

  // Renders the object using the Canvas renderer.
  @override
  void _renderCanvas(CanvasRenderSession renderSession) {
    if (visible == false || alpha == 0) return;

    if (_cacheAsBitmap) {
      _renderCachedSprite(renderSession);
      return;
    }

    if (_mask != null) renderSession.maskManager.pushMask(_mask, renderSession);

    _children.forEach((child) => child._renderCanvas(renderSession));

    if (_mask != null) renderSession.maskManager.popMask(renderSession);
  }
}
