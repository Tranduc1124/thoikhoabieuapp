import 'package:flutter/material.dart';

import '../services/backend_diagnostics_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_gradient_background.dart';

class BackendDiagnosticsScreen extends StatefulWidget {
  const BackendDiagnosticsScreen({super.key});

  @override
  State<BackendDiagnosticsScreen> createState() =>
      _BackendDiagnosticsScreenState();
}

class _BackendDiagnosticsScreenState extends State<BackendDiagnosticsScreen> {
  late Future<BackendDiagnosticsResult> _future;

  @override
  void initState() {
    super.initState();
    _future = BackendDiagnosticsService.checkBackendStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm tra kết nối')),
      body: SoftGradientBackground(
        child: SafeArea(
          child: FutureBuilder<BackendDiagnosticsResult>(
            future: _future,
            builder: (context, snapshot) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  SectionHeader(
                    title: 'Trạng thái hiện tại',
                    subtitle:
                        snapshot.connectionState == ConnectionState.waiting
                        ? 'Đang kiểm tra kết nối…'
                        : 'Xem nhanh tình trạng ứng dụng và phiên đăng nhập của bạn.',
                    trailing: IconButton.filledTonal(
                      onPressed: () => setState(() {
                        _future =
                            BackendDiagnosticsService.checkBackendStatus();
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
                          for (final line in snapshot.data!.toDisplayLines())
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
