import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController(text: 'admin');
  final pass = TextEditingController();
  bool hidden = true;
  String? error;

  Future<void> submit() async {
    final ok = await context.read<AppState>().login(user.text, pass.text);
    if (!ok && mounted) setState(() => error = 'Username හෝ password එක වැරදියි.');
  }

  @override Widget build(BuildContext context) => Scaffold(
    body: Row(children: [
      if (MediaQuery.sizeOf(context).width > 820)
        Expanded(child: Container(color: const Color(0xFF0B4DA2), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/app_icon.png', width: 120),
          const SizedBox(height: 24),
          const Text('Smart School\nTransport Manager', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700, height: 1.25)),
          const SizedBox(height: 12),
          const Text('Students • Payments • Vehicles • Hiring', style: TextStyle(color: Colors.white70)),
        ]))),
      Expanded(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Welcome back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), const Text('ඔබගේ business dashboard එකට login වෙන්න.'),
        const SizedBox(height: 32),
        TextField(controller: user, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 16),
        TextField(controller: pass, obscureText: hidden, onSubmitted: (_) => submit(), decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility : Icons.visibility_off)))),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20), FilledButton.icon(onPressed: submit, icon: const Icon(Icons.login), label: const Padding(padding: EdgeInsets.all(13), child: Text('Login'))),
        const SizedBox(height: 16), const Text('Default: admin / admin123', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
      ]))))),
    ]),
  );
}
