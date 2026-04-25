import 'package:details_app/app_imports.dart';
import 'package:details_app/providers/addresses_provider.dart';
import 'package:details_app/models/address_model.dart';
import 'dart:math' as math;

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _buildingController;
  late TextEditingController _floorController;
  late TextEditingController _apartmentController;
  late TextEditingController _notesController;
  String? _selectedCity;
  bool _isDefault = false;
  bool _isLoading = false;

  late AnimationController _rotationController;

  final List<String> _cities = [
    'رام الله',
    'البيرة',
    'نابلس',
    'الخليل',
    'جنين',
    'طولكرم',
    'قلقيلية',
    'سلفيت',
    'طوباس',
    'أريحا',
    'بيت لحم',
    'القدس',
    'الناصرة',
    'حيفا',
    'يافا',
  ];

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _nameController = TextEditingController(text: addr?.name ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _streetController = TextEditingController(text: addr?.street ?? '');
    _buildingController = TextEditingController(text: addr?.building ?? '');
    _floorController = TextEditingController(text: addr?.floor ?? '');
    _apartmentController = TextEditingController(text: addr?.apartment ?? '');
    _notesController = TextEditingController(text: addr?.notes ?? '');
    _selectedCity = addr?.city;
    _isDefault = addr?.isDefault ?? false;

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _apartmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final provider = Provider.of<AddressesProvider>(context, listen: false);
    final newAddress = AddressModel(
      id: widget.address?.id ?? '',
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _selectedCity!,
      street: _streetController.text.trim(),
      building: _buildingController.text.trim(),
      floor: _floorController.text.trim(),
      apartment: _apartmentController.text.trim(),
      notes: _notesController.text.trim(),
      isDefault: _isDefault,
    );

    bool success;
    if (widget.address == null) {
      success = await provider.addAddress(newAddress);
    } else {
      success = await provider.updateAddress(newAddress);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ??
                  AppLocalizations.of(context)!.translate('error_occurred'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.address == null
              ? loc.translate('add_new_address')
              : loc.translate('edit_address'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg.png', fit: BoxFit.cover),
          ),
          _buildAnimatedBg(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      _nameController,
                      loc.translate('name_label'),
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildCityDropdown(loc),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _streetController,
                      loc.translate('street'),
                      Icons.map_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _buildingController,
                            loc.translate('building'),
                            Icons.apartment,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _floorController,
                            loc.translate('floor'),
                            Icons.layers_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _phoneController,
                      loc.translate('phone_label'),
                      Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _notesController,
                      loc.translate('address_notes'),
                      Icons.note_add_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: Text(
                        loc.translate('set_as_default'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      value: _isDefault,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                loc.translate('save'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBg() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) => Transform.rotate(
          angle: _rotationController.value * 2 * math.pi,
          child: child,
        ),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.goldBorder),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: (v) => v!.isEmpty && maxLines == 1
            ? AppLocalizations.of(context)!.translate('required_field')
            : null,
      ),
    );
  }

  Widget _buildCityDropdown(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedCity,
        decoration: InputDecoration(
          labelText: loc.translate('city'),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.location_city,
            color: AppColors.goldBorder,
          ),
        ),
        items: _cities
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCity = v),
        validator: (v) => v == null ? loc.translate('required_field') : null,
      ),
    );
  }
}
