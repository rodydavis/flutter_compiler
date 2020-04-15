import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_compiler/flutter_compiler.dart';
import 'package:flutter_compiler/src/dart_services.dart';
import 'package:flutter_compiler/src/iframe/decorate.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullCode;
  @override
  void initState() {
//     fullCode = """
// import 'package:flutter/material.dart';

// final Color darkBlue = Color.fromARGB(255, 18, 32, 47);

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         body: Center(
//           child: MyWidget(),
//         ),
//       ),
//     );
//   }
// }

// class MyWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Text('Hello, World!', style: Theme.of(context).textTheme.headline4);
//   }
// }

// """;
    String gistId = '184e2514914f48ac26a728aa12dcda13';
    GistLoader().loadGist(gistId).then((gist) {
      if (mounted)
        setState(() {
          if (gist.hasFlutterContent()) {
            fullCode = gist.files.first.content;
          }
        });
      _loadJsCode(fullCode).then((response) async {
        final _js = decorateJavaScript(
          '__TESTRESULT__',
          response.result,
          // modulesBaseUrl: response.modulesBaseUrl,
        );
        // print('JS -> $_js');
        print('Result: ${response.result}');
        final _html = getCompiledJsHtml(_js);
        print('HTML -> $_html');
        if (mounted)
          setState(() {
            fullCode = _html;
          });
      });
    });
    super.initState();
  }

  Future<CompileDDCResponse> _loadJsCode(String fullCode) {
    var input = CompileRequest()..source = fullCode;
    return dartServices
        .compileDDC(input)
        .timeout(longServiceCallTimeout)
        .then((response) {
      print('execution -> ddc-compile-success');
      return response;
    }).catchError((e, st) {
      print('Error: $e -> $st');
      print('execution -> ddc-compile-failure');
      return "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: fullCode == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: SelectableText(fullCode)),
      // : LayoutBuilder(
      //     builder: (context, dimens) => FlutterWebPreview(
      //       fullCode: fullCode,
      //       width: dimens.maxWidth,
      //       height: dimens.maxHeight,
      //     ),
      //   ),
    );
  }
}
