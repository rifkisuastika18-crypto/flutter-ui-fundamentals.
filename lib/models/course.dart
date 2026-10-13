class Course {
  final String code;
  final String title;
  final int credits;
  final String status;
  final String grade;

  const Course({
    required this.code,
    required this.title,
    required this.credits,
    required this.status,
    this.grade = '-',
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] as String,
      title: json['title'] as String,
      credits: (json['credits'] as num).toInt(),
      status: json['status'] as String,
      grade: json['grade'] as String? ?? '-',
    );
  }
}
