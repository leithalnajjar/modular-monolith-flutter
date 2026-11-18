// apps/bazaar_app/lib/config.dart
import 'package:feature_flags/feature_flags.dart';

/// Where this build of Bazaar runs.
enum BazaarEnvironment {
  /// Everything in memory: demo products, demo sign-in, fake payments.
  demo,

  /// Products from the staging catalog server; sign-in and payments are
  /// still the demo adapters until staging versions exist.
  staging,
}

/// Switches the composition root owns: whether optional modules run at all.
abstract final class AppFlags {
  static const inbox = Flag(
    'app.inbox',
    description:
        'Include the notifications module (Chapter 16). Nothing '
        'depends on it, so it can be switched off without breaking anything.',
    defaultValue: true,
  );

  static const all = [inbox];
}

/// Everything that differs between builds of the same code.
///
/// Read once, in main, and passed down: modules receive plain values and
/// never read the environment themselves.
final class BazaarConfig {
  const BazaarConfig({
    this.environment = BazaarEnvironment.demo,
    this.catalogUrl,
    this.flags = const FlagValues(),
  });

  /// Reads the values given to `flutter run` or `flutter build` with
  /// `--dart-define=NAME=value` or `--dart-define-from-file=<file>.json`.
  factory BazaarConfig.fromEnvironment() => BazaarConfig.parse(
    environment: const String.fromEnvironment('BAZAAR_ENV'),
    catalogUrl: const String.fromEnvironment('BAZAAR_CATALOG_URL'),
    flags: const String.fromEnvironment('BAZAAR_FLAGS'),
  );

  /// Builds a config from raw text and checks it, so a broken build
  /// configuration fails at startup with a clear message instead of
  /// misbehaving later. Empty strings mean "not set".
  factory BazaarConfig.parse({
    String environment = '',
    String catalogUrl = '',
    String flags = '',
  }) {
    final env = environment.isEmpty
        ? BazaarEnvironment.demo
        : BazaarEnvironment.values.asNameMap()[environment] ??
              (throw FormatException(
                'Unknown BAZAAR_ENV "$environment". '
                'Use one of: ${BazaarEnvironment.values.map((e) => e.name).join(', ')}.',
              ));

    Uri? url;
    if (catalogUrl.isNotEmpty) {
      url = Uri.tryParse(catalogUrl);
      if (url == null || url.scheme != 'https' || !url.path.endsWith('/')) {
        throw FormatException(
          'BAZAAR_CATALOG_URL must be an https URL ending '
          'with "/", got "$catalogUrl"',
        );
      }
    }
    if (env == BazaarEnvironment.staging && url == null) {
      throw const FormatException('staging needs BAZAAR_CATALOG_URL');
    }

    return BazaarConfig(
      environment: env,
      catalogUrl: url,
      flags: FlagValues.parse(flags),
    );
  }

  final BazaarEnvironment environment;

  /// The catalog server, or null to use the demo products.
  final Uri? catalogUrl;

  final FlagValues flags;
}
