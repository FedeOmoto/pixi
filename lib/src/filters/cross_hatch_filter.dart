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
class CrossHatchFilter extends Filter {
  CrossHatchFilter() {
    // Set the uniforms.
    _uniforms.add(new Uniform1f('blur', 1 / 512));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform float blur;
        uniform sampler2D uSampler;

        void main(void) {
          float lum = length(texture2D(uSampler, vTextureCoord.xy).rgb);

          gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);

          if (lum < 1.00) {
            if (mod(gl_FragCoord.x + gl_FragCoord.y, 10.0) == 0.0) {
              gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            }
          }

          if (lum < 0.75) {
            if (mod(gl_FragCoord.x - gl_FragCoord.y, 10.0) == 0.0) {
              gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            }
          }

          if (lum < 0.50) {
            if (mod(gl_FragCoord.x + gl_FragCoord.y - 5.0, 10.0) == 0.0) {
              gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            }
          }

          if (lum < 0.3) {
            if (mod(gl_FragCoord.x - gl_FragCoord.y - 5.0, 10.0) == 0.0) {
              gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
            }
          }
        }''';
  }

  double get blur => (_uniforms.first as Uniform1f).x / (1 / 7000);

  void set blur(double value) {
    (_uniforms.first as Uniform1f).x = (1 / 7000) * value;
  }
}
