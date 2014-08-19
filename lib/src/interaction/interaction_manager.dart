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
 * The interaction manager deals with mouse and touch events. Any
 * [DisplayObject] can be interactive if its interactive parameter is set to
 * true.
 * This manager also supports multitouch.
 */
class InteractionManager {
  /// Interaction frequency.
  static const int INTERACTION_FREQUENCY = 30;

  static const bool AUTO_PREVENT_DEFAULT = true;

  /// A reference to the stage.
  Stage stage;

  /// The mouse data.
  InteractionData mouse = new InteractionData();

  /// A map that stores current touches (InteractionData) by id reference.
  Map<int, InteractionData> touchs = new Map<int, InteractionData>();

  Point<int> _tempPoint = new Point<int>(0, 0);

  bool mouseoverEnabled = true;

  /// Tiny little interactiveData pool!
  List<InteractionData> pool = new List<InteractionData>();

  /// A list containing all the iterative items from our interactive tree.
  List<DisplayObjectContainer> interactiveItems =
      new List<DisplayObjectContainer>();

  /// Our canvas.
  HtmlElement interactionDOMElement;

  int last = 0;

  /// The css style of the cursor that is being used.
  String currentCursorStyle = 'inherit';

  /// Is set to true when the mouse is moved out of the canvas.
  bool mouseOut = false;

  // The target for event delegation.
  Renderer _target;

  List<StreamSubscription<UIEvent>> _listeners =
      new List<StreamSubscription<UIEvent>>();

  bool _dirty = false;

  InteractionManager(this.stage);

  bool get dirty => _dirty;

  // Collects an interactive sprite recursively to have their interactions
  // managed.
  void _collectInteractiveSprite(DisplayObjectContainer
      displayObject, DisplayObjectContainer iParent) {
    var children = displayObject._children;

    // Make an interaction tree.
    for (int i = children.length - 1; i >= 0; i--) {
      var child = children[i];

      // Add all interactive bits.
      if (child._interactive) {
        iParent._interactiveChildren = true;
        interactiveItems.add(child);
        if (child.children.isNotEmpty) _collectInteractiveSprite(child, child);
      } else {
        if (child.children.isNotEmpty) {
          _collectInteractiveSprite(child, iParent);
        }
      }

    }
  }

  // Sets the target for event delegation.
  void set _setTarget(Renderer target) {
    _target = target;

    // Check if the dom element has been set. If it has don't do anything.
    if (interactionDOMElement == null) _setTargetDomElement(target.view);
  }

  // Sets the DOM element which will receive mouse/touch events. This is useful
  // for when you have other DOM elements on top of the renderers Canvas
  // element. With this you'll be able to delegate another DOM element to
  // receive those events.
  void _setTargetDomElement(HtmlElement domElement) {
    _removeEvents();

    interactionDOMElement = domElement;

    _listeners.add(domElement.onMouseMove.listen(_onMouseMove));
    _listeners.add(domElement.onMouseDown.listen(_onMouseDown));
    _listeners.add(domElement.onMouseOut.listen(_onMouseOut));

    // Aint no multi touch just yet!
    _listeners.add(domElement.onTouchStart.listen(_onTouchStart));
    _listeners.add(domElement.onTouchEnd.listen(_onTouchEnd));
    _listeners.add(domElement.onTouchMove.listen(_onTouchMove));

    _listeners.add(window.onMouseUp.listen(_onMouseUp));
  }

  void _removeEvents() {
    if (interactionDOMElement == null) return;

    _listeners.forEach((listener) => listener.cancel());

    _listeners.clear();
    interactionDOMElement = null;
  }

  // Updates the state of interactive objects.
  void _update() {
    if (_target == null) return;

    // Frequency of 30fps??
    var now = new DateTime.now().millisecondsSinceEpoch;
    var diff = now - last;
    diff = (diff * INTERACTION_FREQUENCY) / 1000;
    if (diff < 1) return;
    last = now;

    // Ok... so mouse events??
    // Yes for now :)
    // TODO: OPTIMISE - how often to check??
    if (_dirty) _rebuildInteractiveGraph();

    // Loop through interactive objects!
    var cursor = 'inherit';
    bool over = false;

    interactiveItems.forEach((item) {
      item._hit = _hitTest(item, mouse);
      mouse.target = item;

      // Ok so deal with interactions.
      // Looks like there was a hit!
      if (item._hit && !over) {
        if (item.buttonMode) cursor = item.defaultCursor;
        if (!item._interactiveChildren) over = true;

        if (!item._isOver) {
          if (item.onMouseOver._listeners != 0) item.onMouseOver._add(mouse);
          item._isOver = true;
        }
      } else {
        if (item._isOver) {
          if (item.onMouseOut._listeners != 0) item.onMouseOut._add(mouse);
          item._isOver = false;
        }
      }
    });

    if (currentCursorStyle != cursor) {
      currentCursorStyle = cursor;
      interactionDOMElement.style.cursor = cursor;
    }
  }

  void _rebuildInteractiveGraph() {
    _dirty = false;

    interactiveItems.forEach((item) => item._interactiveChildren = false);

    interactiveItems.clear();

    if (stage._interactive) interactiveItems.add(stage);

    // Go through and collect all the objects that are interactive.
    _collectInteractiveSprite(stage, stage);
  }

  // Is called when the mouse moves across the renderer element.
  void _onMouseMove(MouseEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    mouse.originalEvent = event;

    // TODO: optimize by not check EVERY TIME! Maybe half as often?
    var rect = interactionDOMElement.getBoundingClientRect();

    mouse.global.x = (event.client.x - rect.left) * (_target.width /
        rect.width);
    mouse.global.y = (event.client.y - rect.top) * (_target.height /
        rect.height);

    interactiveItems.forEach((item) {
      if (item.onMouseMove._listeners != 0) {
        item.onMouseMove._add(mouse..target = item);
      }
    });
  }

  // Is called when the mouse button is pressed down on the renderer element.
  void _onMouseDown(MouseEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    mouse.originalEvent = event;

    if (AUTO_PREVENT_DEFAULT) mouse.originalEvent.preventDefault();

    // Loop through interaction tree.
    // TODO: optimize
    for (var item in interactiveItems) {
      if (item.onMouseDown._listeners != 0 || item.onClick._listeners != 0) {
        item._mouseIsDown = true;
        item._hit = _hitTest(item, mouse);

        if (item._hit) {
          if (item.onMouseDown._listeners != 0) item.onMouseDown._add(mouse);
          item._isDown = true;

          // Just the one!
          if (!item._interactiveChildren) break;
        }
      }
    }
  }

  // Is called when the mouse button is moved out of the renderer element.
  void _onMouseOut(MouseEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    mouse.originalEvent = event;

    interactionDOMElement.style.cursor = 'inherit';

    interactiveItems.forEach((item) {
      if (item._isOver) {
        mouse.target = item;
        if (item.onMouseOut._listeners != 0) item.onMouseOut._add(mouse);
        item._isOver = false;
      }
    });

    mouseOut = true;

    // Move the mouse to an impossible position.
    mouse.global.x = -10000;
    mouse.global.y = -10000;
  }

  // Is called when the mouse button is released on the renderer element.
  void _onMouseUp(MouseEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    mouse.originalEvent = event;

    bool up = false;

    interactiveItems.forEach((item) {
      item._hit = _hitTest(item, mouse);

      if (item._hit && !up) {
        if (item.onMouseUp._listeners != 0) item.onMouseUp._add(mouse);

        if (item._isDown) {
          if (item.onClick._listeners != 0) item.onClick._add(mouse);
        }

        if (!item._interactiveChildren) up = true;
      } else {
        if (item._isDown) {
          if (item.onMouseUpOutside._listeners != 0) {
            item.onMouseUpOutside._add(mouse);
          }
        }
      }

      item._isDown = false;
    });
  }

  // Tests if the current mouse coordinates hit a sprite.
  bool _hitTest(DisplayObjectContainer item, InteractionData interactionData) {
    var global = interactionData.global;

    if (!item.worldVisible) return false;

    var isSprite = (item is Sprite),
        worldTransform = item._worldTransform,
        a00 = worldTransform.a,
        a01 = worldTransform.b,
        a02 = worldTransform.tx,
        a10 = worldTransform.c,
        a11 = worldTransform.d,
        a12 = worldTransform.ty,
        id = 1 / (a00 * a11 + a01 * -a10),
        x = a11 * id * global.x + -a01 * id * global.y + (a12 * a01 - a02 * a11)
            * id,
        y = a00 * id * global.y + -a10 * id * global.x + (-a12 * a00 + a02 *
            a10) * id;

    interactionData.target = item;

    // A sprite or display object with a hit area defined.
    if (item.hitArea != null) {
      if (item.hitArea.containsPoint(new Point<num>(x, y))) {
        interactionData.target = item;
        return true;
      }

      return false;
    } else if (isSprite) { // A sprite with no hitarea defined.
      var sprite = item as Sprite;
      var width = sprite.texture.frame.width,
          height = sprite.texture.frame.height,
          x1 = -width * sprite.anchor.x,
          y1;

      if (x > x1 && x < x1 + width) {
        y1 = -height * sprite.anchor.y;

        if (y > y1 && y < y1 + height) {
          // Set the target property if a hit is true!
          interactionData.target = sprite;
          return true;
        }
      }
    }

    item.children.forEach((tempItem) {
      var hit = _hitTest(tempItem, interactionData);

      if (hit) {
        // Hmm... TODO: SET CORRECT TARGET?
        interactionData.target = item;
        return true;
      }
    });

    return false;
  }

  // Is called when a touch is moved across the renderer element.
  void _onTouchMove(TouchEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    var rect = interactionDOMElement.getBoundingClientRect();
    var changedTouches = event.changedTouches;
    var touchData;

    changedTouches.forEach((touchEvent) {
      touchData = touchs[touchEvent.identifier];
      touchData.originalEvent = event;

      // Update the touch position.
      touchData.global.x = (touchEvent.client.x - rect.left) * (_target.width /
          rect.width);
      touchData.global.y = (touchEvent.client.y - rect.top) * (_target.height /
          rect.height);

      // TODO: Add support for CocoonJS?
      //if(navigator.isCocoonJS) ...

      interactiveItems.forEach((item) {
        if (item.onTouchMove._listeners != 0 &&
            item._touchData[touchEvent.identifier] != null) {
          item.onTouchMove._add(touchData);
        }
      });
    });
  }

  // Is called when a touch is started on the renderer element.
  void _onTouchStart(TouchEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    var rect = interactionDOMElement.getBoundingClientRect();

    if (AUTO_PREVENT_DEFAULT) event.preventDefault();

    var changedTouches = event.changedTouches;

    changedTouches.forEach((touchEvent) {
      InteractionData touchData;

      if (pool.isNotEmpty) {
        touchData = pool.removeLast();
      } else {
        touchData = new InteractionData();
      }

      touchData.originalEvent = event;

      touchs[touchEvent.identifier] = touchData;
      touchData.global.x = (touchEvent.client.x - rect.left) * (_target.width /
          rect.width);
      touchData.global.y = (touchEvent.client.y - rect.top) * (_target.height /
          rect.height);

      // TODO: Add support for CocoonJS?
      //if(navigator.isCocoonJS) ...

      for (var item in interactiveItems) {
        if (item.onTouchStart._listeners != 0 || item.onTap._listeners != 0) {
          item._hit = _hitTest(item, touchData);

          if (item._hit) {
            if (item.onTouchStart._listeners != 0) {
              item.onTouchStart._add(touchData);
            }

            item._isDown = true;
            item._touchData[touchEvent.identifier] = touchData;

            if (!item._interactiveChildren) break;
          }
        }
      }
    });
  }

  // Is called when a touch is ended on the renderer element.
  void _onTouchEnd(TouchEvent event) {
    if (_dirty) _rebuildInteractiveGraph();

    var rect = interactionDOMElement.getBoundingClientRect();
    var changedTouches = event.changedTouches;

    changedTouches.forEach((touchEvent) {
      var touchData = touchs[touchEvent.identifier];
      var up = false;

      touchData.global.x = (touchEvent.client.x - rect.left) * (_target.width /
          rect.width);
      touchData.global.y = (touchEvent.client.y - rect.top) * (_target.height /
          rect.height);

      // TODO: Add support for CocoonJS?
      //if(navigator.isCocoonJS) ...

      interactiveItems.forEach((item) {
        if (item._touchData[touchEvent.identifier] != null) {
          item._hit = _hitTest(item, item._touchData[touchEvent.identifier]);

          // So this one WAS down...
          touchData.originalEvent = event;

          if (item.onTouchEnd._listeners != 0 || item.onTap._listeners != 0) {
            if (item._hit && !up) {
              if (item.onTouchEnd._listeners != 0) {
                item.onTouchEnd._add(touchData);
              }

              if (item._isDown) {
                if (item.onTap._listeners != 0) item.onTap._add(touchData);
              }

              if (!item._interactiveChildren) up = true;
            } else {
              if (item._isDown) {
                if (item.onTouchEndOutside._listeners != 0) {
                  item.onTouchEndOutside._add(touchData);
                }
              }
            }

            item._isDown = false;
          }

          item._touchData.remove(touchEvent.identifier);
        }
      });

      // Remove the touch.
      pool.add(touchData);
      touchs.remove(touchEvent.identifier);
    });
  }
}
