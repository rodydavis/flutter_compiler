import 'api.dart';
import 'package:http/http.dart' as http;

DartservicesApi get dartServices => DartservicesApi(
      http.Client(),
      false,
      rootUrl: "https://dart-services.appspot.com/",
    );

DartservicesApi get dartServicesRest => DartservicesApi(
      http.Client(),
      true,
      rootUrl: "https://dart-services.appspot.com/",
    );
