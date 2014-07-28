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
 * The [ColorMatrixFilter] class lets you apply a 4x4 matrix transformation on
 * the RGBA color and alpha values of every pixel on your displayObject to
 * produce a result with a new set of RGBA color and alpha values. Its pretty
 * powerful!
 */
class ColorMatrixFilter extends Filter {
  ColorMatrixFilter() {
    // Set the uniforms.
    _uniforms.add(new UniformMatrix4fv('matrix', [1.0, 0.0, 0.0, 0.0, 0.0, 1.0,
        0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]));

    _fragmentSrc =
        '''
      precision mediump float;
      varying vec2 vTextureCoord;
      varying vec4 vColor;
      uniform float invert;
      uniform mat4 matrix;
      uniform sampler2D uSampler;

      void main(void) {
        gl_FragColor = texture2D(uSampler, vTextureCoord) * matrix;
      }''';
  }

  /// Returns the matrix of the color matrix filter.
  Float32List get matrix => (_uniforms.first as UniformMatrix4fv).value;

  /// Sets the matrix of the color matrix filter.
  void set matrix(Float32List value) {
    (_uniforms.first as UniformMatrix4fv).value = value;
  }
}
