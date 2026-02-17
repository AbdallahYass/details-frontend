import 'package:flutter/material.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo1.png', height: 40),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.aboutLogoBackground,
              ),
              child: Image.asset(
                'assets/images/logo1.png',
                height: 100,
                errorBuilder: (c, _, __) => const Icon(
                  Icons.store,
                  size: 80,
                  color: AppColors.aboutLogoFallback,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Details Store",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.aboutTitle,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Since 2024",
              style: TextStyle(
                color: AppColors.aboutTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              context,
              "Our Story",
              "We started with a simple idea: to bring high-quality fashion to your doorstep. Details Store is more than just a shop; it's a lifestyle.",
            ),
            const SizedBox(height: 20),
            _buildSection(
              context,
              "Our Mission",
              "To provide exceptional customer service and curated products that add value to your life.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.aboutTextPrimary,
          ),
        ),
      ],
    );
  }
}
