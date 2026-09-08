import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';

class ScheduleTripInfoScreen extends StatefulWidget {
  const ScheduleTripInfoScreen({super.key});

  @override
  State<ScheduleTripInfoScreen> createState() => _ScheduleTripInfoScreenState();
}

class _ScheduleTripInfoScreenState extends State<ScheduleTripInfoScreen> {
  int _seatsAvailable = 4;
  String _fromCity = 'Kirkuk';
  String _toCity = 'Baghdad';
  final List<String> _iraqiCities = [
    'Kirkuk', 'Baghdad', 'Erbil', 'Basra', 'Sulaymaniyah', 
    'Najaf', 'Karbala', 'Mosul', 'Duhok', 'Anbar', 'Babil'
  ];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);

  String _availabilityStatus = 'All seats are available';
  final List<String> _statusOptions = ['All seats are available', 'Need passengers'];
  bool _isSubmitting = false;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dtDate = DateTime(dt.year, dt.month, dt.day);
    if (dtDate == DateTime(now.year, now.month, now.day)) return 'Today';
    if (dtDate == tomorrow) return 'Tomorrow';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickCity(bool isOrigin) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  isOrigin ? 'Choose Departure City' : 'Choose Destination City',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _iraqiCities.length,
                  itemBuilder: (context, index) {
                    final city = _iraqiCities[index];
                    return ListTile(
                      title: Text(city, style: const TextStyle(fontSize: 16)),
                      trailing: (isOrigin ? _fromCity == city : _toCity == city)
                          ? const Icon(Icons.check, color: AppColors.primaryOrange)
                          : null,
                      onTap: () => Navigator.pop(context, city),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        if (isOrigin) {
          _fromCity = selected;
        } else {
          _toCity = selected;
        }
      });
    }
  }

  Future<void> _submitTrip() async {
    setState(() => _isSubmitting = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    final combinedDeparture = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      if (token != null) {
        await api.createScheduledTrip({
          'fromGovernorate': _fromCity,
          'toGovernorate': _toCity,
          'departureTime': combinedDeparture.toIso8601String(),
          'availableSeats': _availabilityStatus == 'Need passengers' ? _seatsAvailable : 4,
          'totalSeats': 4,
          'pricePerSeat': 15000,
        }, token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scheduled trip published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note: $e')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 28),
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
                  _buildDateTimeBtn('Choose date', _formatDate(_selectedDate), onTap: _pickDate),
                  const SizedBox(width: 12),
                  _buildDateTimeBtn('Choose time', _formatTime(_selectedTime), onTap: _pickTime),
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
                        _buildCityChip(_fromCity, onTap: () => _pickCity(true)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildRouteArrow()),
                        const SizedBox(width: 8),
                        _buildCityChip(_toCity, onTap: () => _pickCity(false)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Icons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat(Icons.event_seat_outlined, '${_availabilityStatus == "Need passengers" ? _seatsAvailable : 4} Seats'),
                        _buildSubStat(Icons.access_time, _formatTime(_selectedTime)),
                        _buildSubStat(Icons.calendar_month_outlined, _formatDate(_selectedDate)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Icon(Icons.directions_car_filled, size: 24, color: Colors.black),
                    const SizedBox(height: 4),
                    const Text(
                      'Standard Vehicle',
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
                  onPressed: _isSubmitting ? null : _submitTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    elevation: 5,
                    shadowColor: AppColors.primaryOrange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    _isSubmitting ? 'Publishing...' : 'Publish Trip',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildDateTimeBtn(String title, String value, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildCityChip(String city, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

