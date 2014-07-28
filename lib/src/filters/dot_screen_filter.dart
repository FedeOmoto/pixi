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
 * This filter applies a dotscreen effect making display objects appear to be
 * made out of black and white halftone dots like an old printer.
 */
class DotScreenFilter extends Filter {
  DotScreenFilter() {
    // Set the uniforms.
    _uniforms
        ..add(new Uniform1f('scale', 1.0))
        ..add(new Uniform1f('angle', 5.0))
        ..add(new Uniform4fv('dimensions', [0.0, 0.0, 0.0, 0.0]));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform vec4 dimensions;
        uniform sampler2D uSampler;

        uniform float angle;
        uniform float scale;

        float pattern() {
          float s = sin(angle), c = cos(angle);
          vec2 tex = vTextureCoord * dimensions.xy;
          vec2 point = vec2(
              c * tex.x - s * tex.y,
              s * tex.x + c * tex.y
          ) * scale;
          return (sin(point.x) * sin(point.y)) * 4.0;
        }

        void main() {
          vec4 color = texture2D(uSampler, vTextureCoord);
          float average = (color.r + color.g + color.b) / 3.0;
          gl_FragColor = vec4(vec3(average * 10.0 - 5.0 + pattern()), color.a);
        }''';
  }

  /// Returns the scale.
  double get scale => (_uniforms.first as Uniform1f).x;

  /// Sets the scale.
  void set scale(double value) {
    _dirty = true;
    (_uniforms.first as Uniform1f).x = value;
  }

  /// Returns the angle.
  double get angle => (_uniforms[1] as Uniform1f).x;

  /// Sets the angle.
  void set angle(double value) {
    _dirty = true;
    (_uniforms[1] as Uniform1f).x = value;
  }
}
