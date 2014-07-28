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

/**
 * The [BlurFilter] applies a Gaussian blur to an object.
 * The strength of the blur can be set for x- and y-axis separately (always
 * relative to the stage).
 */
class BlurFilter extends Filter {
  BlurXFilter blurXFilter = new BlurXFilter();
  BlurYFilter blurYFilter = new BlurYFilter();

  BlurFilter() {
    _passes = [blurXFilter, blurYFilter];
  }

  /**
   * Returns the strength of both the blurX and blurY properties simultaneously.
   */
  double get blur => blurXFilter.blur;

  /// Sets the strength of both the blurX and blurY properties simultaneously.
  void set blur(double value) {
    blurXFilter.blur = blurYFilter.blur = value;
  }

  /// Returns the strength of the blurX property.
  double get blurX => blurXFilter.blur;

  /// Sets the strength of the blurX property.
  void set blurX(double value) {
    blurXFilter.blur = value;
  }

  /// Returns the strength of the blurY property.
  double get blurY => blurYFilter.blur;

  /// Sets the strength of the blurY property.
  void set blurY(double value) {
    blurYFilter.blur = value;
  }
}
