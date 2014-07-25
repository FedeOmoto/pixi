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
 * This class provides a set of methods used by the WebGL renderer to draw the
 * primitive graphics data.
 */
class WebGLGraphics {
  /// Answer the singleton instance of the CanvasGraphics class.
  static WebGLGraphics get current => WebGLGraphics._singleton;

  static final WebGLGraphics _singleton = new WebGLGraphics._internal();

  factory WebGLGraphics() {
    throw new UnsupportedError(
        'WebGLGraphics cannot be instantiated, use WebGLGraphics.current');
  }

  WebGLGraphics._internal();

  // Renders the graphics object.
  void _renderGraphics(Graphics graphics, WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;
    var projection = renderSession.projection,
        offset = renderSession.offset,
        shader = renderSession.shaderManager.primitiveShader;

    int contextId = WebGLContextManager.current.id(context);

    if (graphics._webGL[contextId] == null) {
      graphics._webGL[contextId] = new WebGLProperties(context);
    }

    var webGL = graphics._webGL[contextId];

    if (graphics._dirty) {
      graphics._dirty = false;

      if (graphics._clearDirty) {
        graphics._clearDirty = false;

        webGL.lastIndex = 0;
        webGL.points.clear();
        webGL.indices.clear();
      }

      _updateGraphics(graphics, context);
    }

    renderSession.shaderManager.activatePrimitiveShader();

    // This  could be speeded up for sure!

    // Set the matrix transform.
    context.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

    context.uniformMatrix3fv(shader.translationMatrix, false,
        graphics._worldTransform.asListTransposed());

    context.uniform2f(shader.projectionVector, projection.x, -projection.y);
    context.uniform2f(shader.offsetVector, -offset.x, -offset.y);

    var rgba = graphics.tint.rgba;
    context.uniform3fv(shader.tintColor, new Float32List.fromList([rgba.r / 255,
        rgba.g / 255, rgba.b / 255]));

    context.uniform1f(shader.alpha, graphics._worldAlpha);
    context.bindBuffer(gl.ARRAY_BUFFER, webGL.buffer);

    context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 4 *
        6, 0);
    context.vertexAttribPointer(shader.colorAttribute, 4, gl.FLOAT, false, 4 *
        6, 2 * 4);

    // Set the index buffer!
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, webGL.indexBuffer);

    context.drawElements(gl.TRIANGLE_STRIP, webGL.indices.length,
        gl.UNSIGNED_SHORT, 0);

    renderSession.shaderManager.deactivatePrimitiveShader();
  }

  // Updates the graphics object.
  void _updateGraphics(Graphics graphics, gl.RenderingContext context) {
    var webGL = graphics._webGL[WebGLContextManager.current.id(context)];

    for (int i = webGL.lastIndex; i < graphics.graphicsData.length; i++) {
      var data = graphics.graphicsData[i];

      // TODO: refactor this into a switch.
      if (data.type == Graphics.POLY) {
        if (data.fill) {
          if (data.points.length > 3) _buildPoly(data, webGL);
        }

        if (data.lineWidth > 0) {
          _buildLine(data, webGL);
        }
      } else if (data.type == Graphics.RECT) {
        _buildRectangle(data, webGL);
      } else if (data.type == Graphics.CIRC || data.type == Graphics.ELIP) {
        _buildCircle(data, webGL);
      }
    }

    webGL.lastIndex = graphics.graphicsData.length;

    webGL.glPoints = new Float32List.fromList(webGL.points);

    context.bindBuffer(gl.ARRAY_BUFFER, webGL.buffer);
    context.bufferData(gl.ARRAY_BUFFER, webGL.glPoints, gl.STATIC_DRAW);

    webGL.glIndices = new Uint16List.fromList(webGL.indices);

    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, webGL.indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, webGL.glIndices, gl.STATIC_DRAW
        );
  }

  // Builds a rectangle to draw.
  void _buildRectangle(Path graphicsData, WebGLProperties webGLData) {
    // Need to convert points to a nice regular data.
    var rectData = graphicsData.points;
    var x = rectData[0];
    var y = rectData[1];
    var width = rectData[2];
    var height = rectData[3];

    if (graphicsData.fill) {
      var rgba = graphicsData.fillColor.rgba;
      var alpha = graphicsData.fillAlpha;

      var r = rgba.r / 255 * alpha;
      var g = rgba.g / 255 * alpha;
      var b = rgba.b / 255 * alpha;

      var verts = webGLData.points;
      var indices = webGLData.indices;

      var vertPos = verts.length ~/ 6;

      // Start.
      verts.addAll([x.toDouble(), y.toDouble()]);
      verts.addAll([r, g, b, alpha]);

      verts.addAll([(x + width).toDouble(), y.toDouble()]);
      verts.addAll([r, g, b, alpha]);

      verts.addAll([x.toDouble(), (y + height).toDouble()]);
      verts.addAll([r, g, b, alpha]);

      verts.addAll([(x + width).toDouble(), (y + height).toDouble()]);
      verts.addAll([r, g, b, alpha]);

      // Insert 2 dead triangles.
      indices.addAll([vertPos, vertPos, vertPos + 1, vertPos + 2, vertPos + 3,
          vertPos + 3]);
    }

    if (graphicsData.lineWidth != 0) {
      var tempPoints = graphicsData.points;

      graphicsData.points = [x, y, x + width, y, x + width, y + height, x, y +
          height, x, y];

      _buildLine(graphicsData, webGLData);

      graphicsData.points = tempPoints;
    }
  }

  // Builds a circle to draw.
  void _buildCircle(Path graphicsData, WebGLProperties webGLData) {
    // Need to convert points to a nice regular data.
    var rectData = graphicsData.points;
    var x = rectData[0];
    var y = rectData[1];
    var width = rectData[2];
    var height = rectData[3];

    var totalSegs = 40;
    var seg = (math.PI * 2) / totalSegs;

    if (graphicsData.fill) {
      var rgba = graphicsData.fillColor.rgba;
      var alpha = graphicsData.fillAlpha;

      var r = rgba.r / 255 * alpha;
      var g = rgba.g / 255 * alpha;
      var b = rgba.b / 255 * alpha;

      var verts = webGLData.points;
      var indices = webGLData.indices;

      var vecPos = verts.length ~/ 6;

      indices.add(vecPos);

      for (int i = 0; i < totalSegs + 1; i++) {
        verts.addAll([x.toDouble(), y.toDouble(), r, g, b, alpha]);

        verts.addAll([x + math.sin(seg * i) * width, y + math.cos(seg * i) *
            height, r, g, b, alpha]);

        indices.addAll([vecPos++, vecPos++]);
      }

      indices.add(vecPos - 1);
    }

    if (graphicsData.lineWidth != 0) {
      var tempPoints = graphicsData.points;

      graphicsData.points = new List<num>();

      for (int i = 0; i < totalSegs + 1; i++) {
        graphicsData.points.addAll([x + math.sin(seg * i) * width, y + math.cos(
            seg * i) * height]);
      }

      _buildLine(graphicsData, webGLData);

      graphicsData.points = tempPoints;
    }
  }

  // Builds a line to draw.
  void _buildLine(Path graphicsData, WebGLProperties webGLData) {
    // TODO: OPTIMISE!

    var points = graphicsData.points;
    if (points.isEmpty) return;

    // If the line width is an odd number add 0.5 to align to a whole pixel.
    if (graphicsData.lineWidth.isOdd) {
      for (int i = 0; i < points.length; i++) {
        points[i] += 0.5;
      }
    }

    // Get first and last point... figure out the middle!
    var firstPoint = new Point<num>(points[0], points[1]);
    var lastPoint = new Point<num>(points[points.length - 2], points.last);

    // If the first point is the last point - gonna have issues :)
    if (firstPoint == lastPoint) {
      points.removeLast();
      points.removeLast();

      lastPoint = new Point<num>(points[points.length - 2], points.last);

      var midPointX = lastPoint.x + (firstPoint.x - lastPoint.x) * 0.5;
      var midPointY = lastPoint.y + (firstPoint.y - lastPoint.y) * 0.5;

      points.insertAll(0, [midPointX, midPointY]);
      points.addAll([midPointX, midPointY]);
    }

    var verts = webGLData.points;
    var indices = webGLData.indices;
    var length = points.length ~/ 2;
    var indexCount = points.length;
    var indexStart = verts.length ~/ 6;

    // Draw the Line.
    var width = graphicsData.lineWidth / 2;

    // Sort color.
    var rgba = graphicsData.lineColor.rgba;
    var alpha = graphicsData.lineAlpha;

    var r = rgba.r / 255 * alpha;
    var g = rgba.g / 255 * alpha;
    var b = rgba.b / 255 * alpha;

    var px, py, p1x, p1y, p2x, p2y, p3x, p3y;
    var perpx, perpy, perp2x, perp2y, perp3x, perp3y;
    var a1, b1, c1, a2, b2, c2;
    var denom, pdist, dist;

    p1x = points[0];
    p1y = points[1];

    p2x = points[2];
    p2y = points[3];

    perpx = -(p1y - p2y);
    perpy = p1x - p2x;

    dist = math.sqrt(perpx * perpx + perpy * perpy);

    perpx /= dist;
    perpy /= dist;
    perpx *= width;
    perpy *= width;

    // Start.
    verts.addAll([p1x - perpx, p1y - perpy, r, g, b, alpha]);

    verts.addAll([p1x + perpx, p1y + perpy, r, g, b, alpha]);

    for (int i = 1; i < length - 1; i++) {
      p1x = points[(i - 1) * 2];
      p1y = points[(i - 1) * 2 + 1];

      p2x = points[(i) * 2];
      p2y = points[(i) * 2 + 1];

      p3x = points[(i + 1) * 2];
      p3y = points[(i + 1) * 2 + 1];

      perpx = -(p1y - p2y);
      perpy = p1x - p2x;

      dist = math.sqrt(perpx * perpx + perpy * perpy);
      perpx /= dist;
      perpy /= dist;
      perpx *= width;
      perpy *= width;

      perp2x = -(p2y - p3y);
      perp2y = p2x - p3x;

      dist = math.sqrt(perp2x * perp2x + perp2y * perp2y);
      perp2x /= dist;
      perp2y /= dist;
      perp2x *= width;
      perp2y *= width;

      a1 = (-perpy + p1y) - (-perpy + p2y);
      b1 = (-perpx + p2x) - (-perpx + p1x);
      c1 = (-perpx + p1x) * (-perpy + p2y) - (-perpx + p2x) * (-perpy + p1y);
      a2 = (-perp2y + p3y) - (-perp2y + p2y);
      b2 = (-perp2x + p2x) - (-perp2x + p3x);
      c2 = (-perp2x + p3x) * (-perp2y + p2y) - (-perp2x + p2x) * (-perp2y +
          p3y);

      denom = a1 * b2 - a2 * b1;

      if (denom.abs() < 0.1) {
        denom += 10.1;
        verts.addAll([p2x - perpx, p2y - perpy, r, g, b, alpha]);

        verts.addAll([p2x + perpx, p2y + perpy, r, g, b, alpha]);

        continue;
      }

      px = (b1 * c2 - b2 * c1) / denom;
      py = (a2 * c1 - a1 * c2) / denom;

      pdist = (px - p2x) * (px - p2x) + (py - p2y) + (py - p2y);

      if (pdist > 140 * 140) {
        perp3x = perpx - perp2x;
        perp3y = perpy - perp2y;

        dist = math.sqrt(perp3x * perp3x + perp3y * perp3y);
        perp3x /= dist;
        perp3y /= dist;
        perp3x *= width;
        perp3y *= width;

        verts.addAll([p2x - perp3x, p2y - perp3y]);
        verts.addAll([r, g, b, alpha]);

        verts.addAll([p2x + perp3x, p2y + perp3y]);
        verts.addAll([r, g, b, alpha]);

        verts.addAll([p2x - perp3x, p2y - perp3y]);
        verts.addAll([r, g, b, alpha]);

        indexCount++;
      } else {
        verts.addAll([px, py]);
        verts.addAll([r, g, b, alpha]);

        verts.addAll([p2x - (px - p2x), p2y - (py - p2y)]);
        verts.addAll([r, g, b, alpha]);
      }
    }

    p1x = points[(length - 2) * 2];
    p1y = points[(length - 2) * 2 + 1];

    p2x = points[(length - 1) * 2];
    p2y = points[(length - 1) * 2 + 1];

    perpx = -(p1y - p2y);
    perpy = p1x - p2x;

    dist = math.sqrt(perpx * perpx + perpy * perpy);
    perpx /= dist;
    perpy /= dist;
    perpx *= width;
    perpy *= width;

    verts.addAll([p2x - perpx, p2y - perpy]);
    verts.addAll([r, g, b, alpha]);

    verts.addAll([p2x + perpx, p2y + perpy]);
    verts.addAll([r, g, b, alpha]);

    indices.add(indexStart);

    for (int i = 0; i < indexCount; i++) {
      indices.add(indexStart++);
    }

    indices.add(indexStart - 1);
  }

  // Builds a polygon to draw.
  void _buildPoly(Path graphicsData, WebGLProperties webGLData) {
    var points = graphicsData.points;
    if (points.length < 6) return;

    // Get first and last point... figure out the middle!
    var verts = webGLData.points;
    var indices = webGLData.indices;

    var length = points.length ~/ 2;

    // Sort color.
    var rgba = graphicsData.fillColor.rgba;
    var alpha = graphicsData.fillAlpha;

    var r = rgba.r / 255 * alpha;
    var g = rgba.g / 255 * alpha;
    var b = rgba.b / 255 * alpha;

    var triangles = PolyK.current.triangulate(points);

    var vertPos = verts.length ~/ 6;

    for (int i = 0; i < triangles.length; i += 3) {
      indices.add(triangles[i] + vertPos);
      indices.add(triangles[i] + vertPos);
      indices.add(triangles[i + 1] + vertPos);
      indices.add(triangles[i + 2] + vertPos);
      indices.add(triangles[i + 2] + vertPos);
    }

    for (int i = 0; i < length; i++) {
      verts.addAll([(points[i * 2]).toDouble(), (points[i * 2 + 1]).toDouble(),
          r, g, b, alpha]);
    }
  }
}
