import 'package:flutter/material.dart';
import 'package:flutter_compiler/flutter_compiler.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String fullCode;
  @override
  void initState() {
    String gistId = '184e2514914f48ac26a728aa12dcda13';
    GistLoader().loadGist(gistId).then((gist) {
      if (mounted)
        setState(() {
          if (gist.hasFlutterContent()) {
            fullCode = gist.files.first.content;
          }
        });
      compileDDCOutputHtml(fullCode).then((response) async {
        if (mounted)
          setState(() {
            fullCode = response;
          });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: fullCode == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(child: SelectableText(fullCode)),
    );
  }
}
