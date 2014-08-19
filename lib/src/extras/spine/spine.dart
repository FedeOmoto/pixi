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
 * A class that enables you to import and run your spine animations in pixi.
 * Spine animation data needs to be loaded using [AssetLoader] or [AtlasLoader]
 * before it can be used by this class.
 */
class Spine extends DisplayObjectContainer {
  static Map<String, spine.SkeletonData> _animCache = new Map<String,
      spine.SkeletonData>();

  Map<String, Sprite> _spriteCache = new Map<String, Sprite>();
  spine.SkeletonData spineData;
  spine.Skeleton skeleton;
  spine.AnimationStateData stateData;
  spine.AnimationState state;

  List<DisplayObjectContainer> slotContainers =
      new List<DisplayObjectContainer>();

  int lastTime;

  Spine(String url) {
    spineData = _animCache[url];

    if (spineData == null) {
      throw new StateError(
          'Spine data must be preloaded using AtlasLoader or AssetLoader: $url');
    }

    skeleton = new spine.Skeleton(spineData);
    skeleton.updateWorldTransform();

    stateData = new spine.AnimationStateData(spineData);
    state = new spine.AnimationState(stateData);

    for (var slot in skeleton.drawOrder) {
      var attachment = slot.attachment;
      var slotContainer = new DisplayObjectContainer();

      slotContainers.add(slotContainer);
      addChild(slotContainer);

      if (!(attachment is spine.RegionAttachment)) {
        slotContainer.visible = false;
        continue;
      }

      var sprite = _createSprite(attachment);
      slotContainer.addChild(sprite);
    }
  }

  // Updates the object transform for rendering.
  @override
  void _updateTransform() {
    lastTime = lastTime == null ? new DateTime.now().millisecondsSinceEpoch :
        lastTime;

    double timeDelta = (new DateTime.now().millisecondsSinceEpoch - lastTime) *
        0.001;

    lastTime = new DateTime.now().millisecondsSinceEpoch;
    state.update(timeDelta);
    state.apply(skeleton);
    skeleton.updateWorldTransform();

    var drawOrder = skeleton.drawOrder;

    for (int i = 0,
        n = drawOrder.length; i < n; i++) {
      var slot = drawOrder[i];
      var attachment = slot.attachment;
      var slotContainer = slotContainers[i];

      if (!(attachment is spine.RegionAttachment)) {
        slotContainer.visible = false;
        continue;
      }

      var sprite = _spriteCache[attachment.name];

      if (sprite == null) {
        sprite = _createSprite(attachment);
        slotContainer.addChild(sprite);
      }

      slotContainer._children.forEach((child) {
        child.visible = child == sprite;
      });

      slotContainer.visible = true;

      var bone = slot.bone;

      slotContainer.position.x = bone.worldX + attachment.x * bone.m00 +
          attachment.y * bone.m01;
      slotContainer.position.y = bone.worldY + attachment.x * bone.m10 +
          attachment.y * bone.m11;

      slotContainer.scale.x = bone.worldScaleX;
      slotContainer.scale.y = bone.worldScaleY;

      slotContainer.rotation = -(slot.bone.worldRotation * math.PI / 180);
    }

    super._updateTransform();
  }

  Sprite _createSprite(spine.RegionAttachment attachment) {
    var region = attachment.region;
    var texture = region.page.rendererObject as Texture;
    int width = region.rotate ? region.height : region.width;
    int height = region.rotate ? region.width : region.height;
    int rotation = region.rotate ? 90 : 0;
    var rect = new Rectangle(region.x, region.y, width, height);
    var sprite = new Sprite(new Texture(texture.baseTexture, rect));

    sprite.scale = new Point<double>(attachment.scaleX, attachment.scaleY);
    sprite.rotation = (-attachment.rotation + rotation) * math.PI / 180;
    sprite.tint = new Color(attachment.getColor.toIntBits());
    sprite.alpha = attachment.getColor.a;
    sprite.anchor.x = sprite.anchor.y = 0.5;

    return _spriteCache[attachment.name] = sprite;
  }
}
