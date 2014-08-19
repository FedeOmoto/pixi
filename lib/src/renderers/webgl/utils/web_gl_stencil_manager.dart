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
class WebGLStencilManager {
  gl.RenderingContext context;
  List<WebGLGraphicsData> stencilStack = new List<WebGLGraphicsData>();
  bool reverse = true;
  int count = 0;

  WebGLStencilManager(this.context);

  /**
  * Applies the Mask and adds it to the current filter stack
  * @method pushMask
  * @param maskData {Array}
  * @param renderSession {RenderSession}
  */
  void pushStencil(Graphics graphics, WebGLGraphicsData
      webGLData, WebGLRenderSession renderSession) {
    bindGraphics(graphics, webGLData, renderSession);

    if (stencilStack.isEmpty) {
      context.enable(gl.STENCIL_TEST);
      context.clear(gl.STENCIL_BUFFER_BIT);
      reverse = true;
      count = 0;
    }

    stencilStack.add(webGLData);

    int level = count;

    context.colorMask(false, false, false, false);

    context.stencilFunc(gl.ALWAYS, 0, 0xFF);
    context.stencilOp(gl.KEEP, gl.KEEP, gl.INVERT);

    // Draw the triangle strip!

    if (webGLData.mode == 1) {
      context.drawElements(gl.TRIANGLE_FAN, webGLData.indices.length - 4,
          gl.UNSIGNED_SHORT, 0);

      if (reverse) {
        context.stencilFunc(gl.EQUAL, 0xFF - level, 0xFF);
        context.stencilOp(gl.KEEP, gl.KEEP, gl.DECR);
      } else {
        context.stencilFunc(gl.EQUAL, level, 0xFF);
        context.stencilOp(gl.KEEP, gl.KEEP, gl.INCR);
      }

      // Draw a quad to increment.
      context.drawElements(gl.TRIANGLE_FAN, 4, gl.UNSIGNED_SHORT,
          (webGLData.indices.length - 4) * 2);

      if (reverse) {
        context.stencilFunc(gl.EQUAL, 0xFF - (level + 1), 0xFF);
      } else {
        context.stencilFunc(gl.EQUAL, level + 1, 0xFF);
      }

      reverse = !reverse;
    } else {
      if (!reverse) {
        context.stencilFunc(gl.EQUAL, 0xFF - level, 0xFF);
        context.stencilOp(gl.KEEP, gl.KEEP, gl.DECR);
      } else {
        context.stencilFunc(gl.EQUAL, level, 0xFF);
        context.stencilOp(gl.KEEP, gl.KEEP, gl.INCR);
      }

      context.drawElements(gl.TRIANGLE_STRIP, webGLData.indices.length,
          gl.UNSIGNED_SHORT, 0);

      if (!reverse) {
        context.stencilFunc(gl.EQUAL, 0xFF - (level + 1), 0xFF);
      } else {
        context.stencilFunc(gl.EQUAL, level + 1, 0xFF);
      }
    }

    context.colorMask(true, true, true, true);
    context.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);

    count++;
  }

  // TODO: this does not belong here!
  void bindGraphics(Graphics graphics, WebGLGraphicsData
      webGLData, WebGLRenderSession renderSession) {
    // Bind the graphics object.
    var projection = renderSession.projection,
        offset = renderSession.offset;

    var rgba = graphics.tint.rgba;
    var tint = new Float32List.fromList([rgba.r / 255, rgba.g / 255, rgba.b /
        255]);

    if (webGLData.mode == 1) {
      var shader = renderSession.shaderManager.complexPrimitiveShader;
      renderSession.shaderManager.setShader(shader);

      context.uniformMatrix3fv(shader.translationMatrix, false,
          graphics._worldTransform.asListTransposed());

      context.uniform2f(shader.projectionVector, projection.x, -projection.y);
      context.uniform2f(shader.offsetVector, -offset.x, -offset.y);

      context.uniform3fv(shader.tintColor, tint);
      context.uniform3fv(shader.color, webGLData._color);

      context.uniform1f(shader.alpha, graphics._worldAlpha * webGLData.alpha);

      context.bindBuffer(gl.ARRAY_BUFFER, webGLData.buffer);

      context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 4
          * 2, 0);

      // Now do the rest.
      // Set the index buffer!
      context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, webGLData.indexBuffer);
    } else {
      //renderSession.shaderManager.activatePrimitiveShader();
      var shader = renderSession.shaderManager.primitiveShader;
      renderSession.shaderManager.setShader(shader);

      context.uniformMatrix3fv(shader.translationMatrix, false,
          graphics._worldTransform.asListTransposed());

      context.uniform2f(shader.projectionVector, projection.x, -projection.y);
      context.uniform2f(shader.offsetVector, -offset.x, -offset.y);

      context.uniform3fv(shader.tintColor, tint);

      context.uniform1f(shader.alpha, graphics._worldAlpha);

      context.bindBuffer(gl.ARRAY_BUFFER, webGLData.buffer);

      context.vertexAttribPointer(shader.aVertexPosition, 2, gl.FLOAT, false, 4
          * 6, 0);
      context.vertexAttribPointer(shader.colorAttribute, 4, gl.FLOAT, false, 4 *
          6, 2 * 4);

      // Set the index buffer!
      context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, webGLData.indexBuffer);
    }
  }

  void popStencil(Graphics graphics, WebGLGraphicsData
      webGLData, WebGLRenderSession renderSession) {
    stencilStack.removeLast();

    count--;

    if (stencilStack.isEmpty) {
      // The stack is empty!
      context.disable(gl.STENCIL_TEST);
    } else {
      int level = count;

      bindGraphics(graphics, webGLData, renderSession);

      context.colorMask(false, false, false, false);

      if (webGLData.mode == 1) {
        reverse = !reverse;

        if (reverse) {
          context.stencilFunc(gl.EQUAL, 0xFF - (level + 1), 0xFF);
          context.stencilOp(gl.KEEP, gl.KEEP, gl.INCR);
        } else {
          context.stencilFunc(gl.EQUAL, level + 1, 0xFF);
          context.stencilOp(gl.KEEP, gl.KEEP, gl.DECR);
        }

        // Draw a quad to increment.
        context.drawElements(gl.TRIANGLE_FAN, 4, gl.UNSIGNED_SHORT,
            (webGLData.indices.length - 4) * 2);

        context.stencilFunc(gl.ALWAYS, 0, 0xFF);
        context.stencilOp(gl.KEEP, gl.KEEP, gl.INVERT);

        // Draw the triangle strip!
        context.drawElements(gl.TRIANGLE_FAN, webGLData.indices.length - 4,
            gl.UNSIGNED_SHORT, 0);

        if (!reverse) {
          context.stencilFunc(gl.EQUAL, 0xFF - (level), 0xFF);
        } else {
          context.stencilFunc(gl.EQUAL, level, 0xFF);
        }
      } else {
        if (!reverse) {
          context.stencilFunc(gl.EQUAL, 0xFF - (level + 1), 0xFF);
          context.stencilOp(gl.KEEP, gl.KEEP, gl.INCR);
        } else {
          context.stencilFunc(gl.EQUAL, level + 1, 0xFF);
          context.stencilOp(gl.KEEP, gl.KEEP, gl.DECR);
        }

        context.drawElements(gl.TRIANGLE_STRIP, webGLData.indices.length,
            gl.UNSIGNED_SHORT, 0);

        if (!reverse) {
          context.stencilFunc(gl.EQUAL, 0xFF - (level), 0xFF);
        } else {
          context.stencilFunc(gl.EQUAL, level, 0xFF);
        }
      }

      context.colorMask(true, true, true, true);
      context.stencilOp(gl.KEEP, gl.KEEP, gl.KEEP);
    }
  }

  void destroy() {
    stencilStack = null;
    context = null;
  }
}
