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
class InteractionEventStream extends Stream<InteractionData> {
  StreamController<InteractionData> _streamController;

  // TODO: need to know when a StreamSubscription is cancelled to decrement this
  // counter.
  int _listeners = 0;

  // The type of event this stream is providing.
  String _type;

  InteractionEventStream(String type) {
    _type = type;
    _streamController = new StreamController.broadcast(sync: true);
  }

  // Delegate all regular Stream behavior to our wrapped Stream.
  @override
  StreamSubscription<InteractionData> listen(void onData(InteractionData
      event), {Function onError, void onDone(), bool cancelOnError}) {
    _listeners++;
    return _streamController.stream.listen(onData, onError: onError, onDone:
        onDone, cancelOnError: cancelOnError);
  }

  @override
  Stream<InteractionData> asBroadcastStream({void onListen(StreamSubscription
      subscription), void onCancel(StreamSubscription subscription)}) =>
      _streamController.stream;

  @override
  bool get isBroadcast => true;

  void _add(InteractionData event) {
    _streamController.add(event);
  }
}
