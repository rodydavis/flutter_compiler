// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library execution_iframe;

import 'dart:async';
import 'dart:html';
import 'dart:js';

import 'decorate.dart';
import 'execution.dart';

export 'execution.dart';

class ExecutionServiceIFrame implements ExecutionService {
  static const testKey = '__TESTRESULT__ ';

  final StreamController<String> _stdoutController =
      StreamController<String>.broadcast();
  final StreamController<String> _stderrController =
      StreamController<String>.broadcast();
  final StreamController<TestResult> _testResultsController =
      StreamController<TestResult>.broadcast();

  IFrameElement _frame;
  String _frameSrc;
  Completer _readyCompleter = Completer();

  ExecutionServiceIFrame(this._frame) {
    _frameSrc = _frame.src;
    _initListener();
  }

  IFrameElement get frame => _frame;

  @override
  Future execute(
    String html,
    String css,
    String javaScript, {
    String modulesBaseUrl,
  }) {
    return _reset().whenComplete(() {
      return _send('execute', {
        'html': html,
        'css': css,
        'js': decorateJavaScript(
          testKey,
          javaScript,
          modulesBaseUrl: modulesBaseUrl,
        ),
      });
    });
  }

  @override
  Future tearDown() => _reset();

  @override
  void replaceHtml(String html) {
    _send('setHtml', {'html': html});
  }

  @override
  void replaceCss(String css) {
    _send('setCss', {'css': css});
  }

  set frameSrc(String src) {
    frame.src = src;
    _frameSrc = src;
  }

  /// TODO(redbrogdon): Format message so internal double quotes are escaped.
  @override
  String get testResultDecoration => '''
void _result(bool success, [List<String> messages]) {
  // Join messages into a comma-separated list for inclusion in the JSON array.
  final joinedMessages = messages?.map((m) => '"\$m"')?.join(',') ?? '';

  print('$testKey{"success": \$success, "messages": [\$joinedMessages]}');
}

// Ensure we have at least one use of `_result`.
var resultFunction = _result;
''';

  @override
  Stream<String> get onStdout => _stdoutController.stream;

  @override
  Stream<String> get onStderr => _stderrController.stream;

  @override
  Stream<TestResult> get testResults => _testResultsController.stream;

  Future _send(String command, Map params) {
    Map m = {'command': command};
    m.addAll(params);
    frame.contentWindow.postMessage(m, '*');
    return Future.value();
  }

  /// Destroy and re-load the iframe.
  Future _reset() {
    if (frame.parent != null) {
      _readyCompleter = Completer();

      IFrameElement clone = _frame.clone(false);
      clone.src = _frameSrc;

      List<Element> children = frame.parent.children;
      int index = children.indexOf(_frame);
      children.insert(index, clone);
      frame.parent.children.remove(_frame);
      _frame = clone;
    }

    return _readyCompleter.future.timeout(Duration(seconds: 1), onTimeout: () {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    });
  }

  void _initListener() {
    context['dartMessageListener'] = JsFunction.withThis((_this, data) {
      String type = data['type'];

      if (type == 'testResult') {
        final result = TestResult(
            data['success'], List<String>.from(data['messages'] ?? []));
        _testResultsController.add(result);
      } else if (type == 'stderr') {
        // Ignore any exceptions before the iframe has completed initialization.
        if (_readyCompleter.isCompleted) {
          _stderrController.add(data['message']);
        }
      } else if (type == 'ready' && !_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      } else {
        _stdoutController.add(data['message']);
      }
    });
  }
}
