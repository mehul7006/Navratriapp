import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;
  final String? backgroundImage;

  const BackgroundScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor = const Color(0xA60C0117),
    this.resizeToAvoidBottomInset = true,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            backgroundImage ?? 'assets/images/BGIMAGE.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0C0117), Color(0xFF140228), Color(0xFF0A0114)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),
          // Semi-transparent overlay for readability
          Container(color: backgroundColor),
          // Content
          child,
        ],
      ),
    );
  }
}

class BackgroundBody extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;
  final String? backgroundImage;

  const BackgroundBody({
    super.key,
    required this.child,
    this.overlayOpacity = 0.55,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          backgroundImage ?? 'assets/images/BGIMAGE.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0C0117), Color(0xFF140228), Color(0xFF0A0114)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            );
          },
        ),
        // Semi-transparent overlay
        Container(color: Color.fromRGBO(12, 1, 23, overlayOpacity)),
        // Content
        child,
      ],
    );
  }
}
