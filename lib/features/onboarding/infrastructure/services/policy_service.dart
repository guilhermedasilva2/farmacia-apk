import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:meu_app_inicial/services/prefs_service.dart';

enum PolicyDocument { privacy, terms }

class PolicyService {
  PolicyService({required PrefsService prefsService, this.privacyVersion = 1, this.termsVersion = 1})
      : _prefs = prefsService;

  final PrefsService _prefs;
  final int privacyVersion;
  final int termsVersion;

  bool isRead(PolicyDocument doc) {
    switch (doc) {
      case PolicyDocument.privacy:
        return _prefs.getPolicyReadVersion() >= privacyVersion;
      case PolicyDocument.terms:
        return _prefs.getTermsReadVersion() >= termsVersion;
    }
  }

  Future<void> markRead(PolicyDocument doc) async {
    switch (doc) {
      case PolicyDocument.privacy:
        await _prefs.setPolicyReadVersion(privacyVersion);
        break;
      case PolicyDocument.terms:
        await _prefs.setTermsReadVersion(termsVersion);
        break;
    }
  }

  Future<String> loadMarkdown(PolicyDocument doc) async {
    switch (doc) {
      case PolicyDocument.privacy:
        return rootBundle.loadString('assets/policies/politicas_privacidade_lgpd.md');
      case PolicyDocument.terms:
        return rootBundle.loadString('assets/policies/termos_uso.md');
    }
  }
}


