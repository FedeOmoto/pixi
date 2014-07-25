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
class WebGLSpriteBatch {
  gl.RenderingContext context;

  int vertSize = 6;

  /// The number of images in the SpriteBatch before it flushes.
  int size = 2000;

  /// The total number of floats in our batch.
  int numVerts;

  /// The total number of indices in our batch.
  int numIndices;

  /// Holds the vertices.
  Float32List vertices;

  /// Holds the indices.
  Uint16List indices;

  int lastIndexCount = 0;

  bool drawing = false;

  int currentBatchSize = 0;

  BaseTexture currentBaseTexture;

  gl.Buffer vertexBuffer, indexBuffer;

  BlendModes<int> currentBlendMode;

  WebGLRenderSession renderSession;

  PixiShader shader;

  WebGLSpriteBatch(gl.RenderingContext context) {
    numVerts = size * 4 * vertSize;
    numIndices = size * 6;
    vertices = new Float32List(numVerts);
    indices = new Uint16List(numIndices);

    for (var i = 0,
        j = 0; i < numIndices; i += 6, j += 4) {
      indices[i + 0] = j + 0;
      indices[i + 1] = j + 1;
      indices[i + 2] = j + 2;
      indices[i + 3] = j + 0;
      indices[i + 4] = j + 2;
      indices[i + 5] = j + 3;
    }

    setContext(context);
  }

  void setContext(gl.RenderingContext context) {
    this.context = context;

    // Create a couple of buffers.
    vertexBuffer = context.createBuffer();
    indexBuffer = context.createBuffer();

    // 65535 is max index, so 65535 / 6 = 10922.


    // Upload the index data.
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertices, gl.DYNAMIC_DRAW);

    currentBlendMode = const BlendModes(99999);
  }

  void begin(WebGLRenderSession renderSession) {
    this.renderSession = renderSession;
    shader = renderSession.shaderManager.defaultShader;

    start();
  }

  void end() => flush();

  void render(Sprite sprite) {
    var texture = sprite.texture;

    // Check texture.
    if (texture.baseTexture != currentBaseTexture || currentBatchSize >= size) {
      flush();
      currentBaseTexture = texture.baseTexture;
    }

    // Check blend mode.
    if (sprite.blendMode != currentBlendMode) setBlendMode(sprite.blendMode);

    // Get the uvs for the texture.
    var uvs = texture._uvs;

    // If the uvs have not updated then no point rendering just yet!
    if (uvs == null) return;

    // Get the sprite's current alpha.
    var alpha = sprite._worldAlpha;

    // Get the sprite's current tint.
    var tint = sprite.tint;

    // TODO: trim??
    var aX = sprite.anchor.x;
    var aY = sprite.anchor.y;

    var w0, w1, h0, h1;

    if (texture.trim != null) {
      // If the sprite is trimmed then we need to add the extra space before
      // transforming the sprite coords.
      var trim = texture.trim;

      w1 = trim.left - aX * trim.width;
      w0 = w1 + texture.frame.width;

      h1 = trim.top - aY * trim.height;
      h0 = h1 + texture.frame.height;
    } else {
      w0 = (texture.frame.width) * (1 - aX);
      w1 = (texture.frame.width) * -aX;

      h0 = texture.frame.height * (1 - aY);
      h1 = texture.frame.height * -aY;
    }

    var index = currentBatchSize * 4 * vertSize;

    var worldTransform = sprite._worldTransform;

    var a = worldTransform.a; // [0];
    var b = worldTransform.c; // [3];
    var c = worldTransform.b; // [1];
    var d = worldTransform.d; // [4];
    var tx = worldTransform.tx; // [2];
    var ty = worldTransform.ty; // [5];

    // xy
    vertices[index++] = a * w1 + c * h1 + tx;
    vertices[index++] = d * h1 + b * w1 + ty;

    // uv
    vertices[index++] = uvs.x0;
    vertices[index++] = uvs.y0;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w0 + c * h1 + tx;
    vertices[index++] = d * h1 + b * w0 + ty;

    // uv
    vertices[index++] = uvs.x1;
    vertices[index++] = uvs.y1;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w0 + c * h0 + tx;
    vertices[index++] = d * h0 + b * w0 + ty;

    // uv
    vertices[index++] = uvs.x2;
    vertices[index++] = uvs.y2;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w1 + c * h0 + tx;
    vertices[index++] = d * h0 + b * w1 + ty;

    // uv
    vertices[index++] = uvs.x3;
    vertices[index++] = uvs.y3;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // Increment the batchsize.
    currentBatchSize++;
  }

  /// Renders a [TilingSprite] using the spriteBatch.
  void renderTilingSprite(TilingSprite tilingSprite) {
    var texture = tilingSprite.tilingTexture;

    if (texture.baseTexture != currentBaseTexture || currentBatchSize >= size) {
      flush();
      currentBaseTexture = texture.baseTexture;
    }

    // Check blend mode.
    if (tilingSprite.blendMode != currentBlendMode) {
      setBlendMode(tilingSprite.blendMode);
    }

    // Set the texture's uvs temporarily.
    // TODO: create a separate texture so that we can tile part of a texture.

    if (tilingSprite._uvs == null) tilingSprite._uvs = new TextureUvs();

    var uvs = tilingSprite._uvs;

    tilingSprite.tilePosition.x %= (texture.baseTexture.width *
        tilingSprite.tileScaleOffset.x).toInt();
    tilingSprite.tilePosition.y %= (texture.baseTexture.height *
        tilingSprite.tileScaleOffset.y).toInt();

    var offsetX = tilingSprite.tilePosition.x / (texture.baseTexture.width *
        tilingSprite.tileScaleOffset.x);
    var offsetY = tilingSprite.tilePosition.y / (texture.baseTexture.height *
        tilingSprite.tileScaleOffset.y);

    var scaleX = (tilingSprite.width / texture.baseTexture.width) /
        (tilingSprite.tileScale.x * tilingSprite.tileScaleOffset.x);
    var scaleY = (tilingSprite.height / texture.baseTexture.height) /
        (tilingSprite.tileScale.y * tilingSprite.tileScaleOffset.y);

    uvs.x0 = 0 - offsetX;
    uvs.y0 = 0 - offsetY;

    uvs.x1 = (1 * scaleX) - offsetX;
    uvs.y1 = 0 - offsetY;

    uvs.x2 = (1 * scaleX) - offsetX;
    uvs.y2 = (1 * scaleY) - offsetY;

    uvs.x3 = 0 - offsetX;
    uvs.y3 = (1 * scaleY) - offsetY;

    // Get the tilingSprite's current alpha.
    var alpha = tilingSprite._worldAlpha;

    // Get the tilingSprite's current tint.
    var tint = tilingSprite.tint;

    // TODO: trim??
    var aX = tilingSprite.anchor.x;
    var aY = tilingSprite.anchor.y;
    var w0 = tilingSprite.width * (1 - aX);
    var w1 = tilingSprite.width * -aX;

    var h0 = tilingSprite.height * (1 - aY);
    var h1 = tilingSprite.height * -aY;

    var index = currentBatchSize * 4 * vertSize;

    var worldTransform = tilingSprite._worldTransform;

    var a = worldTransform.a; // [0];
    var b = worldTransform.c; // [3];
    var c = worldTransform.b; // [1];
    var d = worldTransform.d; // [4];
    var tx = worldTransform.tx; // [2];
    var ty = worldTransform.ty; // [5];

    // xy
    vertices[index++] = a * w1 + c * h1 + tx;
    vertices[index++] = d * h1 + b * w1 + ty;

    // uv
    vertices[index++] = uvs.x0;
    vertices[index++] = uvs.y0;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w0 + c * h1 + tx;
    vertices[index++] = d * h1 + b * w0 + ty;

    // uv
    vertices[index++] = uvs.x1;
    vertices[index++] = uvs.y1;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w0 + c * h0 + tx;
    vertices[index++] = d * h0 + b * w0 + ty;

    // uv
    vertices[index++] = uvs.x2;
    vertices[index++] = uvs.y2;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // xy
    vertices[index++] = a * w1 + c * h0 + tx;
    vertices[index++] = d * h0 + b * w1 + ty;

    // uv
    vertices[index++] = uvs.x3;
    vertices[index++] = uvs.y3;

    // color
    vertices[index++] = alpha;
    vertices[index++] = tint.argbValue.toDouble();

    // Increment the batchs.
    currentBatchSize++;
  }

  /// Renders the content and empties the current batch.
  void flush() {
    // If the batch is length 0 then return as there is nothing to draw.
    if (currentBatchSize == 0) return;

    var contextId = WebGLContextManager.current.id(context);
    var texture = currentBaseTexture._glTextures[contextId];

    if (texture == null) {
      texture = WebGLRenderer._createWebGLTexture(currentBaseTexture, context);
    }

    // Bind the current texture.
    context.bindTexture(gl.TEXTURE_2D, texture);

    // Upload the verts to the buffer.

    if (currentBatchSize > (size * 0.5)) {
      context.bufferSubData(gl.ARRAY_BUFFER, 0, vertices);
    } else {
      var view = vertices.sublist(0, currentBatchSize * 4 * vertSize);
      context.bufferSubData(gl.ARRAY_BUFFER, 0, view);
    }

    // Now draw those suckas!
    context.drawElements(gl.TRIANGLES, currentBatchSize * 6, gl.UNSIGNED_SHORT,
        0);

    // Then reset the batch!
    currentBatchSize = 0;

    // Increment the draw count.
    renderSession.drawCount++;
  }

  void stop() => flush();

  void start() {
    // Bind the main texture.
    context.activeTexture(gl.TEXTURE0);

    // Bind the buffers.
    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);

    // Set the projection.
    var projection = renderSession.projection;
    context.uniform2f(shader.projectionVector, projection.x, projection.y);

    // Set the pointers.
    var stride = vertSize * 4;
    context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false,
        stride, 0);
    context.vertexAttribPointer(shader.aTextureCoord, 2, gl.FLOAT, false,
        stride, 2 * 4);
    context.vertexAttribPointer(shader.colorAttribute, 2, gl.FLOAT, false,
        stride, 4 * 4);

    // Set the blend mode.
    if (currentBlendMode != BlendModes.NORMAL) setBlendMode(BlendModes.NORMAL);
  }

  /// Sets-up the given blendMode from WebGL's point of view.
  void setBlendMode(BlendModes<int> blendMode) {
    flush();

    currentBlendMode = blendMode;

    var blendModeWebGL = WebGLRenderer.BLEND_MODES[currentBlendMode.value];
    context.blendFunc(blendModeWebGL[0], blendModeWebGL[1]);
  }

  /// Destroys the SpriteBatch.
  void destroy() {
    vertices = null;
    indices = null;

    context.deleteBuffer(vertexBuffer);
    context.deleteBuffer(indexBuffer);

    currentBaseTexture = null;

    context = null;
  }
}
