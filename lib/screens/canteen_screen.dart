import 'package:flutter/material.dart';
import '../models/canteen.dart';
import '../services/api_service.dart';
import 'meal_feedback_screen.dart';

class CanteenScreen extends StatefulWidget {
  const CanteenScreen({super.key});

  @override
  State<CanteenScreen> createState() => _CanteenScreenState();
}

class _CanteenScreenState extends State<CanteenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<DailyMeal>> _lunchFuture;
  late Future<List<DailyMeal>> _breakfastFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _lunchFuture     = ApiService().fetchTodayMeals(type: 'lunch');
      _breakfastFuture = ApiService().fetchTodayMeals(type: 'breakfast');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Căn tin hôm nay'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Bữa trưa'),
            Tab(text: 'Bữa sáng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealList(_lunchFuture),
          _buildMealList(_breakfastFuture),
        ],
      ),
    );
  }

  Widget _buildMealList(Future<List<DailyMeal>> future) {
    return FutureBuilder<List<DailyMeal>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Lỗi: ${snapshot.error}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final meals = snapshot.data ?? [];

        if (meals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_meals_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chưa có thực đơn hôm nay',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: meals.length,
          itemBuilder: (context, index) => _MealCard(
            meal: meals[index],
            onFeedbackDone: _refresh,
          ),
        );
      },
    );
  }
}

class _MealCard extends StatelessWidget {
  final DailyMeal meal;
  final VoidCallback onFeedbackDone;

  const _MealCard({required this.meal, required this.onFeedbackDone});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal photo
          if (meal.photoUrl != null && meal.photoUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                meal.photoUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 48, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.restaurant_rounded, size: 48, color: Colors.blue),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set label + rating
                Row(children: [
                  if (meal.setNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meal.setLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  const Spacer(),
                  if (meal.averageRating != null) ...[
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${meal.averageRating}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(' (${meal.ratingCount})',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ] else
                    Text('Chưa có đánh giá',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),

                const SizedBox(height: 12),

                // Components list
                ...meal.components.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text(
                      '${_componentLabel(e.key)}: ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ]),
                )),

                const SizedBox(height: 16),

                // Feedback button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text('Đánh giá bữa ăn này'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MealFeedbackScreen(meal: meal),
                        ),
                      );
                      onFeedbackDone();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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