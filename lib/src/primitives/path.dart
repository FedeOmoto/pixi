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
class Path {
  static const int POLY = Graphics.POLY;
  static const int RECT = Graphics.RECT;
  static const int CIRC = Graphics.CIRC;
  static const int ELIP = Graphics.ELIP;

  int type;
  int lineWidth;
  Color lineColor;
  double lineAlpha;
  Color fillColor;
  double fillAlpha;
  bool fill;
  List<num> points;

  Path([this.type, this.lineWidth, this.lineColor, this.lineAlpha, this.fillColor, this.fillAlpha, this.fill, this.points]) {
    if (points == null) points = new List<num>();
  }
}
