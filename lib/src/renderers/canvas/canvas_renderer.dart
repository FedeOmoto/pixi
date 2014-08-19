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
 * The CanvasRenderer draws the stage and all its content onto a 2d canvas. This
 * renderer should be used for browsers that do not support WebGL.
 * Dont forget to add the view to your DOM or you will not see anything :)
 */
class CanvasRenderer extends Renderer {
  // TODO: verify if the browser does support the new blend modes in canvas?
  static const List<String> BLEND_MODES = const <String>['source-over',
      'lighter', 'multiply', 'screen', 'overlay', 'darken', 'lighten', 'color-dodge',
      'color-burn', 'hard-light', 'soft-light', 'difference', 'exclusion', 'hue',
      'saturation', 'color', 'luminosity'];

  final int type = Renderer.CANVAS_RENDERER;

  /**
   * This sets if the CanvasRenderer will clear the canvas or not before the new
   * render pass.
   * If the Stage is NOT transparent Pixi will use a canvas sized fillRect
   * operation every frame to set the canvas background color.
   * If the Stage is transparent Pixi will use clearRect to clear the canvas
   * every frame.
   * Disable this by setting this to false. For example if your game has a
   * canvas filling background image you often don't need this set.
   */
  bool clearBeforeRender = true;

  bool refresh = true;

  int count = 0;

  CanvasRenderer({int width: 800, int height: 600, CanvasElement view, bool
      transparent: false}) : super(width: width, height: height, view: view,
      transparent: transparent) {
    if (Renderer._defaultRenderer == null) Renderer._defaultRenderer = this;

    context = this.view.getContext('2d', {
      'alpha': transparent
    });

    // Instance of a CanvasMaskManager, handles masking when using the canvas
    // renderer.
    maskManager = new CanvasMaskManager();

    // The render session is just a bunch of parameters used for rendering.
    renderSession = new CanvasRenderSession(context, maskManager);
  }

  /// Renders the stage to its canvas view.
  @override
  void render(Stage stage) {
    // Update textures if need be.
    BaseTexture._texturesToUpdate.clear();
    BaseTexture._texturesToDestroy.clear();

    stage._updateTransform();

    var context = this.context as CanvasRenderingContext2D;

    context.setTransform(1, 0, 0, 1, 0, 0);
    context.globalAlpha = 1;

    // TODO: Add support for CocoonJS?
    //if (navigator.isCocoonJS && this.view.screencanvas) ...

    if (!transparent && clearBeforeRender) {
      context.fillStyle = stage.backgroundColor.toString();
      context.fillRect(0, 0, width, height);
    } else if (transparent && clearBeforeRender) {
      context.clearRect(0, 0, this.width, this.height);
    }

    _renderDisplayObject(stage);

    // Run interaction!
    if (stage._interactive) {
      // Need to add some events!
      if (!stage._interactiveEventsAdded) {
        stage._interactiveEventsAdded = true;
        stage.interactionManager._setTarget = this;
      }
    }

    // Remove frame updates.
    if (Texture._frameUpdates.isNotEmpty) Texture._frameUpdates.clear();
  }

  /// Resizes the canvas view to the specified width and height.
  @override
  void resize(int width, int height) {
    this.width = view.width = width;
    this.height = view.height = height;
  }

  // Renders a display object.
  void _renderDisplayObject(DisplayObject
      displayObject, [CanvasRenderingContext2D context]) {
    if (context != null) renderSession.context = context;
    displayObject._renderCanvas(renderSession);
  }

  // Renders a flat strip.
  void _renderStripFlat(Strip strip) {
    var context = this.context as CanvasRenderingContext2D;
    var vertices = strip.vertices;

    var length = vertices.length / 2;
    count++;

    context.beginPath();

    for (var i = 1; i < length - 2; i++) {
      // Draw some triangles!
      var index = i * 2;

      var x0 = vertices[index],
          x1 = vertices[index + 2],
          x2 = vertices[index + 4];

      var y0 = vertices[index + 1],
          y1 = vertices[index + 3],
          y2 = vertices[index + 5];

      context.moveTo(x0, y0);
      context.lineTo(x1, y1);
      context.lineTo(x2, y2);
    }

    context.fillStyle = '#FF0000';
    context.fill();
    context.closePath();
  }

  // Renders a strip.
  void _renderStrip(Strip strip) {
    var context = this.context as CanvasRenderingContext2D;

    // Draw triangles!!
    var vertices = strip.vertices;
    var uvs = strip.uvs;

    var length = vertices.length / 2;
    count++;

    for (var i = 1; i < length - 2; i++) {
      // draw some triangles!
      var index = i * 2;

      var x0 = vertices[index],
          x1 = vertices[index + 2],
          x2 = vertices[index + 4];

      var y0 = vertices[index + 1],
          y1 = vertices[index + 3],
          y2 = vertices[index + 5];

      var u0 = uvs[index] * strip.texture.width,
          u1 = uvs[index + 2] * strip.texture.width,
          u2 = uvs[index + 4] * strip.texture.width;

      var v0 = uvs[index + 1] * strip.texture.height,
          v1 = uvs[index + 3] * strip.texture.height,
          v2 = uvs[index + 5] * strip.texture.height;

      context.save();
      context.beginPath();
      context.moveTo(x0, y0);
      context.lineTo(x1, y1);
      context.lineTo(x2, y2);
      context.closePath();

      context.clip();

      // Compute matrix transform.
      var delta = u0 * v1 + v0 * u2 + u1 * v2 - v1 * u2 - v0 * u1 - u0 * v2;
      var deltaA = x0 * v1 + v0 * x2 + x1 * v2 - v1 * x2 - v0 * x1 - x0 * v2;
      var deltaB = u0 * x1 + x0 * u2 + u1 * x2 - x1 * u2 - x0 * u1 - u0 * x2;
      var deltaC = u0 * v1 * x2 + v0 * x1 * u2 + x0 * u1 * v2 - x0 * v1 * u2 -
          v0 * u1 * x2 - u0 * x1 * v2;
      var deltaD = y0 * v1 + v0 * y2 + y1 * v2 - v1 * y2 - v0 * y1 - y0 * v2;
      var deltaE = u0 * y1 + y0 * u2 + u1 * y2 - y1 * u2 - y0 * u1 - u0 * y2;
      var deltaF = u0 * v1 * y2 + v0 * y1 * u2 + y0 * u1 * v2 - y0 * v1 * u2 -
          v0 * u1 * y2 - u0 * y1 * v2;

      context.transform(deltaA / delta, deltaD / delta, deltaB / delta, deltaE /
          delta, deltaC / delta, deltaF / delta);

      context.drawImage(strip.texture.baseTexture.source, 0, 0);
      context.restore();
    }
  }
}
