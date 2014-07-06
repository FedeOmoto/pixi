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

// TODO: document.
class FilterBlock {
  DisplayObject _target;
  List<Filter> _filterPasses;
  Rectangle<num> _filterArea;
  FilterTexture _glFilterTexture;

  bool visible = true;
  bool renderable = true;

  FilterBlock(this._target, this._filterPasses);

  DisplayObject get target => _target;
  List<Filter> get filterPasses => _filterPasses;
  Rectangle<num> get filterArea => _filterArea;
  FilterTexture get glFilterTexture => _glFilterTexture;
}
