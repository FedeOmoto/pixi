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
 * This class provides a set of methods used by the canvas renderer to draw the
 * primitive graphics data.
 */
class CanvasGraphics {
  /// Answer the singleton instance of the CanvasGraphics class.
  static CanvasGraphics get current => CanvasGraphics._singleton;

  static final CanvasGraphics _singleton = new CanvasGraphics._internal();

  factory CanvasGraphics() {
    throw new UnsupportedError(
        'CanvasGraphics cannot be instantiated, use CanvasGraphics.current');
  }

  CanvasGraphics._internal();

  // Renders the graphics object.
  void _renderGraphics(Graphics graphics, CanvasRenderingContext2D context) {
    var worldAlpha = graphics._worldAlpha;

    graphics.graphicsData.forEach((data) {
      var points = data.points;

      context.strokeStyle = data.lineColor.toString();

      context.lineWidth = data.lineWidth;

      // TODO: refactor this into a switch, with methods for each shape type.
      if (data.type == Graphics.POLY) {
        context.beginPath();

        context.moveTo(points[0], points[1]);

        for (int i = 1; i < points.length / 2; i++) {
          context.lineTo(points[i * 2], points[i * 2 + 1]);
        }

        // If the first and last point are the same close the path - much neater :)
        if (points[0] == points[points.length - 2] && points[1] ==
            points[points.length - 1]) {
          context.closePath();
        }

        if (data.fill) {
          context.globalAlpha = data.fillAlpha * worldAlpha;
          context.fillStyle = data.fillColor.toString();
          context.fill();
        }

        if (data.lineWidth != 0) {
          context.globalAlpha = data.lineAlpha * worldAlpha;
          context.stroke();
        }
      } else if (data.type == Graphics.RECT) {
        if (data.fillColor != null) {
          context.globalAlpha = data.fillAlpha * worldAlpha;
          context.fillStyle = data.fillColor.toString();
          context.fillRect(points[0], points[1], points[2], points[3]);
        }

        if (data.lineWidth != 0) {
          context.globalAlpha = data.lineAlpha * worldAlpha;
          context.strokeRect(points[0], points[1], points[2], points[3]);
        }
      } else if (data.type == Graphics.CIRC) {
        context.beginPath();
        context.arc(points[0], points[1], points[2], 0, 2 * math.PI);
        context.closePath();

        if (data.fill) {
          context.globalAlpha = data.fillAlpha * worldAlpha;
          context.fillStyle = data.fillColor.toString();
          context.fill();
        }

        if (data.lineWidth != 0) {
          context.globalAlpha = data.lineAlpha * worldAlpha;
          context.stroke();
        }
      } else if (data.type == Graphics.ELIP) {
        var w = points[2] * 2;
        var h = points[3] * 2;

        var x = points[0] - w / 2;
        var y = points[1] - h / 2;

        context.beginPath();

        var kappa = 0.5522848,
            ox = (w / 2) * kappa, // control point offset horizontal
            oy = (h / 2) * kappa, // control point offset vertical
            xe = x + w, // x-end
            ye = y + h, // y-end
            xm = x + w / 2, // x-middle
            ym = y + h / 2; // y-middle

        context.moveTo(x, ym);
        context.bezierCurveTo(x, ym - oy, xm - ox, y, xm, y);
        context.bezierCurveTo(xm + ox, y, xe, ym - oy, xe, ym);
        context.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye);
        context.bezierCurveTo(xm - ox, ye, x, ym + oy, x, ym);

        context.closePath();

        if (data.fill) {
          context.globalAlpha = data.fillAlpha * worldAlpha;
          context.fillStyle = data.fillColor.toString();
          context.fill();
        }

        if (data.lineWidth != 0) {
          context.globalAlpha = data.lineAlpha * worldAlpha;
          context.stroke();
        }
      } else if (data.type == Graphics.RREC) {
        var rx = points[0];
        var ry = points[1];
        var width = points[2];
        var height = points[3];
        var radius = points[4];

        var maxRadius = (math.min(width, height) / 2).truncate();
        radius = radius > maxRadius ? maxRadius : radius;

        context.beginPath();
        context.moveTo(rx, ry + radius);
        context.lineTo(rx, ry + height - radius);
        context.quadraticCurveTo(rx, ry + height, rx + radius, ry + height);
        context.lineTo(rx + width - radius, ry + height);
        context.quadraticCurveTo(rx + width, ry + height, rx + width, ry +
            height - radius);
        context.lineTo(rx + width, ry + radius);
        context.quadraticCurveTo(rx + width, ry, rx + width - radius, ry);
        context.lineTo(rx + radius, ry);
        context.quadraticCurveTo(rx, ry, rx, ry + radius);
        context.closePath();

        if (data.fillColor != null || data.fillColor == 0) {
          context.globalAlpha = data.fillAlpha * worldAlpha;
          context.fillStyle = data.fillColor.toString();
          context.fill();
        }

        if (data.lineWidth != 0) {
          context.globalAlpha = data.lineAlpha * worldAlpha;
          context.stroke();
        }
      }
    });
  }

  /// Renders a graphics mask.
  void _renderGraphicsMask(Graphics graphics, CanvasRenderingContext2D context)
      {
    if (graphics.graphicsData.isEmpty) return;

    if (graphics.graphicsData.length > 1) {
      print(
          'Pixi warning: masks in canvas can only mask using the first path in the graphics object.'
          );
    }

    var data = graphics.graphicsData.first;
    var points = data.points;

    // TODO: refactor this into a switch, with methods for each shape type.
    if (data.type == Graphics.POLY) {
      context.beginPath();
      context.moveTo(points[0], points[1]);

      for (int i = 1; i < points.length / 2; i++) {
        context.lineTo(points[i * 2], points[i * 2 + 1]);
      }

      // If the first and last point are the same close the path - much neater :)
      if (points[0] == points[points.length - 2] && points[1] ==
          points[points.length - 1]) {
        context.closePath();
      }
    } else if (data.type == Graphics.RECT) {
      context.beginPath();
      context.rect(points[0], points[1], points[2], points[3]);
      context.closePath();
    } else if (data.type == Graphics.CIRC) {
      context.beginPath();
      context.arc(points[0], points[1], points[2], 0, 2 * math.PI);
      context.closePath();
    } else if (data.type == Graphics.ELIP) {
      var w = points[2] * 2;
      var h = points[3] * 2;

      var x = points[0] - w / 2;
      var y = points[1] - h / 2;

      context.beginPath();

      var kappa = 0.5522848,
          ox = (w / 2) * kappa, // control point offset horizontal
          oy = (h / 2) * kappa, // control point offset vertical
          xe = x + w, // x-end
          ye = y + h, // y-end
          xm = x + w / 2, // x-middle
          ym = y + h / 2; // y-middle

      context.moveTo(x, ym);
      context.bezierCurveTo(x, ym - oy, xm - ox, y, xm, y);
      context.bezierCurveTo(xm + ox, y, xe, ym - oy, xe, ym);
      context.bezierCurveTo(xe, ym + oy, xm + ox, ye, xm, ye);
      context.bezierCurveTo(xm - ox, ye, x, ym + oy, x, ym);
      context.closePath();
    } else if (data.type == Graphics.RREC) {
      var rx = points[0];
      var ry = points[1];
      var width = points[2];
      var height = points[3];
      var radius = points[4];

      var maxRadius = (math.min(width, height) / 2).truncate();
      radius = radius > maxRadius ? maxRadius : radius;

      context.beginPath();
      context.moveTo(rx, ry + radius);
      context.lineTo(rx, ry + height - radius);
      context.quadraticCurveTo(rx, ry + height, rx + radius, ry + height);
      context.lineTo(rx + width - radius, ry + height);
      context.quadraticCurveTo(rx + width, ry + height, rx + width, ry + height
          - radius);
      context.lineTo(rx + width, ry + radius);
      context.quadraticCurveTo(rx + width, ry, rx + width - radius, ry);
      context.lineTo(rx + radius, ry);
      context.quadraticCurveTo(rx, ry, rx, ry + radius);
      context.closePath();
    }
  }
}
