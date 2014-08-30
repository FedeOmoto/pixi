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
class WebGLRenderer extends Renderer {
  static const List<List<int>> BLEND_MODES = const <List<int>>[
      const <int>[gl.ONE, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.SRC_ALPHA, gl.DST_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.SRC_ALPHA, gl.ONE],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA],
      const <int>[gl.DST_COLOR, gl.ONE_MINUS_SRC_ALPHA]];

  /// Is WebGL supported on the current platform?
  static final bool supported = gl.RenderingContext.supported;

  // Updates the textures loaded into this webgl renderer.
  static void _updateTextures() {
    Texture._frameUpdates.forEach((texture) => _updateTextureFrame(texture));

    BaseTexture._texturesToDestroy.forEach((baseTexture) {
      _destroyTexture(baseTexture);
    });

    BaseTexture._texturesToUpdate.clear();
    BaseTexture._texturesToDestroy.clear();
    Texture._frameUpdates.clear();
  }

  // Destroys a loaded webgl texture.
  static void _destroyTexture(BaseTexture texture) {
    texture._glTextures.forEach((contextId, glTexture) {
      var context = WebGLContextManager.current.context(contextId);
      if (context != null) context.deleteTexture(glTexture);
    });

    texture._glTextures.clear();
  }

  static void _updateTextureFrame(Texture texture) {
    // Now set the uvs. Figured that the uv data sits with a texture rather
    // than a sprite.
    // So uv data is stored on the texture itself.
    texture._updateWebGLuvs();
  }

  // Creates a WebGL texture.
  static gl.Texture _createWebGLTexture(BaseTexture texture,
      gl.RenderingContext context) {
    var contextId = WebGLContextManager.current.id(context);

    if (texture._hasLoaded) {
      texture._glTextures[contextId] = context.createTexture();

      context.bindTexture(gl.TEXTURE_2D, texture._glTextures[contextId]);
      context.pixelStorei(
          gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL,
          texture.premultipliedAlpha ? 1 : 0);

      context.texImage2D(
          gl.TEXTURE_2D,
          0,
          gl.RGBA,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          texture.source);
      int boolean = texture.scaleMode == ScaleModes.LINEAR ?
          gl.LINEAR :
          gl.NEAREST;
      context.texParameteri(
          gl.TEXTURE_2D,
          gl.TEXTURE_MAG_FILTER,
          texture.scaleMode == ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);
      context.texParameteri(
          gl.TEXTURE_2D,
          gl.TEXTURE_MIN_FILTER,
          texture.scaleMode == ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);

      // Reguler...

      if (!texture._powerOf2) {
        context.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_S,
            gl.CLAMP_TO_EDGE);
        context.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_T,
            gl.CLAMP_TO_EDGE);
      } else {
        context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      }

      context.bindTexture(gl.TEXTURE_2D, null);

      texture._dirty[contextId] = false;
    }

    return texture._glTextures[contextId];
  }

  // Updates a WebGL texture.
  static void _updateWebGLTexture(BaseTexture texture,
      gl.RenderingContext context) {
    var contextId = WebGLContextManager.current.id(context);

    if (texture._glTextures[contextId] != null) {
      context.bindTexture(gl.TEXTURE_2D, texture._glTextures[contextId]);
      context.pixelStorei(
          gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL,
          texture.premultipliedAlpha ? 1 : 0);

      context.texImage2D(
          gl.TEXTURE_2D,
          0,
          gl.RGBA,
          gl.RGBA,
          gl.UNSIGNED_BYTE,
          texture.source);
      context.texParameteri(
          gl.TEXTURE_2D,
          gl.TEXTURE_MAG_FILTER,
          texture.scaleMode == ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);
      context.texParameteri(
          gl.TEXTURE_2D,
          gl.TEXTURE_MIN_FILTER,
          texture.scaleMode == ScaleModes.LINEAR ? gl.LINEAR : gl.NEAREST);

      // Reguler...

      if (!texture._powerOf2) {
        context.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_S,
            gl.CLAMP_TO_EDGE);
        context.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_T,
            gl.CLAMP_TO_EDGE);
      } else {
        context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        context.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
      }

      texture._dirty[contextId] = false;
    }
  }

  int contextId;

  final int type = Renderer.WEBGL_RENDERER;

  Point<double> projection;

  Point<num> offset = new Point<num>(0, 0);

  // Whether the context was lost.
  bool _contextLost = false;

  /// Deals with managing the shader programs and their attribs.
  WebGLShaderManager shaderManager;

  /// Manages the rendering of sprites.
  WebGLSpriteBatch spriteBatch;

  /// Manages the filters.
  WebGLFilterManager filterManager;

  WebGLStencilManager stencilManager;

  WebGLBlendModeManager blendModeManager;

  Stage _stage;

  final bool antialias;

  /**
   * The value of the preserveDrawingBuffer flag affects whether or not the
   * contents of the stencil buffer is retained after rendering.
   */
  final bool preserveDrawingBuffer;

  List<StreamSubscription<gl.ContextEvent>> _listeners =
      new List<StreamSubscription<gl.ContextEvent>>(2);

  WebGLRenderer({int width: 800, int height: 600, CanvasElement view,
      bool transparent: false, this.antialias: false, this.preserveDrawingBuffer:
      false}) : super(
      width: width,
      height: height,
      view: view,
      transparent: transparent) {
    if (Renderer._defaultRenderer == null) Renderer._defaultRenderer = this;

    // Deal with losing context.
    _listeners[0] = this.view.onWebGlContextLost.listen(_handleContextLost);
    _listeners[1] = this.view.onWebGlContextRestored.listen(
        _handleContextRestored);

    if (!supported) {
      throw new UnsupportedError(
          'This browser does not support webGL. Try using the canvas renderer.');
    }

    this.context = this.view.getContext3d(
        alpha: transparent,
        antialias: antialias,
        premultipliedAlpha: transparent,
        stencil: true,
        preserveDrawingBuffer: preserveDrawingBuffer);

    var context = this.context as gl.RenderingContext;

    contextId = WebGLContextManager.current.add(context);

    projection = new Point<double>(width / 2, -height / 2);

    resize(width, height);

    // Time to create the render managers! Each one focuses on managing a state
    // in webGL.
    shaderManager = new WebGLShaderManager(context);
    spriteBatch = new WebGLSpriteBatch(context);
    maskManager = new WebGLMaskManager();
    filterManager = new WebGLFilterManager(context, transparent);
    stencilManager = new WebGLStencilManager(context);
    blendModeManager = new WebGLBlendModeManager(context);

    this.renderSession = new WebGLRenderSession(context, maskManager);
    var renderSession = this.renderSession as WebGLRenderSession;
    renderSession.shaderManager = shaderManager;
    renderSession.filterManager = filterManager;
    renderSession.blendModeManager = blendModeManager;
    renderSession.spriteBatch = spriteBatch;
    renderSession.stencilManager = stencilManager;

    context.useProgram(shaderManager.defaultShader.program);

    context.disable(gl.DEPTH_TEST);
    context.disable(gl.CULL_FACE);
    context.enable(gl.BLEND);

    context.colorMask(true, true, true, transparent);
  }

  /// Renders the stage to its webGL view.
  void render(Stage stage) {
    if (_contextLost) return;

    // If rendering a new stage clear the batches.
    if (_stage != stage) {
      if (stage._interactive) stage.interactionManager._removeEvents();

      // TODO: make this work.
      // Don't think this is needed any more?
      _stage = stage;
    }

    // Update any textures, this includes uvs and uploading them to the gpu.
    WebGLRenderer._updateTextures();

    // Update the scene graph.
    stage._updateTransform();

    // TODO: is this really needed?
    // Interaction.
    if (stage._interactive) {
      // Need to add some events!
      if (!stage._interactiveEventsAdded) {
        stage._interactiveEventsAdded = true;
        stage.interactionManager._setTarget = this;
      }
    }

    var context = this.context as gl.RenderingContext;

    context.viewport(0, 0, width, height);

    // Make sure we are bound to the main frame buffer.
    context.bindFramebuffer(gl.FRAMEBUFFER, null);

    if (transparent) {
      context.clearColor(0.0, 0.0, 0.0, 0.0);
    } else {
      context.clearColor(
          stage.backgroundColorSplit[0],
          stage.backgroundColorSplit[1],
          stage.backgroundColorSplit[2],
          1.0);
    }

    context.clear(gl.COLOR_BUFFER_BIT);

    _renderDisplayObject(stage, projection);

    // Interaction.
    if (stage._interactive) {
      // Need to add some events!
      if (!stage._interactiveEventsAdded) {
        stage._interactiveEventsAdded = true;
        stage.interactionManager._setTarget = this;
      }
    } else {
      if (stage._interactiveEventsAdded) {
        stage._interactiveEventsAdded = false;
        stage.interactionManager._setTarget = this;
      }
    }
  }

  // Renders a display object.
  void _renderDisplayObject(DisplayObject displayObject,
      Point<double> projection, [gl.Framebuffer buffer]) {
    var renderSession = this.renderSession as WebGLRenderSession;

    renderSession.blendModeManager.setBlendMode(BlendModes.NORMAL);

    // Reset the render session data.
    renderSession.drawCount = 0;
    renderSession.currentBlendMode = const BlendModes(9999);

    renderSession.projection = projection;
    renderSession.offset = offset;

    // Start the sprite batch.
    spriteBatch.begin(renderSession);

    // Start the filter manager.
    filterManager.begin(renderSession, buffer);

    // Render the scene!
    displayObject._renderWebGL(renderSession);

    // Finish the sprite batch.
    spriteBatch.end();
  }

  /// Resizes the webGL view to the specified width and height.
  void resize(int width, int height) {
    this.width = view.width = width;
    this.height = view.height = height;

    (context as gl.RenderingContext).viewport(0, 0, width, height);

    projection.x = width / 2;
    projection.y = -height / 2;
  }

  // Handles a lost webgl context.
  void _handleContextLost(gl.ContextEvent event) {
    event.preventDefault();
    _contextLost = true;
  }

  // Handles a restored webgl context.
  void _handleContextRestored(gl.ContextEvent event) {
    if (!supported) {
      throw new UnsupportedError(
          'This browser does not support webGL. Try using the canvas renderer.');
    }

    this.context = view.getContext3d(
        alpha: transparent,
        antialias: antialias,
        premultipliedAlpha: transparent,
        stencil: true,
        preserveDrawingBuffer: preserveDrawingBuffer);

    WebGLContextManager.current.remove(contextId);

    var context = this.context as gl.RenderingContext;
    contextId = WebGLContextManager.current.add(context);

    // Need to set the context.
    shaderManager.setContext(context);
    spriteBatch.setContext(context);
    filterManager.setContext(context);

    renderSession.context = context;

    context.disable(gl.DEPTH_TEST);
    context.disable(gl.CULL_FACE);

    context.enable(gl.BLEND);
    context.colorMask(true, true, true, transparent);

    context.viewport(0, 0, width, height);

    Texture._cache.values.forEach((texture) {
      texture.baseTexture._glTextures = new Map<int, gl.Texture>();
    });

    _contextLost = false;
  }

  /// Removes everything from the renderer (event listeners, spritebatch, etc).
  void destroy() {
    // Remove listeners.
    _listeners.forEach((listener) => listener.cancel());

    WebGLContextManager.current.remove(contextId);

    projection = null;
    offset = null;

    shaderManager.destroy();
    spriteBatch.destroy();
    filterManager.destroy();

    shaderManager = null;
    spriteBatch = null;
    maskManager = null;
    filterManager = null;

    context = null;

    renderSession = null;
  }
}
