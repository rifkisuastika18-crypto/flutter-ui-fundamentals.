class Course {
  final String code;
  final String title;
  final int credits;
  final String status;
  final String grade;
  final bool isFavorite;

  const Course({
    required this.code,
    required this.title,
    required this.credits,
    required this.status,
    this.grade = '-',
    this.isFavorite = false,
  });

  // Fungsi copyWith untuk memperbarui status favorit tanpa mengubah data lain
  Course copyWith({
    String? code,
    String? title,
    int? credits,
    String? status,
    String? grade,
    bool? isFavorite,
  }) {
    return Course(
      code: code ?? this.code,
      title: title ?? this.title,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] as String,
      title: json['title'] as String,
      credits: (json['credits'] as num).toInt(),
      status: json['status'] as String,
      grade: json['grade'] as String? ?? '-',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
