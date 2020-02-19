import 'dart_services.dart';
import 'api.dart';
import 'utils.dart';

Future<String> formatCode(String source) async {
  String originalSource = source;
  SourceRequest input = SourceRequest()..source = originalSource;
  try {
    FormatResponse result =
        await dartServices.format(input).timeout(serviceCallTimeout);
    if (originalSource == source) {
      if (originalSource != result.newString) {
        return result.newString;
      }
    }
  } catch (e) {
    print(e);
  }
  return source;
}
