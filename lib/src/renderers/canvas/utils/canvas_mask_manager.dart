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

/// CanvasMaskManager is used to handle masking.
class CanvasMaskManager extends MaskManager {
  /// This method adds it to the current stack of masks.
  @override
  void pushMask(Graphics maskData, CanvasRenderSession renderSession) {
    var context = renderSession.context as CanvasRenderingContext2D;

    context.save();

    var transform = maskData._worldTransform;

    context.setTransform(transform.a, transform.c, transform.b, transform.d,
        transform.tx, transform.ty);

    CanvasGraphics.current._renderGraphicsMask(maskData, context);

    context.clip();

    maskData._worldAlpha = maskData.alpha;
  }

  /**
   * Restores the current drawing context to the state it was before the mask
   * was applied.
   */
  void popMask(CanvasRenderSession renderSession) {
    (renderSession.context as CanvasRenderingContext2D).restore();
  }
}
