import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
} // closes EventListScreen class

class _EventListScreenState extends State<EventListScreen> {
  late Future<List<Event>> futureEvents;
  late Future<List<Club>> futureClubs; // New: for filter buttons
  int? selectedClubId; // null = show all clubs
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; //search bar

  @override
  void initState() {
    super.initState();
    futureEvents = ApiService().fetchEvents();
    futureClubs = ApiService().fetchClubs(); // Fetch clubs for filters
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  } // closes initState()

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter helper: returns only events matching selected club (or all if null)
  List<Event> _applySearchAndClubFilter(List<Event> events) {
    var filtered = events;
    // Apply club filter first
    if (selectedClubId != null) {
      filtered = filtered.where((e) => e.club.id == selectedClubId).toList();
    }
    // Then apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final query = _searchQuery.toLowerCase();
        final dateStr = DateFormat('yyyy-MM-dd').format(e.startTime.toLocal());
        return e.title.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            dateStr.contains(query) ||
            e.location.toLowerCase().contains(query) ||
            e.club.name.toLowerCase().contains(query);
      }).toList();
    }

    return filtered; // return events.where((e) => e.club.id == selectedClubId).toList();
  } // closes _filterEvents()

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InSync'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ), // closes AppBar

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // Horizontal filter chips row
          FutureBuilder<List<Club>>(
            future: futureClubs,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final clubs = snapshot.data!;
                return SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      // "All" chip
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedClubId == null,
                          onSelected: (selected) {
                            setState(() => selectedClubId = null);
                          },
                          selectedColor: Colors.blue[100],
                          backgroundColor: Colors.grey[200],
                        ),
                      ), // closes "All" chip Padding
                      // One chip per club
                      ...clubs.map(
                        (club) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(club.name),
                            selected: selectedClubId == club.id,
                            onSelected: (selected) {
                              setState(() => selectedClubId = club.id);
                            },
                            selectedColor: Colors.blue[100],
                            backgroundColor: Colors.grey[200],
                          ),
                        ),
                      ), // closes map(...) for club chips
                    ], // closes ListView children
                  ), // closes ListView (horizontal)
                ); // closes SizedBox (filter row)
              } // closes if (snapshot.hasData)
              return const SizedBox(height: 50); // Loading placeholder
            }, // closes FutureBuilder builder
          ), // closes FutureBuilder for clubs
          // Event list (filtered)
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  futureEvents = ApiService().fetchEvents();
                  futureClubs = ApiService().fetchClubs();
                });
              }, // closes onRefresh

              child: FutureBuilder<List<Event>>(
                future: futureEvents,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final allEvents = snapshot.data!;
                    // final filteredEvents = _filterEvents(
                    //  allEvents,
                    // );
                    final filteredEvents = _applySearchAndClubFilter(
                      allEvents,
                    ); // ← New combined filter
                    if (filteredEvents.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No events found",
                              style: TextStyle(fontSize: 20),
                            ),
                            Text("Try different keywords or another club"),
                          ],
                        ), // closes Column children
                      ); // closes Center (empty filtered)
                    } // closes if (filteredEvents.isEmpty)

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(
                                  event: filteredEvents[index],
                                ),
                              ),
                            ); //navigator
                          }, // on tap
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4, //2 is lil to no shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(
                                16,
                              ), // better internal spacing
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  event.club.name.isNotEmpty
                                      ? event.club.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ), // closes CircleAvatar

                              title: Text(
                                '${event.club.name} - ${event.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ), // closes Text (title)

                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.description,
                                      maxLines: 2, // limit to 2 lines
                                      overflow: TextOverflow
                                          .ellipsis, // show "..." if too long
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Date: ${DateFormat('MMMM d, yyyy • h:mm a').format(event.startTime.toLocal())}', // event.startTime.toLocal().toString().split(' ')[0],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (event.endTime != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Ends: ${DateFormat('MMMM d, yyyy • h:mm a').format(event.endTime!.toLocal())}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (event.location.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                event.location,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ], // children of row
                                        ),
                                      ),
                                  ], // children of Padding
                                ), // closes Column (child)
                              ),
                              trailing:
                                  event.officialLink != null &&
                                      event.officialLink!.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        color: Colors.blue,
                                      ),
                                      tooltip: 'View Official Post',
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        ); // capture BEFORE await
                                        final url = Uri.parse(
                                          event.officialLink!,
                                        );
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            //use of local variable to prevent unmounted await
                                            const SnackBar(
                                              content: Text(
                                                'Could not open link',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null, // No button if no link
                            ), // closes ListTile
                          ), // closes Card
                        );
                      }, // closes itemBuilder lambda
                    ); // closes ListView.builder
                  } // closes if (snapshot.hasData)
                  else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                futureEvents = ApiService().fetchEvents();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ), // closes Column children
                    ); // closes Center (error)
                  } // closes else if (hasError)

                  return const Center(child: CircularProgressIndicator());
                }, // closes builder lambda
              ), // closes FutureBuilder
            ), // closes RefreshIndicator
          ), // closes Expanded
        ], // closes Column children
      ), // closes Column (body)
    ); // closes Scaffold
  } // closes build()
} // closes _EventListScreenState class
