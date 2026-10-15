import 'package:flutter/foundation.dart';

@immutable
class Clinician {
  const Clinician({
    required this.displayName,
    required this.role,
    required this.affiliation,
    required this.email,
  });

  final String displayName;
  final String role;
  final String affiliation;
  final String email;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();
  }
}
