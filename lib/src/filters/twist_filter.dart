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
 * This filter applies a twist effect making display objects appear twisted in
 * the given direction.
 */
class TwistFilter extends Filter {
  TwistFilter() {
    // Set the uniforms.
    _uniforms
        ..add(new Uniform1f('radius', 0.5))
        ..add(new Uniform1f('angle', 5.0))
        ..add(new Uniform2f('offset', 0.5, 0.5));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform vec4 dimensions;
        uniform sampler2D uSampler;

        uniform float radius;
        uniform float angle;
        uniform vec2 offset;

        void main(void) {
          vec2 coord = vTextureCoord - offset;
          float distance = length(coord);

          if (distance < radius) {
            float ratio = (radius - distance) / radius;
            float angleMod = ratio * ratio * angle;
            float s = sin(angleMod);
            float c = cos(angleMod);
            coord = vec2(coord.x * c - coord.y * s, coord.x * s + coord.y * c);
          }

          gl_FragColor = texture2D(uSampler, coord+offset);
        }''';
  }

  Uniform2f get _offset {
    return _uniforms.firstWhere((uniform) => uniform.name == 'offset');
  }

  Uniform1f get _radius {
    return _uniforms.firstWhere((uniform) => uniform.name == 'radius');
  }

  Uniform1f get _angle {
    return _uniforms.firstWhere((uniform) => uniform.name == 'angle');
  }

  /// Returns the the offset of the twist.
  Uniform2f get offset => _uniforms.last;

  /// Returns the x offset of the twist.
  double get offsetX => (_uniforms.last as Uniform2f).x;

  /// Sets the x offset of the twist.
  void set offsetX(double value) {
    _dirty = true;
    (_uniforms.last as Uniform2f).x = value;
  }

  /// Returns the y offset of the twist.
  double get offsetY => (_uniforms.last as Uniform2f).y;

  /// Sets the y offset of the twist.
  void set offsetY(double value) {
    _dirty = true;
    (_uniforms.last as Uniform2f).y = value;
  }

  /// Returns the size of the twist.
  double get radius => (_uniforms.first as Uniform1f).x;

  /// Sets the size of the twist
  void set radius(double value) {
    _dirty = true;
    (_uniforms.first as Uniform1f).x = value;
  }

  /// Returns the angle of the twist.
  double get angle => (_uniforms[1] as Uniform1f).x;

  /// Sets the angle of the twist
  void set angle(double value) {
    _dirty = true;
    (_uniforms[1] as Uniform1f).x = value;
  }
}
