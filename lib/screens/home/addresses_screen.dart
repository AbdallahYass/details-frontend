import 'package:flutter/material.dart';
import 'package:details_app/constants/app_colors.dart';
import 'package:details_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:details_app/providers/addresses_provider.dart';
import 'package:details_app/models/address_model.dart';
import 'package:go_router/go_router.dart';
import 'package:details_app/screens/home/add_edit_address_screen.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AddressesProvider>(context, listen: false).fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressesProvider>(
      builder: (context, addressesProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.translate('saved_addresses'),
            ),
            centerTitle: true,
            backgroundColor: AppColors.appBarBackground,
            foregroundColor: AppColors.appBarForeground,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_location_alt_outlined),
                onPressed: () {
                  context.push('/addresses/add');
                },
              ),
            ],
          ),
          body: addressesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : addressesProvider.addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.translate('saved_addresses') ??
                            'العناوين المحفوظة',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(
                              context,
                            )?.translate('no_saved_addresses') ??
                            'لم تقم بحفظ أي عناوين بعد.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: addressesProvider.addresses.length,
                  itemBuilder: (context, index) {
                    final address = addressesProvider.addresses[index];
                    return _buildAddressCard(
                      context,
                      address,
                      addressesProvider,
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildAddressCard(
    BuildContext context,
    AddressModel address,
    AddressesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  address.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (address.isDefault)
                  Chip(
                    label: Text(
                      AppLocalizations.of(
                        context,
                      )!.translate('default_address'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: AppColors.adminDashCoupons,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${address.street}, ${address.city}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            if (address.building != null && address.building!.isNotEmpty)
              Text(
                '${AppLocalizations.of(context)!.translate('building')}: ${address.building}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            if (address.phone.isNotEmpty)
              Text(
                '${AppLocalizations.of(context)!.translate('phone_label')}: ${address.phone}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditAddressScreen(address: address),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.translate('edit')),
                ),
                TextButton(
                  onPressed: () async {
                    final success = await provider.deleteAddress(address.id);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.translate('address_deleted_success'),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context)!.translate('delete'),
                  ),
                ),
                if (!address.isDefault)
                  TextButton(
                    onPressed: () {
                      provider.setAsDefault(
                        address.id,
                      ); // تعمل الآن عبر الـ Provider
                    },
                    child: Text(
                      AppLocalizations.of(context)!.translate('set_as_default'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
