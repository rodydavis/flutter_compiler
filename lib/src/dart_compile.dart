import 'dart_services.dart';
import 'dartservices.dart';
import 'iframe/decorate.dart';
import 'utils.dart';

Future<CompileDDCResponse> compileDDC(String fullCode) {
  var input = CompileRequest()..source = fullCode;
  return dartServices
      .compileDDC(input)
      .timeout(longServiceCallTimeout)
      .then((response) {
    return response;
  }).catchError((e, st) {
    print('Error: $e -> $st');
    print('execution -> ddc-compile-failure');
    return "";
  });
}

Future<String> compileDDCOutputHtml(String fullCode) {
  var input = CompileRequest()..source = fullCode;
  return dartServices
      .compileDDC(input)
      .timeout(longServiceCallTimeout)
      .then((response) {
    print('execution -> ddc-compile-success');
    final _js = decorateJavaScript(
      '__TESTRESULT__',
      response.result,
      modulesBaseUrl: response.modulesBaseUrl,
    );
    final _html = getCompiledJsHtml(_js, 'require.js');
    return _html;
  }).catchError((e, st) {
    print('Error: $e -> $st');
    print('execution -> ddc-compile-failure');
    return "";
  });
}

void analyze(String source) async {
  SourceRequest request = SourceRequest();
  request.source = source;
  final response = await dartServices.analyze(request);
  print(response.packageImports);
}
