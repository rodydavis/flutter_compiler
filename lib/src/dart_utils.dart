import 'package:dart_style/dart_style.dart';
import 'package:flutter/material.dart';

class DartUtils {
  final String code;
  DartUtils(this.code);

  static const _class = 'class';
  static const _runApp = 'runApp';
  static const _statelessWidget = 'StatelessWidget';
  static const _statefulWidget = 'StatefulWidget';
  static List<String> get _widgets => [_statelessWidget, _statefulWidget];

  String get formatted => DartFormatter().format(code).toString();

  bool get hasMain => code.contains(_runApp);
  bool get hasWidget => hasStatelessWidget || hasStatefulWidget;
  bool get hasStatelessWidget => code.contains(_statelessWidget);
  bool get hasStatefulWidget => code.contains(_statefulWidget);

  List<DartClass> classes() {
    final List<DartClass> _children = [];
    final _results = positionsWhere(_class);
    for (final item in _results) {
      final _item = _nameAfterSpace(item + _class.length);
      _children.add(_item);
    }
    return _children;
  }

  List<int> positionsWhere(String match) {
    List<int> _classes = [];
    int _lastIndex = 0;
    while (_lastIndex != -1) {
      _lastIndex = code.indexOf(match, _lastIndex + match.length);
      if (_lastIndex != -1) _classes.add(_lastIndex);
    }
    return _classes;
  }

  DartClass _nameAfterSpace(int offset) {
    String _name = "";
    var idx = 0;
    for (var i = offset; i < code.length; i++) {
      var char = code[i];
      if (char == ' ') {
        if (_name.isEmpty) {
          continue;
        } else {
          break;
        }
      } else {
        if (_name.isEmpty) {
          idx = i;
        }
        _name += char;
      }
    }
    return DartClass(
      name: _name,
      index: idx,
    );
  }
}

class DartClass {
  final int index;
  final String name;
  final List<DartClass> extend;

  DartClass({
    @required this.index,
    @required this.name,
    this.extend,
  });
}
