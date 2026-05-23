/*
[ Existing Card Header Elements: Club Name / Title / Venue Data ]
                                │
                        [ Description Block ]
                                │
                [ OLD FILE ENDED HERE — CODES DIVIDE ]
                                │
                     ┌──────────┴──────────┐
                     ▼                     ▼
          IF Ticket is NULL?       IF Ticket is Active?
          ┌─────────────────┐     ┌──────────────────┐
          │  ID Input Box   │     │  Success Banner  │
          │  Email Input Box│     │   QR Code Box    │
          │ [Register Button]     │  [Copy Code Row] │
          └─────────────────┘     └──────────────────┘
*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event.dart';
import '../models/registration.dart';
import '../services/api_service.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  // ── Registration state ─────────────────────────────────────────────────────
  final _formKey       = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _emailCtrl     = TextEditingController();
  bool                  _isLoading = false;
  RegistrationResponse? _ticket;
  String?               _errorMsg;

  // ── Event feedback state ───────────────────────────────────────────────────
  int     _feedbackStars    = 0;
  bool    _feedbackSubmitted = false;
  bool    _feedbackLoading   = false;
  String? _feedbackError;
  final   _commentCtrl = TextEditingController();
  final _feedbackStudentIdCtrl = TextEditingController();

  // ── Has event ended? ───────────────────────────────────────────────────────
  bool get _eventHasEnded {
    if (widget.event.endTime == null) return false;
    return DateTime.now().isAfter(widget.event.endTime!);
  }

  // ── Has student registered? (has ticket) ──────────────────────────────────
  bool get _hasTicket => _ticket != null;

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    _feedbackStudentIdCtrl.dispose();
    super.dispose();
  }

  // ── Submit registration ────────────────────────────────────────────────────
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final result = await ApiService().registerForEvent(
        eventId:   widget.event.id,
        studentId: _studentIdCtrl.text.trim(),
        email:     _emailCtrl.text.trim().toLowerCase(),
      );
      setState(() => _ticket = result);
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Submit event feedback ──────────────────────────────────────────────────
  Future<void> _submitFeedback() async {
    if (_feedbackStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao')),
      );
      return;
    }
    setState(() { _feedbackLoading = true; _feedbackError = null; });
    try {
      final result = await ApiService().submitEventFeedback(
        eventId:   widget.event.id,
        studentId: _feedbackStudentIdCtrl.text.trim().isNotEmpty
          ? _feedbackStudentIdCtrl.text.trim()
          : 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        starRating: _feedbackStars,
        comment:    _commentCtrl.text.trim(),
      );
      if (result['success'] == true) {
        setState(() => _feedbackSubmitted = true);
      } else {
        setState(() => _feedbackError = result['message']);
      }
    } catch (e) {
      setState(() => _feedbackError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _feedbackLoading = false);
    }
  }

  void _copyToken() {
    if (_ticket == null) return;
    Clipboard.setData(ClipboardData(text: _ticket!.token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token đã được sao chép'),
          duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Event info (unchanged) ───────────────────────────────────────
            Text(widget.event.club.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: Colors.blue[800])),
            const SizedBox(height: 8),
            Text(widget.event.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Row(children: [
              Icon(Icons.calendar_today, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                '${widget.event.startTime.toLocal().toString().split(' ')[0]} • '
                '${widget.event.startTime.toLocal().toString().split(' ')[1].substring(0, 5)}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ]),
            if (widget.event.endTime != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today_outlined, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  'Ends: ${widget.event.endTime!.toLocal().toString().split(' ')[0]} • '
                  '${widget.event.endTime!.toLocal().toString().split(' ')[1].substring(0, 5)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ]),
            ],
            const SizedBox(height: 16),

            if (widget.event.location.isNotEmpty) ...[
              Row(children: [
                Icon(Icons.location_on, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.event.location,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]))),
              ]),
              const SizedBox(height: 24),
            ],

            const Text('Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.event.description,
                style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 32),

            if (widget.event.officialLink != null &&
                widget.event.officialLink!.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('View Official Post'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final url = Uri.parse(widget.event.officialLink!);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      messenger.showSnackBar(const SnackBar(
                          content: Text('Could not open link')));
                    }
                  },
                ),
              ),

            // ── Registration section ─────────────────────────────────────────
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),

            _ticket != null
                ? _buildTicket()
                : _buildRegistrationForm(),

            // ── Event feedback section (only after event ends) ───────────────
            if (_eventHasEnded) ...[
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),
              _buildEventFeedback()
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Registration form ──────────────────────────────────────────────────────
  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đăng ký sự kiện',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Nhập thông tin để nhận vé QR vào cửa.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 20),

        if (_errorMsg != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _studentIdCtrl,
              decoration: InputDecoration(
                labelText: 'Mã học sinh',
                hintText: 'VD: HS220145',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập mã học sinh'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email trường',
                hintText: 'VD: s220145@school.edu',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Đăng ký & Nhận vé',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ── QR Ticket ──────────────────────────────────────────────────────────────
  Widget _buildTicket() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _ticket!.success ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _ticket!.success
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
            ),
          ),
          child: Row(children: [
            Icon(
              _ticket!.success
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: _ticket!.success ? Colors.green : Colors.orange,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_ticket!.message,
                style: TextStyle(
                    color: _ticket!.success
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontSize: 13))),
          ]),
        ),

        const SizedBox(height: 28),
        Text(_ticket!.eventTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(_ticket!.eventDate,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: _ticket!.token,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ),
        ),

        const SizedBox(height: 20),
        GestureDetector(
          onTap: _copyToken,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(children: [
              Expanded(
                child: Text(_ticket!.token,
                    style: TextStyle(fontFamily: 'monospace',
                        fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Icon(Icons.copy_rounded, size: 14, color: Colors.grey[500]),
            ]),
          ),
        ),

        const SizedBox(height: 16),
        Text('Xuất trình mã QR này ở cổng vào. Không chia sẻ cho người khác.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),

        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Quay lại danh sách'),
        ),
      ],
    );
  }

  // ── Event feedback ─────────────────────────────────────────────────────────
  Widget _buildEventFeedback() {
    if (_feedbackSubmitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(children: [
          const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 40),
          const SizedBox(height: 8),
          const Text('Cảm ơn bạn đã đánh giá!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Phản hồi của bạn giúp chúng tôi cải thiện các sự kiện.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          const Icon(Icons.rate_review_rounded, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Đánh giá sự kiện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('Sự kiện đã kết thúc. Hãy chia sẻ cảm nhận của bạn!',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 20),

        // Error banner
        if (_feedbackError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(_feedbackError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],
        // Student ID
        TextField(
          controller: _feedbackStudentIdCtrl,
          decoration: InputDecoration(
            labelText: 'Mã học sinh',
            hintText: 'VD: HS220145',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 20),
                
        // Star rating
        const Text('Bạn đánh giá sự kiện này thế nào?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _feedbackStars = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  _feedbackStars >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Optional comment
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhận xét thêm (không bắt buộc)...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_feedbackLoading || _feedbackStars == 0)
                ? null
                : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _feedbackLoading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Gửi đánh giá',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}