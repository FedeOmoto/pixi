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
class BlurYFilter extends Filter {
  BlurYFilter() {
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
          vec4 sum = vec4(0.0);

          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y - 4.0 * blur)) * 0.05;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y - 3.0 * blur)) * 0.09;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y - 2.0 * blur)) * 0.12;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y - blur)) * 0.15;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y)) * 0.16;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y + blur)) * 0.15;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y + 2.0 * blur)) * 0.12;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y + 3.0 * blur)) * 0.09;
          sum += texture2D(uSampler, vec2(vTextureCoord.x, vTextureCoord.y + 4.0 * blur)) * 0.05;

          gl_FragColor = sum;
        }''';
  }

  double get blur => (_uniforms.first as Uniform1f).x / (1 / 7000);

  void set blur(double value) {
    (_uniforms.first as Uniform1f).x = (1 / 7000) * value;
  }
}
