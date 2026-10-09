import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_screen_layout.dart';
import '../../../core/widgets/iq_widgets.dart';

class SignUpPersonalScreen extends StatefulWidget {
  const SignUpPersonalScreen({super.key});

  @override
  State<SignUpPersonalScreen> createState() => _SignUpPersonalScreenState();
}

class _SignUpPersonalScreenState extends State<SignUpPersonalScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  DateTime? _selectedDOB;
  int? _calculatedAge;
  String _selectedFrom = 'From';
  String _selectedTo = 'To';
  bool _isDriverLicenseUploaded = false;
  Uint8List? _licenseImageBytes;

  final ImagePicker _picker = ImagePicker();

  final List<String> _cities = ['Kirkuk', 'Baghdad', 'Erbil', 'Basra', 'Karbala', 'Najaf', 'Duhok', 'Sulaymaniyah'];

  void _showCityPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Governorate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Center(child: Text(_cities[index])),
                      onTap: () {
                        setState(() {
                          if (isFrom) {
                            _selectedFrom = _cities[index];
                          } else {
                            _selectedTo = _cities[index];
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = DateTime(now.year - 20, now.month, now.day);
    final DateTime firstDate = DateTime(1940);
    final DateTime lastDate = DateTime(now.year - 16, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDOB ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT YOUR DATE OF BIRTH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryOrange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final today = DateTime.now();
      int age = today.year - picked.year;
      if (today.month < picked.month || (today.month == picked.month && today.day < picked.day)) {
        age--;
      }
      setState(() {
        _selectedDOB = picked;
        _calculatedAge = age;
      });
    }
  }

  Future<void> _pickFile(Function(void Function()) setDialogState) async {
    try {
      Uint8List? bytes;
      try {
        final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (photo != null) {
          bytes = await photo.readAsBytes();
        }
      } catch (e) {
        debugPrint('ImagePicker error, falling back to FilePicker: $e');
      }

      if (bytes == null) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          if (result.files.single.bytes != null) {
            bytes = result.files.single.bytes;
          } else if (result.files.single.path != null) {
            bytes = await File(result.files.single.path!).readAsBytes();
          }
        }
      }

      if (bytes != null) {
        final capturedBytes = bytes;
        setDialogState(() {
          _licenseImageBytes = capturedBytes;
        });
        setState(() {
          _licenseImageBytes = capturedBytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: ${e.toString()}')),
        );
      }
    }
  }

  void _showUploadDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _pickFile(setDialogState),
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _licenseImageBytes != null ? const Color(0xFF65CA28) : AppColors.primaryOrange.withOpacity(0.2), 
                      width: 2
                    ),
                  ),
                  child: _licenseImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.memory(_licenseImageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 50, color: AppColors.primaryOrange.withOpacity(0.6)),
                            const SizedBox(height: 10),
                            const Text('Click to Choose Picture', style: TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _licenseImageBytes == null ? null : () {
                    setState(() => _isDriverLicenseUploaded = true);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Document uploaded and saved successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text('Submit Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Sign Up',
      onBack: () => Navigator.pop(context),
      bottomButton: IQButton(
        label: 'Next',
        onTap: () {
          if (_nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name.')));
            return;
          }
          if (_selectedDOB == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your Date of Birth.')));
            return;
          }
          if (_phoneController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your phone number.')));
            return;
          }
          if (_selectedFrom == 'From' || _selectedTo == 'To') {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your work area (From & To).')));
            return;
          }
          if (!_isDriverLicenseUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload your driver license before continuing.')));
            return;
          }
          String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
          if (rawPhone.startsWith('964')) rawPhone = rawPhone.substring(3);
          if (rawPhone.startsWith('0')) rawPhone = rawPhone.substring(1);
          final formattedPhone = '+964$rawPhone';

          Navigator.pushNamed(
            context, 
            '/signup_vehicle',
            arguments: {
              'phone': formattedPhone,
              'fullName': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'dob': _selectedDOB?.toIso8601String(),
              'age': _calculatedAge,
            },
          );
        },
      ),
      child: Column(
        children: [
          IQTextField(hintText: 'Full Name', controller: _nameController),
          
          // Stylish Date of Birth Picker Field
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primaryOrange.withOpacity(0.8), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDOB == null
                          ? 'Select Date of Birth'
                          : '${_selectedDOB!.day.toString().padLeft(2, '0')} / ${_selectedDOB!.month.toString().padLeft(2, '0')} / ${_selectedDOB!.year}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _selectedDOB == null ? FontWeight.normal : FontWeight.bold,
                        color: _selectedDOB == null ? Colors.grey.withOpacity(0.6) : Colors.black,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),

          // Dynamic Auto-Calculated Age Display
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, color: Colors.grey, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Age: ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
                Text(
                  _calculatedAge != null ? '$_calculatedAge Years Old' : 'Auto-calculated from birthday',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _calculatedAge != null ? FontWeight.bold : FontWeight.normal,
                    color: _calculatedAge != null ? AppColors.primaryOrange : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          IQPhoneInput(controller: _phoneController),
          const SizedBox(height: 18),

          IQTextField(
            hintText: 'Email Address (Optional)', 
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          
          Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Work area',
                      style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 13),
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.black.withOpacity(0.05)),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _showCityPicker(true),
                    child: Center(
                      child: Text(
                        _selectedFrom,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedFrom == 'From' ? Colors.black26 : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.black.withOpacity(0.05)),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _showCityPicker(false),
                    child: Center(
                      child: Text(
                        _selectedTo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedTo == 'To' ? Colors.black26 : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          FadeInUp(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showUploadDialog('Upload Driver License'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _isDriverLicenseUploaded ? const Color(0xFF65CA28) : Colors.black.withOpacity(0.08),
                    width: _isDriverLicenseUploaded ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isDriverLicenseUploaded ? 'Driver license uploaded' : 'Upload your driver license',
                      style: TextStyle(
                        color: _isDriverLicenseUploaded ? const Color(0xFF65CA28) : Colors.black54,
                        fontWeight: _isDriverLicenseUploaded ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (_isDriverLicenseUploaded) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Color(0xFF65CA28), size: 20),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
