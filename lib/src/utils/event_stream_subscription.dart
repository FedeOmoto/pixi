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

ZoneUnaryCallback _wrapZone(callback(arg)) {
  // For performance reasons avoid wrapping if we are in the root zone.
  if (Zone.current == Zone.ROOT) return callback;
  if (callback == null) return null;
  return Zone.current.bindUnaryCallback(callback, runGuarded: true);
}

class EventStreamSubscription<T extends Event> extends StreamSubscription<T> {
  int _pauseCount = 0;
  EventTarget _target;
  final String _eventType;
  var _onData;
  final bool _useCapture;

  EventStreamSubscription(this._target, this._eventType, onData, this._useCapture)
      : _onData = _wrapZone(onData) {
    _tryResume();
  }

  @override
  Future cancel() {
    if (_canceled) return null;
    _unlisten();
    // Clear out the target to indicate this is complete.
    _target = null;
    _onData = null;

    return null;
  }

  bool get _canceled => _target == null;

  @override
  void onData(void handleData(T event)) {
    if (_canceled) throw new StateError('Subscription has been canceled.');

    // Remove current event listener.
    _unlisten();

    _onData = _wrapZone(handleData);
    _tryResume();
  }

  /// Has no effect.
  @override
  void onError(Function handleError) {}

  /// Has no effect.
  @override
  void onDone(void handleDone()) {}

  @override
  void pause([Future resumeSignal]) {
    if (_canceled) return;
    ++_pauseCount;
    _unlisten();
    if (resumeSignal != null) resumeSignal.whenComplete(resume);
  }

  bool get isPaused => _pauseCount > 0;

  @override
  void resume() {
    if (_canceled || !isPaused) return;
    --_pauseCount;
    _tryResume();
  }

  void _tryResume() {
    if (_onData != null && !isPaused) {
      _target.addEventListener(_eventType, _onData, _useCapture);
    }
  }

  void _unlisten() {
    if (_onData != null) {
      _target.removeEventListener(_eventType, _onData, _useCapture);
    }
  }

  @override
  Future asFuture([var futureValue]) {
    // We just need a future that will never succeed or fail.
    Completer completer = new Completer();
    return completer.future;
  }
}
