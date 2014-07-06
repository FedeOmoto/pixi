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
class WebGLMaskManager extends MaskManager {
  List<Graphics> maskStack = new List<Graphics>();

  /// Applies the Mask and adds it to the current filter stack.
  @override
  void pushMask(Graphics maskData, WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;

    if (maskStack.isEmpty) {
      context.enable(context.STENCIL_TEST);
      context.stencilFunc(context.ALWAYS, 1, 1);
    }

    maskStack.add(maskData);

    context.colorMask(false, false, false, false);
    context.stencilOp(context.KEEP, context.KEEP, context.INCR);

    WebGLGraphics.current.renderGraphics(maskData, renderSession);

    context.colorMask(true, true, true, true);
    context.stencilFunc(context.NOTEQUAL, 0, this.maskStack.length);
    context.stencilOp(context.KEEP, context.KEEP, context.KEEP);
  }

  /// Removes the last filter from the filter stack and doesn't return it.
  @override
  void popMask(WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;

    var maskData = maskStack.removeLast();

    if (maskData != null) {
      context.colorMask(false, false, false, false);

      context.stencilOp(context.KEEP, context.KEEP, context.DECR);

      WebGLGraphics.current.renderGraphics(maskData, renderSession);

      context.colorMask(true, true, true, true);
      context.stencilFunc(context.NOTEQUAL, 0, this.maskStack.length);
      context.stencilOp(context.KEEP, context.KEEP, context.KEEP);
    }

    if (maskStack.isEmpty) context.disable(context.STENCIL_TEST);
  }

  /// Destroys the mask stack.
  void destroy() => maskStack = null;
}
