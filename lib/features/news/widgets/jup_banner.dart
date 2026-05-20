import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JupBanner extends StatelessWidget {
  const JupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Ring decoration - left
          Positioned(
            left: -20,
            bottom: 5,
            child: SvgPicture.asset(
              'assets/banners/ellipse_purple.svg',
              height: 67,
            ),
          ),
          // Star decoration - right
          Positioned(
            right: 0,
            bottom: -8,
            child: SvgPicture.asset(
              'assets/banners/star_pink.svg',
              width: 80,
              height: 80,
            ),
          ),
          // jup! logo
          Center(
            child: SvgPicture.asset(
              'assets/banners/logo_jup.svg',
              colorFilter: const ColorFilter.mode(
                Color(0xFF8065D2),
                BlendMode.srcIn,
              ),
              height: 44,
            ),
          ),
        ],
      ),
    );
  }
}
