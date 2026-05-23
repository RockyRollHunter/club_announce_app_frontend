import 'package:flutter/material.dart';
import '../models/canteen.dart';
import '../services/api_service.dart';

class MealFeedbackScreen extends StatefulWidget {
  final DailyMeal meal;
  const MealFeedbackScreen({super.key, required this.meal});

  @override
  State<MealFeedbackScreen> createState() => _MealFeedbackScreenState();
}

class _MealFeedbackScreenState extends State<MealFeedbackScreen> {
  // ── Session submission counter (Option B — 3 per session) ─────────────────
  static final Map<int, int> _sessionCounts = {};

  int get _myCount => _sessionCounts[widget.meal.id] ?? 0;
  bool get _canSubmit => _myCount < 3;

  // ── State ──────────────────────────────────────────────────────────────────
  int  _overallStars = 0;       // 0 = not selected yet
  bool _submitted    = false;
  bool _isLoading    = false;

  // component votes: true = 👍, false = 👎, null = not voted
  final Map<String, bool?> _componentVotes = {};
  // selected tags per component
  final Map<String, Set<String>> _selectedTags = {};
  // service issue
  bool   _showServiceIssue = false;
  final  TextEditingController _serviceIssueCtrl = TextEditingController();

  @override
  void dispose() {
    _serviceIssueCtrl.dispose();
    super.dispose();
  }

  bool get _showDetailSection => _overallStars > 0 && _overallStars <= 3;

  Future<void> _submit() async {
    if (_overallStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn số sao tổng thể')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Flatten selected tags to a single list
    final allTags = _selectedTags.values
        .expand((tags) => tags)
        .toList();

    // Convert votes: only include components that were thumbs-down
    final votes = Map<String, bool>.fromEntries(
      _componentVotes.entries
          .where((e) => e.value != null)
          .map((e) => MapEntry(e.key, e.value!)),
    );

    try {
      final result = await ApiService().submitMealFeedback(
        mealId:         widget.meal.id,
        overallStars:   _overallStars,
        componentVotes: votes,
        selectedTags:   allTags,
        serviceIssue:   _serviceIssueCtrl.text.trim(),
      );

      if (result['success'] == true) {
        _sessionCounts[widget.meal.id] = _myCount + 1;
        setState(() => _submitted = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Có lỗi xảy ra')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meal.setLabel.isNotEmpty
            ? widget.meal.setLabel
            : 'Đánh giá bữa ăn'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _submitted ? _buildThankYou() : _buildForm(),
    );
  }

  // ── Thank you screen ───────────────────────────────────────────────────────
  Widget _buildThankYou() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
        const SizedBox(height: 16),
        const Text('Cảm ơn bạn!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _myCount < 3
              ? 'Bạn còn ${3 - _myCount} lượt đánh giá hôm nay'
              : 'Bạn đã dùng hết lượt đánh giá hôm nay',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
      ]),
    );
  }

  // ── Feedback form ──────────────────────────────────────────────────────────
  Widget _buildForm() {
    if (!_canSubmit) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.block_rounded, color: Colors.orange, size: 64),
          const SizedBox(height: 16),
          const Text('Bạn đã đánh giá 3 lần trong phiên này',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('Quét QR lại để tiếp tục',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Quay lại'),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Meal photo
        if (widget.meal.photoUrl != null && widget.meal.photoUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.meal.photoUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),

        const SizedBox(height: 20),

        // ── Overall star rating ──────────────────────────────────────────────
        const Text('Bữa ăn hôm nay thế nào?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Nhấn để chọn số sao',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() {
                _overallStars = star;
                // Reset detail votes if user upgrades to > 3
                if (star > 3) {
                  _componentVotes.clear();
                  _selectedTags.clear();
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  _overallStars >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 44,
                ),
              ),
            );
          }),
        ),

        // ── Detail section (only if ≤ 3 stars) ──────────────────────────────
        if (_showDetailSection) ...[
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Món nào chưa ổn?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Nhấn 👍 hoặc 👎 cho từng món',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 16),

          // One row per component
          ...widget.meal.components.entries.map((entry) =>
              _buildComponentRow(entry.key, entry.value)),
        ],

        // ── Service issue toggle ─────────────────────────────────────────────
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: () => setState(() => _showServiceIssue = !_showServiceIssue),
          child: Row(children: [
            Icon(
              _showServiceIssue
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Báo cáo sự cố dịch vụ',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ]),
        ),

        if (_showServiceIssue) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _serviceIssueCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả sự cố bạn gặp phải...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // ── Submit button ────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || _overallStars == 0) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Gửi đánh giá',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),

        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Component row with thumbs + sliding tags ───────────────────────────────
  Widget _buildComponentRow(String component, String name) {
    final vote = _componentVotes[component];
    final tags = widget.meal.tagsByComponent[component] ?? [];
    final selected = _selectedTags[component] ?? {};
    final showTags = vote == false && tags.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Component name + thumbs
        Row(children: [
          Expanded(
            child: Text(
              '${_componentLabel(component)}: $name',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          // 👍
          GestureDetector(
            onTap: () => setState(() {
              _componentVotes[component] = true;
              _selectedTags.remove(component);
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vote == true
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: vote == true ? Colors.green : Colors.grey.shade300,
                ),
              ),
              child: Text('👍', style: TextStyle(
                fontSize: 20,
                color: vote == true ? Colors.green : Colors.grey,
              )),
            ),
          ),
          const SizedBox(width: 8),
          // 👎
          GestureDetector(
            onTap: () => setState(() {
              _componentVotes[component] = false;
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vote == false
                    ? Colors.red.withOpacity(0.15)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: vote == false ? Colors.red : Colors.grey.shade300,
                ),
              ),
              child: Text('👎', style: TextStyle(
                fontSize: 20,
                color: vote == false ? Colors.red : Colors.grey,
              )),
            ),
          ),
        ]),

        // Sliding tags (only when 👎)
        if (showTags) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: tags.map((tag) {
              final label = tag['label'] as String;
              final isSelected = selected.contains(label);
              return GestureDetector(
                onTap: () => setState(() {
                  final s = _selectedTags[component] ?? {};
                  if (isSelected) {
                    s.remove(label);
                  } else {
                    s.add(label);
                  }
                  _selectedTags[component] = s;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  String _componentLabel(String key) {
    const labels = {
      'protein':    'Món mặn',
      'vegetables': 'Rau',
      'soup':       'Canh',
      'rice':       'Cơm',
      'dessert':    'Tráng miệng',
    };
    return labels[key] ?? key;
  }
}