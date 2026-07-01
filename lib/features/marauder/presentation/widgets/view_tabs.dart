import 'package:flutter/material.dart';

import '../../../../core/config/device_profile.dart';
import '../../domain/marauder_models.dart';

class MarauderViewTabs extends StatelessWidget {
  const MarauderViewTabs({
    required this.currentView,
    required this.onChanged,
    required this.capabilities,
    super.key,
  });

  final MarauderView currentView;
  final ValueChanged<MarauderView> onChanged;
  final MarauderCapabilities capabilities;

  static const _labels = {
    MarauderView.ap: 'WiFi APs',
    MarauderView.bt: 'Bluetooth',
    MarauderView.gps: 'GPS',
    MarauderView.wardrive: 'Wardrive',
    MarauderView.storage: 'Storage',
    MarauderView.nfc: 'NFC',
  };

  List<MarauderView> get _visibleViews {
    return MarauderView.values.where((view) {
      if (view == MarauderView.nfc && !capabilities.supportsNfc) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final view in _visibleViews)
          ChoiceChip(
            label: Text(_labels[view]!),
            selected: currentView == view,
            onSelected: (_) => onChanged(view),
          ),
      ],
    );
  }
}
