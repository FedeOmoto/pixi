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
class RgbSplitFilter extends Filter {
  RgbSplitFilter() {
    // Set the uniforms.
    _uniforms
        ..add(new Uniform2f('red', 20.0, 20.0))
        ..add(new Uniform2f('green', -20.0, 20.0))
        ..add(new Uniform2f('blue', 20.0, -20.0))
        ..add(new Uniform4fv('dimensions', [0.0, 0.0, 0.0, 0.0]));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform vec2 red;
        uniform vec2 green;
        uniform vec2 blue;
        uniform vec4 dimensions;
        uniform sampler2D uSampler;

        void main(void) {
          gl_FragColor.r = texture2D(uSampler, vTextureCoord + red / dimensions.xy).r;
          gl_FragColor.g = texture2D(uSampler, vTextureCoord + green / dimensions.xy).g;
          gl_FragColor.b = texture2D(uSampler, vTextureCoord + blue / dimensions.xy).b;
          gl_FragColor.a = texture2D(uSampler, vTextureCoord).a;
        }''';
  }
}
