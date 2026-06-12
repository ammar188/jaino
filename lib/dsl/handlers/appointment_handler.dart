import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

import '../models/dsl_handler.dart';
import '../models/dsl_message.dart';
import '../models/dsl_render_result.dart';

class AppointmentDSLHandler extends DSLHandler {
  @override
  String get type => 'appointment';

  @override
  int get version => 1;

  @override
  DSLRenderResult render(Event event, DSLMessage msg) {
    final title = msg.get<String>('title') ?? 'Book Appointment';
    return DSLRenderResult(
      widget: _AppointmentTriggerCard(title: title, room: event.room),
    );
  }
}

// ── Trigger Card ─────────────────────────────────────────────────────────────
class _AppointmentTriggerCard extends StatelessWidget {
  final String title;
  final Room room;

  const _AppointmentTriggerCard({required this.title, required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => _AppointmentScreen1(room: room, title: title),
        ),
      ),
      child: Container(
        width: 193.52,
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Tap to book',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF111111), width: 0.83),
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF111111), size: 6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Screen 1: Calendar + Time ─────────────────────────────────────────────────
class _AppointmentScreen1 extends StatefulWidget {
  final Room room;
  final String title;

  const _AppointmentScreen1({required this.room, required this.title});

  @override
  State<_AppointmentScreen1> createState() => _AppointmentScreen1State();
}

class _AppointmentScreen1State extends State<_AppointmentScreen1> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _times = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM',
    '05:00 PM', '06:00 PM', 
  ];

  bool get _canProceed => _selectedDate != null && _selectedTime != null;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(context, widget.title),
      body: SingleChildScrollView(
  padding: const EdgeInsets.symmetric(horizontal: 15),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Text(
        'Book Appointment',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 18,
          letterSpacing: -1,
          color: Color(0xFF111111),
        ),
      ),
      const SizedBox(height: 16),
      // ── Calendar ──
            Container(
              width: 340.10,
              height: 344.49,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  // Month nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
  onTap: _prevMonth,
  child: Container(
    width: 28.50,
    height: 28.50,
    padding: const EdgeInsets.fromLTRB(7, 7, 8, 7),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFCED3DE), width: 0.84),
    ),
    child: const Icon(Icons.chevron_left, size: 14, color: Color(0xFF8F9BB3)),
  ),
),
                      Column(
  children: [
    const Text(
      'Select Date',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0,
        color: Color(0xFF111111),
      ),
    ),
    const SizedBox(height: 2),
    Text(
      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        fontSize: 10.06,
        letterSpacing: 0,
        color: Color(0xFF8E8E93),
      ),
    ),
  ],
),
                      GestureDetector(
  onTap: _nextMonth,
  child: Container(
    width: 28.50,
    height: 28.50,
    padding: const EdgeInsets.fromLTRB(7, 7, 8, 7),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFCED3DE), width: 0.84),
    ),
    child: const Icon(Icons.chevron_right, size: 14, color: Color(0xFF8F9BB3)),
  ),
),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Day headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                        .map((d) => SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  // Days grid
                  Expanded(child: _buildCalendarGrid()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Select Time ──
            SizedBox(
              width: 360.10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: _times.map((t) {
                      final selected = _selectedTime == t;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9.51, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF7150DB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28.53),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF7150DB)
                                  : const Color(0xFFE0E0E0),
                              width: 0.57,
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF70737D),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Next Button ──
            Center(
              child: GestureDetector(
                onTap: _canProceed
                    ? () => Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (_) => _AppointmentScreen2(
                              room: widget.room,
                              title: widget.title,
                              date: _formatDate(_selectedDate!),
                              time: _selectedTime!,
                            ),
                          ),
                        )
                    : null,
                child: Container(
                  width: 82,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _canProceed
                        ? const Color(0xFF7150DB)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _canProceed ? Colors.white : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    // Monday = 1, so offset = weekday - 1
    final startOffset = (firstDay.weekday - 1) % 7;
    final today = DateTime.now();

    List<Widget> cells = [];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox(width: 32, height: 32));
    }

    for (int d = 1; d <= lastDay.day; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);
      final isSelected = _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

      cells.add(
        GestureDetector(
          onTap: isPast ? null : () => setState(() => _selectedDate = date),
          child: Container(
  width: 25.15,
  height: 25.15,
  decoration: BoxDecoration(
    color: isSelected ? const Color(0xFF7150DB) : Colors.transparent,
    borderRadius: BorderRadius.circular(8.38),
  ),
            child: Center(
              child: Text(
                '$d',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isPast
                          ? const Color(0xFFD0D0D0)
                          : isToday
                              ? const Color(0xFF7150DB)
                              : const Color(0xFF111111),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 0,
      childAspectRatio: 1,
      children: cells,
    );
  }

  String _monthName(int m) => [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}

// ── Screen 2: Your Details ────────────────────────────────────────────────────
class _AppointmentScreen2 extends StatefulWidget {
  final Room room;
  final String title;
  final String date;
  final String time;

  const _AppointmentScreen2({
    required this.room,
    required this.title,
    required this.date,
    required this.time,
  });

  @override
  State<_AppointmentScreen2> createState() => _AppointmentScreen2State();
}

class _AppointmentScreen2State extends State<_AppointmentScreen2> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _genderCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _genderCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    await widget.room.sendEvent(
      {
        'v': 1,
        'type': 'appointment_form',
        'data': {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'gender': _genderCtrl.text.trim(),
          'department': 'General',
          'date': widget.date,
          'time': widget.time,
          'visit_type': 'In-clinic',
          'symptoms': _noteCtrl.text.trim().isNotEmpty
              ? _noteCtrl.text.trim()
              : 'No notes',
        },
      },
      type: 'com.jaino.appointment_form',
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: _buildAppBar(context, widget.title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // ── Details card ──
            Container(
              width: 360.10,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _inputField(_nameCtrl, 'Name'),
                  const SizedBox(height: 10),
                  _inputField(_phoneCtrl, '+92 300 0000000',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  _inputField(_genderCtrl, 'Gender'),
                  const SizedBox(height: 10),
                  // Note field
                  SizedBox(
                    width: 330,
                    height: 106,
                    child: TextField(
                      controller: _noteCtrl,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111111),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 0.4,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: const BorderSide(
                            color: Color(0xFF7150DB),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Done button ──
            Center(
              child: GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: Container(
                  width: 82,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _canSubmit
                        ? const Color(0xFF7150DB)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _canSubmit
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: 330,
      height: 37,
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13, color: Color(0xFF111111)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.4,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: const BorderSide(
              color: Color(0xFF7150DB),
              width: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared AppBar ─────────────────────────────────────────────────────────────
PreferredSizeWidget _buildAppBar(BuildContext context, String title) {
  return PreferredSize(
    preferredSize: const Size(390, 110),
    child: Container(
      width: 390,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF70737D),
                  size: 16,
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Appointment',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    ),
  );
}