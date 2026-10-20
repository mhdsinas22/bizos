import 'package:flutter/foundation.dart';

/// Configuration and feature flags for authentication migration.
///
/// Controls whether the application uses legacy User ID + Password authentication
/// or the new Supabase Auth Email + Password authentication.
class AuthConfig {
  AuthConfig._();

  /// Default flag: KEEP FALSE IN PRODUCTION until the Supabase Auth
  /// user migration and RLS policies have been deployed and verified.
  static const bool _defaultUseSupabaseAuth = true;

  static bool? _overrideUseSupabaseAuth;

  /// Whether to use the Supabase Auth Email + Password flow.
  /// When `false`, the legacy User ID + Password flow is active.
  static bool get useSupabaseAuth =>
      _overrideUseSupabaseAuth ?? _defaultUseSupabaseAuth;

  /// Optional fallback to look up user profile by `email` if `auth_user_id`
  /// has not yet been backfilled in `public.users`.
  static const bool fallbackProfileByEmail = false;

  /// Allows toggling the auth mode for testing and staging verification.
  @visibleForTesting
  static void setUseSupabaseAuthForTesting(bool? value) {
    _overrideUseSupabaseAuth = value;
  }
}
