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
  /// Applies the Mask and adds it to the current filter stack.
  @override
  void pushMask(Graphics maskData, WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;

    if (maskData._dirty) WebGLGraphics._updateGraphics(maskData, context);

    int contextId = WebGLContextManager.current.id(context);
    if (maskData._webGL[contextId].data.isEmpty) return;

    var webGLData = maskData._webGL[contextId].data.first;
    renderSession.stencilManager.pushStencil(maskData, webGLData, renderSession
        );
  }

  /// Removes the last filter from the filter stack and doesn't return it.
  void popMask(Graphics maskData, WebGLRenderSession renderSession) {
    var context = renderSession.context as gl.RenderingContext;
    int contextId = WebGLContextManager.current.id(context);
    var webGLData = maskData._webGL[contextId].data.first;

    renderSession.stencilManager.popStencil(maskData, webGLData, renderSession);
  }
}
