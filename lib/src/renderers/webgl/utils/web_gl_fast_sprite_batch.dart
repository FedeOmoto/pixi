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
class WebGLFastSpriteBatch {
  int vertSize = 10;
  int maxSize = 6000;
  int size;

  Float32List vertices;
  Uint16List indices;

  gl.Buffer vertexBuffer;
  gl.Buffer indexBuffer;

  int lastIndexCount = 0;

  bool drawing = false;
  int currentBatchSize = 0;
  BaseTexture currentBaseTexture;

  BlendModes currentBlendMode = BlendModes.NORMAL;
  WebGLRenderSession renderSession;

  PixiFastShader shader;

  Float32List matrix;

  gl.RenderingContext context;

  WebGLFastSpriteBatch(gl.RenderingContext context) {
    size = maxSize;

    // The total number of floats in our batch.
    int numVerts = size * 4 * vertSize;

    // The total number of indices in our batch.
    int numIndices = maxSize * 6;

    // Vertex data.
    vertices = new Float32List(numVerts);

    // Index data.
    indices = new Uint16List(numIndices);

    for (int i = 0,
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

    // Upload the index data.
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertices, gl.DYNAMIC_DRAW);
  }

  void begin(SpriteBatch spriteBatch, WebGLRenderSession renderSession) {
    this.renderSession = renderSession;
    shader = renderSession.shaderManager.fastShader;

    matrix = spriteBatch._worldTransform.asListTransposed();

    start();
  }

  void end() {
    flush();
  }

  void render(SpriteBatch spriteBatch) {
    var children = spriteBatch.children;
    var sprite = children.first as Sprite;

    // If the uvs have not updated then no point rendering just yet!
    if (sprite.texture._uvs == null) return;

    // Check texture.
    this.currentBaseTexture = sprite.texture.baseTexture;

    // Check blend mode.
    if (sprite.blendMode != renderSession.blendModeManager.currentBlendMode) {
      flush();
      renderSession.blendModeManager.setBlendMode(sprite.blendMode);
    }

    children.forEach((child) => renderSprite(child));

    flush();
  }

  void renderSprite(Sprite sprite) {
    if (!sprite.visible) return;

    // TODO: trim??
    if (!identical(sprite.texture.baseTexture, currentBaseTexture)) {
      flush();
      currentBaseTexture = sprite.texture.baseTexture;

      if (sprite.texture._uvs == null) return;
    }

    var uvs, width, height, w0, w1, h0, h1, index;

    uvs = sprite.texture._uvs;

    width = sprite.texture.frame.width;
    height = sprite.texture.frame.height;

    if (sprite.texture.trim != null) {
      // If the sprite is trimmed then we need to add the extra space before
      // transforming the sprite coords.
      var trim = sprite.texture.trim;

      w1 = trim.left - sprite.anchor.x * trim.width;
      w0 = w1 + sprite.texture.crop.width;

      h1 = trim.top - sprite.anchor.y * trim.height;
      h0 = h1 + sprite.texture.crop.height;
    } else {
      w0 = (sprite.texture.frame.width) * (1 - sprite.anchor.x);
      w1 = (sprite.texture.frame.width) * -sprite.anchor.x;

      h0 = sprite.texture.frame.height * (1 - sprite.anchor.y);
      h1 = sprite.texture.frame.height * -sprite.anchor.y;
    }

    index = currentBatchSize * 4 * vertSize;

    // xy.
    vertices[index++] = w1;
    vertices[index++] = h1;

    vertices[index++] = sprite.position.x;
    vertices[index++] = sprite.position.y;

    // Scale.
    vertices[index++] = sprite.scale.x;
    vertices[index++] = sprite.scale.y;

    // Rotation
    vertices[index++] = sprite.rotation;

    // uv.
    vertices[index++] = uvs.x0;
    vertices[index++] = uvs.y1;

    // Color.
    vertices[index++] = sprite.alpha;

    // xy.
    vertices[index++] = w0;
    vertices[index++] = h1;

    vertices[index++] = sprite.position.x;
    vertices[index++] = sprite.position.y;

    // Scale.
    vertices[index++] = sprite.scale.x;
    vertices[index++] = sprite.scale.y;

    // Rotation.
    vertices[index++] = sprite.rotation;

    // uv
    vertices[index++] = uvs.x1;
    vertices[index++] = uvs.y1;

    // Color.
    vertices[index++] = sprite.alpha;

    // xy.
    vertices[index++] = w0;
    vertices[index++] = h0;

    vertices[index++] = sprite.position.x;
    vertices[index++] = sprite.position.y;

    // Scale.
    vertices[index++] = sprite.scale.x;
    vertices[index++] = sprite.scale.y;

    // Rotation.
    vertices[index++] = sprite.rotation;

    // uv.
    vertices[index++] = uvs.x2;
    vertices[index++] = uvs.y2;

    // Color.
    vertices[index++] = sprite.alpha;

    // xy.
    vertices[index++] = w1;
    vertices[index++] = h0;

    vertices[index++] = sprite.position.x;
    vertices[index++] = sprite.position.y;

    // Scale.
    vertices[index++] = sprite.scale.x;
    vertices[index++] = sprite.scale.y;

    // Rotation.
    vertices[index++] = sprite.rotation;

    // uv.
    vertices[index++] = uvs.x3;
    vertices[index++] = uvs.y3;

    // Color.
    vertices[index++] = sprite.alpha;

    // Increment the batchs.
    currentBatchSize++;

    if (currentBatchSize >= size) flush();
  }

  void flush() {
    // If the batch is length 0 then return as there is nothing to draw.
    if (currentBatchSize == 0) return;

    int contextId = WebGLContextManager.current.id(context);

    if (currentBaseTexture._glTextures[contextId] == null) {
      WebGLRenderer._createWebGLTexture(currentBaseTexture, context);
    }

    // Bind the current texture.
    context.bindTexture(gl.TEXTURE_2D, currentBaseTexture._glTextures[contextId]
        );

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

    // Increment the draw count
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

    // Set the matrix.
    context.uniformMatrix3fv(shader.uMatrix, false, matrix);

    // Set the pointers.
    var stride = vertSize * 4;

    context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false,
        stride, 0);
    context.vertexAttribPointer(shader.aPositionCoord, 2, gl.FLOAT, false,
        stride, 2 * 4);
    context.vertexAttribPointer(shader.aScale, 2, gl.FLOAT, false, stride, 4 * 4
        );
    context.vertexAttribPointer(shader.aRotation, 1, gl.FLOAT, false, stride, 6
        * 4);
    context.vertexAttribPointer(shader.aTextureCoord, 2, gl.FLOAT, false,
        stride, 7 * 4);
    context.vertexAttribPointer(shader.colorAttribute, 1, gl.FLOAT, false,
        stride, 9 * 4);
  }
}
