import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class OrganizerEventDetailScreen extends StatelessWidget {
  final String imageUrl;
  final bool isBase64;
  final String eventTitleFirstPart;
  final String eventTitleSecondPart;
  final String category;
  final String date;
  final String time;
  final String location;
  final String description;
  final int placesTaken;
  final int placesTotal;
  final int participantsCount;
  final VoidCallback? onParticipantsTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const OrganizerEventDetailScreen({
    super.key,
    required this.imageUrl,
    this.isBase64 = false,
    required this.eventTitleFirstPart,
    required this.eventTitleSecondPart,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.placesTaken,
    required this.placesTotal,
    required this.participantsCount,
    this.onParticipantsTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  static const _accentAmber = Color(0xFFF5B84D);
  static const _background = Color(0xFF0B0D10);
  static const _cardBackground = Color(0xFF14161C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: CustomScrollView(
        slivers: [
          // --- Hero image with floating buttons ---
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: _buildHeroImage(),
                ),
                // Gradient for top icon readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _circleIconButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        _circleIconButton(
                          icon: Icons.favorite_border,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Content ---
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Two-color title
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '$eventTitleFirstPart ',
                          style: const TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: eventTitleSecondPart,
                          style: const TextStyle(color: _accentAmber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _accentAmber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.code_rounded,
                          size: 14,
                          color: _accentAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: const TextStyle(
                            color: _accentAmber,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _infoRow(icon: Icons.calendar_today_rounded, text: date),
                  const SizedBox(height: 14),
                  _infoRow(icon: Icons.access_time_rounded, text: time),
                  const SizedBox(height: 14),
                  _infoRow(icon: Icons.location_on_rounded, text: location),

                  const SizedBox(height: 20),
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _iconBadge(Icons.description_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Capacity
                  Row(
                    children: [
                      _iconBadge(Icons.groups_rounded),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Places',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$placesTaken / $placesTotal',
                            style: const TextStyle(
                              color: _accentAmber,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Participants button (amber outline) ---
                  _actionButton(
                    onTap: onParticipantsTap,
                    borderColor: _accentAmber,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: _accentAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Participants ($participantsCount)',
                          style: const TextStyle(
                            color: _accentAmber,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _accentAmber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Edit button (gray outline) ---
                  _actionButton(
                    onTap: onEditTap,
                    borderColor: Colors.white.withValues(alpha: 0.25),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Delete button (red outline) ---
                  _actionButton(
                    onTap: onDeleteTap,
                    borderColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
                    fillColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final errorFallback = Container(
      color: Colors.grey[900],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.white24,
        size: 48,
      ),
    );

    if (isBase64) {
      try {
        final bytes = base64Decode(imageUrl);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => errorFallback,
        );
      } on FormatException {
        return errorFallback;
      }
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => errorFallback,
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
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, color: _accentAmber, size: 24),
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _accentAmber.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _accentAmber, size: 18),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        _iconBadge(icon),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required Widget child,
    required Color borderColor,
    Color? fillColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: fillColor ?? _cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
