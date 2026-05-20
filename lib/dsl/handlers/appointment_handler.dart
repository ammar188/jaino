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
    print('🏥 APPOINTMENT DSL RECEIVED: ${msg.data}');
    final title = msg.get<String>('title') ?? 'Book Appointment';

    return DSLRenderResult(
      widget: _AppointmentTriggerButton(title: title, room: event.room),
    );
  }
}

// ── Trigger Button ────────────────────────────────────────────────────────────
class _AppointmentTriggerButton extends StatelessWidget {
  final String title;
  final Room room;

  const _AppointmentTriggerButton({required this.title, required this.room});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor     = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final titleColor    = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final subtitleColor = const Color(0xFFC9C9C9);
    final tapBgColor    = isDark ? const Color(0xFF3A3A3A) : const Color(0xFF1F1F1F);
    final tapTextColor  = Colors.white;

    return GestureDetector(
      onTap: () => _showAppointmentModal(context, room),
      child: Container(
        width: 193.52,
        height: 95.50,
        padding: const EdgeInsets.all(12.61),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15.14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 168.29,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fill in your details',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Container(
              width: 166.51,
              height: 0.60,
              color: subtitleColor.withOpacity(0.5),
            ),

            const SizedBox(height: 7),

            Container(
              width: 168.29,
              height: 21.04,
              padding: const EdgeInsets.symmetric(horizontal: 5.01),
              decoration: BoxDecoration(
                color: tapBgColor,
                borderRadius: BorderRadius.circular(5.01),
                border: isDark
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
              ),
              child: 
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to book',
                    style: TextStyle(
                      color: tapTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Icon(Icons.arrow_circle_right, color: tapTextColor, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Show Modal ────────────────────────────────────────────────────────────────
void _showAppointmentModal(BuildContext context, Room room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppointmentBottomSheet(room: room),
  );
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────
class _AppointmentBottomSheet extends StatefulWidget {
  final Room room;
  const _AppointmentBottomSheet({required this.room});

  @override
  State<_AppointmentBottomSheet> createState() => _AppointmentBottomSheetState();
}

class _AppointmentBottomSheetState extends State<_AppointmentBottomSheet> {
  int _step = 0;

  // ── Field values ──────────────────────────────────────────────────────────
  final _nameCtrl      = TextEditingController();
  final _ageCtrl       = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _complaintCtrl = TextEditingController();
  String? _gender;
  String? _department;
  String? _date;
  String? _time;
  String? _visitType;

  // ── Step config ───────────────────────────────────────────────────────────
  final List<String> _questions = [
    'What is your full name?',
    'How old are you?',
    'What is your gender?',
    'Your phone number?',
    'Which department?',
    'Preferred date?',
    'Preferred time slot?',
    'Visit type?',
    'Describe your symptoms',
  ];

  // Is the current step ready to proceed?
  bool get _canProceed {
    switch (_step) {
      case 0: return _nameCtrl.text.trim().isNotEmpty;
      case 1: return _ageCtrl.text.trim().isNotEmpty;
      case 2: return _gender != null;
      case 3: return _phoneCtrl.text.trim().isNotEmpty;
      case 4: return _department != null;
      case 5: return _date != null;
      case 6: return _time != null;
      case 7: return _visitType != null;
      case 8: return _complaintCtrl.text.trim().isNotEmpty;
      default: return false;
    }
  }

  // The message sent to the room for the current step
  String get _currentMessage {
    switch (_step) {
      case 0: return _nameCtrl.text.trim();
      case 1: return _ageCtrl.text.trim();
      case 2: return _gender!;
      case 3: return _phoneCtrl.text.trim();
      case 4: return _department!;
      case 5: return _date!;
      case 6: return _time!;
      case 7: return _visitType!;
      case 8: return _complaintCtrl.text.trim();
      default: return '';
    }
  }

  Future<void> _next() async {
  if (_step < _questions.length - 1) {
    setState(() => _step++);
  } else {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
    await _submitAppointment();
    if (mounted) Navigator.of(context).pop();
  }
}

void _back() {
  if (_step > 0) {
    setState(() => _step--);
  } else {
    Navigator.of(context).pop(); // close sheet on first step
  }
}

Future<void> _submitAppointment() async {
  await widget.room.sendEvent(
    {
      'v': 1,
      'type': 'appointment_form',
      'data': {
        'name': _nameCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'gender': _gender,
        'phone': _phoneCtrl.text.trim(),
        'department': _department,
        'date': _date,
        'time': _time,
        'visit_type': _visitType,
        'symptoms': _complaintCtrl.text.trim(),
      },
    },
    type: 'com.jaino.appointment_form',
  );
}

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    _complaintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor       = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final primaryText   = isDark ? const Color(0xFF272727) : Colors.white;
    final secondaryText = const Color(0xFF8E8E93);
    final dividerColor  = isDark ? const Color(0xFFD9D9D9) : const Color(0xFF3A3A3C);
    final dragColor     = const Color(0xFFD9D9D9);
    final nextBtnBg     = isDark ? const Color(0xFF111111) : Colors.white;
    final nextBtnText   = isDark ? Colors.white : const Color(0xFF111111);
    final isLast        = _step == _questions.length - 1;

    return Padding(
  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.85,
    ),
    child: Container(
      width: 388.39,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.43)),
      ),
      padding: const EdgeInsets.all(21.87),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Center(
              child: Container(
                width: 80.92,
                height: 4.37,
                decoration: BoxDecoration(
                  color: dragColor,
                  borderRadius: BorderRadius.circular(13.12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // nav row: back + step counter + close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: primaryText,
                    ),
                  ),
                ),
                Text(
                  'Step ${_step + 1} of ${_questions.length}',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Book Appointment',
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // progress bar
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: dividerColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_step + 1) / _questions.length,
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryText,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9.84),
            Container(width: double.infinity, height: 0.28, color: dividerColor),
            const SizedBox(height: 16),
            // question
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _questions[_step],
                style: TextStyle(
                  color: primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // input
            _buildStepField(isDark, primaryText, secondaryText),
            const SizedBox(height: 20),
            // next/done button
            GestureDetector(
              onTap: _canProceed ? _next : null,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: _canProceed ? nextBtnBg : nextBtnBg.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10.94),
                  border: isDark
                      ? null
                      : Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Done' : 'Next',
                      style: TextStyle(
                        color: nextBtnText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  ),
);
  }

  // ── Field per step ────────────────────────────────────────────────────────
  Widget _buildStepField(bool isDark, Color primaryText, Color secondaryText) {
    switch (_step) {
      case 0:
        return _inputField(_nameCtrl, 'Your Name', isDark, primaryText);
      case 1:
        return _inputField(_ageCtrl, 'Age', isDark, primaryText,
            keyboardType: TextInputType.number);
      case 2:
  return _radioGroup(
    ['Male', 'Female', 'Other'],
    _gender,
    (v) => setState(() => _gender = v),
    isDark, primaryText,
  );
      case 3:
        return _inputField(_phoneCtrl, 'Phone Number', isDark, primaryText,
            keyboardType: TextInputType.phone);
      case 4:
  return _radioGroup(
    ['General', 'Cardiology', 'Orthopedic', 'Neurology', 'Pediatrics'],
    _department,
    (v) => setState(() => _department = v),
    isDark, primaryText,
  );
      case 5:
        return _datePicker(isDark, primaryText, secondaryText);
      case 6:
        return _chips(
            ['9:00 AM', '9:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '2:00 PM', '2:30 PM', '3:00 PM'],
            _time,
            (v) => setState(() => _time = v),
            isDark,
            primaryText);
      case 7:
  return _radioGroup(
    ['In-clinic', 'Video call'],
    _visitType,
    (v) => setState(() => _visitType = v),
    isDark, primaryText,
  );
      case 8:
        return _inputField(_complaintCtrl, 'Describe your symptoms briefly...', isDark, primaryText,
            maxLines: 3);
      default:
        return const SizedBox();
    }
  }

  // ── Reusable text input ───────────────────────────────────────────────────
  Widget _inputField(
    TextEditingController ctrl,
    String hint,
    bool isDark,
    Color primaryText, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: true,
      style: TextStyle(color: primaryText, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Reusable chip selector ────────────────────────────────────────────────
  Widget _radioGroup(
  List<String> options,
  String? selected,
  ValueChanged<String> onSelect,
  bool isDark,
  Color primaryText,
) {
  return Column(
    children: options.map((opt) {
      final active = selected == opt;
      return GestureDetector(
        onTap: () => onSelect(opt),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF272727) : Colors.white)
                : (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E)),
            borderRadius: BorderRadius.circular(10),
            border: active
                ? Border.all(
                    color: isDark ? const Color(0xFF272727) : Colors.white,
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Radio circle
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? (isDark ? Colors.white : const Color(0xFF111111))
                        : const Color(0xFF8E8E93),
                    width: 2,
                  ),
                ),
                child: active
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white : const Color(0xFF111111),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                opt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? (isDark ? Colors.white : const Color(0xFF111111))
                      : primaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

// ── Reusable chip selector ────────────────────────────────────────────────
  Widget _chips(
    List<String> options,
    String? selected,
    ValueChanged<String> onSelect,
    bool isDark,
    Color primaryText,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final active = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? (isDark ? const Color(0xFF272727) : Colors.white)
                  : (isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active
                    ? (isDark ? Colors.white : const Color(0xFF111111))
                    : primaryText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Date picker ───────────────────────────────────────────────────────────
  Widget _datePicker(bool isDark, Color primaryText, Color secondaryText) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(
                primary: isDark ? const Color(0xFF272727) : Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() =>
              _date = '${picked.day}/${picked.month}/${picked.year}');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 16, color: secondaryText),
          const SizedBox(width: 10),
          Text(
            _date ?? 'Select a date',
            style: TextStyle(
              fontSize: 14,
              color: _date != null ? primaryText : secondaryText,
            ),
          ),
        ]),
      ),
    );
  }
}