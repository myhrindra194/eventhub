import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E12),
      resizeToAvoidBottomInset: false,
      body: eventAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF5A52FF)),
        ),
        error: (err, stack) => Center(
          child: Text('Erreur: $err', style: const TextStyle(color: Colors.white)),
        ),
        data: (event) {
          if (event == null) {
            return const Center(
              child: Text('Événement introuvable', style: TextStyle(color: Colors.white)),
            );
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image d'en-tête et bouton Retour
                      Stack(
                        children: [
                          Image.asset(
                            event.imageUrl,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 280,
                              color: Colors.grey[800],
                              child: const Icon(Icons.image_not_supported, color: Colors.white38, size: 60),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.5),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Contenu détaillé
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF5A52FF), size: 18),
                                const SizedBox(width: 8),
                                Text(event.date, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF5A52FF), size: 18),
                                const SizedBox(width: 8),
                                Text(event.location, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'À propos de l\'événement',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.description,
                              style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton d'action en bas
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF1E1F25),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A52FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    child: const Text('S\'inscrire', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}