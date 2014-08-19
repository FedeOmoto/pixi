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
class WebGLGraphicsData {
  gl.RenderingContext context;
  List<WebGLGraphicsData> data = new List<WebGLGraphicsData>();
  Float32List _color = new Float32List.fromList([0.0, 0.0, 0.0]);
  List<double> points = new List<double>();
  List<int> indices = new List<int>();
  int lastIndex = 0;
  gl.Buffer buffer;
  gl.Buffer indexBuffer;
  Float32List glPoints;
  Uint16List glIndices;
  int mode = 1;
  double alpha = 1.0;
  bool dirty = true;

  WebGLGraphicsData(this.context) {
    buffer = context.createBuffer();
    indexBuffer = context.createBuffer();
  }

  WebGLGraphicsData.noBuffers(this.context);

  Color get color {
    int r = (_color[0] * 255).toInt();
    int g = (_color[1] * 255).toInt();
    int b = (_color[2] * 255).toInt();

    return new Color.createRgba(r, g, b);
  }

  void set color(Color value) {
    var rgba = value.rgba;

    _color[0] = rgba.r / 255;
    _color[1] = rgba.g / 255;
    _color[2] = rgba.b / 255;
  }

  void reset() {
    points.clear();
    indices.clear();
    lastIndex = 0;
  }

  void upload() {
    glPoints = new Float32List.fromList(points);

    context.bindBuffer(gl.ARRAY_BUFFER, buffer);
    context.bufferData(gl.ARRAY_BUFFER, glPoints, gl.STATIC_DRAW);

    glIndices = new Uint16List.fromList(indices);

    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, glIndices, gl.STATIC_DRAW);

    dirty = false;
  }
}
