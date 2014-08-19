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
class PixiFastShader extends Shader {
  gl.UniformLocation uSampler, dimensions, uMatrix;

  int aPositionCoord, aScale, aRotation, aTextureCoord;

  PixiFastShader(gl.RenderingContext context) : super(context);

  @override
  void setProgramSource() {
    fragmentSrc =
        '''
            precision lowp float;
            varying vec2 vTextureCoord;
            varying float vColor;
            uniform sampler2D uSampler;

            void main(void) {
              gl_FragColor = texture2D(uSampler, vTextureCoord) * vColor;
            }''';

    vertexSrc =
        '''
        attribute vec2 aVertexPosition;
        attribute vec2 aPositionCoord;
        attribute vec2 aScale;
        attribute float aRotation;
        attribute vec2 aTextureCoord;
        attribute float aColor;

        uniform vec2 projectionVector;
        uniform vec2 offsetVector;
        uniform mat3 uMatrix;

        varying vec2 vTextureCoord;
        varying float vColor;

        const vec2 center = vec2(-1.0, 1.0);

        void main(void) {
          vec2 v;
          vec2 sv = aVertexPosition * aScale;
          v.x = (sv.x) * cos(aRotation) - (sv.y) * sin(aRotation);
          v.y = (sv.x) * sin(aRotation) + (sv.y) * cos(aRotation);
          v = (uMatrix * vec3(v + aPositionCoord , 1.0)).xy;
          gl_Position = vec4((v / projectionVector) + center, 0.0, 1.0);
          vTextureCoord = aTextureCoord;
          vColor = aColor;
        }''';
  }

  @override
  void init() {
    var program = compileProgram(vertexSrc, fragmentSrc);

    context.useProgram(program);

    // Get and store the uniforms for the shader.
    uSampler = context.getUniformLocation(program, 'uSampler');

    projectionVector = context.getUniformLocation(program, 'projectionVector');
    offsetVector = context.getUniformLocation(program, 'offsetVector');
    dimensions = context.getUniformLocation(program, 'dimensions');
    uMatrix = context.getUniformLocation(program, 'uMatrix');

    // Get and store the attributes.
    aVertexPosition = context.getAttribLocation(program, 'aVertexPosition');
    aPositionCoord = context.getAttribLocation(program, 'aPositionCoord');

    aScale = context.getAttribLocation(program, 'aScale');
    aRotation = context.getAttribLocation(program, 'aRotation');

    aTextureCoord = context.getAttribLocation(program, 'aTextureCoord');
    colorAttribute = context.getAttribLocation(program, 'aColor');

    if (colorAttribute == -1) colorAttribute = 2;

    attributes = new List<int>.from([aVertexPosition, aPositionCoord, aScale,
        aRotation, aTextureCoord, colorAttribute], growable: false);

    this.program = program;
  }
}
