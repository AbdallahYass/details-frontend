import 'package:details_app/app_imports.dart'; // عشان تستخدم AppConstants لو لزم

class HomeFooterWidget extends StatelessWidget {
  const HomeFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // فوتر أسود فخم
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "DETAILS STORE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Elevate Your Style",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.instagram,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(AppConstants.instagramUrl);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    debugPrint('Could not launch Instagram');
                  }
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () async {
                  final Uri url = Uri.parse(AppConstants.whatsappUrl);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  )) {
                    debugPrint('Could not launch WhatsApp');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          const Text(
            "© 2026 Details Store. All rights reserved.",
            style: TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
