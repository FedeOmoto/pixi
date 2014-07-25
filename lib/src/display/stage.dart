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
 * A Stage represents the root of the display tree. Everything connected to the
 * stage is rendered.
 */
class Stage extends DisplayObjectContainer {
  /**
   * The interaction manager for this stage, manages all interactive activity on
   * the stage.
   */
  InteractionManager interactionManager;

  bool _dirty = true;

  /// The Stage background color.
  Color backgroundColor;

  bool _interactiveEventsAdded = false;

  List<double> backgroundColorSplit = new List<double>(3);

  /**
   * Creating a stage is a mandatory process when you use Pixi, which is as
   * simple as this: 
   * 
   *     var stage = new Stage(Color.white);
   * 
   * Where the parameter given is the background colour of the stage.
   * You will use this stage instance to add your sprites to it and therefore to
   * the renderer.
   * Here is how to add a sprite to the stage:
   * 
   *     stage.addChild(sprite);
   */
  Stage([this.backgroundColor]) {
    _interactive = true;
    interactionManager = new InteractionManager(this);

    // The stage is its own stage.
    _stage = this;

    // Optimize hit detection a bit.
    _stage.hitArea = new Rectangle<int>(0, 0, 100000, 100000);

    setBackgroundColor(backgroundColor);
  }

  /// Whether the stage is dirty and needs to have interactions updated.
  bool get dirty => _dirty;

  /**
   * Sets another [HtmlElement] which can receive mouse/touch interactions
   * instead of the default Canvas element.
   * This is useful for when you have other [HtmlElement]s on top of the Canvas
   * element.
   */
  void setInteractionDelegate(HtmlElement domElement) {
    interactionManager._setTargetDomElement(domElement);
  }

  // Updates the object transform for rendering.
  @override
  void _updateTransform() {
    _worldAlpha = 1.0;

    _children.forEach((child) => child._updateTransform());

    if (_dirty) {
      _dirty = false;

      // Update interactive!
      interactionManager._dirty = true;
    }

    if (_interactive) interactionManager._update();
  }

  /// Sets the background color for the stage.
  void setBackgroundColor(Color backgroundColor) {
    if (backgroundColor == null) this.backgroundColor = Color.black;

    var rgba = this.backgroundColor.rgba;

    backgroundColorSplit[0] = rgba.r / 255;
    backgroundColorSplit[1] = rgba.g / 255;
    backgroundColorSplit[2] = rgba.b / 255;
  }

  /// This will return the point containing global coords of the mouse.
  Point<int> get mousePosition => interactionManager.mouse.global;
}
