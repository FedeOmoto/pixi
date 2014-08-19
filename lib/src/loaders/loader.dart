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
abstract class Loader extends EventTarget {
  /// The URL of the asset.
  String url;

  /// Whether the requests should be treated as cross origin.
  bool crossOrigin;

  bool _loaded = false;

  Loader(this.url, [this.crossOrigin = false]);

  factory Loader.from(String type, String url, bool crossOrigin) {
    switch (type) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return new ImageLoader(url, crossOrigin);

      case 'json':
        return new JsonLoader(url, crossOrigin);

      case 'atlas':
        return new AtlasLoader(url, crossOrigin);

      case 'xml':
      case 'fnt':
        return new BitmapFontLoader(url, crossOrigin);

      default:
        throw new UnsupportedError('$type is an unsupported file type.');
    }
  }

  /// Whether the data has loaded yet.
  bool get loaded => _loaded;

  /// Loads the asset.
  void load();

  // Invoked when the asset is loaded.
  void _onLoaded([CustomEvent event]) {
    _loaded = true;
    dispatchEvent(new CustomEvent('loaded', detail: this));
  }

  /// Stream of `loaded` events handled by this [Loader].
  CustomEventStream<CustomEvent> get onLoaded => on['loaded'];
}
