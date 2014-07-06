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

typedef EventListener(CustomEvent event);

/// Base class for all objects that support events.
abstract class EventTarget implements html.EventTarget {
  CustomEvents _events;
  Map<EventListener, StreamSubscription<CustomEvent>> _subscriptions;

  EventTarget() {
    _events = new CustomEvents(this);
    _subscriptions = new Map<EventListener, StreamSubscription<CustomEvent>>();
  }

  void addEventListener(String type, EventListener listener, [bool useCapture])
      {
    _events._eventStream.putIfAbsent(type, () =>
        new CustomEventStream<CustomEvent>(this, type, false));
    _subscriptions[listener] = _events[type]._streamController.stream.listen(
        listener);
  }

  /**
   * This is an ease-of-use accessor for event streams which should only be used
   * when an explicit accessor is not available.
   */
  Events get on => _events;

  void removeEventListener(String type, EventListener listener, [bool
      useCapture]) {
    if (!_subscriptions.containsKey(listener)) return;
    _subscriptions[listener].cancel();
  }

  bool dispatchEvent(CustomEvent event) {
    if (!_events._eventStream.containsKey(event.type)) return false;
    _events[event.type].add(event);
    return true;
  }
}
