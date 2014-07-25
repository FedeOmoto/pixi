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

/// Base class that supports listening for and dispatching events.
class CustomEvents implements Events {
  // Raw event target.
  final EventTarget _ptr;

  Map<String, CustomEventStream<CustomEvent>> _eventStream = new Map<String,
      CustomEventStream<CustomEvent>>();

  CustomEvents(this._ptr);

  CustomEventStream<CustomEvent> operator [](String type) {
    _eventStream.putIfAbsent(type, () => new CustomEventStream<CustomEvent>(
        _ptr, type, false));
    return _eventStream[type];
  }
}
