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
 * A texture stores the information that represents an image. All textures have
 * a base texture.
 */
class BaseTexture extends EventTarget {
  static Map<String, BaseTexture> _cache = new Map<String, BaseTexture>();
  static List<BaseTexture> _texturesToUpdate = new List<BaseTexture>();
  static List<BaseTexture> _texturesToDestroy = new List<BaseTexture>();
  static int _cacheIdGenerator = 0;

  int _width = 100;
  int _height = 100;

  /// The scale mode to apply when scaling this texture.
  ScaleModes<int> scaleMode;

  bool _hasLoaded = false;

  /// The source that is loaded to create the texture.
  CanvasImageSource source;

  // The source with type information.
  var _source;

  final int id = BaseTexture._cacheIdGenerator++;

  /// Controls if RGB channels should be premultiplied by Alpha (WebGL only).
  bool premultipliedAlpha = true;

  // Used for webGL.
  Map<int, gl.Texture> _glTextures = new Map<int, gl.Texture>();

  // Used for webGL teture updateing.
  Map<int, bool> _dirty = new Map<int, bool>();

  String _imageUrl;
  bool _powerOf2 = false;

  BaseTexture([this.source, this.scaleMode = ScaleModes.DEFAULT]) {
    if (source == null) return;

    if (source is ImageElement) {
      _source = source as ImageElement;
    } else if (source is CanvasElement) {
      _source = source as CanvasElement;
    } else {
      _source = source as VideoElement;
    }

    if (((_source is ImageElement && _source.complete) ||
        _source is! ImageElement) &&
        _source.width != 0 &&
        _source.height != 0) {
      _hasLoaded = true;
      _width = _source.width;
      _height = _source.height;

      BaseTexture._texturesToUpdate.add(this);
    } else {
      _source.onLoad.listen((event) {
        _hasLoaded = true;
        _width = _source.width;
        _height = _source.height;

        for (int i = 0; i < _glTextures.length; i++) {
          _dirty[i] = true;
        }

        dispatchEvent(new CustomEvent('loaded', detail: this));
      });

      _source.onError.listen((event) {
        dispatchEvent(new CustomEvent('error', detail: this));
      });
    }
  }

  /**
   * Returns a base texture based on an image url.
   * If the image is not in the base texture cache it will be created and
   * loaded.
   */
  factory BaseTexture.fromImage(String imageUrl, [bool crossOrigin,
      ScaleModes<int> scaleMode]) {
    var baseTexture = BaseTexture._cache[imageUrl];

    crossOrigin = (crossOrigin == null && !imageUrl.startsWith('data:'));

    if (baseTexture == null) {
      var image = new ImageElement(src: imageUrl);

      if (crossOrigin) image.crossOrigin = '';
      baseTexture = new BaseTexture(image, scaleMode);
      baseTexture._imageUrl = imageUrl;
      BaseTexture._cache[imageUrl] = baseTexture;
    }

    return baseTexture;
  }

  /**
   * Returns a base texture based on a canvas element.
   * If the image is not in the base texture cache it will be created and
   * loaded.
   */
  factory BaseTexture.fromCanvas(CanvasElement canvas,
      [ScaleModes<int> scaleMode]) {
    if (canvas.dataset['pixiId'] == null) {
      canvas.dataset['pixiId'] = 'canvas_${BaseTexture._cacheIdGenerator++}';
    }

    var baseTexture = BaseTexture._cache[canvas.dataset['pixiId']];

    if (baseTexture == null) {
      baseTexture = new BaseTexture(canvas, scaleMode);
      BaseTexture._cache[canvas.dataset['pixiId']] = baseTexture;
    }

    return baseTexture;
  }

  /// Stream of `loaded` events handled by this [BaseTexture].
  CustomEventStream<CustomEvent> get onLoaded => on['loaded'];

  /// Stream of `error` events handled by this [BaseTexture].
  CustomEventStream<CustomEvent> get onError => on['error'];

  /// The width of the base texture set when the image has loaded.
  int get width => _width;

  /// The height of the base texture set when the image has loaded.
  int get height => _height;

  /// Describes if the base texture has loaded or not.
  bool get hasLoaded => _hasLoaded;

  /// Destroys this base texture.
  void destroy() {
    if (_imageUrl != null) {
      BaseTexture._cache.remove(_imageUrl);
      Texture._cache.remove(_imageUrl);
      _imageUrl = null;
      _source.src = '';
    } else if (_source != null && _source.dataset['pixiId'] != null) {
      BaseTexture._cache.remove(_source.dataset['pixiId']);
    }

    source = _source = null;
    BaseTexture._texturesToDestroy.add(this);
  }

  /// Changes the source of the texture.
  void updateSource(String newSrc) {
    _hasLoaded = false;
    _source.src = newSrc;
  }
}
