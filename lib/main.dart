import 'src/main_mobile.dart'
    if (dart.library.html) 'src/main_web.dart'
    as entrypoint;

Future<void> main() => entrypoint.main();
