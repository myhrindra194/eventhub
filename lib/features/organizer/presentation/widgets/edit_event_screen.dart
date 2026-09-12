import 'package:flutter/material.dart';
import '../../../../core/router/app_router.dart';

class EditEventScreen extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final String initialCategory;
  final String initialDate;
  final String initialTime;
  final String initialLocation;
  final String initialCapacity;
  final String initialPrice;
  final String? headerImageUrl;
  final List<String> categories;
  final void Function({
    required String title,
    required String description,
    required String category,
    required String date,
    required String time,
    required String location,
    required String capacity,
    required String price,
  })?
  onSave;

  const EditEventScreen({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    required this.initialCategory,
    required this.initialDate,
    required this.initialTime,
    required this.initialLocation,
    required this.initialCapacity,
    required this.initialPrice,
    this.headerImageUrl,
    this.categories = const [
      'Technologie',
      'Musique',
      'Sport',
      'Art',
      'Business',
    ],
    this.onSave,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  static const _accentAmber = Color(0xFFF5B84D);
  static const _background = Color(0xFF0B0D10);
  static const _fieldBackground = Color(0xFF14161C);
  static const _fieldBorder = Color(0xFF262A33);

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _priceController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _dateController = TextEditingController(text: widget.initialDate);
    _timeController = TextEditingController(text: widget.initialTime);
    _locationController = TextEditingController(text: widget.initialLocation);
    _capacityController = TextEditingController(text: widget.initialCapacity);
    _priceController = TextEditingController(text: widget.initialPrice);
    _selectedCategory = widget.categories.contains(widget.initialCategory)
        ? widget.initialCategory
        : widget.categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.dark(primary: _accentAmber)),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _handleSave() {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        int.tryParse(_capacityController.text.trim()) == null ||
        double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ==
            null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    widget.onSave?.call(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      date: _dateController.text,
      time: _timeController.text,
      location: _locationController.text.trim(),
      capacity: _capacityController.text.trim(),
      price: _priceController.text.trim().replaceAll(',', '.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: DottedBorderBox(
                        color: _accentAmber,
                        child: const SizedBox(
                          width: double.infinity,
                          height: 140,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                color: _accentAmber,
                                size: 30,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Change image',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _fieldLabel(Icons.edit_rounded, 'Event title'),
                  const SizedBox(height: 8),
                  _textField(_titleController),
                  const SizedBox(height: 22),
                  _fieldLabel(Icons.description_outlined, 'Description'),
                  const SizedBox(height: 8),
                  _textField(_descriptionController, maxLines: 3),
                  const SizedBox(height: 22),
                  _fieldLabel(Icons.grid_view_rounded, 'Category'),
                  const SizedBox(height: 8),
                  _dropdownField(),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _dateOrTimeField(
                          label: 'Date',
                          icon: Icons.calendar_today_rounded,
                          controller: _dateController,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _dateOrTimeField(
                          label: 'Time',
                          icon: Icons.access_time_rounded,
                          controller: _timeController,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel(Icons.location_on_outlined, 'Location'),
                  const SizedBox(height: 8),
                  _textField(
                    _locationController,
                    trailingIcon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel(Icons.groups_rounded, 'Maximum capacity'),
                  const SizedBox(height: 8),
                  _textField(
                    _capacityController,
                    keyboardType: TextInputType.number,
                    trailingIcon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 22),
                  _fieldLabel(Icons.euro_rounded, 'Price'),
                  const SizedBox(height: 8),
                  _textField(
                    _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    trailingIcon: Icons.euro_rounded,
                  ),
                  const SizedBox(height: 30),
                  _saveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            image: widget.headerImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.headerImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            color: const Color(0xFF1A1208),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.25), _background],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _circleIconButton(
                      icon: Icons.home_rounded,
                      onTap: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRouter.home,
                            (route) => false,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: _accentAmber,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'Edit ',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'event',
                            style: TextStyle(color: _accentAmber),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateOrTimeField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(icon, label),
        const SizedBox(height: 8),
        _textField(
          controller,
          readOnly: true,
          onTap: onTap,
          trailingIcon: icon,
        ),
      ],
    );
  }

  Widget _fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        const SizedBox(width: 1),
        Icon(icon, color: _accentAmber, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller, {
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? trailingIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: _fieldBackground,
        suffixIcon: trailingIcon == null
            ? null
            : Icon(trailingIcon, color: _accentAmber, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: _accentAmber, width: 1.4),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color ?? _fieldBorder, width: width),
    );
  }

  Widget _dropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _fieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: _fieldBackground,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _accentAmber,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: widget.categories
              .map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedCategory = value);
          },
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _handleSave,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF4338CA)],
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Save changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _accentAmber, size: 24),
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;

  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(color: const Color(0xFF14161C), child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
