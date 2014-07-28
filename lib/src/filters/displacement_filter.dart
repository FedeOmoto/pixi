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
 * The [DisplacementFilter] class uses the pixel values from the specified
 * texture (called the displacement map) to perform a displacement of an object.
 * You can use this filter to apply all manor of crazy warping effects.
 * Currently the r property of the texture is used to offset the x and the g
 * propery of the texture is used to offset the y.
 */
class DisplacementFilter extends Filter {
  DisplacementFilter(Texture texture) {
    texture.baseTexture._powerOf2 = true;

    // Set the uniforms.
    _uniforms
        ..add(new UniformSampler2D('displacementMap', texture))
        ..add(new Uniform2f('scale', 30.0, 30.0))
        ..add(new Uniform2f('offset', 0.0, 0.0))
        ..add(new Uniform2f('mapDimensions', 1.0, 5112.0))
        ..add(new Uniform4fv('dimensions', [0.0, 0.0, 0.0, 0.0]));

    if (texture.baseTexture.hasLoaded) {
      var mapDimensions = _uniforms[3] as Uniform2f;

      mapDimensions.x = texture.width.toDouble();
      mapDimensions.y = texture.height.toDouble();
    } else {
      texture.baseTexture.addEventListener('loaded', _onTextureLoaded);
    }

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform sampler2D displacementMap;
        uniform sampler2D uSampler;
        uniform vec2 scale;
        uniform vec2 offset;
        uniform vec4 dimensions;
        uniform vec2 mapDimensions;

        void main(void) {
          vec2 mapCords = vTextureCoord.xy;
          mapCords += (dimensions.zw + offset) / dimensions.xy;
          mapCords.y *= -1.0;
          mapCords.y += 1.0;
          vec2 matSample = texture2D(displacementMap, mapCords).xy;
          matSample -= 0.5;
          matSample *= scale;
          matSample /= mapDimensions;
          gl_FragColor = texture2D(uSampler, vec2(vTextureCoord.x + matSample.x, vTextureCoord.y + matSample.y));
          gl_FragColor.rgb = mix(gl_FragColor.rgb, gl_FragColor.rgb, 1.0);
          vec2 cord = vTextureCoord;
        }''';
  }

  void _onTextureLoaded(CustomEvent event) {
    var mapDimensions = _uniforms[3] as Uniform2f;
    var displacementMap = _uniforms.first as UniformSampler2D;

    mapDimensions.x = displacementMap.value._width.toDouble();
    mapDimensions.y = displacementMap.value._height.toDouble();

    displacementMap.value.baseTexture.removeEventListener('loaded',
        _onTextureLoaded);
  }

  /**
   * Returns the texture used for the displacemtent map. Must be power of 2
   * texture at the moment.
   */
  Texture get map => (_uniforms.first as UniformSampler2D).value;

  /**
   * Sets the texture used for the displacemtent map. Must be power of 2 texture
   * at the moment.x
   */
  void set map(Texture value) {
    (_uniforms.first as UniformSampler2D).value = value;
  }

  /**
   * Returns the multiplier used to scale the displacement result from the map
   * calculation.
   */
  Uniform2f get scale => _uniforms[1];

  /**
   * Returns the x multiplier used to scale the displacement result from the map
   * calculation.
   */
  double get scaleX => (_uniforms[1] as Uniform2f).x;

  /**
   * Sets the x multiplier used to scale the displacement result from the map
   * calculation.
   */
  void set scaleX(double value) {
    (_uniforms[1] as Uniform2f).x = value;
  }

  /**
   * Returns the y multiplier used to scale the displacement result from the map
   * calculation.
   */
  double get scaleY => (_uniforms[1] as Uniform2f).y;

  /**
   * Sets the y multiplier used to scale the displacement result from the map
   * calculation.
   */
  void set scaleY(double value) {
    (_uniforms[1] as Uniform2f).y = value;
  }

  /// Returns the offset used to move the displacement map.
  Uniform2f get offset => _uniforms[2];

  /// Returns the x offset used to move the displacement map.
  double get offsetX => (_uniforms[2] as Uniform2f).x;

  /// Sets the x offset used to move the displacement map.
  void set offsetX(double value) {
    (_uniforms[2] as Uniform2f).x = value;
  }

  /// Returns the y offset used to move the displacement map.
  double get offsetY => (_uniforms[2] as Uniform2f).y;

  /// Sets the y offset used to move the displacement map.
  void set offsetY(double value) {
    (_uniforms[2] as Uniform2f).y = value;
  }
}
