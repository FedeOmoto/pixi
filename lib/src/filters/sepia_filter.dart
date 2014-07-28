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

/// This applies a sepia effect to your displayObjects.
class SepiaFilter extends Filter {
  SepiaFilter() {
    // Set the uniforms.
    _uniforms.add(new Uniform1f('sepia', 1.0));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform float sepia;
        uniform sampler2D uSampler;

        const mat3 sepiaMatrix = mat3(0.3588, 0.7044, 0.1368, 0.2990, 0.5870, 0.1140, 0.2392, 0.4696, 0.0912);

        void main(void) {
          gl_FragColor = texture2D(uSampler, vTextureCoord);
          gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb * sepiaMatrix, sepia);
        }''';
  }

  /// Returns the strength of the sepia.
  double get sepia => (_uniforms.first as Uniform1f).x;

  /**
   * Sets the strength of the sepia. 1 will apply the full sepia effect, 0 will
   * make the object its normal color.
   */
  void set sepia(double value) {
    (_uniforms.first as Uniform1f).x = value;
  }
}
