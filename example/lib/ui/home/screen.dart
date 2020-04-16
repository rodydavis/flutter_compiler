import 'package:flutter/material.dart';
import 'package:flutter_compiler/flutter_compiler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String jsOutput;
  String fullCode = r"""
  import 'package:flutter/material.dart';
import 'dart:html';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Downloader Example',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: FileDownloadExample(),
    );
  }
}

class FileDownloadExample extends StatefulWidget {
  @override
  _FileDownloadExampleState createState() => _FileDownloadExampleState();
}

class _FileDownloadExampleState extends State<FileDownloadExample> {
  String _data = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Download Example"),
        actions: <Widget>[
          IconButton(
            tooltip: "Download File",
            icon: Icon(Icons.cloud_download),
            onPressed: () => downloadFile(_data, 'file_download_example.txt'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: TextStyle(color: Colors.black),
              decoration: const InputDecoration(
                hintText: 'Enter Text Here',
                border: InputBorder.none,
              ),
              maxLines: null,
              onChanged: (val) => _data = val,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

void downloadFile(String data, String filename) {
  String encodedFileContents = Uri.encodeComponent(data);
  AnchorElement(href: "data:text/plain;charset=utf-8,$encodedFileContents")
    ..setAttribute("download", filename)
    ..click();
}
  """;
  @override
  void initState() {
    _textController.text = fullCode;
    _compile();
    super.initState();
  }

  void _analyze() {
    final _code = _textController.text;
    final _analyzer = DartUtils(_code);
    final _classes = _analyzer.classes();
    for (final item in _classes) {
      print('class: ${item.index} -> ${item.name}');
    }
  }

  void _compile() {
    final _code = _textController.text;
    compileDDCOutputHtml(_code).then((response) async {
      if (mounted)
        setState(() {
          jsOutput = response;
        });
    });
  }

  void _format() {
    if (mounted)
      setState(() {
        _textController.text = formatDart(_textController.text);
      });
  }

  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Compiler'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: _analyze,
          ),
          IconButton(
            icon: Icon(Icons.format_quote),
            onPressed: _format,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _compile,
          ),
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Scrollbar(
              child: TextField(
                controller: _textController,
                maxLines: null,
              ),
            ),
          ),
          VerticalDivider(),
          Flexible(
            flex: 1,
            child: Scrollbar(
              child: jsOutput == null
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(child: SelectableText(jsOutput)),
            ),
          ),
        ],
      ),
    );
  }
}
