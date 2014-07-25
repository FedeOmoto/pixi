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
class _BitmapFontChar {
  int xOffset;
  int yOffset;
  int xAdvance;
  Map<int, int> kerning = new Map<int, int>();
  Texture texture;

  _BitmapFontChar(Element letter, int charCode, BitmapFontLoader loader) {
    int left = int.parse(letter.attributes['x']);
    int top = int.parse(letter.attributes['y']);
    int width = int.parse(letter.attributes['width']);
    int height = int.parse(letter.attributes['height']);
    var textureRect = new Rectangle<int>(left, top, width, height);

    xOffset = int.parse(letter.attributes['xoffset']);
    yOffset = int.parse(letter.attributes['yoffset']);
    xAdvance = int.parse(letter.attributes['xadvance']);
    texture = Texture._cache[charCode.toString()] = new Texture(loader._texture,
        textureRect);
  }
}

// TODO: document.
class _BitmapFontData {
  String font;
  int size;
  int lineHeight;
  Map<int, _BitmapFontChar> chars = new Map<int, _BitmapFontChar>();

  _BitmapFontData(Element info, Element common, ElementList<Element>
      letters, ElementList<Element> kernings, BitmapFontLoader loader) {
    font = info.attributes['face'];
    size = int.parse(info.attributes['size']);
    lineHeight = int.parse(common.getAttribute('lineHeight'));

    parseLetters(letters, loader);
    parseKernings(kernings);
  }

  void parseLetters(ElementList<Element> letters, BitmapFontLoader loader) {
    letters.forEach((letter) {
      int charCode = int.parse(letter.attributes['id']);
      chars[charCode] = new _BitmapFontChar(letter, charCode, loader);
    });
  }

  void parseKernings(ElementList<Element> kernings) {
    kernings.forEach((kerning) {
      int first = int.parse(kerning.attributes['first']);
      int second = int.parse(kerning.attributes['second']);
      int amount = int.parse(kerning.attributes['amount']);

      chars[second].kerning[first] = amount;
    });
  }
}

/**
 * The xml loader is used to load in XML bitmap font data ('xml' or 'fnt').
 * To generate the data you can use [http://www.angelcode.com/products/bmfont/]
 * (http://www.angelcode.com/products/bmfont/).
 * This loader will also load the image file as the data.
 * When loaded this class will dispatch a 'loaded' event.
 */
class BitmapFontLoader extends Loader {
  String _baseUrl;
  BaseTexture _texture;

  BitmapFontLoader(String url, [bool crossOrigin]) : super(url, crossOrigin) {
    _baseUrl = url.replaceFirst(new RegExp(r'[^\/]*$'), '');
  }

  /// The base URL of the bitmap font data.
  String get baseUrl => _baseUrl;

  /// The texture of the bitmap font.
  BaseTexture get texture => _texture;

  /// Loads the XML font data.
  @override
  void load() {
    HttpRequest.request(url).then(_onXmlLoaded).catchError(_onError);
  }

  // Invoked when JSON file is loaded.
  void _onXmlLoaded(HttpRequest response) {
    var responseXml = response.responseXml;

    var textureUrl = baseUrl + responseXml.querySelector('page'
        ).attributes['file'];
    var image = new ImageLoader(textureUrl, crossOrigin);
    _texture = image.texture.baseTexture;

    var info = responseXml.getElementsByTagName('info')[0];
    var common = responseXml.getElementsByTagName('common')[0];
    var letters = responseXml.querySelectorAll('char');
    var kernings = responseXml.querySelectorAll('kerning');
    var data = new _BitmapFontData(info, common, letters, kernings, this);

    BitmapText._fonts[data.font] = data;

    image.addEventListener('loaded', _onLoaded);
    image.load();
  }

  // Invoked when error occured.
  void _onError(Error error) {
    dispatchEvent(new CustomEvent('error', detail: this));
  }

  /// Stream of error events handled by this [BitmapFontLoader].
  CustomEventStream<CustomEvent> get onError => on['error'];
}
