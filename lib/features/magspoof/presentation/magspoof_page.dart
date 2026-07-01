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
import '../domain/magspoof_commands.dart';
import 'magspoof_controller.dart';
import 'magspoof_state.dart';
import 'widgets/command_panel.dart';
import 'widgets/terminal_panel.dart';
import 'widgets/tracks_table_panel.dart';

class MagspoofPage extends ConsumerStatefulWidget {
  const MagspoofPage({required this.profile, super.key});

  final DeviceProfile profile;

  @override
  ConsumerState<MagspoofPage> createState() => _MagspoofPageState();
}

class _MagspoofPageState extends ConsumerState<MagspoofPage> {
  final _terminalScrollController = ScrollController();
  late final TextEditingController _track1Controller;
  late final TextEditingController _track2Controller;

  @override
  void initState() {
    super.initState();
    _track1Controller = TextEditingController(text: defaultTrack1);
    _track2Controller = TextEditingController(text: defaultTrack2);
  }

  @override
  void dispose() {
    _terminalScrollController.dispose();
    _track1Controller.dispose();
    _track2Controller.dispose();
    super.dispose();
  }

  MagspoofController get _controller =>
      ref.read(magspoofControllerProvider(widget.profile).notifier);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(magspoofControllerProvider(widget.profile));
    final isNarrow = MediaQuery.sizeOf(context).width < AppBreakpoints.wide;

    ref.listen(magspoofControllerProvider(widget.profile), (previous, next) {
      if (next.rawTerminal.length != (previous?.rawTerminal.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_terminalScrollController.hasClients) {
            _terminalScrollController.jumpTo(
              _terminalScrollController.position.maxScrollExtent,
            );
          }
        });
      }

      if (previous?.track1Value != next.track1Value &&
          _track1Controller.text != next.track1Value) {
        _track1Controller.text = next.track1Value;
      }
      if (previous?.track2Value != next.track2Value &&
          _track2Controller.text != next.track2Value) {
        _track2Controller.text = next.track2Value;
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
            TextButton(
              onPressed: _controller.toggleTheme,
              child: Text(state.isDarkTheme ? 'Claro' : 'Oscuro'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConnectionPanel(
                state: state,
                onBaudRateChanged: _controller.setBaudRate,
                onConnect: _controller.connect,
                onDisconnect: _controller.disconnect,
              ),
              if (state.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(state.errorMessage),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (isNarrow) ...[
                MagspoofTerminalPanel(
                  rawTerminal: state.rawTerminal,
                  scrollController: _terminalScrollController,
                  onClear: _controller.clearTerminal,
                ),
                const SizedBox(height: 16),
                MagspoofCommandPanel(
                  track1Controller: _track1Controller,
                  track2Controller: _track2Controller,
                  onQuickCommand: _controller.sendQuickCommand,
                  onManualCommand: _controller.sendManualCommand,
                  onSendTrack1: () => _controller.sendTrack(
                    _track1Controller.text,
                    'track_1_editor',
                  ),
                  onSendTrack2: () => _controller.sendTrack(
                    _track2Controller.text,
                    'track_2_editor',
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MagspoofTerminalPanel(
                        rawTerminal: state.rawTerminal,
                        scrollController: _terminalScrollController,
                        onClear: _controller.clearTerminal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MagspoofCommandPanel(
                        track1Controller: _track1Controller,
                        track2Controller: _track2Controller,
                        onQuickCommand: _controller.sendQuickCommand,
                        onManualCommand: _controller.sendManualCommand,
                        onSendTrack1: () => _controller.sendTrack(
                          _track1Controller.text,
                          'track_1_editor',
                        ),
                        onSendTrack2: () => _controller.sendTrack(
                          _track2Controller.text,
                          'track_2_editor',
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              MagspoofTracksTablePanel(
                records: state.parsedRecords,
                tableView: state.tableView,
                exportMode: state.exportMode,
                onTableViewChanged: _controller.setTableView,
                onExportModeChanged: _controller.setExportMode,
                onParseBuffer: _controller.parseBufferedInput,
                onClearRecords: _controller.clearRecords,
                onExportCsv: _controller.exportCurrentCsv,
              ),
              const SiteCreditFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({
    required this.state,
    required this.onBaudRateChanged,
    required this.onConnect,
    required this.onDisconnect,
  });

  final MagspoofState state;
  final ValueChanged<int> onBaudRateChanged;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final magspoofBaudRates = baudRates
        .where((rate) => rate <= 115200)
        .toList(growable: false);

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
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MagSpoof Web Serial Client',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.villagePurple,
                      ),
                    ),
                    Text(
                      state.statusMessage,
                      style: TextStyle(
                        color: state.isConnected
                            ? AppColors.villageGreen
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                DropdownButton<int>(
                  value: state.baudRate,
                  items: [
                    for (final rate in magspoofBaudRates)
                      DropdownMenuItem(value: rate, child: Text('$rate')),
                  ],
                  onChanged: state.isConnected
                      ? null
                      : (value) {
                          if (value != null) onBaudRateChanged(value);
                        },
                ),
                if (!state.isConnected)
                  FilledButton(
                    onPressed: state.isConnecting ? null : onConnect,
                    child: Text(
                      state.isConnecting ? 'Conectando...' : 'Conectar',
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: state.isDisconnecting ? null : onDisconnect,
                    child: Text(
                      state.isDisconnecting
                          ? 'Desconectando...'
                          : 'Desconectar',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
