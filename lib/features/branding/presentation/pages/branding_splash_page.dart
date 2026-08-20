import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class BrandingSplashPage extends StatefulWidget {
  const BrandingSplashPage({super.key});

  @override
  State<BrandingSplashPage> createState() => _BrandingSplashPageState();
}

class _BrandingSplashPageState extends State<BrandingSplashPage>
    with SingleTickerProviderStateMixin {
  static const String _logoAsset = 'assets/branding/hook_logo_white.png';

  late final AnimationController _controller;
  late final Animation<double> _logoReveal;
  late final Animation<double> _shineSweep;
  late final Animation<double> _shineOpacity;
  late final Animation<double> _textFade;
  late final Animation<double> _textReveal;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    AppRouter.isBrandingSplashActive.value = true;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _logoReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.78, curve: Curves.easeOutCubic),
    );
    _shineSweep = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.96, curve: Curves.easeInOutCubic),
      ),
    );
    _shineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.97, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 0.92, curve: Curves.easeOut),
    );
    _textReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.94, curve: Curves.easeOutCubic),
    );
    _textSlide = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        AppRouter.isBrandingSplashActive.value = false;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    AppRouter.isBrandingSplashActive.value = false;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortestSide = constraints.biggest.shortestSide;
            final logoWidth = (shortestSide * 0.54).clamp(180.0, 430.0);

            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: logoWidth,
                          child: _AnimatedHookLogo(
                            assetPath: _logoAsset,
                            revealProgress: _logoReveal.value,
                            shineSweep: _shineSweep.value,
                            shineOpacity: _shineOpacity.value,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: _textFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _textSlide.value),
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.center,
                                widthFactor: _textReveal.value.clamp(0, 1),
                                child: Text(
                                  'SISTEMAS DE PESAJE',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary.withValues(
                                          alpha: 0.88,
                                        ),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 3.2,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedHookLogo extends StatelessWidget {
  const _AnimatedHookLogo({
    required this.assetPath,
    required this.revealProgress,
    required this.shineSweep,
    required this.shineOpacity,
  });

  final String assetPath;
  final double revealProgress;
  final double shineSweep;
  final double shineOpacity;

  @override
  Widget build(BuildContext context) {
    final progress = revealProgress.clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: AppConstants.appName,
      image: true,
      child: AspectRatio(
        aspectRatio: 2.7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              clipper: _LogoRevealClipper(progress),
              child: _buildLogoImage(),
            ),
            if (shineOpacity > 0.001)
              IgnorePointer(
                child: ClipRect(
                  clipper: _LogoRevealClipper(progress),
                  child: Opacity(
                    opacity: shineOpacity.clamp(0.0, 1.0).toDouble(),
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) {
                        final center = -1.20 + (shineSweep * 2.40);
                        return LinearGradient(
                          begin: Alignment(center - 0.18, 0),
                          end: Alignment(center + 0.18, 0),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.92),
                            Colors.white.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                          stops: const [0.00, 0.42, 0.50, 0.58, 1.00],
                        ).createShader(rect);
                      },
                      child: _buildLogoImage(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage() {
    return Image.asset(assetPath, fit: BoxFit.contain, filterQuality: FilterQuality.high);
  }
}

class _LogoRevealClipper extends CustomClipper<Rect> {
  const _LogoRevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    return Rect.fromLTWH(0, 0, size.width * clamped, size.height);
  }

  @override
  bool shouldReclip(covariant _LogoRevealClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}