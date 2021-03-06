import 'require.dart';

const kRequireJs =
    'https://firebasestorage.googleapis.com/v0/b/flutter-web-ide.appspot.com/o/compiler%2Frequire.js?alt=media&token=f1a92547-8ccf-4b83-81ec-15e0b47d50bd';

String getCompiledJsHtml(String js) {
  return """
  <!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">
  <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Roboto">
  <link href="https://fonts.googleapis.com/icon?family=Material+Icons"
      rel="stylesheet">

  <!-- iOS meta tags & icons -->
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="example">
  <link rel="apple-touch-icon" href="/icons/Icon-192.png">


  <title>example</title>
</head>
<body>
  <script>
  $kRequireJS
  </script>
  <script id="compiledJsScript" type="application/javascript">
  $js
  </script>
</body>
</html>
  """;
}

String decorateJavaScript(String testKey, String javaScript,
    {String modulesBaseUrl}) {
  final String postMessagePrint = '''
const testKey = '$testKey';

function dartPrint(message) {
  if (message.startsWith(testKey)) {
    var resultMsg = JSON.parse(message.substring(testKey.length));
    resultMsg.sender = 'frame';
    resultMsg.type = 'testResult';
    parent.postMessage(resultMsg, '*');
  } else {
    parent.postMessage(
      {'sender': 'frame', 'type': 'stdout', 'message': message.toString()}, '*');
  }
}
''';

  /// The javascript exception handling for Dartpad catches both errors
  /// directly raised by main() (in which case we might have useful Dart
  /// exception information we don't want to discard), as well as errors
  /// generated by other means, like assertion errors when starting up
  /// asynchronous functions.
  ///
  /// To avoid duplicating error messages on the DartPad console, we signal to
  /// window.onerror that we've already sent a dartMainRunner message by
  /// flipping _thrownDartMainRunner to true.  Some platforms don't populate
  /// error so avoid using it if it is null.
  ///
  /// This seems to produce both the stack traces we expect in inspector
  /// and the right error messages on the console.
  final String exceptionHandler = '''
var _thrownDartMainRunner = false;
function dartMainRunner(main, args) {
  try {
    main(args);
  } catch(error) {
    parent.postMessage(
      {'sender': 'frame', 'type': 'stderr', 'message': "Uncaught exception:\\n" + error.message}, '*');
    _thrownDartMainRunner = true;
    throw error;
  }
}

window.onerror = function(message, url, lineNumber, colno, error) {
  if (!_thrownDartMainRunner) {
    var errorMessage = '';
    if (error != null) {
      errorMessage = 'Error: ' + error;
    } 
    parent.postMessage(
      {'sender': 'frame', 'type': 'stderr', 'message': message + errorMessage}, '*');
  }
  _thrownDartMainRunner = false;
};
''';

  String requireConfig = '';
  if (modulesBaseUrl != null) {
    requireConfig = '''
require.config({
  "baseUrl": "$modulesBaseUrl",
  "waitSeconds": 60
});
''';
  }

  final bool usesRequireJs = modulesBaseUrl != null;

  String postfix = '';
  if (usesRequireJs) {
    postfix = '''
require(["dartpad_main", "dart_sdk"], function(dartpad_main, dart_sdk) {
    // SDK initialization.
    dart_sdk.dart.setStartAsyncSynchronously(true);
    dart_sdk._isolate_helper.startRootIsolate(() => {}, []);

    // Loads the `dartpad_main` module and runs its bootstrapped main method.
    //
    // DDK provides the user's code in a RequireJS module, which exports an
    // object that looks something like this:
    //
    // {
    //       [random_tokens]__bootstrap: bootstrap,
    //       [random_tokens]__main: main
    // }
    //
    // The first of those properties holds the compiled code for the bootstrap
    // Dart file, which the server uses to wrap the user's code and wait on a
    // call to dart:ui's `webOnlyInitializePlatform` before executing any of it.
    //
    // The loop below iterates over the properties of the exported object,
    // looking for one that ends in "__bootstrap". Once found, it executes the
    // bootstrapped main method, which calls the user's main method, which
    // (presumably) calls runApp and starts Flutter's rendering. 

    for (var prop in dartpad_main) {
          if (prop.endsWith("__bootstrap")) {
            dartpad_main[prop].main();
          }
    }});
''';
  }

  return '$postMessagePrint\n$exceptionHandler\n$requireConfig\n'
          '$javaScript\n$postfix'
      .trim();
}
