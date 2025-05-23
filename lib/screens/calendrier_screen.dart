import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mon_sirh_mobile/models/conge.dart';
import 'package:mon_sirh_mobile/providers/conge_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendrierScreen extends StatefulWidget {
  const CalendrierScreen({super.key});

  @override
  State<CalendrierScreen> createState() => _CalendrierScreenState();
}

class _CalendrierScreenState extends State<CalendrierScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Conge>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Load events when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  void _loadEvents() {
    final congeProvider = Provider.of<CongeProvider>(context, listen: false);
    final allRequests = congeProvider.congeRequests; // Get all requests from provider
    final Map<DateTime, List<Conge>> events = {};

    for (var request in allRequests) {
      // Normalize dates to midnight UTC to avoid timezone issues with map keys
      DateTime day = DateTime.utc(request.dateDebut.year, request.dateDebut.month, request.dateDebut.day);
      final endDate = DateTime.utc(request.dateFin.year, request.dateFin.month, request.dateFin.day);

      // Add event for each day in the range
      while (day.isBefore(endDate) || day.isAtSameMomentAs(endDate)) {
         if (events[day] == null) events[day] = [];
         events[day]!.add(request);
         day = day.add(const Duration(days: 1));
      }
    }
    setState(() {
      _events = events;
    });
  }

  List<Conge> _getEventsForDay(DateTime day) {
    // Normalize the selected day to midnight UTC for lookup
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay; // update `_focusedDay` here as well
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider changes to reload events if data updates
    Provider.of<CongeProvider>(context).addListener(_loadEvents);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des Absences'),
      ),
      body: Column(
        children: [
          TableCalendar<Conge>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              // Customize styles
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
               markerDecoration: BoxDecoration(
                 color: Colors.redAccent,
                 shape: BoxShape.circle,
               ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // Hide format button
              titleCentered: true,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
             calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  // Simple marker: a dot below the day number
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Color based on status? e.g., red for pending, green for approved
                        color: events.any((e) => e.status == CongeStatus.enAttente) ? Colors.orange : Colors.green,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (selectedDayEvents.isEmpty) {
      return const Center(child: Text("Aucune absence ce jour-là."));
    }

    return ListView.builder(
      itemCount: selectedDayEvents.length,
      itemBuilder: (context, index) {
        final conge = selectedDayEvents[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ListTile(
            leading: Icon(_getIconForStatus(conge.status), color: _getColorForStatus(conge.status)),
            title: Text('${conge.employeeName} - ${conge.type.toString().split('.').last}'),
            subtitle: Text('Du ${DateFormat('dd/MM').format(conge.dateDebut)} au ${DateFormat('dd/MM').format(conge.dateFin)}'),
            // Add onTap for details?
          ),
        );
      },
    );
  }

  Color _getColorForStatus(CongeStatus status) {
    switch (status) {
      case CongeStatus.approuvee:
        return Colors.green;
      case CongeStatus.refusee:
        return Colors.red;
      case CongeStatus.enAttente:
      default:
        return Colors.orange;
    }
  }

   IconData _getIconForStatus(CongeStatus status) {
    switch (status) {
      case CongeStatus.approuvee:
        return Icons.check_circle;
      case CongeStatus.refusee:
        return Icons.cancel;
      case CongeStatus.enAttente:
      default:
        return Icons.hourglass_empty;
    }
  }
}

