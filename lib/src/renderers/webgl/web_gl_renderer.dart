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
class WebGLRenderer extends Renderer {
  // TODO

  static const List<List<int>> BLEND_MODES = const <List<int>>[const
      <int>[gl.ONE, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.SRC_ALPHA, gl.DST_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.SRC_ALPHA,
      gl.ONE], const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const
      <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR,
      gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR,
      gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR,
      gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR,
      gl.ONE_MINUS_SRC_ALPHA], const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA]];
}
