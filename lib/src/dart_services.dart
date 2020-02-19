import 'dartservices.dart';
import 'package:http/http.dart' as http;

DartservicesApi get dartServices => DartservicesApi(
      http.Client(),
      rootUrl: "https://dart-services.appspot.com/",
    );
