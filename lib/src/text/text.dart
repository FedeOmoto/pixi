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
 * A Text Object will create a line(s) of text. To split a line you can use '\n' 
 * or [TextStyle.wordWrap] set to `true` and [TextStyle.wordWrapWidth] with a
 * value in the [TextStyle] object.
 */
class Text extends Sprite {
  static Map<String, int> _heightCache = new Map<String, int>();

  /// The canvas element that everything is drawn to.
  CanvasElement canvas;

  /// The canvas 2d context that everything is drawn with.
  CanvasRenderingContext2D context;

  TextStyle _style;
  String _text;
  bool _dirty = true;
  bool _requiresUpdate = true;

  Text(String text, TextStyle style) : super(new Texture.fromCanvas(
      new CanvasElement())) {
    canvas = texture.baseTexture.source;
    context = canvas.context2D;

    _text = text;
    _style = style;
  }

  /// Returns the width of the [Text].
  num get width {
    if (_dirty) {
      _updateText();
      _dirty = false;
    }

    return scale.x * texture.frame.width;
  }

  /**
   * Sets the width of the [Text], setting this will actually modify the scale
   * to achieve the value set.
   */
  void set width(num value) {
    scale.x = value / texture.frame.width;
    _width = value;
  }

  /// Returns the height of the [Text].
  num get height {
    if (_dirty) {
      _updateText();
      _dirty = false;
    }

    return scale.y * texture.frame.height;
  }

  /**
   * Sets the height of the [Text], setting this will actually modify the scale
   * to achieve the value set
   */
  void set height(num value) {
    scale.y = value / texture.frame.height;
    _height = value;
  }

  /// Set the style of the text.
  void set style(TextStyle style) {
    _style = style;
    _dirty = true;
  }

  /// Set the copy for the text object. To split a line you can use '\n'.
  void set text(String text) {
    _text = new String.fromCharCodes(text.runes);
    _dirty = true;
  }

  // Renders text and updates it when needed.
  void _updateText() {
    context.font = _style.font;

    var outputText = _text;

    // Word wrap.
    // Preserve original text.
    if (_style.wordWrap) outputText = _wordWrap(_text);

    // Split text into lines.
    var lines = outputText.split(new RegExp('(?:\r\n|\r|\n)'));

    // Calculate text width.
    var lineWidths = new List<double>();
    double maxLineWidth = 0.0;

    lines.forEach((line) {
      var lineWidth = context.measureText(line).width;
      lineWidths.add(lineWidth);
      maxLineWidth = math.max(maxLineWidth, lineWidth);
    });

    var width = maxLineWidth + _style.strokeThickness;
    if (_style.dropShadow) width += _style.dropShadowDistance;

    canvas.width = (width + this.context.lineWidth).ceil();

    // Calculate text height.
    var lineHeight = _determineFontHeight('font: ${_style.font};') +
        _style.strokeThickness;

    var height = lineHeight * lines.length;
    if (_style.dropShadow) height += _style.dropShadowDistance;

    this.canvas.height = height;

    // TODO: Add support for CocoonJS?
    //if(navigator.isCocoonJS) this.context.clearRect(0,0,this.canvas.width,this.canvas.height);

    context.font = _style.font;
    context.strokeStyle = _style.stroke.toString();
    context.lineWidth = _style.strokeThickness;
    context.textBaseline = 'top';

    var linePositionX;
    var linePositionY;

    if (_style.dropShadow) {
      context.fillStyle = _style.dropShadowColor.toString();

      var xShadowOffset = math.sin(_style.dropShadowAngle) *
          _style.dropShadowDistance;
      var yShadowOffset = math.cos(_style.dropShadowAngle) *
          _style.dropShadowDistance;

      for (int i = 0; i < lines.length; i++) {
        linePositionX = _style.strokeThickness / 2;
        linePositionY = _style.strokeThickness / 2 + i * lineHeight;

        if (_style.align == 'right') {
          linePositionX += maxLineWidth - lineWidths[i];
        } else if (_style.align == 'center') {
          linePositionX += (maxLineWidth - lineWidths[i]) / 2;
        }

        if (_style.fill != null) {
          context.fillText(lines[i], linePositionX + xShadowOffset,
              linePositionY + yShadowOffset);
        }
      }
    }

    // Set canvas text styles.
    context.fillStyle = _style.fill.toString();

    // Draw lines line by line.
    for (int i = 0; i < lines.length; i++) {
      linePositionX = _style.strokeThickness / 2;
      linePositionY = _style.strokeThickness / 2 + i * lineHeight;

      if (_style.align == 'right') {
        linePositionX += maxLineWidth - lineWidths[i];
      } else if (_style.align == 'center') {
        linePositionX += (maxLineWidth - lineWidths[i]) / 2;
      }

      if (_style.stroke != null && _style.strokeThickness != 0) {
        context.strokeText(lines[i], linePositionX, linePositionY);
      }

      if (_style.fill != null) {
        context.fillText(lines[i], linePositionX, linePositionY);
      }
    }

    this._updateTexture();
  }

  // Updates texture size based on canvas size.
  void _updateTexture() {
    texture.baseTexture._width = canvas.width;
    texture.baseTexture._height = canvas.height;
    texture.crop.width = texture.frame.width = canvas.width;
    texture.crop.height = texture.frame.height = canvas.height;

    _width = canvas.width;
    _height = canvas.height;

    _requiresUpdate = true;
  }

  @override
  void _renderWebGL(WebGLRenderSession renderSession) {
    if (_requiresUpdate) {
      _requiresUpdate = false;
      WebGLRenderer._updateWebGLTexture(texture.baseTexture,
          renderSession.context);
    }

    super._renderWebGL(renderSession);
  }

  // Updates the transform of this object.
  void _updateTransform() {
    if (_dirty) {
      _updateText();
      _dirty = false;
    }

    super._updateTransform();
  }

  int _determineFontHeight(String fontStyle) {
    // Build a little reference dictionary so if the font style has been used
    // return a cached version.
    var result = _heightCache[fontStyle];

    if (result == null) {
      var body = querySelector('body');
      var dummy = new DivElement();
      dummy.text = 'M';
      dummy.setAttribute('style', '$fontStyle;position:absolute;top:0;left:0');
      body.append(dummy);

      result = dummy.offsetHeight;
      _heightCache[fontStyle] = result;

      dummy.remove();
    }

    return result;
  }

  // Applies newlines to a string to have it optimally fit into the horizontal
  // bounds set by the Text object's wordWrapWidth property.
  String _wordWrap(String text) {
    // Greedy wrapping algorithm that will wrap words as the line grows longer
    // than its horizontal bounds.
    var result = '';
    var lines = text.split(new RegExp('(?:\r\n|\r|\n)'));

    for (int i = 0; i < lines.length; i++) {
      var spaceLeft = _style.wordWrapWidth;
      var words = lines[i].split(' ');

      for (int j = 0; j < words.length; j++) {
        var wordWidth = context.measureText(words[j]).width;
        var wordWidthWithSpace = wordWidth + context.measureText(' ').width;

        if (j == 0 || wordWidthWithSpace > spaceLeft) {
          // Skip printing the newline if it's the first word of the line that
          // is greater than the word wrap width.
          if (j > 0) result = '$result\n';

          result = result + words[j];
          spaceLeft = _style.wordWrapWidth - wordWidth;
        } else {
          spaceLeft -= wordWidthWithSpace;
          result = result + ' ' + words[j];
        }
      }

      if (i < lines.length - 1) result = '$result\n';
    }

    return result;
  }

  /// Destroys this text object.
  void destroy([bool destroyBaseTexture = true]) {
    // Make sure to reset the the context and canvas, don't want this hanging
    // around in memory!
    context = null;
    canvas = null;

    texture.destroy(destroyBaseTexture);
  }
}
