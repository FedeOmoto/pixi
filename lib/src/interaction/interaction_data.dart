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

/// Holds all information related to an Interaction event.
class InteractionData {
  /**
   * This point stores the global coords of where the touch/mouse event
   * happened.
   */
  Point<num> global = new Point<num>(0, 0);

  /// The target [DisplayObjectContainer] that was interacted with.
  DisplayObjectContainer target;

  /**
   * When passed to an event handler, this will be the original DOM Event that
   * was captured.
   */
  UIEvent originalEvent;

  /**
   * This will return the local coordinates of the specified
   * [DisplayObjectContainer] for this InteractionData.
   */
  Point<num> getLocalPosition(DisplayObjectContainer displayObject) {
    var worldTransform = displayObject._worldTransform;

    // Do a cheeky transform to get the mouse coords.
    var a00 = worldTransform.a,
        a01 = worldTransform.b,
        a02 = worldTransform.tx,
        a10 = worldTransform.c,
        a11 = worldTransform.d,
        a12 = worldTransform.ty,
        id = 1 / (a00 * a11 + a01 * -a10);

    // Set the mouse coords.
    return new Point<num>(a11 * id * global.x + -a01 * id * global.y + (a12 *
        a01 - a02 * a11) * id, a00 * id * global.y + -a10 * id * global.x + (-a12 * a00
        + a02 * a10) * id);
  }
}
