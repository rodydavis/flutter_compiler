import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import 'package:flutter_compiler/flutter_compiler.dart';

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
  DartservicesApi get dartServices => DartservicesApi(
        http.Client(),
        rootUrl: "https://dart-services.appspot.com/",
      );
  ExecutionService executionSvc;
  final _iframe = html.IFrameElement();

  Future<CompileDDCResponse> _loadJsCode(String fullCode) {
    var input = CompileRequest()..source = fullCode;
    // print('Input: $fullCode');
    return dartServices
        .compileDDC(input)
        .timeout(longServiceCallTimeout)
        .then((CompileDDCResponse response) {
      // String _url = response?.modulesBaseUrl;
      // service.execute(
      //   '',
      //   '',
      //   response.result,
      //   modulesBaseUrl: null,
      // );
      print('execution -> ddc-compile-success');
      return response;
    }).catchError((e, st) {
      // consoleExpandController.showOutput('Error compiling to JavaScript:\n$e',
      //     error: true);
      print('Error: $e -> $st');
      print('execution -> ddc-compile-failure');
      return "";
    });
  }

  bool _loaded = false;
  String _id = 'preview';
  @override
  void initState() {
    executionSvc = ExecutionServiceIFrame(_iframe);
    // _iframe.src = 'javascript:void(0);';
    // _iframe.setInnerHtml(output);

    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // executionSvc = ExecutionServiceIFrame(_iframe)
    //   ..frameSrc =
    //       isDarkMode ? '../scripts/frame_dark.html' : '../scripts/frame.html';
    _loadJsCode(widget.fullCode).then((response) {
      // print('Output: $output');
      final _js = ExecutionServiceIFrame.decorateJavaScript(response.result,
          modulesBaseUrl: response.modulesBaseUrl);
//       final html = "";
//       final css = "";
      final source = """
    <html>
      <head></head>
      <body>
        <script>
        $_js
        </script>
      </body>
    </html>
""";

      print(source);

      // _iframe.srcdoc = source;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_id, (int viewId) {
        final element = _iframe
          ..style.border = 'none'
          ..innerHtml = source
          ..setAttribute("sandbox", "allow-scripts")
          ..height = widget.height.toInt().toString()
          ..width = widget.width.toInt().toString();
        return element;
      });
      if (mounted) setState(() => _loaded = true);
      executionSvc.execute(
        '',
        '',
        response.result,
        modulesBaseUrl: response.modulesBaseUrl,
      );
    });
    super.initState();
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
