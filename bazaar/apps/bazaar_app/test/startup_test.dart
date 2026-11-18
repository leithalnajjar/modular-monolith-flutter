import 'package:bazaar_app/modules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every service every module registered can be built', () async {
    final host = await startBazaar();
    addTearDown(host.stop);

    // Lazy singletons are normally built the first time a screen asks for
    // them. Build them all now: a module whose dependencies nobody
    // registers (because the module that provides them was removed from
    // bazaarModules) fails here, in CI, instead of in front of a user.
    final services = host.di.findAll<Object>(
      instantiateLazySingletons: true,
      callFactories: true,
    );

    expect(services, isNotEmpty);
  });
}
