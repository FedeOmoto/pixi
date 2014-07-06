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
  static const int POLY = 0;
  static const int RECT = 1;
  static const int CIRC = 2;
  static const int ELIP = 3;

  int type;
  int lineWidth;
  Color lineColor;
  double lineAlpha;
  Color fillColor;
  double fillAlpha;
  bool fill;
  List<int> points = new List<int>();

  Path([this.type, this.lineWidth, this.lineColor, this.lineAlpha, this.fillColor, this.fillAlpha, this.fill, this.points]);
}
