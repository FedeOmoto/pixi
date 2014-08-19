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
 * A texture stores the information that represents an image or part of an
 * image. It cannot be added to the display list directly. To do this use
 * [Sprite]. If no frame is provided then the whole image is used.
 */
class Texture extends EventTarget {
  static Map<String, Texture> _cache = new Map<String, Texture>();
  static List<Texture> _frameUpdates = new List<Texture>();

  /// Does this [Texture] have any frame data assigned to it?
  bool noFrame = false;

  /// The base texture that this texture uses.
  final BaseTexture baseTexture;

  /// The frame specifies the region of the base texture that this texture uses.
  Rectangle<int> frame;

  /// The trim rectangle.
  Rectangle<int> trim;

  /**
   * This will let the renderer know if the texture is valid. If its not then it
   * cannot be rendered.
   */
  bool _valid = false;

  /**
   * This is the area of the BaseTexture image to actually copy to the Canvas /
   * WebGL when rendering, irrespective of the actual frame size or placement
   * (which can be influenced by trimmed texture atlases).
   */
  Rectangle<int> crop = new Rectangle<int>(0, 0, 1, 1);

  Map<String, CanvasImageSource> tintCache;

  // The WebGL UV data cache.
  TextureUvs _uvs;

  int _width = 0;
  int _height = 0;
  bool _needsUpdate = false;
  bool _isTiling = false;
  CanvasBuffer _canvasBuffer;

  Texture(this.baseTexture, [Rectangle<int> frame]) {
    if (frame == null) {
      noFrame = true;
      frame = new Rectangle<int>(0, 0, 1, 1);
    }

    this.frame = frame;

    if (baseTexture.hasLoaded) {
      if (noFrame) {
        frame = new Rectangle<int>(0, 0, baseTexture.width, baseTexture.height);
      }

      setFrame(frame);
    } else {
      baseTexture.addEventListener('loaded', _onBaseTextureLoaded);
    }
  }

  /**
   * Returns a texture based on an image url.
   * If the image is not in the texture cache it will be  created and loaded.
   */
  factory Texture.fromImage(String imageUrl, [bool crossorigin, ScaleModes<int>
      scaleMode = ScaleModes.DEFAULT]) {
    var texture = Texture._cache[imageUrl];

    if (texture == null) {
      texture = new Texture(new BaseTexture.fromImage(imageUrl, crossorigin,
          scaleMode));
      Texture._cache[imageUrl] = texture;
    }

    return texture;
  }

  /**
   * Returns a texture based on a frame id.
   * If the frame id is not in the texture cache a [StateError] will be thrown.
   */
  factory Texture.fromFrame(String frameId) {
    var texture = Texture._cache[frameId];

    if (texture == null) {
      throw new StateError(
          'The frameId "$frameId" does not exist in the texture cache.');
    }

    return texture;
  }

  /**
   * Returns a texture based on a canvas element.
   * If the canvas is not in the texture cache it will be created and loaded.
   */
  factory Texture.fromCanvas(CanvasElement canvas, [ScaleModes<int> scaleMode =
      ScaleModes.DEFAULT]) {
    var baseTexture = new BaseTexture.fromCanvas(canvas, scaleMode);
    return new Texture(baseTexture);
  }

  /// The width of the [Texture] in pixels.
  int get width => _width;

  /// The height of the [Texture] in pixels.
  int get height => _height;

  /// Called when the base texture is loaded.
  void _onBaseTextureLoaded(CustomEvent event) {
    // TODO: why does the JavaScript code removes the 'this.onLoaded' listener?
    baseTexture.removeEventListener('loaded', _onBaseTextureLoaded);

    if (noFrame) {
      frame = new Rectangle<int>(0, 0, baseTexture.width, baseTexture.height);
    }

    setFrame(frame);

    dispatchEvent(new CustomEvent('update', detail: this));
  }

  /// Stream of update events handled by this [Texture].
  CustomEventStream<CustomEvent> get onUpdate => on['update'];

  /// Destroys this texture.
  void destroy([bool destroyBase = false]) {
    if (destroyBase) baseTexture.destroy();
    _valid = false;
  }

  /// Specifies the region of the baseTexture that this texture will use.
  void setFrame(Rectangle<int> frame) {
    noFrame = false;

    this.frame = frame;
    _width = frame.width;
    _height = frame.height;

    crop.left = frame.left;
    crop.top = frame.top;
    crop.width = frame.width;
    crop.height = frame.height;

    if (trim == null && (frame.left + frame.width > baseTexture.width ||
        frame.top + frame.height > baseTexture.height)) {
      throw new StateError(
          'Texture Error: frame does not fit inside the base Texture dimensions.');
    }

    _valid = frame != null && frame.width != 0 && frame.height != 0 &&
        baseTexture.source != null && baseTexture.hasLoaded;

    if (trim != null) {
      _width = trim.width;
      _height = trim.height;
      this.frame.width = trim.width;
      this.frame.height = trim.height;
    }

    if (_valid) Texture._frameUpdates.add(this);
  }

  // Updates the internal WebGL UV cache.
  void _updateWebGLuvs() {
    if (_uvs == null) _uvs = new TextureUvs();

    var frame = crop;

    var tw = baseTexture.width;
    var th = baseTexture.height;

    this._uvs.x0 = frame.left / tw;
    this._uvs.y0 = frame.top / th;

    this._uvs.x1 = (frame.left + frame.width) / tw;
    this._uvs.y1 = frame.top / th;

    this._uvs.x2 = (frame.left + frame.width) / tw;
    this._uvs.y2 = (frame.top + frame.height) / th;

    this._uvs.x3 = frame.left / tw;
    this._uvs.y3 = (frame.top + frame.height) / th;
  }

  /// Adds a texture to the textureCache.
  static void addTextureToCache(Texture texture, String id) {
    Texture._cache[id] = texture;
  }

  /// Remove a texture from the textureCache.
  static Texture removeTextureFromCache(String id) => Texture._cache.remove(id);
}
