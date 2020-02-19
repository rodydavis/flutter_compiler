// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_compiler/flutter_compiler_native.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_static/shelf_static.dart';


Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(createCorsHeadersMiddleware())
      .addMiddleware(logRequests())
      .addHandler(Router.handler);
  // .addHandler(
  //     createStaticHandler('build/web', defaultDocument: 'index.html'));

  final server = await io.serve(handler, 'localhost', 8000)
    ..autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

/// Middleware which adds [CORS headers](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS)
/// to shelf responses. Also handles preflight (OPTIONS) requests.
Middleware createCorsHeadersMiddleware({Map<String, String> corsHeaders}) {
  // By default allow access from everywhere.
  corsHeaders ??= <String, String>{'Access-Control-Allow-Origin': '*'};
  print("Setting Headers: $corsHeaders");

  // Handle preflight (OPTIONS) requests by just adding headers and an empty
  // response.
  Response handleOptionsRequest(Request request) {
    if (request.method == 'OPTIONS') {
      return Response.ok(null, headers: corsHeaders);
    } else {
      return null;
    }
  }

  Response addCorsHeaders(Response response) =>
      response.change(headers: corsHeaders);

  return createMiddleware(
    requestHandler: handleOptionsRequest,
    responseHandler: addCorsHeaders,
  );
}

class Router {
  static FutureOr<Response> handler(Request request) {
    var component = request.url.pathSegments.first;
    if (component == "format") return format(request);
    if (component == "compileDDC") return compileDDC(request);
    if (component == "compile") return compile(request);
    if (component == "downloadGist") return downloadGist(request);
    return Response.notFound(null);
  }

  static Future<Response> compileDDC(Request request) async {
    final body = await request.readAsString();
    var input = CompileRequest()..source = json.decode(body)["source"];
    CompileDDCResponse result = await dartServices
        .compileDDC(input)
        .timeout(longServiceCallTimeout)
        .then((CompileDDCResponse response) {
      print('execution -> ddc-compile-success');
      return response;
    }).catchError((e, st) {
      print('Error: $e -> $st');
      print('execution -> ddc-compile-failure');
      return null;
    });
    if (result == null) {
      return Response.internalServerError(
        body: json.encode({
          "error": "Error compileDDC",
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    }
    return Response.ok(
      json.encode({
        "modulesBaseUrl": result.modulesBaseUrl,
        "result": result.result,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<Response> compile(Request request) async {
    final body = await request.readAsString();
    var input = CompileRequest()..source = json.decode(body)["source"];
    CompileResponse result = await dartServices
        .compile(input)
        .timeout(longServiceCallTimeout)
        .then((CompileResponse response) {
      print('execution -> ddc-compile-success');
      return response;
    }).catchError((e, st) {
      print('Error: $e -> $st');
      print('execution -> ddc-compile-failure');
      return null;
    });
    if (result == null) {
      return Response.internalServerError(
        body: json.encode({
          "error": "Error compile",
        }),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    }
    return Response.ok(
      json.encode({
        "sourceMap": result.sourceMap,
        "result": result.result,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<Response> format(Request request) async {
    final body = await request.readAsString();
    final code = json.decode(body)["source"];
    var formattedCode = await formatCode(code);
    return Response.ok(
      json.encode({
        "code": formattedCode,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }

  static Future<Response> downloadGist(Request request) async {
    final gistId = request.url.queryParameters['id'];
    final gist = await GistLoader().loadGist(gistId);
    String code;
    if (gist.hasFlutterContent()) {
      code = gist.files.first.content;
    }
    // code = await dartfmt.formatCode(code);
    return Response.ok(
      json.encode({
        "code": code,
      }),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
