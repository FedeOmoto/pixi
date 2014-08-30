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
 * A Class that loads a bunch of images / sprite sheet / bitmap font files. Once
 * the assets have been loaded they are added to the PIXI Texture cache and can
 * be accessed easily through [Texture.fromImage] and [Sprite.fromImage].
 * When all items have been loaded this class will dispatch a 'onLoaded' event.
 * As each individual item is loaded this class will dispatch a 'onProgress'
 * event.
 */
class AssetLoader extends EventTarget {
  /// The list of asset URLs that are going to be loaded.
  List<String> assetURLs;

  /// Whether the requests should be treated as cross origin.
  bool crossOrigin;

  int _loadCount;

  AssetLoader(this.assetURLs, [this.crossOrigin = false]);

  // Given a filename, returns its extension.
  String _getDataType(String str) {
    if (str.startsWith(new RegExp('data:', caseSensitive: false))) {
      //if (start === test) {
      var data = str.substring(str.indexOf(':') + 1);

      var sepIdx = data.indexOf(',');

      // Malformed data URI scheme.
      if (sepIdx == -1) return null;

      // E.g. 'image/gif;base64' => 'image/gif'
      var info = data.substring(0, sepIdx).split(';')[0];

      // We might need to handle some special cases here...
      // Standardize text/plain to 'txt' file extension
      if (info == null || info.toLowerCase() == 'text/plain') return 'txt';

      // User specified mime type, try splitting it by '/'
      return info.split('/').removeLast().toLowerCase();
    }

    return null;
  }

  /// Starts loading the assets sequentially.
  void load() {
    _loadCount = assetURLs.length;

    assetURLs.forEach((fileName) {
      // First see if we have a data URI scheme.
      var fileType = this._getDataType(fileName);

      // If not, assume it's a file URI.
      if (fileType == null) {
        fileType = fileName.split('?').removeAt(0).split('.').removeLast(
            ).toLowerCase();
      }

      var loader = new Loader.from(fileType, fileName, crossOrigin);

      loader.addEventListener('loaded', _onAssetLoaded);
      loader.load();
    });
  }

  // Invoked after each file is loaded.
  void _onAssetLoaded(CustomEvent event) {
    _loadCount--;

    dispatchEvent(new CustomEvent('progress', detail: {
      'content': this,
      'loader': event.detail
    }));

    if (_loadCount == 0) {
      dispatchEvent(new CustomEvent('complete', detail: this));
    }
  }

  /// Stream of progress events handled by this [AssetLoader].
  CustomEventStream<CustomEvent> get onProgress => on['progress'];

  /// Stream of complete events handled by this [AssetLoader].
  CustomEventStream<CustomEvent> get onComplete => on['complete'];
}
