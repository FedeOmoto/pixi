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
 * The image loader class is responsible for loading images file formats
 * ('jpeg', 'jpg', 'png' and 'gif').
 * Once the image has been loaded it is stored in the PIXI texture cache and can
 * be accessed though [Texture.fromFrame] and [Sprite.fromFrame].
 * When loaded this class will dispatch a 'loaded' event.
 */
class ImageLoader extends Loader {
  /// The texture being loaded.
  Texture texture;

  /**
   * If the image is loaded with [loadFramedSpriteSheet], [frames] will contain
   * the sprite sheet frames.
   */
  List<Texture> frames;

  ImageLoader(String url, [bool crossOrigin]) : super(url, crossOrigin) {
    texture = new Texture.fromImage(url, this.crossOrigin);
  }

  /// Loads image or takes it from cache.
  @override
  void load() {
    if (!texture.baseTexture._hasLoaded) {
      texture.baseTexture.addEventListener('loaded', _onLoaded);
    } else {
      _onLoaded();
    }
  }

  /// Loads image and split it to uniform sized frames.
  void loadFramedSpriteSheet(int frameWidth, int frameHeight, [String
      textureName]) {
    frames = new List<Texture>();

    var cols = (texture._width / frameWidth).floor();
    var rows = (texture._height / frameHeight).floor();

    int i = 0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++, i++) {
        var textureFrame = new Rectangle<int>(x * frameWidth, y * frameHeight,
            frameWidth, frameHeight);
        var texture = new Texture(this.texture.baseTexture, textureFrame);

        frames.add(texture);
        if (textureName != null) Texture._cache['$textureName-$i'] = texture;
      }
    }

    if (!texture.baseTexture._hasLoaded) {
      texture.baseTexture.addEventListener('loaded', _onLoaded);
    } else {
      _onLoaded();
    }
  }
}
