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
abstract class UniformIntVector extends Uniform {
  Int32List value;

  UniformIntVector(int type, String name, List<int> value) : super(type, name) {
    bool error = false;

    switch (type) {
      case gl.INT:
        if (value.length != 1) error = true;
        break;

      case gl.INT_VEC2:
        if (value.length != 2) error = true;
        break;

      case gl.INT_VEC3:
        if (value.length != 3) error = true;
        break;

      case gl.INT_VEC4:
        if (value.length != 4) error = true;
        break;
    }

    if (error) {
      throw new StateError('Invalid value length.');
    }

    this.value = new Int32List.fromList(value);
  }
}
