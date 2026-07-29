import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

class AddCreditScreen extends StatefulWidget {
  const AddCreditScreen({super.key});

  @override
  State<AddCreditScreen> createState() => _AddCreditScreenState();
}

class _AddCreditScreenState extends State<AddCreditScreen> {
  int _amount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Add Credit',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ── Quick Amount Chips ─────────────────────────────────────
            FadeInDown(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAmountChip('1,000', 1000),
                  const SizedBox(width: 16),
                  _buildAmountChip('5,000', 5000),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // ── Counter ───────────────────────────────────────────────
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCounterBtn(Icons.remove, () {
                    if (_amount >= 1000) setState(() => _amount -= 1000);
                  }),
                  const SizedBox(width: 28),
                  Text(
                    '$_amount IQD',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(width: 28),
                  _buildCounterBtn(Icons.add, () => setState(() => _amount += 1000)),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // ── Payment Methods ───────────────────────────────────────
            FadeInUp(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mastercard
                    Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle),
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF79E1B).withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('Mastercard', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: 28),
                    // VISA
                    const Text(
                      'VISA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1F71),
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 28),
                    // Q logo (IQ payment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber.shade600),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Q',
                        style: TextStyle(
                          color: Colors.amber.shade600,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountChip(String label, int value) {
    return GestureDetector(
      onTap: () => setState(() => _amount = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _amount == value ? AppColors.primaryOrange : Colors.black12, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: _amount == value ? AppColors.primaryOrange : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
    );
  }
}
