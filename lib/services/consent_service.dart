import 'prefs_service.dart';

class ConsentService {
  ConsentService({required PrefsService prefsService, required this.currentConsentVersion})
      : _prefs = prefsService;

  final PrefsService _prefs;
  final int currentConsentVersion;

  bool get isConsentAccepted => _prefs.getConsentAcceptedVersion() >= currentConsentVersion;

  Future<void> acceptConsent() async {
    await _prefs.setConsentAcceptedVersion(currentConsentVersion);
    await _prefs.setConsentAcceptedAt(DateTime.now());
  }

  Future<void> revokeConsent() async {
    await _prefs.setConsentAcceptedVersion(0);
    await _prefs.setConsentAcceptedAt(DateTime.fromMillisecondsSinceEpoch(0));
  }
}


