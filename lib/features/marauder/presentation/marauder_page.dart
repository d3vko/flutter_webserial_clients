import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/rf_village_gradient.dart';
import '../../../core/widgets/site_credit_footer.dart';
import '../domain/marauder_models.dart';
import 'marauder_auth_modal.dart';
import 'marauder_controller.dart';
import 'marauder_state.dart';
import 'widgets/ble_device_table.dart';
import 'widgets/command_builder.dart';
import 'widgets/gps_panel.dart';
import 'widgets/nfc_panel.dart';
import 'widgets/storage_panel.dart';
import 'widgets/system_utilities_panel.dart';
import 'widgets/terminal_panel.dart';
import 'widgets/view_tabs.dart';
import 'widgets/wardrive_panel.dart';
import 'widgets/wifi_ap_table.dart';
import 'widgets/workflow_dialog.dart';

class MarauderPage extends ConsumerStatefulWidget {
  const MarauderPage({required this.profile, super.key});

  final DeviceProfile profile;

  @override
  ConsumerState<MarauderPage> createState() => _MarauderPageState();
}

class _MarauderPageState extends ConsumerState<MarauderPage> {
  final _terminalScrollController = ScrollController();

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  MarauderController get _controller =>
      ref.read(marauderControllerProvider(widget.profile).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marauderControllerProvider(widget.profile));
    final isNarrow = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    ref.listen(marauderControllerProvider(widget.profile), (previous, next) {
      if (next.terminalLines.length != (previous?.terminalLines.length ?? 0)) {
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

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.villageGreen,
          secondary: AppColors.villagePurple,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/branding/pwnterrey.png',
                height: 28,
                filterQuality: FilterQuality.medium,
              ),
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
            TextButton(
              onPressed: _controller.toggleTheme,
              child: Text(state.isDarkTheme ? 'White mode' : 'Black mode'),
            ),
            if (state.isLoggedIn)
              TextButton(
                onPressed: () async => _controller.logout(),
                child: Text('Logout (${state.authUsername})'),
              )
            else
              TextButton(
                onPressed: () =>
                    showMarauderAuthModal(context, ref, widget.profile),
                child: const Text('Log in'),
              ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConnectionPanel(
                    state: state,
                    onConnect: _controller.connect,
                    onDisconnect: _controller.disconnect,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth >= AppBreakpoints.medium;
                        if (wide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 320,
                                child: _Sidebar(
                                  state: state,
                                  controller: _controller,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _MainPanel(
                                  state: state,
                                  controller: _controller,
                                  terminalScrollController:
                                      _terminalScrollController,
                                  profile: widget.profile,
                                  ref: ref,
                                ),
                              ),
                            ],
                          );
                        }
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _Sidebar(state: state, controller: _controller),
                              const SizedBox(height: 16),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 400,
                                ),
                                child: _MainPanel(
                                  state: state,
                                  controller: _controller,
                                  terminalScrollController:
                                      _terminalScrollController,
                                  profile: widget.profile,
                                  ref: ref,
                                ),
                              ),
                              const SiteCreditFooter(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= AppBreakpoints.medium)
                    const SiteCreditFooter(),
                ],
              ),
            ),
            if (isNarrow) const _MobileBlocker(),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state, required this.controller});

  final MarauderState state;
  final MarauderController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommandBuilder(
            onCommand: controller.sendCommand,
            initialMode: state.currentView == MarauderView.bt
                ? CommandBuilderMode.bluetooth
                : CommandBuilderMode.wifi,
          ),
          const SizedBox(height: 12),
          SystemUtilitiesPanel(
            onCommand: controller.sendCommand,
            onOpenStorage: () => controller.setView(MarauderView.storage),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Workflows',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final workflow in controller.workflows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: OutlinedButton(
                        onPressed: state.isConnected
                            ? () => showWorkflowDialog(
                                context,
                                workflow: workflow,
                                onExecute: (inputs) => controller
                                    .executeWorkflow(workflow, inputs),
                              )
                            : null,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(workflow.name),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel({
    required this.state,
    required this.controller,
    required this.terminalScrollController,
    required this.profile,
    required this.ref,
  });

  final MarauderState state;
  final MarauderController controller;
  final ScrollController terminalScrollController;
  final DeviceProfile profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarauderViewTabs(
          currentView: state.currentView,
          onChanged: controller.setView,
        ),
        if (state.activeCommand != null) ...[
          const SizedBox(height: 8),
          _ActiveCommandBar(
            command: state.activeCommand!,
            onStop: controller.stopScan,
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: TerminalPanel(
            lines: state.terminalLines,
            scrollController: terminalScrollController,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          flex: 3,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _ViewContent(
                state: state,
                controller: controller,
                profile: profile,
                ref: ref,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewContent extends StatelessWidget {
  const _ViewContent({
    required this.state,
    required this.controller,
    required this.profile,
    required this.ref,
  });

  final MarauderState state;
  final MarauderController controller;
  final DeviceProfile profile;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return switch (state.currentView) {
      MarauderView.ap => WifiApTable(
        accessPoints: state.accessPoints,
        isConnected: state.isConnected,
        onRefresh: controller.refreshAccessPoints,
        onClear: controller.clearAccessPoints,
      ),
      MarauderView.bt => BleDeviceTable(
        devices: state.bluetoothDevices,
        isConnected: state.isConnected,
        onRefresh: controller.refreshBluetoothDevices,
        onClear: controller.clearBluetoothDevices,
      ),
      MarauderView.gps => SingleChildScrollView(
        child: GpsPanel(
          telemetry: state.gpsTelemetry,
          logLines: state.gpsLogLines,
          onCommand: controller.sendCommand,
        ),
      ),
      MarauderView.wardrive => Align(
        alignment: Alignment.topLeft,
        child: WardrivePanel(
          entryCount: state.wardriveEntries.length,
          uploadPhase: state.uploadPhase,
          uploadError: state.uploadError,
          isUploading: state.isUploading,
          isLoggedIn: state.isLoggedIn,
          onDownload: controller.downloadWardriveCsv,
          onUpload: () async {
            if (!state.isLoggedIn) {
              await showMarauderAuthModal(context, ref, profile);
            }
            await controller.uploadWardrive();
          },
          onClear: controller.clearWardriveEntries,
        ),
      ),
      MarauderView.storage => StoragePanel(
        files: state.spiffsFiles,
        storageInfo: state.spiffsStorageInfo,
        isCapturing: state.isCapturingFile,
        capturingFileName: state.capturingFileName,
        onList: controller.listSpiffsFiles,
        onDownload: controller.downloadSpiffsFile,
        onDelete: controller.deleteSpiffsFile,
        onFormat: controller.formatSpiffs,
      ),
      MarauderView.nfc => SingleChildScrollView(
        child: NfcPanel(
          lastOutput: state.nfcLastOutput,
          onCommand: controller.sendCommand,
        ),
      ),
    };
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
  });

  final MarauderState state;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
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
                  state.statusMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (state.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (!state.isConnected)
                      FilledButton(
                        onPressed: state.isConnecting ? null : onConnect,
                        child: state.isConnecting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Connect'),
                      )
                    else
                      FilledButton.tonal(
                        onPressed: state.isDisconnecting ? null : onDisconnect,
                        child: const Text('Disconnect'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCommandBar extends StatelessWidget {
  const _ActiveCommandBar({required this.command, required this.onStop});

  final String command;
  final Future<void> Function() onStop;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.play_circle, color: Colors.greenAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                command,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.greenAccent,
                ),
              ),
            ),
            TextButton(onPressed: onStop, child: const Text('Stop')),
          ],
        ),
      ),
    );
  }
}

class _MobileBlocker extends StatelessWidget {
  const _MobileBlocker();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.desktop_windows, size: 48),
              const SizedBox(height: 16),
              Text(
                'Desktop required',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Web Serial for Marauder requires Chrome or Edge on desktop.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
