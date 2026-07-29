import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';

class ScheduleTripInfoScreen extends StatefulWidget {
  const ScheduleTripInfoScreen({super.key});

  @override
  State<ScheduleTripInfoScreen> createState() => _ScheduleTripInfoScreenState();
}

class _ScheduleTripInfoScreenState extends State<ScheduleTripInfoScreen> {
  int _seatsAvailable = 2;
  String _availabilityStatus = 'All seats are available';
  final List<String> _statusOptions = ['All seats are available', 'Need passengers'];

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yalla ',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 32),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ── Date/Time Buttons Card ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  _buildDateTimeBtn('Choose date', '14/2/2026'),
                  const SizedBox(width: 12),
                  _buildDateTimeBtn('Choose time', '2:00 PM'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── Route & Info Card ──────────────────────────────────────
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    // Route Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCityChip('Kirkuk'),
                        const SizedBox(width: 8),
                        Expanded(child: _buildRouteArrow()),
                        const SizedBox(width: 8),
                        _buildCityChip('Bagdad'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Icons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat(Icons.event_seat_outlined, '4'),
                        _buildSubStat(Icons.access_time, '2:00 PM'),
                        _buildSubStat(Icons.calendar_month_outlined, '14/2/2026'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.directions_car_filled, size: 24, color: Colors.black),
                    const SizedBox(height: 4),
                    const Text(
                      'Dodge Charger',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Availability Dropdown / Selection ────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _availabilityStatus,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w500),
                  items: _statusOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _availabilityStatus = val);
                  },
                ),
              ),
            ),

            // ── Seats Available Counter (Conditional) ───────────────
            if (_availabilityStatus == 'Need passengers')
              FadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(top: 25, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'seats available',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          _buildCounterCircle(Icons.remove, () {
                            if (_seatsAvailable > 1) setState(() => _seatsAvailable--);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Text(
                              '$_seatsAvailable',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildCounterCircle(Icons.add, () {
                            setState(() => _seatsAvailable++);
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 60),

            // ── Submit Button ──────────────────────────────────────────
            FadeInUp(
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 5,
                    shadowColor: AppColors.primaryOrange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeBtn(String title, String value) {
    return Expanded(
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: AppColors.primaryOrange.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildCityChip(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _buildRouteArrow() {
    return Row(
      children: [
        Expanded(child: Container(height: 1.5, color: Colors.black)),
        const Icon(Icons.arrow_forward, size: 18, color: Colors.black),
      ],
    );
  }

  Widget _buildSubStat(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.black),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildCounterCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }
}
