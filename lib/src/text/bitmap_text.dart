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

class _Char {
  Texture texture;
  int line;
  int charCode;
  Point<int> position;

  _Char(this.texture, this.line, this.charCode, this.position);
}

/**
 * A Text Object will create a line(s) of text using bitmap font. To split a
 * line you can use '\n', '\r' or '\r\n'.
 * You can generate the fnt files using
 * [http://www.angelcode.com/products/bmfont/](http://www.angelcode.com/
 * products/bmfont/) for windows or [http://www.bmglyph.com/]
 * (http://www.bmglyph.com/) for mac.
 */
class BitmapText extends DisplayObjectContainer {
  static Map<String, _BitmapFontData> _fonts = new Map<String, _BitmapFontData>(
      );

  BitmapTextStyle _style;
  String _text;
  bool _dirty;
  String _fontName;
  int _fontSize;
  double _textWidth, _textHeight;
  List<DisplayObject> _pool = new List<DisplayObject>();

  BitmapText(String text, BitmapTextStyle style) {
    _text = text;
    this.style = style;
    _updateText();
    _dirty = false;
  }

  /// Set the style of the text.
  void set style(BitmapTextStyle style) {
    _style = style;

    var font = style._font.split(' ');
    _fontName = font.last;
    _fontSize = font.length >= 2 ? int.parse(font.first.replaceFirst('px', ''))
        : BitmapText._fonts[_fontName].size;

    _dirty = true;
  }

  /// Set the copy for the text object. To split a line you can use '\n'.
  void set text(String text) {
    _text = new String.fromCharCodes(text.runes);
    _dirty = true;
  }

  /**
   * The width of the overall text, different from fontSize, which is defined in
   * the style object.
   */
  double get textWidth => _textWidth;

  /**
   * The height of the overall text, different from fontSize, which is defined
   * in the style object.
   */
  double get textHeight => _textHeight;

  // Renders text and updates it when needed.
  void _updateText() {
    var data = BitmapText._fonts[_fontName];
    var pos = new Point<int>(0, 0);
    int prevCharCode;
    var chars = new List<_Char>();
    int maxLineWidth = 0;
    var lineWidths = new List<int>();
    int line = 0;
    var scale = _fontSize / data.size;

    for (int i = 0; i < _text.length; i++) {
      int charCode = _text.codeUnitAt(i);

      if (_text[i] == '\n') {
        lineWidths.add(pos.x);
        maxLineWidth = math.max(maxLineWidth, pos.x);
        line++;

        pos.x = 0;
        pos.y += data.lineHeight;
        prevCharCode = null;

        continue;
      }

      var charData = data.chars[charCode];
      if (charData == null) continue;

      // TODO: ???
      //if (prevCharCode != null && charData[prevCharCode] != null) {
      //  pos.x += charData.kerning[prevCharCode];
      //}

      chars.add(new _Char(charData.texture, line, charCode, new Point<int>(pos.x
          + charData.xOffset, pos.y + charData.yOffset)));
      pos.x += charData.xAdvance;

      prevCharCode = charCode;
    }

    lineWidths.add(pos.x);
    maxLineWidth = math.max(maxLineWidth, pos.x);

    var lineAlignOffsets = new List<num>();

    for (int i = 0; i <= line; i++) {
      var alignOffset = 0;

      if (_style.align == 'right') {
        alignOffset = maxLineWidth - lineWidths[i];
      } else if (_style.align == 'center') {
        alignOffset = (maxLineWidth - lineWidths[i]) / 2;
      }

      lineAlignOffsets.add(alignOffset);
    }

    int lenChildren = _children.length;
    int lenChars = chars.length;

    for (int i = 0; i < lenChars; i++) {
      DisplayObject c;

      // Get old child if have. If not, take from pool.
      if (i < lenChildren) {
        c = _children[i];
      } else if (_pool.isNotEmpty) {
        _pool.removeLast();
      }

      if (c != null) { // Check if got one before.
        (c as Sprite).setTexture(chars[i].texture);
      } else { // If no create new one.
        c = new Sprite(chars[i].texture);
      }

      c.position.x = (chars[i].position.x + lineAlignOffsets[chars[i].line]) *
          scale;
      c.position.y = chars[i].position.y * scale;
      c.scale.x = c.scale.y = scale;
      (c as Sprite).tint = _style.fill;
      if (c.parent == null) addChild(c);
    }

    // Remove unnecessary children and put their into the pool.
    while (_children.length > lenChars) {
      var child = getChildAt(children.length - 1);
      _pool.add(child);
      removeChild(child);
    }

    _textWidth = maxLineWidth * scale;
    _textHeight = (pos.y + data.lineHeight) * scale;
  }

  // Updates the transform of this object.
  @override
  void _updateTransform() {
    if (_dirty) {
      _updateText();
      _dirty = false;
    }

    super._updateTransform();
  }
}
