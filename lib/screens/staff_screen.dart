import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import 'qr_screens.dart';

// ── Hardcoded PIN — change this before demo ────────────────────────────────
const String _kStaffPin = '1234';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return _unlocked ? _EventPickerScreen(
      onLockOut: () => setState(() => _unlocked = false),
    ) : _PinScreen(
      onUnlocked: () => setState(() => _unlocked = true),
    );
  }
}

// ── PIN entry screen ───────────────────────────────────────────────────────

class _PinScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _PinScreen({required this.onUnlocked});

  @override
  State<_PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<_PinScreen> {
  String _pin = '';
  bool   _error = false;

  void _onKey(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = false;
    });
    if (_pin.length == 4) _checkPin();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _checkPin() {
    if (_pin == _kStaffPin) {
      widget.onUnlocked();
    } else {
      setState(() { _pin = ''; _error = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 48, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('Nhập mã PIN nhân viên',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length ? Colors.blue : Colors.grey[300],
                  ),
                )),
              ),

              if (_error) ...[
                const SizedBox(height: 12),
                const Text('Mã PIN không đúng',
                    style: TextStyle(color: Colors.red, fontSize: 13)),
              ],

              const SizedBox(height: 32),

              // Number pad
              ...[[1,2,3],[4,5,6],[7,8,9]].map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row.map((digit) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _PinButton(
                      label: '$digit',
                      onTap: () => _onKey('$digit'),
                    ),
                  )).toList(),
                ),
              )),

              // 0 + delete
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(width: 56)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _PinButton(label: '0', onTap: () => _onKey('0')),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _PinButton(
                      label: '⌫',
                      onTap: _onDelete,
                      isDelete: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDelete;

  const _PinButton({
    required this.label,
    required this.onTap,
    this.isDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDelete ? Colors.grey[100] : Colors.blue[50],
          border: Border.all(
            color: isDelete ? Colors.grey.shade300 : Colors.blue.shade200,
          ),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDelete ? Colors.grey[700] : Colors.blue[800],
              )),
        ),
      ),
    );
  }
}

// ── Event picker screen (after PIN unlock) ─────────────────────────────────

class _EventPickerScreen extends StatefulWidget {
  final VoidCallback onLockOut;
  const _EventPickerScreen({required this.onLockOut});

  @override
  State<_EventPickerScreen> createState() => _EventPickerScreenState();
}

class _EventPickerScreenState extends State<_EventPickerScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = ApiService().fetchEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn sự kiện'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: widget.onLockOut,
            icon: const Icon(Icons.lock_rounded, color: Colors.white, size: 16),
            label: const Text('Khoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('Không có sự kiện nào'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      event.club.name[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(event.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(event.club.name),
                  trailing: const Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.blue),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCheckInScreen(
                        eventId:    event.id,
                        eventTitle: event.title,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}