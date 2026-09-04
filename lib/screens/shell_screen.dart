import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/app_theme.dart';
import 'modules.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int selected = 0;
  final items = const [
    ('Dashboard', Icons.dashboard_outlined), ('Students', Icons.school_outlined),
    ('Payments', Icons.payments_outlined), ('Payment History', Icons.receipt_long_outlined),
    ('Vehicles', Icons.directions_bus_outlined), ('Hiring / Trips', Icons.route_outlined),
    ('Messages', Icons.chat_outlined), ('Reports', Icons.bar_chart_outlined),
    ('Settings', Icons.settings_outlined), ('Users', Icons.manage_accounts_outlined),
  ];

  Widget page() => switch (selected) {
    0 => const DashboardPage(), 1 => const StudentsPage(), 2 => const PaymentsPage(),
    3 => const PaymentHistoryPage(), 4 => const VehiclesPage(), 5 => const HiringPage(),
    6 => const MessagesPage(), 7 => const ReportsPage(), 8 => const SettingsPage(), _ => const UsersPage(),
  };

  @override Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(body: Row(children: [
      Container(width: 238, color: AppTheme.sidebar, child: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [Image.asset('assets/images/app_icon.png', width: 42), const SizedBox(width: 10), const Expanded(child: Text('NETHSARA\nTRANSPORT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, height: 1.2)))])),
        const Divider(color: Color(0xFF343437)),
        Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 10), itemCount: items.length, itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: ListTile(
          selected: selected == i, selectedTileColor: AppTheme.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          leading: Icon(items[i].$2, color: selected == i ? Colors.white : Colors.white54),
          title: Text(items[i].$1, style: TextStyle(color: selected == i ? Colors.white : Colors.white70, fontSize: 13)),
          onTap: () => setState(() => selected = i),
        )))),
        ListTile(leading: const Icon(Icons.logout, color: Colors.white54), title: const Text('Logout', style: TextStyle(color: Colors.white70)), onTap: state.logout),
        Padding(padding: const EdgeInsets.all(16), child: Text('${state.user?['full_name']}\n${state.user?['role']}', style: const TextStyle(color: Colors.white54, fontSize: 11))),
      ]))),
      Expanded(child: SafeArea(child: page())),
    ]));
  }
}

class PageFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;
  const PageFrame({super.key, required this.title, required this.child, this.subtitle = '', this.actions = const []});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)), if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey))])), ...actions]),
    const SizedBox(height: 22), Expanded(child: child),
  ]));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String text;
  const EmptyState(this.icon, this.text, {super.key});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 52, color: Colors.grey.shade400), const SizedBox(height: 12), Text(text, style: const TextStyle(color: Colors.grey))]));
}
