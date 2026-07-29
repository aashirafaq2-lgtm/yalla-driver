import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
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
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedFrom = 'From';
  String _selectedTo = 'To';
  bool _isDriverLicenseUploaded = false;
  Uint8List? _webImage;

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

  Future<void> _pickFile(Function(void Function()) setDialogState) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setDialogState(() {
          _webImage = result.files.single.bytes;
        });
        setState(() {
          _webImage = result.files.single.bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
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
                      color: _webImage != null ? const Color(0xFF65CA28) : AppColors.primaryOrange.withOpacity(0.2), 
                      width: 2
                    ),
                  ),
                  child: _webImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.memory(_webImage!, fit: BoxFit.cover),
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
                  onPressed: _webImage == null ? null : () {
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
          if (_phoneController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number')));
            return;
          }
          Navigator.pushNamed(
            context, 
            '/signup_vehicle',
            arguments: {'phone': _phoneController.text},
          );
        },
      ),
      child: Column(
        children: [
          IQTextField(hintText: 'Full Name', controller: _nameController),
          const IQTextField(hintText: 'Birthday'),
          const IQTextField(hintText: 'Age'),
          IQPhoneInput(controller: _phoneController),
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
