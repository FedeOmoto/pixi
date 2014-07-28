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
 * This is the base class for creating a pixi filter. Currently only webGL
 * supports filters.
 * If you want to make a custom filter this should be your base class.
 */
abstract class Filter {
  // A list of passes - some filters contain a few steps this array simply
  // stores the steps in a liniear fashion.
  // For example the blur filter has two passes blurX and blurY.
  List<Filter> _passes = new List<Filter>();

  Map<int, Shader> _shaders = new Map<int, Shader>();
  bool _dirty = true;
  int _padding = 0;
  List<Uniform> _uniforms = new List<Uniform>();
  String _fragmentSrc;

  Filter() {
    _passes.add(this);
  }
}
