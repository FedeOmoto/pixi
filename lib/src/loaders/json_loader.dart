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
 * The JSON file loader is used to load in JSON data and parse it.
 * When loaded this class will dispatch a 'loaded' event.
 * If loading fails this class will dispatch an 'error' event.
 */
class JsonLoader extends Loader {
  Map json;
  String _baseUrl;

  JsonLoader(String url, [bool crossOrigin]) : super(url, crossOrigin) {
    _baseUrl = url.replaceFirst(new RegExp(r'[^\/]*$'), '');
  }

  /// The base URL of the JSON data.
  String get baseUrl => _baseUrl;

  /// Loads the JSON data.
  @override
  void load() {
    HttpRequest.getString(url).then(_onJsonLoaded).catchError(_onError);
  }

  // Invoked when JSON file is loaded.
  void _onJsonLoaded(String jsonString) {
    json = JSON.decode(jsonString);

    if (json['frames'] != null) { // Sprite sheet.
      var textureUrl = baseUrl + json['meta']['image'];
      var image = new ImageLoader(textureUrl, crossOrigin);

      image.addEventListener('loaded', _onLoaded);

      json['frames'].forEach((frameName, frameData) {
        var frameRect = frameData['frame'];

        if (frameRect != null) {
          var texture = image.texture.baseTexture;
          var rect = new Rectangle<int>(frameRect['x'], frameRect['y'],
              frameRect['w'], frameRect['h']);

          Texture._cache[frameName] = new Texture(texture, rect);

          Texture._cache[frameName].crop = rect.clone();

          //  Check to see if the sprite is trimmed
          if (frameData['trimmed']) {
            var actualSize = frameData['sourceSize'];
            var realSize = frameData['spriteSourceSize'];

            Texture._cache[frameName].trim = new Rectangle<int>(realSize['x'],
                realSize['y'], actualSize['w'], actualSize['h']);
          }
        }
      });

      image.load();
    } else {
      _onLoaded();
    }
  }

  // Invoked when error occured.
  void _onError(Error error) {
    dispatchEvent(new CustomEvent('error', detail: this));
  }

  /// Stream of error events handled by this [JsonLoader].
  CustomEventStream<CustomEvent> get onError => on['error'];
}
