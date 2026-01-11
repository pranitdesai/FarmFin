import 'package:carousel_slider/carousel_slider.dart';
import 'package:desaifarms/Utils/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextStyle _welcomeTextStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 32,
    color: Colors.white,
  );
  final TextStyle _welcomeSubTextStyle = GoogleFonts.poppins(
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: Colors.white,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: StartFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              RepaintBoundary(
                child: ClipPath(
                  clipper: WaveClipperOne(flip: true),
                  child: Container(
                    height: 250,
                    color: AppColor.green800,
                  ),
                ),
              ),
              Padding(
                // ✨ OPTIMIZATION: Used const.
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome',
                      style: _welcomeTextStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Freshness, Quality, and Care — Delivered Naturally.',
                      style: _welcomeSubTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Expanded(
            child: Column(
              children: [
                SvgCarouselExample(),
                SizedBox(height: 36),
                WaveTextSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SvgCarouselExample extends StatefulWidget {
  const SvgCarouselExample({super.key});

  @override
  State<SvgCarouselExample> createState() => _SvgCarouselExampleState();
}

class _SvgCarouselExampleState extends State<SvgCarouselExample> {
  final List<String> svgs = [
    'assets/farm_tractor_1.svg',
    'assets/farm_tractor_2.svg',
    'assets/forest.svg',
  ];

  final CarouselSliderController _controller = CarouselSliderController();
  final ValueNotifier<int> currentPage = ValueNotifier<int>(0);

  @override
  void dispose() {
    currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: svgs.length,
          itemBuilder: (context, index, realIndex) {
            return RepaintBoundary(
              child: SvgPicture.asset(
                svgs[index],
                fit: BoxFit.contain,
              ),
            );
          },
          options: CarouselOptions(
            height: 300,
            autoPlay: true,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) => currentPage.value = index,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<int>(
          valueListenable: currentPage,
          builder: (context, value, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(svgs.length, (index) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value == index ? AppColor.green500 : Colors.grey,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class WaveTextSection extends StatelessWidget {
  const WaveTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RepaintBoundary(
        child: ClipPath(
          clipper: WaveClipperOne(flip: true, reverse: true),
          child: Container(
            width: double.infinity,
            color: AppColor.green800,
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20),
            child: Text(
                '',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
          ),
        ),
      ),
    );
  }
}

class StartFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const StartFAB({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.white,
        splashColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.arrow_forward,
          size: 28,
          color: AppColor.green900,
        ),
      ),
    );
  }
}