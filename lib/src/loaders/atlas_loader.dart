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
 * The atlas file loader is used to load in Atlas data and parse it.
 * When loaded this class will dispatch a `loaded` event
 * If loading fails this class will dispatch an `error` event.
 */
class AtlasLoader extends Loader {
  String _baseUrl;

  AtlasLoader(String url, [bool crossOrigin]) : super(url, crossOrigin) {
    _baseUrl = path.dirname(url) + '/';
  }

  /// The base URL of the JSON data.
  String get baseUrl => _baseUrl;

  /// Loads the Atlas data.
  @override
  void load() {
    HttpRequest.getString(url).then(_onAtlasLoaded).catchError(_onError);
  }

  // Invoked when Atlas file is loaded.
  void _onAtlasLoaded(String atlasString) {
    var atlas = new spine.Atlas(atlasString, new AtlasTextureLoader(_baseUrl));

    atlas.onLoaded.listen((atlas) => _loadSkeletonData(atlas));
  }

  void _loadSkeletonData(spine.Atlas atlas) {
    var skeletonJson = new spine.SkeletonJson.fromAtlas(atlas);
    var jsonUrl = path.withoutExtension(url) + '.json';
    var jsonLoader = new JsonLoader(jsonUrl);

    jsonLoader.onError.listen((event) => _onError());

    jsonLoader.onLoaded.listen((event) {
      var skeletonData = skeletonJson.readSkeletonData(event.detail.json,
          jsonUrl);

      Spine._animCache[url] = skeletonData;
      _onLoaded();
    });

    jsonLoader.load();
  }

  // Invoked when error occured.
  void _onError([Error error]) {
    dispatchEvent(new CustomEvent('error', detail: this));
  }

  /// Stream of `error` events handled by this [AtlasLoader].
  CustomEventStream<CustomEvent> get onError => on['error'];
}
