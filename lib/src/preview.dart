import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;

import 'dart_services.dart';
import 'api.dart';
import 'iframe/execution_iframe.dart';
import 'utils.dart';

ExecutionService executionSvc;

class FlutterWebPreview extends StatefulWidget {
  final String fullCode;
  final num width, height;

  const FlutterWebPreview({
    Key key,
    @required this.fullCode,
    @required this.width,
    @required this.height,
  }) : super(key: key);
  @override
  _FlutterWebPreviewState createState() => _FlutterWebPreviewState();
}

class _FlutterWebPreviewState extends State<FlutterWebPreview> {
  var _iframe = html.IFrameElement();

  Future<CompileDDCResponse> _loadJsCode(String fullCode) {
    var input = CompileRequest()..source = fullCode;
    return dartServices
        .compileDDC(input)
        .timeout(longServiceCallTimeout)
        .then((CompileDDCResponse response) {
      print('execution -> ddc-compile-success');
      return response;
    }).catchError((e, st) {
      print('Error: $e -> $st');
      print('execution -> ddc-compile-failure');
      return "";
    });
  }

  bool _loaded = false;
  String _id = 'preview';

  @override
  void initState() {
    if (!_loaded) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_id, (int viewId) {
        final element = _iframe
          ..style.border = 'none'
          ..src = 'scripts/frame.html'
          ..setAttribute("sandbox", "allow-scripts")
          ..setAttribute('flex', 'auto')
          ..height = widget.height.toInt().toString()
          ..width = widget.width.toInt().toString();
        _iframe = element;
        return element;
      });
      executionSvc = ExecutionServiceIFrame(_iframe);
    }
    refresh();
    super.initState();
  }

  @override
  void didUpdateWidget(FlutterWebPreview oldWidget) {
    if (oldWidget.fullCode != widget.fullCode) {
      if (mounted) setState(() => refresh(true));
    }
    super.didUpdateWidget(oldWidget);
  }

  void refresh([bool update = false]) {
    _loadJsCode(widget.fullCode).then((response) async {
      if (mounted) setState(() => _loaded = true);
      executionSvc.execute(
        '',
        '',
        response.result,
        modulesBaseUrl: response.modulesBaseUrl,
        fresh: !update,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget?.width,
      height: widget?.height,
      child: _loaded
          ? AbsorbPointer(child: HtmlElementView(viewType: _id))
          : Center(child: CircularProgressIndicator()),
    );
  }
}
