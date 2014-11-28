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

/**
 * A port of the [pixi.js](https://github.com/GoodBoyDigital/pixi.js/) rendering
 * engine to Dart.
 * 
 * [Pixi](http://www.pixijs.com/) is a super fast HTML5 2D rendering engine that
 * uses webGL with canvas fallback.
 */
library pixi;

import 'dart:html' hide EventTarget;
import 'dart:html' as html show EventTarget;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:web_gl' as gl;
import 'dart:async';
import 'dart:convert' show JSON;

export 'package:csslib/parser.dart' show Color;
import 'package:csslib/parser.dart' show Color;

import 'package:path/path.dart' as path;
import 'package:spine/spine.dart' as spine;

part 'src/utils/enum.dart';
part 'src/utils/event_target.dart';
part 'src/utils/custom_events.dart';
part 'src/utils/custom_event_stream.dart';
part 'src/utils/event_stream_subscription.dart';
part 'src/utils/polyk.dart';
part 'src/utils/uid.dart';
part 'src/geom/point.dart';
part 'src/geom/shape.dart';
part 'src/geom/rectangle.dart';
part 'src/geom/circle.dart';
part 'src/geom/ellipse.dart';
part 'src/geom/polygon.dart';
part 'src/math/matrix.dart';
part 'src/display/display_object.dart';
part 'src/display/display_object_container.dart';
part 'src/display/stage.dart';
part 'src/display/sprite.dart';
part 'src/display/sprite_batch.dart';
part 'src/display/movie_clip.dart';
part 'src/primitives/graphics.dart';
part 'src/primitives/path.dart';
part 'src/filters/filter.dart';
part 'src/filters/filter_block.dart';
part 'src/filters/color_matrix_filter.dart';
part 'src/filters/blur_x_filter.dart';
part 'src/filters/blur_y_filter.dart';
part 'src/filters/blur_filter.dart';
part 'src/filters/displacement_filter.dart';
part 'src/filters/pixelate_filter.dart';
part 'src/filters/invert_filter.dart';
part 'src/filters/gray_filter.dart';
part 'src/filters/sepia_filter.dart';
part 'src/filters/twist_filter.dart';
part 'src/filters/dot_screen_filter.dart';
part 'src/filters/color_step_filter.dart';
part 'src/filters/cross_hatch_filter.dart';
part 'src/filters/rgb_split_filter.dart';
part 'src/renderers/common/renderer.dart';
part 'src/renderers/common/render_session.dart';
part 'src/renderers/common/mask_manager.dart';
part 'src/renderers/common/texture_buffer.dart';
part 'src/renderers/canvas/canvas_renderer.dart';
part 'src/renderers/canvas/canvas_render_session.dart';
part 'src/renderers/canvas/canvas_graphics.dart';
part 'src/renderers/canvas/utils/canvas_mask_manager.dart';
part 'src/renderers/canvas/utils/canvas_buffer.dart';
part 'src/renderers/canvas/utils/canvas_tinter.dart';
part 'src/renderers/webgl/web_gl_renderer.dart';
part 'src/renderers/webgl/web_gl_render_session.dart';
part 'src/renderers/webgl/utils/web_gl_mask_manager.dart';
part 'src/renderers/webgl/shaders/shader.dart';
part 'src/renderers/webgl/shaders/pixi_shader.dart';
part 'src/renderers/webgl/shaders/primitive_shader.dart';
part 'src/renderers/webgl/shaders/pixi_fast_shader.dart';
part 'src/renderers/webgl/shaders/strip_shader.dart';
part 'src/renderers/webgl/shaders/complex_primitive_shader.dart';
part 'src/renderers/webgl/primitives/uniform.dart';
part 'src/renderers/webgl/primitives/uniform_sampler_2d.dart';
part 'src/renderers/webgl/primitives/uniform_matrix.dart';
part 'src/renderers/webgl/primitives/uniform_matrix_2fv.dart';
part 'src/renderers/webgl/primitives/uniform_matrix_3fv.dart';
part 'src/renderers/webgl/primitives/uniform_matrix_4fv.dart';
part 'src/renderers/webgl/primitives/uniform_float_vector.dart';
part 'src/renderers/webgl/primitives/uniform_int_vector.dart';
part 'src/renderers/webgl/primitives/uniform_1f.dart';
part 'src/renderers/webgl/primitives/uniform_1fv.dart';
part 'src/renderers/webgl/primitives/uniform_1i.dart';
part 'src/renderers/webgl/primitives/uniform_1iv.dart';
part 'src/renderers/webgl/primitives/uniform_2f.dart';
part 'src/renderers/webgl/primitives/uniform_2fv.dart';
part 'src/renderers/webgl/primitives/uniform_2i.dart';
part 'src/renderers/webgl/primitives/uniform_2iv.dart';
part 'src/renderers/webgl/primitives/uniform_3f.dart';
part 'src/renderers/webgl/primitives/uniform_3fv.dart';
part 'src/renderers/webgl/primitives/uniform_3i.dart';
part 'src/renderers/webgl/primitives/uniform_3iv.dart';
part 'src/renderers/webgl/primitives/uniform_4f.dart';
part 'src/renderers/webgl/primitives/uniform_4fv.dart';
part 'src/renderers/webgl/primitives/uniform_4i.dart';
part 'src/renderers/webgl/primitives/uniform_4iv.dart';
part 'src/renderers/webgl/utils/web_gl_context_manager.dart';
part 'src/renderers/webgl/utils/web_gl_shader_manager.dart';
part 'src/renderers/webgl/utils/web_gl_filter_manager.dart';
part 'src/renderers/webgl/utils/web_gl_blend_mode_manager.dart';
part 'src/renderers/webgl/utils/web_gl_stencil_manager.dart';
part 'src/renderers/webgl/utils/web_gl_sprite_batch.dart';
part 'src/renderers/webgl/utils/web_gl_graphics.dart';
part 'src/renderers/webgl/utils/web_gl_graphics_data.dart';
part 'src/renderers/webgl/utils/filter_texture.dart';
part 'src/renderers/webgl/utils/web_gl_fast_sprite_batch.dart';
part 'src/textures/texture.dart';
part 'src/textures/render_texture.dart';
part 'src/textures/base_texture.dart';
part 'src/textures/texture_uvs.dart';
part 'src/interaction/interaction_data.dart';
part 'src/interaction/interaction_event_stream.dart';
part 'src/interaction/interaction_manager.dart';
part 'src/extras/tiling_sprite.dart';
part 'src/extras/strip.dart';
part 'src/extras/rope.dart';
part 'src/extras/spine/atlas_texture_loader.dart';
part 'src/extras/spine/spine.dart';
part 'src/loaders/loader.dart';
part 'src/loaders/asset_loader.dart';
part 'src/loaders/image_loader.dart';
part 'src/loaders/json_loader.dart';
part 'src/loaders/bitmap_font_loader.dart';
part 'src/loaders/atlas_loader.dart';
part 'src/text/text_style_base.dart';
part 'src/text/text_style.dart';
part 'src/text/bitmap_text_style.dart';
part 'src/text/text.dart';
part 'src/text/bitmap_text.dart';

/// Useful for testing against if your lib is using pixi.
const String VERSION = '1.6.1';

/// The various blend modes supported by pixi.
class BlendModes<int> extends Enum<int> {
  const BlendModes(int value) : super(value);

  static const BlendModes NORMAL = const BlendModes(0);
  static const BlendModes ADD = const BlendModes(1);
  static const BlendModes MULTIPLY = const BlendModes(2);
  static const BlendModes SCREEN = const BlendModes(3);
  static const BlendModes OVERLAY = const BlendModes(4);
  static const BlendModes DARKEN = const BlendModes(5);
  static const BlendModes LIGHTEN = const BlendModes(6);
  static const BlendModes COLOR_DODGE = const BlendModes(7);
  static const BlendModes COLOR_BURN = const BlendModes(8);
  static const BlendModes HARD_LIGHT = const BlendModes(9);
  static const BlendModes SOFT_LIGHT = const BlendModes(10);
  static const BlendModes DIFFERENCE = const BlendModes(11);
  static const BlendModes EXCLUSION = const BlendModes(12);
  static const BlendModes HUE = const BlendModes(13);
  static const BlendModes SATURATION = const BlendModes(14);
  static const BlendModes COLOR = const BlendModes(15);
  static const BlendModes LUMINOSITY = const BlendModes(16);
}

/// The scale modes.
class ScaleModes<int> extends Enum<int> {
  const ScaleModes(int value) : super(value);

  static const ScaleModes DEFAULT = const ScaleModes(0);
  static const ScaleModes LINEAR = const ScaleModes(0);
  static const ScaleModes NEAREST = const ScaleModes(1);
}

const double RAD_TO_DEG = 180.0 / math.PI;
const double DEG_TO_RAD = math.PI / 180.0;
