import 'package:flutter/foundation.dart';

class Config {
  String backend_scheme;
  String backend_host;
  int backend_port;

  Config({
    required this.backend_scheme,
    required this.backend_host,
    required this.backend_port,
  });
  Config.debug()
      : this(
          backend_scheme: 'http',
          backend_host: 'localhost',
          backend_port: 8080,
        );
  Config.release()
      : this(
          backend_scheme: 'https',
          backend_host: 'api.sustainity.dev',
          backend_port: 443,
        );

  static Config load() {
    if (kReleaseMode) {
      return Config.release();
    } else {
      return Config.debug();
    }
  }
}
