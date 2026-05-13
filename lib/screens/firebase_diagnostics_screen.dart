import 'package:flutter/material.dart';

import '../services/firebase_diagnostics_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class FirebaseDiagnosticsScreen extends StatefulWidget {
  const FirebaseDiagnosticsScreen({super.key});

  @override
  State<FirebaseDiagnosticsScreen> createState() =>
      _FirebaseDiagnosticsScreenState();
}

class _FirebaseDiagnosticsScreenState extends State<FirebaseDiagnosticsScreen> {
  late Future<FirebaseDiagnosticsResult> _future;

  @override
  void initState() {
    super.initState();
    _future = FirebaseDiagnosticsService.checkFirebaseStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase diagnostics')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: FutureBuilder<FirebaseDiagnosticsResult>(
            future: _future,
            builder: (context, snapshot) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  SectionHeader(
                    title: 'Kiểm tra Firebase',
                    subtitle:
                        snapshot.connectionState == ConnectionState.waiting
                        ? 'Đang kiểm tra cấu hình...'
                        : 'Không log secret/private key.',
                    trailing: IconButton.filledTonal(
                      onPressed: () => setState(() {
                        _future =
                            FirebaseDiagnosticsService.checkFirebaseStatus();
                      }),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!snapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in snapshot.data!.toLogLines())
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(line),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
