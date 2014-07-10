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
abstract class UniformMatrix extends Uniform {
  bool transpose = false; // TODO: ???
  Float32List value;

  UniformMatrix(int type, String name, Float32List value) : super(type, name) {
    bool error = false;

    switch (type) {
      case gl.FLOAT_MAT2:
        if (value.length != 4) error = true;
        break;

      case gl.FLOAT_MAT3:
        if (value.length != 9) error = true;
        break;

      case gl.FLOAT_MAT4:
        if (value.length != 16) error = true;
        break;
    }

    if (error) {
      throw new StateError('Invalid value length.');
    }

    this.value = value;
  }
}
