class Meal {
  final String mealId; // Add mealId field
  final String donorId;
  final String name;
  final String description;
  final String location;
  final String photo;
  String status;

  Meal({
    required this.mealId,
    required this.donorId,
    required this.name,
    required this.description,
    required this.location,
    required this.photo,
    required this.status,
    required String date,
  });
}
