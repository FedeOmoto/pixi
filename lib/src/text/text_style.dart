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
class TextStyle extends TextStyleBase {
  /// A color that will be used on the text stroke.
  Color stroke = Color.black;

  /**
   * A number that represents the thickness of the stroke. Default is 0 (no
   * stroke).
   */
  int strokeThickness = 0;

  /// Indicates if word wrap should be used.
  bool wordWrap = false;

  /// The width at which text will wrap.
  int wordWrapWidth = 100;

  /// Set a drop shadow for the text.
  bool dropShadow = false;

  /// Set the angle of the drop shadow.
  double dropShadowAngle = math.PI / 6;

  /// Set the distance of the drop shadow.
  int dropShadowDistance = 4;

  /// Set the color of the drop shadow.
  Color dropShadowColor = Color.black;

  @override
  void set font(String font) {
    _font = font;
  }

  @override
  String get font {
    if (_font == null) _font = 'bold 20px Arial';
    return _font;
  }
}
