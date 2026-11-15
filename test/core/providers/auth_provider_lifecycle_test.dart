import 'package:adepa_teachers/core/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared preferences loading does not recreate the auth notifier', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifierBeforePreferencesLoad = container.read(authProvider.notifier);
    await container.read(sharedPreferencesProvider.future);
    final notifierAfterPreferencesLoad = container.read(authProvider.notifier);

    expect(notifierAfterPreferencesLoad, same(notifierBeforePreferencesLoad));
  });
}
