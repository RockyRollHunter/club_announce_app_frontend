// qr_screens.dart
// Campus Hub — QR Ticket Display + Admin Check-In Screen
//
// DEPENDENCIES (add to pubspec.yaml):
//   qr_flutter: ^4.1.0          — renders QR codes from a string
//   mobile_scanner: ^5.2.3      — webcam/camera barcode scanner (Flutter Web compatible)
//   http: ^1.2.0                — API calls (likely already in your project)
//
// USAGE:
//   After registration succeeds, push:
//     Navigator.push(context, MaterialPageRoute(
//       builder: (_) => QRTicketScreen(
//         qrToken: 'abc123hash',
//         eventTitle: 'Tech Fest 2025',
//         eventDate: 'Sat 21 Jun · 09:00',
//         studentId: 'HS220145',
//       ),
//     ));
//
//   For the admin panel:
//     Navigator.push(context, MaterialPageRoute(
//       builder: (_) => AdminCheckInScreen(eventId: 3, eventTitle: 'Tech Fest 2025'),
//     ));

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─── CONFIG ──────────────────────────────────────────────────────────────────

const String kBaseUrl = 'http://127.0.0.1:8000/api'; // const String kBaseUrl = 'https://yourname.pythonanywhere.com/api'; 

// ─── COLOUR + TYPOGRAPHY TOKENS ──────────────────────────────────────────────

const _kBg         = Color(0xFF0E0F11);   // near-black canvas
const _kSurface    = Color(0xFF171820);   // card surface
const _kBorder     = Color(0xFF2A2C38);   // subtle border
const _kAccent     = Color(0xFF00E5A0);   // neon teal — primary action
const _kAccentDim  = Color(0xFF00966B);
const _kDanger     = Color(0xFFFF4D4D);
const _kWarning    = Color(0xFFFFBF3C);
const _kText       = Color(0xFFECEDF2);
const _kMuted      = Color(0xFF6B6E82);

const _kMono = TextStyle(fontFamily: 'RobotoMono', color: _kMuted, fontSize: 11, letterSpacing: 0.5);

// ─── SHARED HELPERS ──────────────────────────────────────────────────────────

/// Divider with label — used on ticket and scanner cards.
Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Row(children: [
    const Expanded(child: Divider(color: _kBorder, thickness: 1)),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(text, style: _kMono.copyWith(fontSize: 10, letterSpacing: 1.4)),
    ),
    const Expanded(child: Divider(color: _kBorder, thickness: 1)),
  ]),
);

/// Pill badge — status indicator.
Widget _badge(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
    border: Border.all(color: bg.withValues(alpha: 0.4), width: 1)),
  child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
);

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 1 — QR TICKET DISPLAY
// Shown to a student immediately after they register for an event.
// ═══════════════════════════════════════════════════════════════════════════════

class QRTicketScreen extends StatefulWidget {
  final String qrToken;      // cryptographic hash from Django
  final String eventTitle;
  final String eventDate;    // pre-formatted, e.g. "Sat 21 Jun · 09:00"
  final String studentId;

  const QRTicketScreen({
    super.key,
    required this.qrToken,
    required this.eventTitle,
    required this.eventDate,
    required this.studentId,
  });

  @override
  State<QRTicketScreen> createState() => _QRTicketScreenState();
}

class _QRTicketScreenState extends State<QRTicketScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _copyToken() {
    Clipboard.setData(ClipboardData(text: widget.qrToken));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Token copied to clipboard'),
        backgroundColor: _kAccentDim,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kText,
        elevation: 0,
        title: Text('Your ticket', style: _kMono.copyWith(color: _kText, fontSize: 13)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: _kMuted),
            tooltip: 'Copy token',
            onPressed: _copyToken,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Status banner ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded, color: _kAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Registration confirmed. Show this QR code at the entrance.',
                            style: TextStyle(color: _kAccent.withValues(alpha: 0.9), fontSize: 13),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 28),

                    // ── Event name ────────────────────────────────────────
                    Text(
                      widget.eventTitle,
                      style: const TextStyle(
                        color: _kText, fontSize: 26, fontWeight: FontWeight.w700,
                        letterSpacing: -0.5, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: _kMuted),
                      const SizedBox(width: 6),
                      Text(widget.eventDate, style: _kMono.copyWith(color: _kMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.badge_outlined, size: 13, color: _kMuted),
                      const SizedBox(width: 6),
                      Text('ID: ${widget.studentId}', style: _kMono.copyWith(color: _kMuted)),
                    ]),

                    _sectionLabel('SCAN AT ENTRY'),

                    // ── QR Code ──────────────────────────────────────────
                    // White background is intentional — scanners need contrast.
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: widget.qrToken,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0E0F11),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0E0F11),
                          ),
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          // H = highest error correction — works even if partially obscured
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Token string ──────────────────────────────────────
                    GestureDetector(
                      onTap: _copyToken,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              widget.qrToken,
                              style: _kMono.copyWith(color: _kMuted, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 14, color: _kMuted),
                        ]),
                      ),
                    ),

                    _sectionLabel('IMPORTANT'),

                    // ── Disclaimer ────────────────────────────────────────
                    Text(
                      'This QR code is unique to your registration. Do not share it — one scan '
                      'checks you in. If you lose it, contact the event organiser with your '
                      'Student ID.',
                      style: TextStyle(color: _kMuted, fontSize: 13, height: 1.6),
                    ),

                    const SizedBox(height: 32),

                    // ── Close button ──────────────────────────────────────
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kText,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Back to events', style: TextStyle(fontSize: 14)),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — ADMIN CHECK-IN (SOAT VÉ)
// Admin activates webcam, scans QR codes, counter increments live.
// ═══════════════════════════════════════════════════════════════════════════════

/// Result model for a single scan attempt.
class _ScanResult {
  final bool success;
  final String message;
  final String? studentId;
  final String? studentEmail;
  final DateTime timestamp;

  _ScanResult({
    required this.success,
    required this.message,
    this.studentId,
    this.studentEmail,
  }) : timestamp = DateTime.now();
}

class AdminCheckInScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const AdminCheckInScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<AdminCheckInScreen> createState() => _AdminCheckInScreenState();
}

class _AdminCheckInScreenState extends State<AdminCheckInScreen> {
  // ── Scanner state ──────────────────────────────────────────────────────────
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.front, // laptop webcam
    formats: [BarcodeFormat.qrCode],
  );

  bool _scannerActive = false;    // user has explicitly started scanning
  bool _processing    = false;    // API call in-flight — prevents double-scan

  // ── Attendee data ──────────────────────────────────────────────────────────
  int _checkedInCount    = 0;
  int _totalCapacity     = 0;     // fetched from backend on init
  bool _loadingCapacity  = true;

  // ── Scan history (most recent first) ──────────────────────────────────────
  final List<_ScanResult> _history = [];

  // ── Last scan flash ───────────────────────────────────────────────────────
  _ScanResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _fetchEventStats();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  // ── Fetch current check-in count and capacity from Django ─────────────────
  Future<void> _fetchEventStats() async {
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/events/${widget.eventId}/stats/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _checkedInCount   = (data['checked_in_count'] as int?)  ?? 0;
            _totalCapacity    = (data['total_capacity']   as int?)  ?? 0;
            _loadingCapacity  = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingCapacity = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCapacity = false);
    }
  }

  // ── Called on every QR code detected by the scanner ───────────────────────
  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    // Guard: skip if already processing a scan
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _processing = true);

    // Pause scanner to avoid re-firing while the API call is in-flight.
    await _scanner.stop();

    final result = await _checkIn(raw);

    if (mounted) {
      setState(() {
        _lastResult = result;
        _history.insert(0, result);
        if (result.success) _checkedInCount++;
        _processing = false;
      });

      // Resume scanner after a short visual hold so admin can read the result.
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted && _scannerActive) {
        setState(() => _lastResult = null);
        await _scanner.start();
      }
    }
  }

  // ── Hit the Django check-in endpoint ──────────────────────────────────────
  // Expected response: { "success": true, "student_id": "HS220145",
  //                       "email": "student@school.edu", "message": "Checked in" }
  // Error cases: { "success": false, "message": "Already checked in" }
  Future<_ScanResult> _checkIn(String token) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/checkin/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'event_id': widget.eventId}),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _ScanResult(
          success:      (data['success'] as bool?) ?? false,
          message:      (data['message']    as String?) ?? 'Unknown response',
          studentId:    data['student_id']  as String?,
          studentEmail: data['email']       as String?,
        );
      } else if (res.statusCode == 404) {
        return _ScanResult(success: false, message: 'Token not found — invalid ticket');
      } else {
        return _ScanResult(success: false, message: 'Server error (${res.statusCode})');
      }
    } on Exception catch (e) {
      return _ScanResult(success: false, message: 'Network error: $e');
    }
  }

  // ── Toggle scanner on/off ─────────────────────────────────────────────────
  Future<void> _toggleScanner() async {
    if (_scannerActive) {
      await _scanner.stop();
      setState(() { _scannerActive = false; _lastResult = null; });
    } else {
      await _scanner.start();
      setState(() { _scannerActive = true; });
    }
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _statChip(String value, String label, {Color valueColor = _kText}) => Column(
    children: [
      Text(value, style: TextStyle(color: valueColor, fontSize: 28,
          fontWeight: FontWeight.w700, letterSpacing: -1)),
      const SizedBox(height: 2),
      Text(label, style: _kMono.copyWith(fontSize: 10, letterSpacing: 1.2)),
    ],
  );

  Widget _historyTile(_ScanResult r) {
    final icon  = r.success ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final color = r.success ? _kAccent : _kDanger;
    final time  = '${r.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${r.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${r.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.message, style: TextStyle(color: _kText, fontSize: 13)),
            if (r.studentId != null)
              Text('ID: ${r.studentId}  ·  ${r.studentEmail ?? ''}',
                  style: _kMono.copyWith(fontSize: 10)),
          ]),
        ),
        Text(time, style: _kMono.copyWith(fontSize: 10)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Capacity fill percentage — safe division
    final double fillPct = (_totalCapacity > 0)
        ? (_checkedInCount / _totalCapacity).clamp(0.0, 1.0)
        : 0.0;
    final bool nearCapacity = fillPct > 0.85;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kText,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SOÁT VÉ', style: _kMono.copyWith(color: _kAccent, fontSize: 11, letterSpacing: 2)),
          Text(widget.eventTitle,
              style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          // Refresh stats manually
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: _kMuted),
            tooltip: 'Refresh count',
            onPressed: _fetchEventStats,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Two-column layout on wide screens (laptop), single column on mobile.
          final bool wide = constraints.maxWidth >= 760;

          final statsPanel = _buildStatsPanel(fillPct, nearCapacity);
          final scannerPanel = _buildScannerPanel();
          final historyPanel = _buildHistoryPanel();

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: scanner
                Expanded(flex: 5, child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [statsPanel, const SizedBox(height: 20), scannerPanel]),
                )),
                // Right: history
                Expanded(flex: 4, child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                  child: historyPanel,
                )),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              statsPanel, const SizedBox(height: 20),
              scannerPanel, const SizedBox(height: 20),
              historyPanel,
            ]),
          );
        },
      ),
    );
  }

  // ── Stats panel ───────────────────────────────────────────────────────────
  Widget _buildStatsPanel(double fillPct, bool nearCapacity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('ATTENDANCE', style: _kMono.copyWith(letterSpacing: 1.5)),
          const Spacer(),
          if (nearCapacity) _badge('NEAR CAPACITY', _kWarning, _kWarning),
        ]),
        const SizedBox(height: 20),

        // Counter row
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statChip(
            _checkedInCount.toString(),
            'CHECKED IN',
            valueColor: _kAccent,
          ),
          Container(width: 1, height: 48, color: _kBorder),
          _loadingCapacity
              ? _statChip('—', 'CAPACITY')
              : _statChip(_totalCapacity.toString(), 'CAPACITY'),
          Container(width: 1, height: 48, color: _kBorder),
          _statChip(
            _totalCapacity > 0
                ? '${(_checkedInCount / _totalCapacity * 100).toStringAsFixed(0)}%'
                : '—',
            'FILL RATE',
            valueColor: nearCapacity ? _kWarning : _kText,
          ),
        ]),

        const SizedBox(height: 16),

        // Capacity bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fillPct,
            minHeight: 6,
            backgroundColor: _kBorder,
            valueColor: AlwaysStoppedAnimation(nearCapacity ? _kWarning : _kAccent),
          ),
        ),
      ]),
    );
  }

  // ── Scanner panel ─────────────────────────────────────────────────────────
  Widget _buildScannerPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scannerActive ? _kAccent.withValues(alpha: 0.4) : _kBorder),
      ),
      child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(children: [
            Text('WEBCAM SCANNER', style: _kMono.copyWith(letterSpacing: 1.5)),
            const Spacer(),
            _badge(
              _scannerActive ? 'LIVE' : 'STANDBY',
              _scannerActive ? _kAccent : _kMuted,
              _scannerActive ? _kAccent : _kMuted,
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Camera viewport — only renders when active
        if (_scannerActive) ...[
          Stack(
            children: [
              // The actual webcam feed + QR detection
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.zero),
                child: SizedBox(
                  height: 280,
                  child: MobileScanner(
                    controller: _scanner,
                    onDetect: _onBarcodeDetected,
                    // Overlay: shows the scanning frame widget
                    overlayBuilder: (context, constraints) => _ScanOverlay(
                      processing: _processing,
                    ),
                  ),
                ),
              ),

              // Result flash — overlays the camera feed
              if (_lastResult != null)
                Positioned.fill(
                  child: _ResultFlash(result: _lastResult!),
                ),
            ],
          ),
        ] else ...[
          // Placeholder when scanner is off
          SizedBox(
            height: 280,
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.qr_code_scanner_rounded, size: 64, color: _kBorder),
                const SizedBox(height: 16),
                Text('Camera inactive', style: TextStyle(color: _kMuted, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Press Start to activate webcam',
                    style: _kMono.copyWith(fontSize: 11)),
              ]),
            ),
          ),
        ],

        // Start / Stop button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: _processing
                ? ElevatedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kBg),
                    ),
                    label: const Text('Processing…'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentDim,
                      foregroundColor: _kBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _toggleScanner,
                    icon: Icon(_scannerActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_scannerActive ? 'Stop scanner' : 'Start scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scannerActive ? _kDanger.withValues(alpha: 0.15) : _kAccent,
                      foregroundColor: _scannerActive ? _kDanger : _kBg,
                      side: _scannerActive ? const BorderSide(color: _kDanger) : BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  // ── History panel ─────────────────────────────────────────────────────────
  Widget _buildHistoryPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('SCAN LOG', style: _kMono.copyWith(letterSpacing: 1.5)),
          const Spacer(),
          Text('${_history.length} scans', style: _kMono.copyWith(fontSize: 10)),
        ]),
        const SizedBox(height: 14),
        if (_history.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text('No scans yet — start the scanner.',
                  style: TextStyle(color: _kMuted, fontSize: 13)),
            ),
          )
        else
          // Limit displayed rows to keep the UI snappy; no infinite scroll needed.
          ...(_history.take(30).map(_historyTile)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: Scan Overlay — the targeting frame drawn over the camera feed
// ═══════════════════════════════════════════════════════════════════════════════

class _ScanOverlay extends StatelessWidget {
  final bool processing;
  const _ScanOverlay({required this.processing});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(processing: processing),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final bool processing;
  _OverlayPainter({required this.processing});

  @override
  void paint(Canvas canvas, Size size) {
    const double boxSize = 180;
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final left   = cx - boxSize / 2;
    final top    = cy - boxSize / 2;
    final right  = cx + boxSize / 2;
    final bottom = cy + boxSize / 2;

    // Dim the area outside the scan zone
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, top), dimPaint);
    // Bottom
    canvas.drawRect(Rect.fromLTRB(0, bottom, size.width, size.height), dimPaint);
    // Left
    canvas.drawRect(Rect.fromLTRB(0, top, left, bottom), dimPaint);
    // Right
    canvas.drawRect(Rect.fromLTRB(right, top, size.width, bottom), dimPaint);

    // Corner markers
    final markerPaint = Paint()
      ..color = processing ? _kWarning : _kAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double len = 22;
    // Top-left
    canvas.drawLine(Offset(left, top + len), Offset(left, top), markerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + len, top), markerPaint);
    // Top-right
    canvas.drawLine(Offset(right - len, top), Offset(right, top), markerPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + len), markerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - len), Offset(left, bottom), markerPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + len, bottom), markerPaint);
    // Bottom-right
    canvas.drawLine(Offset(right - len, bottom), Offset(right, bottom), markerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - len), markerPaint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => old.processing != processing;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: Result Flash — full-screen overlay after a scan resolves
// ═══════════════════════════════════════════════════════════════════════════════

class _ResultFlash extends StatelessWidget {
  final _ScanResult result;
  const _ResultFlash({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.success ? _kAccent : _kDanger;
    final icon  = result.success
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;

    return Container(
      color: color.withValues(alpha: 0.88),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 56),
          const SizedBox(height: 12),
          Text(
            result.success ? 'CHECKED IN' : 'DENIED',
            style: const TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          if (result.studentId != null)
            Text(result.studentId!,
                style: const TextStyle(color: Colors.white70, fontSize: 15,
                    fontFamily: 'RobotoMono')),
          const SizedBox(height: 4),
          Text(result.message,
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ]),
      ),
    );
  }
}
