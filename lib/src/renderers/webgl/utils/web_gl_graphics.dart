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
  static List<WebGLGraphicsData> _graphicsDataPool =
      new List<WebGLGraphicsData>();

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

    if (graphics._dirty) {
      _updateGraphics(graphics, context);
    }

    int contextId = WebGLContextManager.current.id(context);
    var webGL = graphics._webGL[contextId];

    // This  could be speeded up for sure!

    webGL.data.forEach((webGLData) {
      if (webGLData.mode == 1) {
        renderSession.stencilManager.pushStencil(graphics, webGLData,
            renderSession);

        // Render quad.
        context.drawElements(gl.TRIANGLE_FAN, 4, gl.UNSIGNED_SHORT,
            (webGLData.indices.length - 4) * 2);

        renderSession.stencilManager.popStencil(graphics, webGLData,
            renderSession);
      } else {
        renderSession.shaderManager.setShader(shader);
        shader = renderSession.shaderManager.primitiveShader;
        context.uniformMatrix3fv(shader.translationMatrix, false,
            graphics._worldTransform.asListTransposed());

        context.uniform2f(shader.projectionVector, projection.x, -projection.y);
        context.uniform2f(shader.offsetVector, -offset.x, -offset.y);

        var rgba = graphics.tint.rgba;
        context.uniform3fv(shader.tintColor, new Float32List.fromList([rgba.r /
            255, rgba.g / 255, rgba.b / 255]));

        context.uniform1f(shader.alpha, graphics._worldAlpha);

        context.bindBuffer(gl.ARRAY_BUFFER, webGLData.buffer);

        context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false,
            4 * 6, 0);
        context.vertexAttribPointer(shader.colorAttribute, 4, gl.FLOAT, false, 4
            * 6, 2 * 4);

        // Set the index buffer!
        context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, webGLData.indexBuffer);
        context.drawElements(gl.TRIANGLE_STRIP, webGLData.indices.length,
            gl.UNSIGNED_SHORT, 0);
      }
    });
  }

  // Updates the graphics object.
  static void _updateGraphics(Graphics graphics, gl.RenderingContext context) {
    int contextId = WebGLContextManager.current.id(context);

    // Get the context's graphics object.
    var webGL = graphics._webGL[contextId];

    // If the graphics object does not exist in the webGL context, time to
    // create it!
    if (webGL == null) {
      webGL = graphics._webGL[contextId] = new WebGLGraphicsData.noBuffers(
          context);
    }

    // Flag the graphics as not dirty as we are about to update it.
    graphics._dirty = false;

    // If the user cleared the graphics object we will need to clear every
    // object.
    if (graphics._clearDirty) {
      graphics._clearDirty = false;

      // Loop through and return all the webGLDatas to the object pool so than
      // can be reused later on.
      webGL.data.forEach((graphicsData) {
        graphicsData.reset();
        _graphicsDataPool.add(graphicsData);
      });

      // Clear the array and reset the index.
      webGL.data.clear();
      webGL.lastIndex = 0;
    }

    var webGLData;

    // Loop through the graphics datas and construct each one.
    // If the object is a complex fill then the new stencil buffer technique
    // will be used, otherwise graphics objects will be pushed into a batch.
    for (int i = webGL.lastIndex; i < graphics.graphicsData.length; i++) {
      var data = graphics.graphicsData[i];

      // TODO: refactor this into a switch.
      if (data.type == Graphics.POLY) {
        // MAKE SURE WE HAVE THE CORRECT TYPE.
        if (data.fill) {
          if (data.points.length > 6) {
            if (data.points.length > 5 * 2) {
              webGLData = _switchMode(webGL, 1);
              _buildComplexPoly(data, webGLData);
            } else {
              webGLData = _switchMode(webGL, 0);
              _buildPoly(data, webGLData);
            }
          }
        }

        if (data.lineWidth > 0) {
          webGLData = _switchMode(webGL, 0);
          _buildLine(data, webGLData);
        }
      } else {
        webGLData = _switchMode(webGL, 0);

        if (data.type == Graphics.RECT) {
          _buildRectangle(data, webGLData);
        } else if (data.type == Graphics.CIRC || data.type == Graphics.ELIP) {
          _buildCircle(data, webGLData);
        } else if (data.type == Graphics.RREC) {
          _buildRoundedRectangle(data, webGLData);
        }
      }

      webGL.lastIndex++;
    }

    // Upload all the dirty data.
    webGL.data.forEach((webGLData) {
      if (webGLData.dirty) webGLData.upload();
    });
  }

  static WebGLGraphicsData _switchMode(WebGLGraphicsData webGL, int type) {
    WebGLGraphicsData webGLData;

    if (webGL.data.isEmpty) {
      if (_graphicsDataPool.isNotEmpty) {
        webGLData = _graphicsDataPool.removeLast();
      } else {
        webGLData = new WebGLGraphicsData(webGL.context);
      }

      webGLData.mode = type;
      webGL.data.add(webGLData);
    } else {
      webGLData = webGL.data.last;

      if (webGLData.mode != type || type == 1) {
        if (_graphicsDataPool.isNotEmpty) {
          webGLData = _graphicsDataPool.removeLast();
        } else {
          webGLData = new WebGLGraphicsData(webGL.context);
        }

        webGLData.mode = type;
        webGL.data.add(webGLData);
      }
    }

    webGLData.dirty = true;

    return webGLData;
  }

  // Builds a rectangle to draw.
  static void _buildRectangle(Path graphicsData, WebGLGraphicsData webGLData) {
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

  // Builds a rounded rectangle to draw.
  static void _buildRoundedRectangle(Path graphicsData, WebGLGraphicsData
      webGLData) {
    var points = graphicsData.points;
    num x = points[0];
    num y = points[1];
    num width = points[2];
    num height = points[3];
    num radius = points[4];

    var recPoints = new List<num>();
    recPoints.addAll([x, y + radius]);
    recPoints.addAll(_quadraticBezierCurve(x, y + height - radius, x, y +
        height, x + radius, y + height));
    recPoints.addAll(_quadraticBezierCurve(x + width - radius, y + height, x +
        width, y + height, x + width, y + height - radius));
    recPoints.addAll(_quadraticBezierCurve(x + width, y + radius, x + width, y,
        x + width - radius, y));
    recPoints.addAll(_quadraticBezierCurve(x + radius, y, x, y, x, y + radius));

    if (graphicsData.fill) {
      var color = graphicsData.fillColor.rgba;
      double alpha = graphicsData.fillAlpha;

      double r = color.r / 255 * alpha;
      double g = color.g / 255 * alpha;
      double b = color.b / 255 * alpha;

      var verts = webGLData.points;
      var indices = webGLData.indices;

      double vecPos = verts.length / 6;

      var triangles = PolyK.current.triangulate(recPoints);

      for (int i = 0; i < triangles.length; i += 3) {
        indices.add(triangles[i] + vecPos);
        indices.add(triangles[i] + vecPos);
        indices.add(triangles[i + 1] + vecPos);
        indices.add(triangles[i + 2] + vecPos);
        indices.add(triangles[i + 2] + vecPos);
      }

      for (int i = 0; i < recPoints.length; i++) {
        verts.addAll([recPoints[i], recPoints[++i], r, g, b, alpha]);
      }
    }

    if (graphicsData.lineWidth != 0) {
      var tempPoints = graphicsData.points;

      graphicsData.points = recPoints;
      _buildLine(graphicsData, webGLData);
      graphicsData.points = tempPoints;
    }
  }

  static double _getPt(num n1, num n2, double perc) {
    int diff = n2 - n1;

    return n1 + (diff * perc);
  }

  // Calculates the points for a quadratic bezier curve.
  static List<num> _quadraticBezierCurve(int fromX, int fromY, int cpX, int
      cpY, int toX, int toY) {
    double xa, ya, xb, yb, x, y, j;
    int n = 20;
    var points = new List<num>();

    for (int i = 0; i <= n; i++) {
      j = i / n;

      // The Green Line.
      xa = _getPt(fromX, cpX, j);
      ya = _getPt(fromY, cpY, j);
      xb = _getPt(cpX, toX, j);
      yb = _getPt(cpY, toY, j);

      // The Black Dot.
      x = _getPt(xa, xb, j);
      y = _getPt(ya, yb, j);

      points.addAll([x, y]);
    }

    return points;
  }

  // Builds a circle to draw.
  static void _buildCircle(Path graphicsData, WebGLGraphicsData webGLData) {
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
  static void _buildLine(Path graphicsData, WebGLGraphicsData webGLData) {
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
      // Need to clone as we are going to slightly modify the shape.
      points = new List<num>.from(points);

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

  // Builds a complex polygon to draw.
  static void _buildComplexPoly(Path graphicsData, WebGLGraphicsData webGLData)
      {
    //TODO: no need to copy this as it gets turned into a FLoat32List anyways.
    var points = new List<double>.generate(graphicsData.points.length, (int
        index) {
      return graphicsData.points[index].toDouble();
    });

    if (points.length < 6) return;

    // Get first and last point, figure out the middle!
    var indices = webGLData.indices;
    webGLData.points = points;
    webGLData.alpha = graphicsData.fillAlpha;
    webGLData.color = graphicsData.fillColor;

    // Calculate the bounds.
    double minX = double.INFINITY;
    double maxX = double.NEGATIVE_INFINITY;

    double minY = double.INFINITY;
    double maxY = double.NEGATIVE_INFINITY;

    num x, y;

    // Get size.
    for (int i = 0; i < points.length; i += 2) {
      x = points[i];
      y = points[i + 1];

      minX = x < minX ? x : minX;
      maxX = x > maxX ? x : maxX;

      minY = y < minY ? y : minY;
      maxY = y > maxY ? y : maxY;
    }

    // Add a quad to the end cos there is no point making another buffer!
    points.addAll([minX, minY, maxX, minY, maxX, maxY, minX, maxY]);

    // Push a quad onto the end..

    //TODO: this aint needed!
    for (int i = 0; i < points.length / 2; i++) {
      indices.add(i);
    }
  }

  // Builds a polygon to draw.
  static void _buildPoly(Path graphicsData, WebGLGraphicsData webGLData) {
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
