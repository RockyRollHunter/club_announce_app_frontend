class RegistrationResponse {
  final bool success;
  final String message;
  final String token;
  final String eventTitle;
  final String eventDate;

  RegistrationResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.eventTitle,
    required this.eventDate,
  });

  factory RegistrationResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationResponse(
      success:    json['success']     as bool,
      message:    json['message']     as String,
      token:      json['token']       as String,
      eventTitle: json['event_title'] as String,
      eventDate:  json['event_date']  as String,
    );
  }
}