import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'repo.dart';
import 'theme.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await sb.auth.signInWithOAuth(OAuthProvider.google, redirectTo: Config.redirect);
    } catch (e) {
      if (mounted) toast(context, 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screen(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(children: [
          const Spacer(flex: 2),
          const CatLogo(size: 128),
          const SizedBox(height: 20),
          Text('GATO', style: disp(48).copyWith(letterSpacing: 4)),
          const SizedBox(height: 6),
          Text('Your daily journal, notes, quotes\nand voice memos.',
              textAlign: TextAlign.center, style: txt(16, color: C.muted)),
          const Spacer(flex: 3),
          Material(
            color: C.white,
            borderRadius: BorderRadius.circular(32),
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: _busy ? null : _google,
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Center(
                  child: _busy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: C.green))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
                            child: Text('G', style: disp(18, color: C.green)),
                          ),
                          const SizedBox(width: 12),
                          Text('Continue with Google', style: txt(17, color: C.green, w: FontWeight.w700)),
                        ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Your entries sync privately to your account.',
              style: txt(13, color: C.muted), textAlign: TextAlign.center),
          const SizedBox(height: 28),
        ]),
      ),
    );
  }
}
