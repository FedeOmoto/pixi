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
class AtlasTextureLoader extends spine.TextureLoader {
  String _basePath;

  AtlasTextureLoader(this._basePath);

  @override
  void load(spine.AtlasPage page, String path, spine.Atlas atlas) {
    path = _basePath + path;

    var loader = new ImageLoader(path);

    loader.onLoaded.listen((event) {
      Texture texture = Texture._cache[path];

      page.rendererObject = texture;
      page.width = texture.width;
      page.height = texture.height;
      atlas.updateUVs(page);

      hasLoaded = page;
    });

    loader.load();
  }

  @override
  void unload(Texture texture) {
    // TODO: remove from cache.
    texture.destroy(true);
  }
}
