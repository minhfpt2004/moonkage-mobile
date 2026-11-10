import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (_) => const ExternalUrlLauncher(),
);

class ExternalUrlLauncher {
  const ExternalUrlLauncher();

  static const _channel = MethodChannel('moonkage/external_url');

  Future<bool> open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return false;
    return await _channel.invokeMethod<bool>('open', {'url': uri.toString()}) ?? false;
  }
}
