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
class Strip extends DisplayObjectContainer {
  Texture texture;

  Float32List uvs;
  Float32List vertices;
  Float32List colors;
  Uint16List indices;

  bool _dirty = true;

  gl.Buffer _vertexBuffer, _indexBuffer, _uvBuffer, _colorBuffer;

  Strip(this.texture) {
    _init();
  }

  void _init() {
    // Set up the main bits.
    uvs = new Float32List.fromList([0, 1, 1, 1, 1, 0, 0, 1]);
    vertices = new Float32List.fromList([0, 0, 100, 0, 100, 100, 0, 100]);
    colors = new Float32List.fromList([1, 1, 1, 1]);
    indices = new Uint16List.fromList([0, 1, 2, 3]);
  }

  void _renderWebGL(WebGLRenderSession renderSession) {
    // If the sprite is not visible or the alpha is 0 then no need to render
    // this element
    if (!this.visible || this.alpha <= 0) return;

    renderSession.spriteBatch.stop();

    // Init! Init!
    if (this._vertexBuffer == null) _initWebGL(renderSession);

    renderSession.shaderManager.setShader(
        renderSession.shaderManager.stripShader);

    _renderStrip(renderSession);

    renderSession.spriteBatch.start();

    // TODO: check culling.
  }

  void _initWebGL(WebGLRenderSession renderSession) {
    // Build the strip!
    var context = renderSession.context as gl.RenderingContext;

    _vertexBuffer = context.createBuffer();
    _indexBuffer = context.createBuffer();
    _uvBuffer = context.createBuffer();
    _colorBuffer = context.createBuffer();

    context.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertices, gl.DYNAMIC_DRAW);

    context.bindBuffer(gl.ARRAY_BUFFER, _uvBuffer);
    context.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW);

    context.bindBuffer(gl.ARRAY_BUFFER, _colorBuffer);
    context.bufferData(gl.ARRAY_BUFFER, colors, gl.STATIC_DRAW);

    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);
  }

  void _renderStrip(WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;
    var projection = renderSession.projection,
        offset = renderSession.offset,
        shader = renderSession.shaderManager.stripShader;

    context.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

    // Set uniforms.
    context.uniformMatrix3fv(shader.translationMatrix, false,
        _worldTransform.asListTransposed());
    context.uniform2f(shader.projectionVector, projection.x, -projection.y);
    context.uniform2f(shader.offsetVector, -offset.x, -offset.y);
    context.uniform1f(shader.alpha, 1);

    if (!_dirty) {
      context.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
      context.bufferSubData(gl.ARRAY_BUFFER, 0, vertices);
      context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 0,
          0);

      // Update the uvs.
      context.bindBuffer(gl.ARRAY_BUFFER, _uvBuffer);
      context.vertexAttribPointer(shader.aTextureCoord, 2, gl.FLOAT, false, 0, 0
          );

      context.activeTexture(gl.TEXTURE0);

      var contextId = WebGLContextManager.current.id(context);
      gl.Texture texture = this.texture.baseTexture._glTextures[contextId];

      if (texture == null) {
        texture = WebGLRenderer._createWebGLTexture(this.texture.baseTexture,
            context);
      }

      // Bind the current texture.
      context.bindTexture(gl.TEXTURE_2D, texture);

      // Don't need to upload!
      context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
    } else {
      _dirty = false;
      context.bindBuffer(gl.ARRAY_BUFFER, _vertexBuffer);
      context.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
      context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 0,
          0);

      // update the uvs
      context.bindBuffer(gl.ARRAY_BUFFER, _uvBuffer);
      context.bufferData(gl.ARRAY_BUFFER, uvs, gl.STATIC_DRAW);
      context.vertexAttribPointer(shader.aTextureCoord, 2, gl.FLOAT, false, 0, 0
          );

      context.activeTexture(gl.TEXTURE0);

      var contextId = WebGLContextManager.current.id(context);
      gl.Texture texture = this.texture.baseTexture._glTextures[contextId];

      if (texture == null) {
        texture = WebGLRenderer._createWebGLTexture(this.texture.baseTexture,
            context);
      }

      context.bindTexture(gl.TEXTURE_2D, texture);

      // Don't need to upload!
      context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, _indexBuffer);
      context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices, gl.STATIC_DRAW);
    }

    context.drawElements(gl.TRIANGLE_STRIP, indices.length, gl.UNSIGNED_SHORT, 0
        );
  }

  void _renderCanvas(CanvasRenderSession renderSession) {
    var context = renderSession.context as CanvasRenderingContext2D;

    if (renderSession.roundPixels) {
      context.setTransform(_worldTransform.a, _worldTransform.c,
          _worldTransform.b, _worldTransform.d, _worldTransform.tx.truncateToDouble(),
          _worldTransform.ty.truncateToDouble());
    } else {
      context.setTransform(_worldTransform.a, _worldTransform.c,
          _worldTransform.b, _worldTransform.d, _worldTransform.tx, _worldTransform.ty);
    }

    var length = vertices.length / 2;

    for (int i = 0; i < length - 2; i++) {
      // Draw some triangles!
      int index = i * 2;

      double x0 = vertices[index],
          x1 = vertices[index + 2],
          x2 = vertices[index + 4];
      double y0 = vertices[index + 1],
          y1 = vertices[index + 3],
          y2 = vertices[index + 5];

      if (true) {
        double centerX = (x0 + x1 + x2) / 3;
        double centerY = (y0 + y1 + y2) / 3;

        double normX = x0 - centerX;
        double normY = y0 - centerY;

        double dist = math.sqrt(normX * normX + normY * normY);
        x0 = centerX + (normX / dist) * (dist + 3);
        y0 = centerY + (normY / dist) * (dist + 3);

        normX = x1 - centerX;
        normY = y1 - centerY;

        dist = math.sqrt(normX * normX + normY * normY);
        x1 = centerX + (normX / dist) * (dist + 3);
        y1 = centerY + (normY / dist) * (dist + 3);

        normX = x2 - centerX;
        normY = y2 - centerY;

        dist = math.sqrt(normX * normX + normY * normY);
        x2 = centerX + (normX / dist) * (dist + 3);
        y2 = centerY + (normY / dist) * (dist + 3);
      }

      double u0 = uvs[index] * texture._width,
          u1 = uvs[index + 2] * texture._width,
          u2 = uvs[index + 4] * texture._width;
      double v0 = uvs[index + 1] * texture._height,
          v1 = uvs[index + 3] * texture._height,
          v2 = uvs[index + 5] * texture._height;

      context.save();
      context.beginPath();

      context.moveTo(x0, y0);
      context.lineTo(x1, y1);
      context.lineTo(x2, y2);

      context.closePath();

      context.clip();

      // Compute matrix transform.
      double delta = u0 * v1 + v0 * u2 + u1 * v2 - v1 * u2 - v0 * u1 - u0 * v2;
      double deltaA = x0 * v1 + v0 * x2 + x1 * v2 - v1 * x2 - v0 * x1 - x0 * v2;
      double deltaB = u0 * x1 + x0 * u2 + u1 * x2 - x1 * u2 - x0 * u1 - u0 * x2;
      double deltaC = u0 * v1 * x2 + v0 * x1 * u2 + x0 * u1 * v2 - x0 * v1 * u2
          - v0 * u1 * x2 - u0 * x1 * v2;
      double deltaD = y0 * v1 + v0 * y2 + y1 * v2 - v1 * y2 - v0 * y1 - y0 * v2;
      double deltaE = u0 * y1 + y0 * u2 + u1 * y2 - y1 * u2 - y0 * u1 - u0 * y2;
      double deltaF = u0 * v1 * y2 + v0 * y1 * u2 + y0 * u1 * v2 - y0 * v1 * u2
          - v0 * u1 * y2 - u0 * y1 * v2;

      context.transform(deltaA / delta, deltaD / delta, deltaB / delta, deltaE /
          delta, deltaC / delta, deltaF / delta);

      context.drawImage(texture.baseTexture.source, 0, 0);
      context.restore();
    }
  }
}
