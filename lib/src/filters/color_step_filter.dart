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
 * This lowers the color depth of your image by the given amount, producing an
 * image with a smaller palette.
 */
class ColorStepFilter extends Filter {
  ColorStepFilter() {
    // Set the uniforms.
    _uniforms.add(new Uniform1f('step', 5.0));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform sampler2D uSampler;
        uniform float step;

        void main(void) {
          vec4 color = texture2D(uSampler, vTextureCoord);
          color = floor(color * step) / step;
          gl_FragColor = color;
        }''';
  }

  /// Returns the number of steps.
  double get step => (_uniforms.first as Uniform1f).x;

  /// Sets the number of steps.
  void set step(double value) {
    (_uniforms.first as Uniform1f).x = value;
  }
}
