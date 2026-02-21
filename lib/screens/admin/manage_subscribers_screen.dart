import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:details_app/app_imports.dart';

class ManageSubscribersScreen extends StatefulWidget {
  const ManageSubscribersScreen({super.key});

  @override
  State<ManageSubscribersScreen> createState() =>
      _ManageSubscribersScreenState();
}

class _ManageSubscribersScreenState extends State<ManageSubscribersScreen> {
  List<dynamic> _subscribers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubscribers();
  }

  Future<void> _fetchSubscribers() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final response = await http.get(
        Uri.parse('https://api.details-store.com/api/admin/subscribers'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      if (response.statusCode == 200) {
        setState(() {
          _subscribers = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching subscribers: $e');
    }
  }

  void _copyAllEmails() {
    final emails = _subscribers.map((s) => s['email']).join(',');
    Clipboard.setData(ClipboardData(text: emails));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ جميع الإيميلات'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _sendEmail() async {
    if (_subscribers.isEmpty) return;

    final emails = _subscribers.map((s) => s['email']).join(',');

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      query: _encodeQueryParameters({
        'bcc': emails, // استخدام BCC لحماية خصوصية العملاء
        'subject': 'Details Store Update',
      }),
    );

    try {
      if (!await launchUrl(emailLaunchUri)) {
        throw 'Could not launch';
      }
    } catch (e) {
      if (mounted) _copyAllEmails(); // في حال الفشل ننسخ الإيميلات
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        title: Image.asset('assets/images/logo2.png', height: 100),
        backgroundColor: AppColors.appBarBackground,
        foregroundColor: AppColors.appBarForeground,
        centerTitle: true,
        actions: [
          if (_subscribers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: 'إرسال بريد',
              onPressed: _sendEmail,
            ),
          if (_subscribers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_all),
              tooltip: 'نسخ الكل',
              onPressed: _copyAllEmails,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _subscribers.isEmpty
          ? const Center(child: Text('لا يوجد مشتركين حتى الآن'))
          : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _subscribers.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final sub = _subscribers[i];
                // تنسيق التاريخ
                final date = sub['createdAt'] != null
                    ? DateTime.parse(
                        sub['createdAt'],
                      ).toLocal().toString().split(' ')[0]
                    : '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.email,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    sub['email'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'تاريخ الاشتراك: $date',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: sub['email']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ البريد الإلكتروني'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
