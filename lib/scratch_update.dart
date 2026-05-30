import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Initializing Supabase...');
  final supabase = await Supabase.initialize(
    url: 'https://ubcasncuupxebngpsfgh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InViY2FzbmN1dXB4ZWJuZ3BzZmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMDkwNjksImV4cCI6MjA5MDc4NTA2OX0.41UBvM1W95wxhgWTB4S0Yxs2YuDhGcSOE8BgTEzkQ9Y',
  );

  final client = supabase.client;

  print('Logging in as test@hostelhub.com...');
  try {
    final response = await client.auth.signInWithPassword(
      email: 'test@hostelhub.com',
      password: 'testpassword123',
    );

    if (response.session != null) {
      print('Logged in successfully! User ID: ${response.user?.id}');
      
      print('Updating profile role to student...');
      final updateResponse = await client
          .from('profiles')
          .update({'role': 'student'})
          .eq('phone', '+919876543210')
          .select();

      print('Success! Profile updated: $updateResponse');
    } else {
      print('Failed to log in: session is null');
    }
  } catch (e) {
    print('Error occurred: $e');
  }
}
