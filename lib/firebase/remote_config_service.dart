import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setDefaults(const {
      'max_journals_displayed': 10,
      'max_keywords_displayed': 20,
    });

    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    await refresh();
  }

  int get maxJournalsDisplayed => _remoteConfig.getInt('max_journals_displayed');
  int get maxKeywordsDisplayed => _remoteConfig.getInt('max_keywords_displayed');

  Future<void> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Ignore or log error
    }
  }
}
