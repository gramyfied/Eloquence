import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:eloquence_2_0/presentation/theme/eloquence_design_system.dart';

// --- WIDGETS DE BASE ---

class EloquenceScaffold extends StatelessWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final List<BottomNavigationBarItem>? bottomNavItems;
  final int currentIndex;
  final Function(int)? onNavTap;
  
  const EloquenceScaffold({
    Key? key,
    required this.body,
    this.floatingActionButton,
    this.bottomNavItems,
    this.currentIndex = 0,
    this.onNavTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EloquenceColors.navy,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavItems != null 
        ? EloquenceBottomNav(
            items: bottomNavItems!,
            currentIndex: currentIndex,
            onTap: onNavTap,
          )
        : null,
    );
  }
}

class EloquenceGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  
  const EloquenceGlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: EloquenceRadii.card,
      child: BackdropFilter(
        filter: EloquenceEffects.blur,
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(EloquenceSpacing.md),
          decoration: BoxDecoration(
            color: EloquenceColors.glassBackground,
            borderRadius: EloquenceRadii.card,
            border: EloquenceBorders.card,
            boxShadow: EloquenceShadows.card,
          ),
          child: child,
        ),
      ),
    );
  }
}

// --- COMPOSANTS INTERACTIFS ---

class EloquenceMicrophone extends StatefulWidget {
  final bool isRecording;
  final VoidCallback onTap;
  final double size;
  
  const EloquenceMicrophone({
    Key? key,
    required this.isRecording,
    required this.onTap,
    this.size = 120.0,
  }) : super(key: key);
  
  @override
  EloquenceMicrophoneState createState() => EloquenceMicrophoneState();
}

class EloquenceMicrophoneState extends State<EloquenceMicrophone>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EloquenceMicrophone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.animateTo(0.0);
      }
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: EloquenceColors.haloGradient,
              boxShadow: [
                BoxShadow(
                  color: EloquenceColors.cyan.withAlpha(
                    (widget.isRecording ? _pulseAnimation.value * 255 : 77).toInt()
                  ),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.size / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: EloquenceColors.glassWhite,
                    border: Border.all(
                      color: EloquenceColors.glassBorder,
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: widget.size * 0.4,
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

class EloquenceBottomNav extends StatelessWidget {
  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final Function(int)? onTap;
  
  const EloquenceBottomNav({
    Key? key,
    required this.items,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: BottomNavigationBar(
          backgroundColor: EloquenceColors.glassBackground,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: EloquenceColors.cyan,
          unselectedItemColor: Colors.white.withAlpha(153),
          currentIndex: currentIndex,
          onTap: onTap,
          items: items,
          elevation: 0,
        ),
      ),
    );
  }
}

// --- COMPOSANTS VISUELS ---

class EloquenceProgressBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 à 1.0
  final String? percentage;
  
  const EloquenceProgressBar({
    Key? key,
    required this.label,
    required this.value,
    this.percentage,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: EloquenceTextStyles.body1),
              if (percentage != null)
                Text(percentage!, style: EloquenceTextStyles.body1),
            ],
          ),
          const SizedBox(height: EloquenceSpacing.sm),
        ],
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: EloquenceColors.glassBackground,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: EloquenceColors.cyanVioletGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EloquenceWaveforms extends StatefulWidget {
  final bool isActive;
  final int barCount;

  const EloquenceWaveforms({
    Key? key,
    this.isActive = false,
    this.barCount = 25,
  }) : super(key: key);

  @override
  EloquenceWaveformsState createState() => EloquenceWaveformsState();
}

class EloquenceWaveformsState extends State<EloquenceWaveforms> {
  final Random _random = Random();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.barCount, (index) {
        return WaveformBar(
          isActive: widget.isActive,
          random: _random,
        );
      }),
    );
  }
}

class WaveformBar extends StatefulWidget {
  final bool isActive;
  final Random random;

  const WaveformBar({
    Key? key,
    required this.isActive,
    required this.random,
  }) : super(key: key);

  @override
  WaveformBarState createState() => WaveformBarState();
}

class WaveformBarState extends State<WaveformBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + widget.random.nextInt(400)),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 4.0,
      end: 40.0 + widget.random.nextDouble() * 20.0,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          width: 3,
          height: widget.isActive ? _animation.value : 4,
          decoration: BoxDecoration(
            gradient: EloquenceColors.cyanVioletGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}