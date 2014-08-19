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
 * The SpriteBatch class is a really fast version of the
 * [DisplayObjectContainer] built solely for speed, so use when you need a lot
 * of sprites or particles.
 * And it's extremely easy to use: 
 *
 *     var container = new SpriteBatch();
 *
 *     stage.addChild(container);
 *
 *     for(var i = 0; i < 100; i++) {
 *       var sprite = new Sprite.fromImage('myImage.png');
 *       container.addChild(sprite);
 *     }
 * 
 * And here you have a hundred sprites that will be renderer at the speed of
 * light.
 */
class SpriteBatch extends DisplayObjectContainer {
  bool ready = false;
  WebGLFastSpriteBatch fastSpriteBatch;

  /// Initialises the spriteBatch.
  void initWebGL(gl.RenderingContext context) {
    // TODO: only one needed for the whole engine really?
    fastSpriteBatch = new WebGLFastSpriteBatch(context);

    ready = true;
  }

  // Updates the object transform for rendering.
  @override
  void _updateTransform() {
    if (!_cacheAsBitmap) {
      _cacheAsBitmap = true;
      super._updateTransform();
      _cacheAsBitmap = false;
    } else {
      super._updateTransform();
    }
  }

  // Renders the object using the WebGL renderer.
  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    if (!visible || alpha <= 0 || _children.isEmpty) return;

    if (!ready) initWebGL(renderSession.context);

    renderSession.spriteBatch.stop();

    renderSession.shaderManager.setShader(renderSession.shaderManager.fastShader
        );

    fastSpriteBatch.begin(this, renderSession);
    fastSpriteBatch.render(this);

    renderSession.spriteBatch.start();
  }

  // Renders the object using the Canvas renderer.
  @override
  void _renderCanvas(CanvasRenderSession renderSession) {
    var context = renderSession.context as CanvasRenderingContext2D;
    context.globalAlpha = _worldAlpha;

    _updateTransform();

    var isRotated = true;

    for (var child in _children) {
      if (!child.visible) continue;

      var texture = child.texture;
      var frame = texture.frame;

      context.globalAlpha = _worldAlpha * child.alpha;

      if (child.rotation % (math.PI * 2) == 0) {
        if (isRotated) {
          context.setTransform(_worldTransform.a, _worldTransform.c,
              _worldTransform.b, _worldTransform.d, _worldTransform.tx, _worldTransform.ty);
          isRotated = false;
        }

        // This is the fastest way to optimise! - if rotation is 0 then we can
        // avoid any kind of setTransform call.
        context.drawImageScaledFromSource(texture.baseTexture.source,
            frame.left, frame.top, frame.width, frame.height, ((child.anchor.x) *
            (-frame.width * child.scale.x) + child.position.x + 0.5).truncate(),
            ((child.anchor.y) * (-frame.height * child.scale.y) + child.position.y +
            0.5).truncate(), frame.width * child.scale.x, frame.height * child.scale.y);
      } else {
        if (!isRotated) isRotated = true;

        _updateTransform();

        var childTransform = child._worldTransform;

        if (renderSession.roundPixels) {
          context.setTransform(childTransform.a, childTransform.c,
              childTransform.b, childTransform.d, childTransform.tx.truncate(),
              childTransform.ty.truncate());
        } else {
          context.setTransform(childTransform.a, childTransform.c,
              childTransform.b, childTransform.d, childTransform.tx, childTransform.ty);
        }

        context.drawImageScaledFromSource(texture.baseTexture.source,
            frame.left, frame.top, frame.width, frame.height, ((child.anchor.x) *
            (-frame.width) + 0.5).truncate(), ((child.anchor.y) * (-frame.height) +
            0.5).truncate(), frame.width, frame.height);
      }
    }
  }
}
