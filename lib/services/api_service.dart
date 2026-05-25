import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/event.dart';
import '../models/registration.dart';
import '../models/canteen.dart';

class ApiService {
  static const String baseUrl = 'https://club-announce-backend.onrender.com/api/';

  Future<List<Event>> fetchEvents() async {
    final response = await http.get(Uri.parse('${baseUrl}events/'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Event.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }
  Future<List<Club>> fetchClubs() async {
    final response = await http.get(Uri.parse('${baseUrl}clubs/'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Club.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load clubs');
    }
  }


  // ── NEW: Registration ─────────────────────────────────────────────────────

  Future<RegistrationResponse> registerForEvent({
    required int eventId,
    required String studentId,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('${baseUrl}register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'event_id':   eventId,
        'student_id': studentId,
        'email':      email,
      }),
    ).timeout(const Duration(seconds: 10));

    // 200 = success, 409 = already registered (we still show the QR)
    if (response.statusCode == 200 || response.statusCode == 409) {
      return RegistrationResponse.fromJson(json.decode(response.body));
    }

    // 400 or anything else
    final body = json.decode(response.body);
    throw Exception(body['message'] ?? 'Registration failed.');
  }

  // ── Canteen ───────────────────────────────────────────────────────────────────

  Future<List<DailyMeal>> fetchTodayMeals({String type = 'lunch'}) async {
    final response = await http
        .get(Uri.parse('${baseUrl}meals/today/?type=$type'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List meals = data['meals'] as List;
      return meals.map((m) => DailyMeal.fromJson(m)).toList();
    }
    throw Exception('Failed to load meals');
  }

  Future<DailyMeal> fetchMealDetail(int mealId) async {
    final response = await http
        .get(Uri.parse('${baseUrl}meals/$mealId/'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode == 200) {
      return DailyMeal.fromJson(json.decode(response.body));
    }
    throw Exception('Meal not found');
  }

  Future<Map<String, dynamic>> submitMealFeedback({
    required int mealId,
    required int overallStars,
    Map<String, bool> componentVotes = const {},
    List<String> selectedTags = const [],
    String serviceIssue = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}meals/feedback/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'meal_id':         mealId,
            'overall_stars':   overallStars,
            'component_votes': componentVotes,
            'selected_tags':   selectedTags,
            'service_issue':   serviceIssue,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitEventFeedback({
    required int eventId,
    required String studentId,
    required int starRating,
    String comment = '',
  }) async {
    final response = await http
        .post(
          Uri.parse('${baseUrl}events/$eventId/feedback/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'event_id':   eventId,
            'student_id': studentId,
            'star_rating': starRating,
            'comment':    comment,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
