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

/// Adapter for exposing events as Dart streams.
class CustomEventStream<T extends Event> extends Stream<T> implements
    CustomStream<T> {
  final EventTarget _target;
  final String _eventType;
  final bool _useCapture;
  final StreamController<T> _streamController;

  CustomEventStream(this._target, this._eventType, this._useCapture) :
      _streamController = new StreamController<T>.broadcast(sync: true);

  // Events are inherently multi-subscribers.
  @override
  Stream<T> asBroadcastStream({void onListen(StreamSubscription
      subscription), void onCancel(StreamSubscription subscription)}) => this;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(void onData(T event), {Function onError, void
      onDone(), bool cancelOnError}) {
    return new EventStreamSubscription<T>(_target, _eventType, onData,
        _useCapture);
  }

  void add(T event) {
    if (event.type == _eventType) _streamController.add(event);
  }
}
