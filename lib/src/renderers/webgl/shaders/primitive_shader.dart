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
class PrimitiveShader extends Shader {
  gl.UniformLocation tintColor, translationMatrix, alpha;

  PrimitiveShader(gl.RenderingContext context) : super(context);

  @override
  void setProgramSource() {
    fragmentSrc =
        '''
        precision mediump float;
        varying vec4 vColor;

        void main(void) {
          gl_FragColor = vColor;
        }''';

    vertexSrc =
        '''
        attribute vec2 aVertexPosition;
        attribute vec4 aColor;
        uniform mat3 translationMatrix;
        uniform vec2 projectionVector;
        uniform vec2 offsetVector;
        uniform float alpha;
        uniform vec3 tint;
        varying vec4 vColor;

        void main(void) {
          vec3 v = translationMatrix * vec3(aVertexPosition, 1.0);
          v -= offsetVector.xyx;
          gl_Position = vec4(v.x / projectionVector.x - 1.0, v.y / -projectionVector.y + 1.0, 0.0, 1.0);
          vColor = aColor * vec4(tint * alpha, alpha);
        }''';
  }

  @override
  void init() {
    var program = compileProgram(vertexSrc, fragmentSrc);

    context.useProgram(program);

    // Get and store the uniforms for the shader.
    projectionVector = context.getUniformLocation(program, 'projectionVector');
    offsetVector = context.getUniformLocation(program, 'offsetVector');
    tintColor = context.getUniformLocation(program, 'tint');

    // Get and store the attributes.
    aVertexPosition = context.getAttribLocation(program, 'aVertexPosition');
    colorAttribute = context.getAttribLocation(program, 'aColor');

    attributes = new List<int>.from([aVertexPosition, colorAttribute], growable:
        false);

    translationMatrix = context.getUniformLocation(program, 'translationMatrix'
        );
    alpha = context.getUniformLocation(program, 'alpha');

    this.program = program;
  }

  @override
  void destroy() {
    context.deleteProgram(program);
    uniforms = null;
    context = null;

    attributes = null;
  }
}
