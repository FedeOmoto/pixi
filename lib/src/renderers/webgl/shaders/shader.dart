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
abstract class Shader {
  int _uid = UID.get;

  gl.RenderingContext context;

  /// The WebGL program.
  gl.Program program;

  /// The fragment shader.
  String fragmentSrc;

  /// The vertex shader.
  String vertexSrc;

  List<int> attributes;

  gl.UniformLocation projectionVector, offsetVector;

  int aVertexPosition, colorAttribute;

  List<Uniform> uniforms = new List<Uniform>();

  Shader(this.context) {
    setProgramSource();
    init();
  }

  /// Should set the vertex and fragment shader source.
  void setProgramSource();

  /// Initialises the shader.
  void init();

  /// Destroys the shader.
  void destroy() {
    context.deleteProgram(program);

    uniforms = null;
    context = null;
    attributes = null;
  }

  gl.Program compileProgram(String vertexSrc, String fragmentSrc) {
    var fragmentShader = compileFragmentShader(fragmentSrc);
    var vertexShader = compileVertexShader(vertexSrc);

    var shaderProgram = context.createProgram();

    context.attachShader(shaderProgram, vertexShader);
    context.attachShader(shaderProgram, fragmentShader);
    context.linkProgram(shaderProgram);

    if (!context.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
      print('Could not initialise shaders!');
    }

    return shaderProgram;
  }

  gl.Shader compileVertexShader(String shaderSrc) {
    return _compileShader(shaderSrc, gl.VERTEX_SHADER);
  }

  gl.Shader compileFragmentShader(String shaderSrc) {
    return _compileShader(shaderSrc, gl.FRAGMENT_SHADER);
  }

  gl.Shader _compileShader(String shaderSrc, int shaderType) {
    var shader = context.createShader(shaderType);

    context.shaderSource(shader, shaderSrc);
    context.compileShader(shader);

    if (!context.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      print(context.getShaderInfoLog(shader));
      return null;
    }

    return shader;
  }
}
