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

/// This turns your displayObjects to black and white.
class GrayFilter extends Filter {
  GrayFilter() {
    // Set the uniforms.
    _uniforms.add(new Uniform1f('gray', 1.0));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform sampler2D uSampler;
        uniform float gray;

        void main(void) {
          gl_FragColor = texture2D(uSampler, vTextureCoord);
          gl_FragColor.rgb = mix(gl_FragColor.rgb, vec3(0.2126 * gl_FragColor.r + 0.7152 * gl_FragColor.g + 0.0722 * gl_FragColor.b), gray);
        }''';
  }

  /// Returns the strength of the gray.
  double get gray => (_uniforms.first as Uniform1f).x;

  /**
   * Sets the strength of the gray. 1 will make the object black and white, 0
   * will make the object its normal color.
   */
  void set gray(double value) {
    (_uniforms.first as Uniform1f).x = value;
  }
}
