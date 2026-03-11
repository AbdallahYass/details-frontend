import 'package:details_app/app_imports.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF121212),
      padding: const EdgeInsets.only(
        top: 60,
        bottom: 120, // مساحة إضافية عشان الناف بار ما يغطي الفوتر
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          // Branding
          const Text(
            'DETAILS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          Text(
            'STORE',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 30),

          // Description
          Text(
            AppLocalizations.of(context)!.translate('footer_about_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),

          // Contact Info
          Column(
            children: [
              _contactRow(Icons.email_outlined, "support@details-store.com"),
              const SizedBox(height: 10),
              _contactRow(Icons.phone_android, "+972-598723438"),
            ],
          ),
          const SizedBox(height: 30),

          // Social Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(
                FontAwesomeIcons.instagram,
                'https://www.instagram.com/details__store__?igsh=c3Nuam5mNDM4ajBp',
              ),
              const SizedBox(width: 20),
              _socialButton(
                FontAwesomeIcons.whatsapp,
                'https://wa.me/972598723438',
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Links (Accordions)
          Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                _footerAccordion(
                  context,
                  AppLocalizations.of(context)!.translate('language'),
                  customChildren: [
                    _buildLanguageItem(
                      context,
                      'العربية',
                      const Locale('ar', ''),
                    ),
                    _buildLanguageItem(
                      context,
                      'English',
                      const Locale('en', ''),
                    ),
                  ],
                ),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                _footerAccordion(
                  context,
                  AppLocalizations.of(context)!.translate('policies'),
                  customChildren: [
                    _buildPolicyItem(
                      context,
                      AppLocalizations.of(context)!.translate('policy_cancel'),
                    ),
                    _buildPolicyItem(
                      context,
                      AppLocalizations.of(context)!.translate('policy_return'),
                    ),
                    _buildPolicyItem(
                      context,
                      AppLocalizations.of(
                        context,
                      )!.translate('policy_shipping'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Copyright
          Text(
            AppLocalizations.of(context)!.translate('copyright'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String label, Locale locale) {
    return GestureDetector(
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setLocale(locale);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(title),
            content: Text(title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(AppLocalizations.of(context)!.translate('ok')),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _footerAccordion(
    BuildContext context,
    String title, {
    List<Widget>? customChildren,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: AppColors.secondary,
        collapsedIconColor: Colors.white.withValues(alpha: 0.5),
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: customChildren ?? [],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.secondary, size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _socialButton(IconData icon, String url) {
    return GestureDetector(
      onTap: () async {
        if (!await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        )) {
          debugPrint('Could not launch $url');
        }
      },
      child: Container(
        width: 45,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
