import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_screen_layout.dart';
import '../../../core/widgets/iq_widgets.dart';
import '../../../core/network/api_service.dart';

class SignUpVehicleScreen extends StatefulWidget {
  const SignUpVehicleScreen({super.key});

  @override
  State<SignUpVehicleScreen> createState() => _SignUpVehicleScreenState();
}

class _SignUpVehicleScreenState extends State<SignUpVehicleScreen> {
  int seats = 4;
  bool _isCardIdUploaded = false;
  bool _isCarImageUploaded = false;
  bool _isLoading = false;
  
  Uint8List? _cardIdBytes;
  Uint8List? _carImageBytes;

  Future<void> _pickFile(bool isCardId, Function(void Function()) setDialogState) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setDialogState(() {
          if (isCardId) _cardIdBytes = result.files.single.bytes;
          else _carImageBytes = result.files.single.bytes;
        });
        setState(() {
          if (isCardId) _cardIdBytes = result.files.single.bytes;
          else _carImageBytes = result.files.single.bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  void _showUploadDialog(String title, bool isCardId) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Uint8List? currentBytes = isCardId ? _cardIdBytes : _carImageBytes;
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _pickFile(isCardId, setDialogState),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: currentBytes != null ? const Color(0xFF65CA28) : AppColors.primaryOrange.withOpacity(0.2), 
                        width: 2
                      ),
                    ),
                    child: currentBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.memory(currentBytes, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 50, color: AppColors.primaryOrange.withOpacity(0.6)),
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
                    onPressed: currentBytes == null ? null : () {
                      setState(() {
                        if (isCardId) _isCardIdUploaded = true;
                        else _isCarImageUploaded = true;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title uploaded successfully!')),
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
          );
        },
      ),
    );
  }

  Future<void> _handleNext(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number missing!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      // This call registers/logins the user in the backend
      await api.login(phone);
      
      if (mounted) {
        Navigator.pushNamed(
          context, 
          '/otp',
          arguments: {'phone': phone},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error initializing registration: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? phone = args?['phone'];

    return AuthScreenLayout(
      title: 'Sign Up',
      onBack: () => Navigator.pop(context),
      bottomButton: IQButton(
        label: _isLoading ? 'Initializng...' : 'Next',
        onTap: () => _handleNext(phone),
      ),
      child: Column(
        children: [
          const IQTextField(hintText: 'Car or Vehicle name'),
          
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Number of seats',
                  style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 13),
                ),
                Row(
                  children: [
                    _buildCounterBtn(Icons.remove, () {
                      if (seats > 1) setState(() => seats--);
                    }),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$seats',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                    _buildCounterBtn(Icons.add, () {
                      setState(() => seats++);
                    }),
                  ],
                ),
              ],
            ),
          ),

          const IQTextField(hintText: 'Car number'),

          _buildFunctionalUploadBox(
            label: 'Upload Card ID',
            isUploaded: _isCardIdUploaded,
            onTap: () => _showUploadDialog('Upload Card ID', true),
          ),

          _buildFunctionalUploadBox(
            label: 'Upload Image of car',
            isUploaded: _isCarImageUploaded,
            onTap: () => _showUploadDialog('Upload Image of car', false),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildFunctionalUploadBox({required String label, required bool isUploaded, required VoidCallback onTap}) {
    return FadeInUp(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isUploaded ? const Color(0xFF65CA28) : Colors.black.withOpacity(0.08),
              width: isUploaded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isUploaded ? '$label uploaded' : label,
                style: TextStyle(
                  color: isUploaded ? const Color(0xFF65CA28) : Colors.black54,
                  fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isUploaded) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Color(0xFF65CA28), size: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
