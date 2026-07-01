import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/device_profile.dart';
import '../../../core/layout/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/rf_village_gradient.dart';
import '../../../core/widgets/rf_village_logo.dart';
import '../../../core/widgets/site_credit_footer.dart';

class DeviceSelectorPage extends StatelessWidget {
  const DeviceSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < AppBreakpoints.narrow;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const RfVillageLogo(size: RfVillageLogoSize.appBar),
            const SizedBox(width: 10),
            const Text('RF Village MX'),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: EdgeInsets.all(isNarrow ? 16 : 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const RfVillageLogo(size: RfVillageLogoSize.hero),
                        const SizedBox(height: 24),
                        Text(
                          'RF Village MX — Web Serial Clients',
                          style: (isNarrow
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(
                                color: AppColors.villageGreen,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LilyGO wardriving, Badge Pwnterrey Marauder y MagSpoof V5.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.villageText.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                        ),
                        const SizedBox(height: 32),
                        _SectionHeader(title: 'LilyGO Wardriving'),
                        for (final profile in DeviceProfile.forKind(
                          AppKind.wardriving,
                        )) ...[
                          _DeviceCard(profile: profile),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'Marauder Badge'),
                        for (final profile in DeviceProfile.forKind(
                          AppKind.marauder,
                        )) ...[
                          _DeviceCard(profile: profile),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'MagSpoof'),
                        for (final profile in DeviceProfile.forKind(
                          AppKind.magspoof,
                        )) ...[
                          _DeviceCard(profile: profile),
                          const SizedBox(height: 16),
                        ],
                        const SiteCreditFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.villagePurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.profile});

  final DeviceProfile profile;

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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.villagePurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(profile.subtitle),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go(profile.routePath),
                  child: Text('Abrir ${profile.id}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
