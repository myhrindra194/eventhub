import 'package:eventhub/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'event_participants_screen.dart';
import '../../../events/domain/entities/event.dart';
import '../providers/organizer_events_provider.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/organizer_event_detail_screen.dart';
import '../widgets/edit_event_screen.dart';
import '../widgets/delete_event_dialog.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    try {
      ref.invalidate(organizerEventDetailProvider(widget.eventId));

      final event = await ref.read(
        organizerEventDetailProvider(widget.eventId).future,
      );

      if (!mounted) return;

      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load event: $error')));
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDeleteEventDialog(context);

    if (confirmed != true) return;

    try {
      await ref
          .read(organizerEventRepositoryProvider)
          .deleteEvent(widget.eventId);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete event: $error')));
    }
  }

  /// Publie un événement DRAFT.
  ///
  /// C'est la seule transition qui ouvre EventPublishedScreen.
  Future<void> _publishEvent() async {
    final event = _event;

    if (event == null || event.status != EventStatus.draft) {
      return;
    }

    try {
      await ref
          .read(organizerEventRepositoryProvider)
          .updateEvent(event.copyWith(status: EventStatus.live));

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRouter.organizerEventPublished,
        arguments: {
          'eventTitle': event.title,
          'publicUrl': 'eventhub.com/e/${event.id}',
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish event: $error')),
      );
    }
  }

  /// Gère les autres changements de statut.
  ///
  /// DRAFT -> LIVE passe obligatoirement par _publishEvent().
  /// Les autres changements restent sur EventDetailScreen.
  Future<void> _changeStatus(EventStatus status) async {
    final event = _event;

    if (event == null || event.status == status) {
      return;
    }

    // Première publication.
    if (event.status == EventStatus.draft && status == EventStatus.live) {
      await _publishEvent();
      return;
    }

    try {
      await ref
          .read(organizerEventRepositoryProvider)
          .updateEvent(event.copyWith(status: status));

      await _loadEventData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event status changed to ${status.name}.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update status: $error')),
      );
    }
  }

  Future<void> _showStatusPicker() async {
    final event = _event;

    if (event == null) return;

    final selectedStatus = await showModalBottomSheet<EventStatus>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: EventStatus.values
                .map(
                  (status) => ListTile(
                    leading: Icon(_statusIcon(status)),
                    title: Text(status.name.toUpperCase()),
                    trailing: status == event.status
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop(status);
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );

    if (selectedStatus != null) {
      await _changeStatus(selectedStatus);
    }
  }

  IconData _statusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return Icons.edit_note;

      case EventStatus.live:
        return Icons.public;

      case EventStatus.completed:
        return Icons.check_circle_outline;

      case EventStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  void _editEvent() {
    final event = _event;

    if (event == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditEventScreen(
          initialTitle: event.title,
          initialDescription: event.description,
          initialCategory: event.category.name,
          initialDate:
              '${event.date.day.toString().padLeft(2, '0')}/'
              '${event.date.month.toString().padLeft(2, '0')}/'
              '${event.date.year}',
          initialTime:
              '${event.date.hour.toString().padLeft(2, '0')}:'
              '${event.date.minute.toString().padLeft(2, '0')}',
          initialLocation: event.location,
          initialCapacity: event.capacity.toString(),
          initialPrice: event.price.toStringAsFixed(2),
          headerImageUrl: event.imageUrl.isEmpty ? null : event.imageUrl,
          onSave:
              ({
                required title,
                required description,
                required category,
                required date,
                required time,
                required location,
                required capacity,
                required price,
              }) {
                _saveEditedEvent(
                  event: event,
                  title: title,
                  description: description,
                  date: date,
                  time: time,
                  location: location,
                  capacity: capacity,
                  price: price,
                );
              },
        ),
      ),
    );
  }

  Future<void> _saveEditedEvent({
    required Event event,
    required String title,
    required String description,
    required String date,
    required String time,
    required String location,
    required String capacity,
    required String price,
  }) async {
    final dateParts = date.split('/');
    final timeParts = time.split(':');

    final parsedDate = dateParts.length == 3 && timeParts.length == 2
        ? DateTime.tryParse(
            '${dateParts[2]}-'
            '${dateParts[1]}-'
            '${dateParts[0]} '
            '${timeParts[0]}:'
            '${timeParts[1]}',
          )
        : null;

    final updatedEvent = event.copyWith(
      title: title,
      description: description,
      date: parsedDate ?? event.date,
      capacity: int.tryParse(capacity) ?? event.capacity,
      location: location,
      price: double.tryParse(price.replaceAll(',', '.')) ?? event.price,
    );

    try {
      await ref
          .read(organizerEventRepositoryProvider)
          .updateEvent(updatedEvent);

      if (!mounted) return;

      Navigator.of(context).pop();

      await _loadEventData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update event: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _event != null) {
      final event = _event!;

      final titleParts = event.title.trim().split(RegExp(r'\s+'));

      final titleFirstPart = titleParts.length > 1
          ? titleParts.first
          : event.title;

      final titleSecondPart = titleParts.length > 1
          ? titleParts.skip(1).join(' ')
          : '';

      return OrganizerEventDetailScreen(
        imageUrl: event.imageUrl,
        eventTitleFirstPart: titleFirstPart,
        eventTitleSecondPart: titleSecondPart,
        category: event.category.name,
        date:
            '${event.date.day}/'
            '${event.date.month}/'
            '${event.date.year}',
        time:
            '${event.date.hour.toString().padLeft(2, '0')}:'
            '${event.date.minute.toString().padLeft(2, '0')}',
        location: event.location,
        description: event.description,
        placesTaken: event.currentAttendees,
        placesTotal: event.capacity,
        participantsCount: event.currentAttendees,
        onParticipantsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return EventParticipantsScreen(eventId: event.id);
              },
            ),
          );
        },
        onStatusChange: _showStatusPicker,
        onEditTap: _editEvent,
        onDeleteTap: _deleteEvent,
      );
    }

    return Column(
      children: [
        AppHeader(
          title: widget.eventTitle,
          subtitle: 'Event Details',
          showBackButton: true,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _event != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _event!.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              if (_event!.status == EventStatus.draft)
                                IconButton(
                                  icon: const Icon(Icons.publish),
                                  onPressed: _publishEvent,
                                  tooltip: 'Publish Event',
                                  iconSize: 20,
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: _editEvent,
                                tooltip: 'Edit Event',
                                iconSize: 20,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: _deleteEvent,
                                tooltip: 'Delete Event',
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_event!.status.name),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _event!.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _event!.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date',
                        '${_event!.date.month}/'
                            '${_event!.date.day}/'
                            '${_event!.date.year}',
                      ),
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        _event!.location,
                      ),
                      _buildInfoRow(
                        Icons.euro,
                        'Price',
                        _event!.formattedPrice,
                      ),
                      _buildInfoRow(
                        Icons.people,
                        'Attendees',
                        '${_event!.currentAttendees}/'
                            '${_event!.capacity}',
                      ),
                      const SizedBox(height: 32),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.people_outline),
                          title: const Text('View Participants'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) {
                                  return EventParticipantsScreen(
                                    eventId: widget.eventId,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text('Event not found')),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Flexible(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.green;

      case 'draft':
        return Colors.orange;

      case 'completed':
        return Colors.blue;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
