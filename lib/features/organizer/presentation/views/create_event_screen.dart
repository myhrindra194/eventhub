import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/usecases/create_event_usecase.dart';
import 'event_published_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final CreateEventUseCase _createEventUseCase = CreateEventUseCase(
    EventRepositoryImpl(),
  );
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  String? _base64Image;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final formattedTime = picked.format(context);
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);

        setState(() {
          _selectedImage = File(image.path);
          _base64Image = base64;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _createEvent() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _capacityController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final event = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _nameController.text,
      description: _descriptionController.text,
      imageUrl:
          _base64Image ??
          'assets/images/tech.jpg', // Use selected image or default
      date: _selectedDate ?? DateTime.now(),
      capacity: int.tryParse(_capacityController.text) ?? 50,
      currentAttendees: 0,
      status: EventStatus.draft,
      location: _locationController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      isBase64: _base64Image != null,
    );

    try {
      await _createEventUseCase.call(event);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EventPublishedScreen(
              eventTitle: event.title,
              publicUrl: 'eventhub.com/e/${event.id}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark
        ? const Color(0xFF0F1117)
        : const Color(0xFFF8F9FA);
    final inputBgColor = isDark ? const Color(0xFF161922) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF262A36)
        : const Color(0xFFE0E0E0);
    final labelColor = isDark ? const Color(0xFF8A8F9E) : Colors.grey[600]!;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Event',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('EVENT BANNER', labelColor),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _base64Image = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: labelColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'UPLOAD HIGH-RES IMAGE',
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to select image',
                              style: TextStyle(
                                color: labelColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('EVENT NAME', labelColor),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hintText: 'e.g. Summer Jazz Gala',
                bgColor: inputBgColor,
                borderColor: borderColor,
                textColor: textColor,
                hintColor: labelColor,
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('DESCRIPTION', labelColor),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: "What's this event about?",
                bgColor: inputBgColor,
                borderColor: borderColor,
                textColor: textColor,
                hintColor: labelColor,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('DATE', labelColor),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _dateController,
                          hintText: 'MM/DD/YYYY',
                          bgColor: inputBgColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          hintColor: labelColor,
                          readOnly: true,
                          onTap: _pickDate,
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('TIME', labelColor),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _timeController,
                          hintText: '00:00 AM',
                          bgColor: inputBgColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          hintColor: labelColor,
                          readOnly: true,
                          onTap: _pickTime,
                          suffixIcon: Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('LOCATION', labelColor),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _locationController,
                hintText: 'e.g. Paris, France',
                bgColor: inputBgColor,
                borderColor: borderColor,
                textColor: textColor,
                hintColor: labelColor,
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('CAPACITY', labelColor),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _capacityController,
                hintText: 'e.g. 100',
                bgColor: inputBgColor,
                borderColor: borderColor,
                textColor: textColor,
                hintColor: labelColor,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              _buildSectionLabel('PRICE (€)', labelColor),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _priceController,
                hintText: 'e.g. 49.99',
                bgColor: inputBgColor,
                borderColor: borderColor,
                textColor: textColor,
                hintColor: labelColor,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _createEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color hintColor,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: bgColor,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
        ),
      ),
    );
  }
}
