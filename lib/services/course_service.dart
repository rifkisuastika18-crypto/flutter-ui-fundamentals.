import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/course.dart';

class CourseService {
  final AssetBundle _bundle;
  late final Future<Map<String, dynamic>> _dataFuture = _loadData();

  CourseService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  Future<Map<String, dynamic>> loadStudentData() async {
    final data = await _dataFuture;
    return {...data, 'courses': parseCourses(data['courses'] as List<dynamic>)};
  }

  Future<List<Course>> loadCourses() async {
    final data = await _dataFuture;
    return parseCourses(data['courses'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final jsonString = await _bundle.loadString(
        'assets/data/student_data.json',
      );
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return {
        'student': {'name': 'Gede Rifki Swastika Utama', 'nim': '2415051095'},
        'courses': [
          {
            'code': 'IF101',
            'title': 'Pemrograman Mobile',
            'credits': 3,
            'status': 'active',
            'grade': 'A',
          },
          {
            'code': 'IF102',
            'title': 'Struktur Data & Algoritma',
            'credits': 4,
            'status': 'done',
            'grade': 'A',
          },
        ],
      };
    }
  }

  static List<Course> parseCourses(List<dynamic> courseJson) {
    return courseJson
        .map((json) {
          if (json is Course) return json;
          return Course.fromJson(json as Map<String, dynamic>);
        })
        .toList(growable: false);
  }

  static Map<String, dynamic> withTypedCourses(Map<String, dynamic> data) {
    return {...data, 'courses': parseCourses(data['courses'] as List<dynamic>)};
  }
}
