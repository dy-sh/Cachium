import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../widgets/coming_soon_tile.dart';
import '../widgets/settings_section.dart';

class ComingSoonSettingsScreen extends StatelessWidget {
  const ComingSoonSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              LucideIcons.chevronLeft,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text('Coming Soon', style: AppTypography.h3),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SettingsSection(
                    title: 'Feature Roadmap',
                    children: const [
                      ComingSoonTile(
                        title: 'Import/Export CSV',
                        icon: LucideIcons.fileSpreadsheet,
                      ),
                      ComingSoonTile(
                        title: 'iCloud Sync',
                        icon: LucideIcons.cloud,
                      ),
                      ComingSoonTile(
                        title: 'Apple Watch App',
                        icon: LucideIcons.watch,
                      ),
                      ComingSoonTile(
                        title: 'Siri Integration',
                        icon: LucideIcons.mic,
                      ),
                      ComingSoonTile(
                        title: 'Password Protection',
                        icon: LucideIcons.lock,
                      ),
                      ComingSoonTile(
                        title: 'Graphs & Analytics',
                        icon: LucideIcons.barChart3,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
