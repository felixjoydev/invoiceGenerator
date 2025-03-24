/// Supabase authentication configuration
class SupabaseConfig {
  /// The URL of your Supabase project
  static const String supabaseUrl = 'https://lmhwjvkwzekiibxqanec.supabase.co';

  /// The anonymous key for your Supabase project
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxtaHdqdmt3emVraWlieHFhbmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI0OTY4NjAsImV4cCI6MjA1ODA3Mjg2MH0.kKTnsD0q4xvuh2jZXbOlN8TJwbG1y_frWwU95WNQ3as';

  /// Deep link redirect URL for authentication
  static const String redirectUrl =
      'io.supabase.invoicegenerator://login-callback/';

  /// Alternative deep link format for more reliable handling
  static const String alternateRedirectUrl =
      'io.supabase.invoicegenerator.login-callback://';
}
