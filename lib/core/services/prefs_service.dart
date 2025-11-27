import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyOnboardingIntroCompleted = 'onboarding_intro_completed';
  static const String keyPolicyReadVersion = 'policy_read_version';
  static const String keyTermsReadVersion = 'terms_read_version';
  static const String keyConsentAcceptedVersion = 'consent_accepted_version';
  static const String keyConsentAcceptedAt = 'consent_accepted_at';
  static const String keyMarketingConsent = 'marketing_consent';

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(keyOnboardingCompleted) ?? false;
  }

  Future<bool> setOnboardingCompleted(bool value) async {
    return _prefs.setBool(keyOnboardingCompleted, value);
  }

  bool getOnboardingIntroCompleted() {
    return _prefs.getBool(keyOnboardingIntroCompleted) ?? false;
  }

  Future<bool> setOnboardingIntroCompleted(bool value) async {
    return _prefs.setBool(keyOnboardingIntroCompleted, value);
  }

  int getPolicyReadVersion() {
    return _prefs.getInt(keyPolicyReadVersion) ?? 0;
  }

  Future<bool> setPolicyReadVersion(int version) async {
    return _prefs.setInt(keyPolicyReadVersion, version);
  }

  int getTermsReadVersion() {
    return _prefs.getInt(keyTermsReadVersion) ?? 0;
  }

  Future<bool> setTermsReadVersion(int version) async {
    return _prefs.setInt(keyTermsReadVersion, version);
  }

  int getConsentAcceptedVersion() {
    return _prefs.getInt(keyConsentAcceptedVersion) ?? 0;
  }

  Future<bool> setConsentAcceptedVersion(int version) async {
    return _prefs.setInt(keyConsentAcceptedVersion, version);
  }

  DateTime? getConsentAcceptedAt() {
    final millis = _prefs.getInt(keyConsentAcceptedAt);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<bool> setConsentAcceptedAt(DateTime dateTime) async {
    return _prefs.setInt(keyConsentAcceptedAt, dateTime.millisecondsSinceEpoch);
  }

  bool getMarketingConsent() {
    return _prefs.getBool(keyMarketingConsent) ?? false;
  }

  Future<bool> setMarketingConsent(bool value) async {
    return _prefs.setBool(keyMarketingConsent, value);
  }
}


