import 'package:flutter/material.dart';

import '../../domain/nfc_commands.dart';

class NfcPanel extends StatefulWidget {
  const NfcPanel({
    required this.lastOutput,
    required this.onCommand,
    super.key,
  });

  final String lastOutput;
  final Future<void> Function(String command) onCommand;

  @override
  State<NfcPanel> createState() => _NfcPanelState();
}

class _NfcPanelState extends State<NfcPanel> {
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  final _authController = TextEditingController(text: 'WPA2');

  @override
  void dispose() {
    _urlController.dispose();
    _textController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ssidController.dispose();
    _passController.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'NT3H2111 tag emulator — approach an NFC reader to the badge.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () => widget.onCommand(nfcScanCommand()),
              child: const Text('Scan'),
            ),
            FilledButton(
              onPressed: () => widget.onCommand(nfcReadCommand()),
              child: const Text('Read'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _row(
          'URL',
          _urlController,
          () => widget.onCommand(nfcUrlCommand(_urlController.text.trim())),
        ),
        _row(
          'Text',
          _textController,
          () => widget.onCommand(nfcTextCommand(_textController.text.trim())),
        ),
        const Text(
          'vCard (name, phone, email)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onCommand(
                nfcVcardCommand(
                  _nameController.text.trim(),
                  _phoneController.text.trim(),
                  _emailController.text.trim(),
                ),
              ),
              child: const Text('Write vCard'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'WiFi credentials',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ssidController,
                decoration: const InputDecoration(labelText: 'SSID'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _passController,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _authController,
                decoration: const InputDecoration(labelText: 'Auth'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onCommand(
                nfcWifiCommand(
                  _ssidController.text.trim(),
                  _passController.text.trim(),
                  _authController.text.trim(),
                ),
              ),
              child: const Text('Write WiFi'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Last NFC output',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              widget.lastOutput.isEmpty
                  ? 'No NFC output yet.'
                  : widget.lastOutput,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(
    String label,
    TextEditingController controller,
    VoidCallback onWrite,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: onWrite, child: Text('Write $label')),
        ],
      ),
    );
  }
}
