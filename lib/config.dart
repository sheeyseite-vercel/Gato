class Config {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://juedaxrgpynmhdohuyxn.supabase.co');
  // Publishable (client-side) key; protected by row level security.
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY',
      defaultValue: 'sb_publishable_Omj1-DJKQJcmmOs6umXVig_Bo4v61bw');
  static const redirect = 'io.supabase.gato://login-callback/';
}
