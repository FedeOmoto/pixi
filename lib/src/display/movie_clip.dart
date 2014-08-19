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
 * A MovieClip is a simple way to display an animation depicted by a list of
 * textures.
 */
class MovieClip extends Sprite {
  /// The list of textures that make up the animation.
  List<Texture> textures;

  /**
   * The speed that the MovieClip will play at. Higher is faster, lower is
   * slower.
   */
  double animationSpeed = 1.0;

  /// Whether or not the movie clip repeats after playing.
  bool loop = true;

  /// Function to call when a MovieClip finishes playing.
  Function onComplete;

  double _currentFrame = 0.0;

  bool _playing = false;

  MovieClip(List<Texture> textures) : super(textures.first) {
    this.textures = textures;
  }

  /// A short hand way of creating a MovieClip from a list of frame ids.
  factory MovieClip.fromFrames(List<String> frames) {
    var textures = new List<Texture>();
    frames.forEach((frameId) => textures.add(new Texture.fromFrame(frameId)));
    return new MovieClip(textures);
  }

  /// A short hand way of creating a MovieClip from an array of image ids.
  factory MovieClip.fromImages(List<String> images) {
    var textures = new List<Texture>();

    images.forEach((imageUrl) {
      textures.add(new Texture.fromImage(imageUrl));
    });

    return new MovieClip(textures);
  }

  /**
   * The MovieClip's current frame index (this may not have to be a whole
   * number).
   */
  double get currentFrame => _currentFrame;

  /// Indicates if the MovieClip is currently playing.
  bool get playing => _playing;

  /**
   * [totalFrames] is the total number of frames in the MovieClip. This is the
   * same as number of textures assigned to the MovieClip.
   */
  int get totalFrames => textures.length;

  /// Stops the MovieClip.
  void stop() {
    _playing = false;
  }

  /// Plays the MovieClip.
  void play() {
    _playing = true;
  }

  /// Stops the MovieClip and goes to a specific frame.
  void gotoAndStop(int frameNumber) {
    _playing = false;
    _currentFrame = frameNumber.toDouble();
    int round = (_currentFrame + 0.5).truncate();
    setTexture(textures[round % textures.length]);
  }

  /// Goes to a specific frame and begins playing the MovieClip.
  void gotoAndPlay(int frameNumber) {
    _currentFrame = frameNumber.toDouble();
    _playing = true;
  }

  // Updates the object transform for rendering.
  @override
  void _updateTransform() {
    super._updateTransform();

    if (!_playing) return;

    _currentFrame += animationSpeed;

    int round = (_currentFrame + 0.5).truncate();

    _currentFrame = _currentFrame % textures.length;

    if (loop || round < textures.length) {
      setTexture(textures[round % textures.length]);
    } else if (round >= textures.length) {
      gotoAndStop(textures.length - 1);
      if (onComplete != null) onComplete();
    }
  }
}
