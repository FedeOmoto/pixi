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
class CanvasTinter {
  /// Answer the singleton instance of the CanvasTinter class.
  static CanvasTinter get current => CanvasTinter._singleton;

  static final CanvasTinter _singleton = new CanvasTinter._internal();

  factory CanvasTinter() {
    throw new UnsupportedError(
        'CanvasTinter cannot be instantiated, use CanvasTinter.current');
  }

  CanvasTinter._internal();

  /// Number of steps which will be used as a cap when rounding colors.
  int cacheStepsPerColorChannel = 8;

  bool convertTintToImage = false;

  /**
   * Basically this method just needs a sprite and a color and tints the sprite 
   * with the given color.
   */
  CanvasImageSource getTintedTexture(Sprite sprite, Color color) {
    var texture = sprite.texture;

    color = roundColor(color);

    var stringColor = color.toString();

    if (texture.tintCache == null) {
      texture.tintCache = new Map<String, CanvasImageSource>();
    }

    if (texture.tintCache[stringColor] != null) {
      return texture.tintCache[stringColor];
    }

    // Clone texture.
    var canvas = new CanvasElement();

    // TODO: implement?
    //tintMethod(texture, color, canvas);

    tintWithMultiply(texture, color, canvas);

    if (convertTintToImage) {
      // Is this better?
      var tintImage = new ImageElement();
      tintImage.src = canvas.toDataUrl();

      texture.tintCache[stringColor] = tintImage;
    } else {
      texture.tintCache[stringColor] = canvas;
    }

    return canvas;
  }

  /// Tint a texture using the "multiply" operation.
  void tintWithMultiply(Texture texture, Color color, CanvasElement canvas) {
    var context = canvas.context2D;

    var frame = texture.frame;

    canvas.width = frame.width;
    canvas.height = frame.height;

    context.fillStyle = color.toString();

    context.fillRect(0, 0, frame.width, frame.height);

    context.globalCompositeOperation = 'multiply';

    context.drawImageScaledFromSource(texture.baseTexture.source, frame.left,
        frame.top, frame.width, frame.height, 0, 0, frame.width, frame.height);

    context.globalCompositeOperation = 'destination-atop';

    context.drawImageScaledFromSource(texture.baseTexture.source, frame.left,
        frame.top, frame.width, frame.height, 0, 0, frame.width, frame.height);
  }

  /// Tint a texture using the "overlay" operation.
  void tintWithOverlay(Texture texture, Color color, CanvasElement canvas) {
    var context = canvas.context2D;

    var frame = texture.frame;

    canvas.width = frame.width;
    canvas.height = frame.height;

    context.globalCompositeOperation = 'copy';
    context.fillStyle = color.toString();
    context.fillRect(0, 0, frame.width, frame.height);

    context.globalCompositeOperation = 'destination-atop';
    context.drawImageScaledFromSource(texture.baseTexture.source, frame.left,
        frame.top, frame.width, frame.height, 0, 0, frame.width, frame.height);
  }

  /// Tint a texture pixel per pixel.
  void tintWithPerPixel(Texture texture, Color color, CanvasElement canvas) {
    var context = canvas.context2D;

    var frame = texture.frame;

    canvas.width = frame.width;
    canvas.height = frame.height;

    context.globalCompositeOperation = 'copy';
    context.drawImageScaledFromSource(texture.baseTexture.source, frame.left,
        frame.top, frame.width, frame.height, 0, 0, frame.width, frame.height);

    var rgba = color.rgba;
    var r = rgba.r / 255;
    var g = rgba.g / 255;
    var b = rgba.b / 255;

    var pixelData = context.getImageData(0, 0, frame.width, frame.height);

    var pixels = pixelData.data;

    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i + 0] *= r;
      pixels[i + 1] *= g;
      pixels[i + 2] *= b;
    }

    context.putImageData(pixelData, 0, 0);
  }

  /// Rounds the specified color according to the [cacheStepsPerColorChannel].
  roundColor(Color color) {
    var step = cacheStepsPerColorChannel;

    var rgba = color.rgba;

    var r = math.min(255, ((rgba.r / 255) / step) * step);
    var g = math.min(255, ((rgba.g / 255) / step) * step);
    var b = math.min(255, ((rgba.b / 255) / step) * step);

    return new Color.createRgba((r * 255).toInt(), (g * 255).toInt(), (b *
        255).toInt());
  }
}
