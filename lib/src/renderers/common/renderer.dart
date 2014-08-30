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
abstract class Renderer {
  static const int WEBGL_RENDERER = 0;
  static const int CANVAS_RENDERER = 1;

  static Renderer _defaultRenderer;
  static Renderer get defaultRenderer => _defaultRenderer;

  /// Whether the render view is transparent.
  bool transparent;

  /// The width of the canvas view.
  int width;

  /// The height of the canvas view.
  int height;

  /// The canvas element that everything is drawn to.
  CanvasElement view;

  /// The canvas context that everything is drawn with.
  CanvasRenderingContext context;

  /// Handles masking.
  MaskManager maskManager;

  /// The render session is just a bunch of parameters used for rendering.
  RenderSession renderSession;

  Renderer({this.width, this.height, CanvasElement view, this.transparent}) {
    if (view == null) this.view = new CanvasElement();

    this.view.width = width;
    this.view.height = height;
  }

  /**
   * This will automatically detect which renderer you should be using.
   * WebGL is the preferred renderer as it is a lot faster. If webGL is not
   * supported by the browser then this method will return a canvas renderer.
   */
  factory Renderer.autoDetect({int width: 800, int height: 600,
      CanvasElement view, bool transparent: false, bool antialias: false}) {
    if (WebGLRenderer.supported) {
      return new WebGLRenderer(
          width: width,
          height: height,
          view: view,
          transparent: transparent,
          antialias: antialias);
    }

    return new CanvasRenderer(
        width: width,
        height: height,
        view: view,
        transparent: transparent);
  }

  int get type;

  /// Renders the stage to its view.
  void render(Stage stage);

  /// Resizes the view to the specified width and height.
  void resize(int width, int height);
}
