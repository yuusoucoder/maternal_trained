import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/aiovy_logo.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../login/login_screen.dart';

/// Stitch: splash_intro
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return Scaffold(
      body: Stack(
        children: [
          // Soft blurred blooms behind the content
          Positioned(
            top: -60,
            right: -80,
            child: _Bloom(size: 320, color: AppColors.primaryFixed.withAlpha(70)),
          ),
          Positioned(
            bottom: 80,
            left: -90,
            child: _Bloom(size: 288, color: AppColors.secondaryFixed.withAlpha(110)),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: FadeTransition(
                    opacity: fade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        const Pill(
                          text: 'For Maternal Healthcare Professionals',
                          uppercase: true,
                          icon: Icons.verified_user,
                          background: Color(0x99E7DDE0),
                          foreground: AppColors.onSurfaceVariant,
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                          child: Column(
                            children: [
                              const _HeroMark(),
                              const SizedBox(height: AppSpacing.lg),
                              Semantics(
                                header: true,
                                child: Text(AppStrings.appName,
                                    style: AppTextStyles.displayLg.copyWith(color: AppColors.onTertiaryFixed)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.tagline,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headlineSm.copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 320),
                                child: Text(
                                  'Clinical decision-support for maternal risk assessment & timely clinical review.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              const Row(
                                children: [
                                  Expanded(child: _FeatureTile(icon: Icons.monitor_heart_outlined, label: 'Real-Time')),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                      child: _FeatureTile(icon: Icons.health_and_safety_outlined, label: 'Explainable')),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(child: _FeatureTile(icon: Icons.lock_outline, label: 'Protected')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            PrimaryButton(
                              label: 'Get Started',
                              trailingIcon: Icons.arrow_forward,
                              onPressed: () => AppNavigator.replace(context, const LoginScreen()),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Version 1.0 · Clinical Decision-Support Prototype',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelSm.copyWith(color: const Color(0xFF58404C)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Built for safe, empathetic obstetrics workflow',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSm.copyWith(color: AppColors.outline, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      height: 156,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 156,
            height: 156,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(36),
            ),
          ),
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Color(0x1F2D1924), blurRadius: 28, offset: Offset(0, 12))],
            ),
            child: const AiovyLogoMark(size: 100),
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
                boxShadow: AppShadows.md,
              ),
              child: const Icon(Icons.medical_services_outlined, size: 17, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
