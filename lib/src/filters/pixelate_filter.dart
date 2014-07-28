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
 * This filter applies a pixelate effect making display objects appear 'blocky'.
 */
class PixelateFilter extends Filter {
  PixelateFilter() {
    // Set the uniforms.
    _uniforms
        ..add(new Uniform1f('invert', 0.0))
        ..add(new Uniform4fv('dimensions', [10000.0, 100.0, 10.0, 10.0]))
        ..add(new Uniform2f('pixelSize', 10.0, 10.0));

    _fragmentSrc =
        '''
      precision mediump float;
      varying vec2 vTextureCoord;
      varying vec4 vColor;
      uniform vec2 testDim;
      uniform vec4 dimensions;
      uniform vec2 pixelSize;
      uniform sampler2D uSampler;

      void main(void) {
        vec2 coord = vTextureCoord;
        vec2 size = dimensions.xy/pixelSize;
        vec2 color = floor((vTextureCoord * size)) / size + pixelSize/dimensions.xy * 0.5;
        gl_FragColor = texture2D(uSampler, color);
      }''';
  }

  /**
   * Returns a point that describes the size of the blocks. x is the width of
   * the block and y is the the height.
   */
  Uniform2f get size => _uniforms[2];

  /// Returns the width (x) of the block.
  double get sizeX => (_uniforms[2] as Uniform2f).x;

  /// Sets the width (x) of the block.
  void set sizeX(double value) {
    (_uniforms[2] as Uniform2f).x = value;
  }

  /// Returns the height (y) of the block.
  double get sizeY => (_uniforms[2] as Uniform2f).y;

  /// Sets the height (y) of the block.
  void set sizeY(double value) {
    (_uniforms[2] as Uniform2f).y = value;
  }
}
