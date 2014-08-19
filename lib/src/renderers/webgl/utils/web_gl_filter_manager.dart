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
class WebGLFilterManager {
  bool transparent;

  List<FilterBlock> filterStack = new List<FilterBlock>();

  num offsetX = 0;
  num offsetY = 0;

  gl.RenderingContext context;

  List<FilterTexture> texturePool;

  gl.Buffer vertexBuffer;
  gl.Buffer uvBuffer;
  gl.Buffer colorBuffer;
  gl.Buffer indexBuffer;

  Float32List vertexList;
  Float32List uvList;
  Float32List colorList;

  WebGLRenderSession renderSession;

  PixiShader defaultShader;

  int width;
  int height;

  gl.Framebuffer buffer;

  WebGLFilterManager(gl.RenderingContext context, this.transparent) {
    setContext(context);
  }

  /// Initialises the context and the properties.
  void setContext(gl.RenderingContext context) {
    this.context = context;
    texturePool = new List<FilterTexture>();

    initShaderBuffers();
  }

  void begin(WebGLRenderSession renderSession, gl.Framebuffer buffer) {
    this.renderSession = renderSession;
    defaultShader = renderSession.shaderManager.defaultShader;

    var projection = renderSession.projection;

    width = (projection.x * 2).toInt();
    height = (-projection.y * 2).toInt();
    this.buffer = buffer;
  }

  /// Applies the filter and adds it to the current filter stack.
  void pushFilter(FilterBlock filterBlock) {
    var projection = renderSession.projection;
    var offset = renderSession.offset;

    filterBlock._filterArea = filterBlock._target.filterArea == null ?
        filterBlock._target.getBounds() : filterBlock._target.filterArea;

    // Filter program.
    // OPTIMISATION - the first filter is free if its a simple color change?
    filterStack.add(filterBlock);

    var filter = filterBlock.filterPasses[0];

    offsetX += filterBlock._filterArea.left;
    offsetY += filterBlock._filterArea.top;

    var texture;

    if (texturePool.isNotEmpty) texture = texturePool.removeLast();

    if (texture == null) {
      texture = new FilterTexture(context, width, height);
    } else {
      texture.resize(width, height);
    }

    context.bindTexture(gl.TEXTURE_2D, texture.texture);

    var filterArea = filterBlock._filterArea;
    var padding = filter._padding;

    filterArea.left -= padding;
    filterArea.top -= padding;
    filterArea.width += padding * 2;
    filterArea.height += padding * 2;

    // Cap filter to screen size.
    if (filterArea.left < 0) filterArea.left = 0;
    if (filterArea.width > width) filterArea.width = width;
    if (filterArea.top < 0) filterArea.top = 0;
    if (filterArea.height > height) filterArea.height = height;

    context.bindFramebuffer(gl.FRAMEBUFFER, texture.frameBuffer);

    // Set view port.
    context.viewport(0, 0, filterArea.width.round(), filterArea.height.round());

    projection.x = filterArea.width / 2;
    projection.y = -filterArea.height / 2;

    offset.x = -filterArea.left;
    offset.y = -filterArea.top;

    // Update projection.
    // Now restore the regular shader.
    renderSession.shaderManager.setShader(defaultShader);
    context.uniform2f(defaultShader.projectionVector, filterArea.width / 2,
        -filterArea.height / 2);
    context.uniform2f(defaultShader.offsetVector, -filterArea.left,
        -filterArea.top);

    context.colorMask(true, true, true, true);
    context.clearColor(0, 0, 0, 0);
    context.clear(gl.COLOR_BUFFER_BIT);

    filterBlock._glFilterTexture = texture;
  }

  /// Removes the last filter from the filter stack and doesn't return it.
  void popFilter() {
    var filterBlock = filterStack.removeLast();
    var filterArea = filterBlock._filterArea;
    var texture = filterBlock._glFilterTexture;
    var projection = renderSession.projection;
    var offset = renderSession.offset;

    if (filterBlock._filterPasses.length > 1) {
      context.viewport(0, 0, filterArea.width.round(), filterArea.height.round()
          );

      context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);

      vertexList[0] = 0.0;
      vertexList[1] = filterArea.height.toDouble();

      vertexList[2] = filterArea.width.toDouble();
      vertexList[3] = filterArea.height.toDouble();

      vertexList[4] = 0.0;
      vertexList[5] = 0.0;

      vertexList[6] = filterArea.width.toDouble();
      vertexList[7] = 0.0;

      context.bufferSubData(gl.ARRAY_BUFFER, 0, vertexList);

      context.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);

      // Now set the uvs.
      uvList[2] = filterArea.width / width;
      uvList[5] = filterArea.height / height;
      uvList[6] = filterArea.width / width;
      uvList[7] = filterArea.height / height;

      context.bufferSubData(gl.ARRAY_BUFFER, 0, uvList);

      var inputTexture = texture;
      var outputTexture;

      if (texturePool.isNotEmpty) outputTexture = texturePool.removeLast();

      if (outputTexture == null) {
        outputTexture = new FilterTexture(context, width, height);
      }

      outputTexture.resize(width, height);

      // Need to clear this FBO as it may have some left over elements from a
      // previous filter.
      context.bindFramebuffer(gl.FRAMEBUFFER, outputTexture.frameBuffer);
      context.clear(gl.COLOR_BUFFER_BIT);

      context.disable(gl.BLEND);

      for (var i = 0; i < filterBlock._filterPasses.length - 1; i++) {
        var filterPass = filterBlock._filterPasses[i];

        context.bindFramebuffer(gl.FRAMEBUFFER, outputTexture.frameBuffer);

        // Set texture.
        context.activeTexture(gl.TEXTURE0);
        context.bindTexture(gl.TEXTURE_2D, inputTexture.texture);

        // Draw texture.
        applyFilterPass(filterPass, filterArea, filterArea.width.round(),
            filterArea.height.round());

        // Swap the textures.
        var temp = inputTexture;
        inputTexture = outputTexture;
        outputTexture = temp;
      }

      context.enable(gl.BLEND);

      texture = inputTexture;
      texturePool.add(outputTexture);
    }

    var filter = filterBlock._filterPasses.last;

    this.offsetX -= filterArea.left;
    this.offsetY -= filterArea.top;

    var sizeX = width;
    var sizeY = height;

    var offsetX = 0;
    var offsetY = 0;

    var buffer = this.buffer;

    // Time to render the filters texture to the previous scene.
    if (filterStack.isEmpty) {
      context.colorMask(true, true, true, true);
    } else {
      var currentFilter = filterStack.last;
      filterArea = currentFilter._filterArea;

      sizeX = filterArea.width;
      sizeY = filterArea.height;

      offsetX = filterArea.left;
      offsetY = filterArea.top;

      buffer = currentFilter._glFilterTexture.frameBuffer;
    }

    // TODO: need to remove thease global elements.
    projection.x = sizeX / 2;
    projection.y = -sizeY / 2;

    offset.x = offsetX;
    offset.y = offsetY;

    filterArea = filterBlock._filterArea;

    var x = filterArea.left - offsetX;
    var y = filterArea.top - offsetY;

    // Update the buffers.
    // Make sure to flip the y!
    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);

    vertexList[0] = x.toDouble();
    vertexList[1] = (y + filterArea.height).toDouble();

    vertexList[2] = (x + filterArea.width).toDouble();
    vertexList[3] = (y + filterArea.height).toDouble();

    vertexList[4] = x.toDouble();
    vertexList[5] = y.toDouble();

    vertexList[6] = (x + filterArea.width).toDouble();
    vertexList[7] = y.toDouble();

    context.bufferSubData(gl.ARRAY_BUFFER, 0, vertexList);

    context.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);

    uvList[2] = filterArea.width / width;
    uvList[5] = filterArea.height / height;
    uvList[6] = filterArea.width / width;
    uvList[7] = filterArea.height / height;

    context.bufferSubData(gl.ARRAY_BUFFER, 0, uvList);

    context.viewport(0, 0, sizeX, sizeY);

    // Bind the buffer.
    context.bindFramebuffer(gl.FRAMEBUFFER, buffer);

    // Set texture.
    context.activeTexture(gl.TEXTURE0);
    context.bindTexture(gl.TEXTURE_2D, texture.texture);

    // Apply!
    applyFilterPass(filter, filterArea, sizeX, sizeY);

    // Now restore the regular shader.
    renderSession.shaderManager.setShader(defaultShader);
    context.uniform2f(defaultShader.projectionVector, sizeX / 2, -sizeY / 2);
    context.uniform2f(defaultShader.offsetVector, -offsetX, -offsetY);

    // Return the texture to the pool.
    texturePool.add(texture);
    filterBlock._glFilterTexture = null;
  }

  /// Applies the filter to the specified area.
  void applyFilterPass(Filter filter, Rectangle<num> filterArea, int width, int
      height) {
    // Use program.
    var shader = filter._shaders[WebGLContextManager.current.id(context)];

    if (shader == null) {
      shader = new PixiShader(context);

      shader.fragmentSrc = filter._fragmentSrc;
      shader.uniforms = filter._uniforms;
      shader.init();

      filter._shaders[WebGLContextManager.current.id(context)] = shader;
    }

    // Set the shader.
    renderSession.shaderManager.setShader(shader);

    context.uniform2f(shader.projectionVector, width / 2, -height / 2);
    context.uniform2f(shader.offsetVector, 0, 0);

    Uniform4fv dimensions = filter._uniforms.firstWhere((uniform) {
      return uniform.name == 'dimensions';
    }, orElse: () => null);

    if (dimensions != null) {
      dimensions.value[0] = width.toDouble();
      dimensions.value[1] = height.toDouble();
      dimensions.value[2] = vertexList[0];
      dimensions.value[3] = vertexList[5];
    }

    shader.syncUniforms();

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 0, 0
        );

    context.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);
    context.vertexAttribPointer(shader.aTextureCoord, 2, gl.FLOAT, false, 0, 0);

    context.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    context.vertexAttribPointer(shader.colorAttribute, 2, gl.FLOAT, false, 0, 0
        );

    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);

    // Draw the filter.
    context.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0);

    renderSession.drawCount++;
  }

  /// Initialises the shader buffers.
  void initShaderBuffers() {
    // Create some buffers.
    vertexBuffer = context.createBuffer();
    uvBuffer = context.createBuffer();
    colorBuffer = context.createBuffer();
    indexBuffer = context.createBuffer();

    // Bind and upload the vertexs.
    // Keep a reference to the vertexFloatData.
    vertexList = new Float32List.fromList([0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        1.0]);

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertexList, gl.STATIC_DRAW);

    // Bind and upload the uv buffer.
    uvList = new Float32List.fromList([0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0]);

    context.bindBuffer(gl.ARRAY_BUFFER, uvBuffer);
    context.bufferData(gl.ARRAY_BUFFER, uvList, gl.STATIC_DRAW);

    colorList = new Float32List.fromList([1.0, 0xFFFFFF.toDouble(), 1.0,
        0xFFFFFF.toDouble(), 1.0, 0xFFFFFF.toDouble(), 1.0, 0xFFFFFF.toDouble()]);

    context.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
    context.bufferData(gl.ARRAY_BUFFER, colorList, gl.STATIC_DRAW);

    // Bind and upload the index.
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16List.fromList([0, 1,
        2, 1, 3, 2]), gl.STATIC_DRAW);
  }

  /// Destroys the filter and removes it from the filter stack.
  void destroy() {
    filterStack = null;

    offsetX = 0;
    offsetY = 0;

    // Destroy textures.
    texturePool.forEach((filterTexture) => filterTexture.destroy());

    texturePool = null;

    // Destroy buffers.
    context.deleteBuffer(vertexBuffer);
    context.deleteBuffer(uvBuffer);
    context.deleteBuffer(colorBuffer);
    context.deleteBuffer(indexBuffer);
  }
}
