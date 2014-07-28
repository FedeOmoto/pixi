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
class PixiShader extends Shader {
  gl.UniformLocation uSampler, dimensions;

  int aTextureCoord;

  PixiShader(gl.RenderingContext context) : super(context);

  @override
  void setProgramSource() {
    fragmentSrc =
        '''
        precision lowp float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform sampler2D uSampler;

        void main(void) {
          gl_FragColor = texture2D(uSampler, vTextureCoord) * vColor;
        }''';

    vertexSrc =
        '''
        attribute vec2 aVertexPosition;
        attribute vec2 aTextureCoord;
        attribute vec2 aColor;

        uniform vec2 projectionVector;
        uniform vec2 offsetVector;

        varying vec2 vTextureCoord;
        varying vec4 vColor;

        const vec2 center = vec2(-1.0, 1.0);

        void main(void) {
          gl_Position = vec4(((aVertexPosition + offsetVector) / projectionVector) + center, 0.0, 1.0);
          vTextureCoord = aTextureCoord;
          vec3 color = mod(vec3(aColor.y / 65536.0, aColor.y / 256.0, aColor.y), 256.0) / 256.0;
          vColor = vec4(color * aColor.x, aColor.x);
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

    // Get and store the attributes.
    aVertexPosition = context.getAttribLocation(program, 'aVertexPosition');
    aTextureCoord = context.getAttribLocation(program, 'aTextureCoord');
    colorAttribute = context.getAttribLocation(program, 'aColor');

    if (colorAttribute == -1) colorAttribute = 2;

    attributes = new List<int>.from([aVertexPosition, aTextureCoord,
        colorAttribute], growable: false);

    // Add those custom shaders!
    uniforms.forEach((uniform) {
      uniform.location = context.getUniformLocation(program, uniform.name);

      // Initialize all sampler 2d uniforms.
      if (uniform.type == gl.SAMPLER_2D) {
        uniform.init(context);
      }
    });

    this.program = program;
  }

  /// Updates the shader uniform values.
  void syncUniforms() {
    UniformSampler2D._textureCount = 0;
    uniforms.forEach((uniform) => uniform.sync(context));
  }

  @override
  void destroy() {
    context.deleteProgram(program);
    uniforms = null;
    context = null;

    attributes = null;
  }
}
