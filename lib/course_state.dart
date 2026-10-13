import 'package:flutter/foundation.dart';

import 'models/course.dart';
import 'repositories/course_repository.dart';

class CourseState extends ChangeNotifier {
  final CourseRepository repository;
  final Set<String> favorites = {};
  Future<List<Course>>? _coursesFuture;
  Future<Map<String, dynamic>>? _studentDataFuture;

  CourseState({required this.repository});

  Future<List<Course>> getCourses() {
    return _coursesFuture ??= repository.getCourses();
  }

  Future<Map<String, dynamic>> getStudentData() {
    return _studentDataFuture ??= repository.getStudentData();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    notifyListeners();
  }
}
