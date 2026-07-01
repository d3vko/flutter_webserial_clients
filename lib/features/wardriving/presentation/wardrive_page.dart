import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/rf_village_gradient.dart';
import '../../../core/widgets/rf_village_logo.dart';
import '../../../core/widgets/site_credit_footer.dart';
import '../domain/csv_exporter.dart';
import '../domain/models.dart';
import 'auth_modal.dart';
import 'widgets/capture_map_section.dart';
import 'widgets/scan_data_section.dart';
import 'wardrive_controller.dart';
import 'wardrive_state.dart';

class WardrivePage extends ConsumerStatefulWidget {
  const WardrivePage({required this.profile, super.key});

  final DeviceProfile profile;

  @override
  ConsumerState<WardrivePage> createState() => _WardrivePageState();
}

class _WardrivePageState extends ConsumerState<WardrivePage> {
  final _terminalScrollController = ScrollController();

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  WardriveController get _controller =>
      ref.read(wardriveControllerProvider(widget.profile).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wardriveControllerProvider(widget.profile));

    ref.listen(wardriveControllerProvider(widget.profile), (previous, next) {
      if (next.rawLogs.length != (previous?.rawLogs.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_terminalScrollController.hasClients) {
            _terminalScrollController.jumpTo(
              _terminalScrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });

    final theme = state.isDarkTheme ? AppTheme.dark() : AppTheme.light();
    final isNarrow = MediaQuery.sizeOf(context).width < AppBreakpoints.narrow;
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.villageGreen,
          secondary: AppColors.villagePurple,
          tertiary: AppColors.villageCyan,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const RfVillageLogo(size: RfVillageLogoSize.appBar),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.profile.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          actions: [
            if (isCompact)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'theme':
                      _controller.toggleTheme();
                    case 'login':
                      if (state.isLoggedIn) {
                        await _controller.logout();
                      } else {
                        if (!context.mounted) return;
                        await showAuthModal(context, ref, widget.profile);
                      }
                    case 'register':
                      if (!state.isLoggedIn) {
                        if (!context.mounted) return;
                        await showAuthModal(
                          context,
                          ref,
                          widget.profile,
                          view: AuthView.register,
                        );
                      }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'theme',
                    child: Text(
                      state.isDarkTheme ? 'White mode' : 'Black mode',
                    ),
                  ),
                  if (state.isLoggedIn)
                    PopupMenuItem(
                      value: 'login',
                      child: Text('Logout (${state.authUsername})'),
                    )
                  else ...[
                    const PopupMenuItem(value: 'login', child: Text('Log in')),
                    const PopupMenuItem(
                      value: 'register',
                      child: Text('Register'),
                    ),
                  ],
                ],
              )
            else ...[
              TextButton(
                onPressed: _controller.toggleTheme,
                child: Text(state.isDarkTheme ? 'White mode' : 'Black mode'),
              ),
              if (state.isLoggedIn)
                TextButton(
                  onPressed: () async => _controller.logout(),
                  child: Text('Logout (${state.authUsername})'),
                )
              else ...[
                TextButton(
                  onPressed: () => showAuthModal(context, ref, widget.profile),
                  child: const Text('Log in'),
                ),
                TextButton(
                  onPressed: () => showAuthModal(
                    context,
                    ref,
                    widget.profile,
                    view: AuthView.register,
                  ),
                  child: const Text('Register'),
                ),
              ],
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isNarrow ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SerialPanel(profile: widget.profile, state: state),
              const SizedBox(height: 16),
              _TerminalPanel(
                state: state,
                scrollController: _terminalScrollController,
              ),
              const SizedBox(height: 16),
              CaptureMapSection(
                lteRows: state.lteRows,
                wifiRows: state.wifiRows,
                bleRows: state.bleRows,
              ),
              const SizedBox(height: 16),
              ScanDataSection.lte(
                subtitle: '${state.lteRows.length} records',
                filename: makeCsvFilename(ScanType.lte),
                rows: state.lteRows,
                onDownload: () => _controller.downloadCsv(ScanType.lte),
                onClear: () => _controller.clearRows(ScanType.lte),
                onUpload: () => _handleUpload(ScanType.lte, state),
              ),
              ScanDataSection.wifi(
                subtitle: '${state.wifiRows.length} access points',
                filename: makeCsvFilename(ScanType.wifi),
                rows: state.wifiRows,
                onDownload: () => _controller.downloadCsv(ScanType.wifi),
                onClear: () => _controller.clearRows(ScanType.wifi),
                onUpload: () => _handleUpload(ScanType.wifi, state),
              ),
              ScanDataSection.ble(
                subtitle: '${state.bleRows.length} devices',
                filename: makeCsvFilename(ScanType.ble),
                rows: state.bleRows,
                onDownload: () => _controller.downloadCsv(ScanType.ble),
                onClear: () => _controller.clearRows(ScanType.ble),
                onUpload: () => _handleUpload(ScanType.ble, state),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _controller.clearAllRows,
                    child: const Text('Clear all'),
                  ),
                  FilledButton(
                    onPressed: state.hasAnyRows
                        ? () => _handleUploadAll(state)
                        : null,
                    child: const Text('Upload all'),
                  ),
                ],
              ),
              if (state.uploadSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(state.uploadSummary),
              ],
              if (state.ignoredCount > 0) ...[
                const SizedBox(height: 8),
                Text('Ignored invalid coordinates: ${state.ignoredCount}'),
              ],
              const SiteCreditFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpload(ScanType type, WardriveState state) async {
    if (!state.isLoggedIn) {
      _controller.clearPendingUploadAll();
      await showAuthModal(context, ref, widget.profile);
      return;
    }
    await _controller.uploadType(type);
  }

  Future<void> _handleUploadAll(WardriveState state) async {
    if (!state.isLoggedIn) {
      await _controller.requestUploadAll();
      if (!mounted) return;
      await showAuthModal(context, ref, widget.profile);
      return;
    }
    await _controller.requestUploadAll();
  }
}

class _SerialPanel extends ConsumerWidget {
  const _SerialPanel({required this.profile, required this.state});

  final DeviceProfile profile;
  final WardriveState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(wardriveControllerProvider(profile).notifier);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: RfVillageGradient.cardAccent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.subtitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Baud rate'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: state.baudRate,
                      items: baudRates
                          .map(
                            (rate) => DropdownMenuItem(
                              value: rate,
                              child: Text('$rate'),
                            ),
                          )
                          .toList(),
                      onChanged: state.isConnected
                          ? null
                          : (value) {
                              if (value != null) controller.setBaudRate(value);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (!profile.supportsAdvancedSerial)
                      FilledButton(
                        onPressed: state.isConnected || state.isConnecting
                            ? null
                            : () => controller.connectSerial(),
                        child: Text(
                          state.isConnecting
                              ? 'Connecting...'
                              : 'Connect serial',
                        ),
                      )
                    else ...[
                      FilledButton(
                        onPressed: state.isConnected || state.isConnecting
                            ? null
                            : () => controller.connectSerial(
                                mode: SerialConnectMode.target,
                              ),
                        child: const Text('Connect TSIM 7600H-G'),
                      ),
                      OutlinedButton(
                        onPressed: state.isConnected || state.isConnecting
                            ? null
                            : () => controller.connectSerial(
                                mode: SerialConnectMode.usbFallback,
                              ),
                        child: const Text('Other USB serial'),
                      ),
                      OutlinedButton(
                        onPressed: state.isConnected || state.isConnecting
                            ? null
                            : () => controller.connectSerial(
                                mode: SerialConnectMode.all,
                              ),
                        child: const Text('Show all ports'),
                      ),
                    ],
                    if (state.isConnected)
                      OutlinedButton(
                        onPressed: state.isDisconnecting
                            ? null
                            : controller.disconnectSerial,
                        child: const Text('Disconnect'),
                      ),
                    OutlinedButton(
                      onPressed: controller.loadSample,
                      child: const Text('Load sample'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Status: ${state.statusMessage}'),
                if (state.selectedPortLabel.isNotEmpty)
                  Text('Port: ${state.selectedPortLabel}'),
                if (state.errorMessage.isNotEmpty)
                  Text(
                    state.errorMessage,
                    style: const TextStyle(color: AppColors.errorRed),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Web Serial requires Chrome/Edge on localhost or HTTPS.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalPanel extends StatelessWidget {
  const _TerminalPanel({required this.state, required this.scrollController});

  final WardriveState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raw terminal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.villageBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.villageGreen.withValues(alpha: 0.25),
                ),
              ),
              child: state.rawLogs.isEmpty
                  ? Text(
                      'Connect a device or load the sample data.',
                      style: TextStyle(
                        color: AppColors.villageText.withValues(alpha: 0.6),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: state.rawLogs.length,
                      itemBuilder: (context, index) {
                        final line = state.rawLogs[index];
                        return Text(
                          '[${line.receivedAt}] ${line.text}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.villageGreen,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
