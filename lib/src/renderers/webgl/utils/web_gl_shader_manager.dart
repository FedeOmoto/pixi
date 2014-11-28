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
class WebGLShaderManager {
  gl.RenderingContext context;

  List<bool> attribState = new List.filled(10, false);
  List<bool> tempAttribState;

  PrimitiveShader primitiveShader;
  ComplexPrimitiveShader complexPrimitiveShader;
  PixiShader defaultShader;
  PixiFastShader fastShader;
  StripShader stripShader;

  Shader currentShader;

  int _currentId;

  WebGLShaderManager(this.context) {
    setContext(context);
  }

  /// Initialises the context and the properties.
  void setContext(gl.RenderingContext context) {
    this.context = context;

    // The next one is used for rendering primitives.
    primitiveShader = new PrimitiveShader(context);

    // The next one is used for rendering triangle strips.
    complexPrimitiveShader = new ComplexPrimitiveShader(context);

    // This shader is used for the default sprite rendering.
    defaultShader = new PixiShader(context);

    // This shader is used for the fast sprite rendering.
    fastShader = new PixiFastShader(context);

    // The next one is used for rendering triangle strips.
    stripShader = new StripShader(context);

    setShader(defaultShader);
  }

  /// Takes the attributes given in parameters.
  void setAttribs(List<int> attribs) {
    // Reset temp state.
    tempAttribState = new List.filled(10, false);

    // Set the new attribs.
    attribs.forEach((attribId) => tempAttribState[attribId] = true);

    for (int i = 0; i < attribState.length; i++) {
      if (attribState[i] != tempAttribState[i]) {
        attribState[i] = tempAttribState[i];

        if (tempAttribState[i]) {
          context.enableVertexAttribArray(i);
        } else {
          context.disableVertexAttribArray(i);
        }
      }
    }
  }

  /// Sets-up the given shader.
  bool setShader(Shader shader) {
    if (_currentId == shader._uid) return false;

    _currentId = shader._uid;

    currentShader = shader;

    context.useProgram(shader.program);
    setAttribs(shader.attributes);

    return true;
  }

  void destroy() {
    attribState = null;
    tempAttribState = null;
    primitiveShader.destroy();
    complexPrimitiveShader.destroy();
    defaultShader.destroy();
    fastShader.destroy();
    stripShader.destroy();
    context = null;
  }
}
