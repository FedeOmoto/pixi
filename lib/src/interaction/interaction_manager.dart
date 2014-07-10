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
  // TODO

  /// A reference to the stage.
  Stage stage;

  /// The mouse data.
  InteractionData mouse = new InteractionData();

  bool _dirty = false;

  InteractionManager(this.stage);

  bool get dirty => _dirty;

  void _update() {
    // TODO
  }

  void _setTarget(Renderer target) {
    // TODO
  }

  void removeEvents() {
    // TODO
  }

  void _setTargetDomElement(HtmlElement domElement) {
    // TODO
  }
}
