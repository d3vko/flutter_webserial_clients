import 'package:flutter/material.dart';

import '../../domain/marauder_models.dart';

class MarauderViewTabs extends StatelessWidget {
  const MarauderViewTabs({
    required this.currentView,
    required this.onChanged,
    super.key,
  });

  final MarauderView currentView;
  final ValueChanged<MarauderView> onChanged;

  static const _labels = {
    MarauderView.ap: 'WiFi APs',
    MarauderView.bt: 'Bluetooth',
    MarauderView.gps: 'GPS',
    MarauderView.wardrive: 'Wardrive',
    MarauderView.storage: 'Storage',
    MarauderView.nfc: 'NFC',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final view in MarauderView.values)
          ChoiceChip(
            label: Text(_labels[view]!),
            selected: currentView == view,
            onSelected: (_) => onChanged(view),
          ),
      ],
    );
  }
}
