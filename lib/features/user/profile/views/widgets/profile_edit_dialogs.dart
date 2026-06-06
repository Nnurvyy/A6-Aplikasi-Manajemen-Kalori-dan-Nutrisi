import 'package:flutter/material.dart';

// Palette Colors
const _green = Color(0xFF2E7D32);
const _greenLight = Color(0xFF4CAF50);
const _pinkLight = Color(0xFFFFEBEE);
const _pink = Color(0xFFEF5350);
const _blueLight = Color(0xFFE3F2FD);
const _blue = Color(0xFF42A5F5);

// ─────────────────────────────────────────────────────────────────────────────
// CuteTextEditModal — untuk edit field teks (nama, dll.)
// ─────────────────────────────────────────────────────────────────────────────
class CuteTextEditModal extends StatefulWidget {
  final String title;
  final String label;
  final String initialValue;
  final Function(String) onSave;

  const CuteTextEditModal({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<CuteTextEditModal> createState() => _CuteTextEditModalState();
}

class _CuteTextEditModalState extends State<CuteTextEditModal> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: _green, size: 28),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A7A5A),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E1A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF4FAF4),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _greenLight, width: 2),
                ),
                hintText: 'Tuliskan ${widget.label.toLowerCase()}...',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return '${widget.label} tidak boleh kosong ya!';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onSave(_controller.text.trim());
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: _green.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CuteGenderEditModal — untuk edit jenis kelamin
// ─────────────────────────────────────────────────────────────────────────────
class CuteGenderEditModal extends StatefulWidget {
  final String initialGender;
  final Function(String) onSave;

  const CuteGenderEditModal({
    super.key,
    required this.initialGender,
    required this.onSave,
  });

  @override
  State<CuteGenderEditModal> createState() => _CuteGenderEditModalState();
}

class _CuteGenderEditModalState extends State<CuteGenderEditModal> {
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.wc_rounded, color: _green, size: 28),
              SizedBox(width: 8),
              Text(
                'Edit Jenis Kelamin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  genderName: 'Laki-laki',
                  icon: Icons.male_rounded,
                  activeColor: _blue,
                  activeBg: _blueLight,
                  emoji: '👦',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderCard(
                  genderName: 'Perempuan',
                  icon: Icons.female_rounded,
                  activeColor: _pink,
                  activeBg: _pinkLight,
                  emoji: '👧',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selectedGender);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: _green.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String genderName,
    required IconData icon,
    required Color activeColor,
    required Color activeBg,
    required String emoji,
  }) {
    final isSelected = _selectedGender == genderName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = genderName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? activeColor : Colors.grey[400],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  genderName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? activeColor : Colors.grey[600],
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

// ─────────────────────────────────────────────────────────────────────────────
// CuteNumberEditModal — untuk edit field angka (tinggi, berat, umur, target)
// dengan tombol + dan - serta input manual
// ─────────────────────────────────────────────────────────────────────────────
class CuteNumberEditModal extends StatefulWidget {
  final String title;
  final String label;
  final double initialValue;
  final String unit;
  final double step;
  final bool isDecimal;
  final double minValue;
  final double maxValue;
  final Function(double) onSave;

  const CuteNumberEditModal({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.unit,
    this.step = 1.0,
    this.isDecimal = false,
    this.minValue = 0.0,
    this.maxValue = 300.0,
    required this.onSave,
  });

  @override
  State<CuteNumberEditModal> createState() => _CuteNumberEditModalState();
}

class _CuteNumberEditModalState extends State<CuteNumberEditModal> {
  late double _currentVal;
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentVal = widget.initialValue;
    _controller = TextEditingController(text: _formatValue(_currentVal));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _parseAndSetText();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.isDecimal) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
    }
  }

  void _parseAndSetText() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed != null) {
      double bounded = parsed;
      if (bounded < widget.minValue) bounded = widget.minValue;
      if (bounded > widget.maxValue) bounded = widget.maxValue;
      setState(() {
        _currentVal = bounded;
        _controller.text = _formatValue(_currentVal);
      });
    } else {
      setState(() {
        _controller.text = _formatValue(_currentVal);
      });
    }
  }

  void _adjustValue(bool increment) {
    double newVal = _currentVal + (increment ? widget.step : -widget.step);
    if (newVal < widget.minValue) newVal = widget.minValue;
    if (newVal > widget.maxValue) newVal = widget.maxValue;
    setState(() {
      _currentVal = newVal;
      _controller.text = _formatValue(_currentVal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _green, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A2E1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5A7A5A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),

          // ─── Large Interactive Number Area ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tombol -
              _buildAdjustButton(
                icon: Icons.remove_rounded,
                color: _pink,
                bgColor: _pinkLight,
                onTap: () => _adjustValue(false),
              ),
              const SizedBox(width: 24),

              // Nilai & unit (tappable untuk edit manual)
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FAF4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: widget.isDecimal,
                            signed: widget.minValue < 0,
                          ),
                          textAlign: TextAlign.center,
                          onChanged: (text) {
                            final parsed = double.tryParse(text);
                            if (parsed != null) {
                              _currentVal = parsed;
                            }
                          },
                          onSubmitted: (_) => _parseAndSetText(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.unit,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5A7A5A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Tombol +
              _buildAdjustButton(
                icon: Icons.add_rounded,
                color: _green,
                bgColor: _greenLight.withValues(alpha: 0.2),
                onTap: () => _adjustValue(true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ketuk angka untuk mengetik manual  •  +/- = ${_formatValue(widget.step)} ${widget.unit}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 36),

          // Tombol Simpan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _parseAndSetText();
                widget.onSave(_currentVal);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: _green.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CuteActivityEditModal — untuk pilih tingkat aktivitas
// ─────────────────────────────────────────────────────────────────────────────
class CuteActivityEditModal extends StatefulWidget {
  final String initialActivity;
  final List<String> activityLevels;
  final Function(String) onSave;

  const CuteActivityEditModal({
    super.key,
    required this.initialActivity,
    required this.activityLevels,
    required this.onSave,
  });

  @override
  State<CuteActivityEditModal> createState() => _CuteActivityEditModalState();
}

class _CuteActivityEditModalState extends State<CuteActivityEditModal> {
  late String _selectedActivity;

  final Map<int, String> _activityEmojis = {
    0: '🛋️',
    1: '🚶',
    2: '🏃',
    3: '🏋️',
    4: '🚴',
  };

  final Map<int, Color> _activityColors = {
    0: Colors.blueGrey,
    1: Colors.blue,
    2: Colors.green,
    3: Colors.orange,
    4: Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.activityLevels.contains(widget.initialActivity)
        ? widget.initialActivity
        : widget.activityLevels[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.directions_run_rounded, color: _green, size: 28),
              SizedBox(width: 8),
              Text(
                'Edit Tingkat Aktivitas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2E1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.activityLevels.length,
              itemBuilder: (ctx, index) {
                final activity = widget.activityLevels[index];
                final isSelected = _selectedActivity == activity;
                final emoji = _activityEmojis[index] ?? '⚡';
                final color = _activityColors[index] ?? _green;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedActivity = activity;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.08)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : const Color(0xFF1A2E1A),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: color,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_selectedActivity);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                shadowColor: _green.withValues(alpha: 0.3),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
