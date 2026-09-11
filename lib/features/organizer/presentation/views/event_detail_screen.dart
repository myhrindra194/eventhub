import 'package:flutter/material.dart';
import 'event_participants_screen.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../../../core/widgets/app_header.dart';
import '../widgets/organizer_event_detail_screen.dart';
import '../widgets/edit_event_screen.dart';
import '../widgets/delete_event_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventRepositoryImpl _repository = EventRepositoryImpl();
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    final event = await _repository.getEventById(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDeleteEventDialog(context);

    if (confirmed == true) {
      await _repository.deleteEvent(widget.eventId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    }
  }

  Future<void> _publishEvent() async {
    await _repository.publishEvent(widget.eventId);
    await _loadEventData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event published successfully')),
      );
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
          initialCategory: event.status.name,
          initialDate:
              '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}',
          initialTime:
              '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
          initialLocation: event.location,
          initialCapacity: event.capacity.toString(),
          initialPrice: event.price.toStringAsFixed(2),
          headerImageUrl: event.isBase64 ? null : event.imageUrl,
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
            '${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${timeParts[0]}:${timeParts[1]}',
          )
        : null;
    final updatedEvent = Event(
      id: event.id,
      title: title,
      description: description,
      imageUrl: event.imageUrl,
      date: parsedDate ?? event.date,
      capacity: int.tryParse(capacity) ?? event.capacity,
      currentAttendees: event.currentAttendees,
      status: event.status,
      location: location,
      price: double.tryParse(price.replaceAll(',', '.')) ?? event.price,
      isBase64: event.isBase64,
    );

    await _repository.updateEvent(updatedEvent);
    if (!mounted) return;
    Navigator.of(context).pop();
    await _loadEventData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
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
        isBase64: event.isBase64,
        eventTitleFirstPart: titleFirstPart,
        eventTitleSecondPart: titleSecondPart,
        category: event.status.name,
        date: '${event.date.day}/${event.date.month}/${event.date.year}',
        time:
            '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
        location: event.location,
        description: event.description,
        placesTaken: event.currentAttendees,
        placesTotal: event.capacity,
        participantsCount: event.currentAttendees,
        onParticipantsTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventParticipantsScreen(eventId: event.id),
            ),
          );
        },
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
                        '${_event!.date.month}/${_event!.date.day}/${_event!.date.year}',
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
                        '${_event!.currentAttendees}/${_event!.capacity}',
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
                                builder: (context) => EventParticipantsScreen(
                                  eventId: widget.eventId,
                                ),
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
