import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

// Function Pembaca JSON
Future<Map<String, dynamic>> loadStudentData() async {
  final jsonString = await rootBundle.loadString(
    'assets/data/student_data.json',
  );
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Learning Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> studentFuture;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Future hanya sekali saat widget dibuat
    studentFuture = loadStudentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Dashboard'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: studentFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Gagal memuat data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Data tidak ditemukan.'));
            }

            // 3. Data Loaded State
            final data = snapshot.data!;
            final student = data['student'] as Map<String, dynamic>;
            final courses = data['courses'] as List<dynamic>;

            // Menghitung Statistik Dinamis
            final int totalCourses = courses.length;
            final int totalCredits = courses.fold<int>(
              0,
                  (sum, item) => sum + (item['credits'] as int? ?? 0),
            );

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reusable Widget 1: Kartu Profil Mahasiswa
                  ProfileHeaderCard(
                    name: student['name'] as String,
                    nim: student['nim'] as String,
                  ),

                  const SizedBox(height: 16),

                  // Reusable Widget 2: Baris Summary Stats
                  Row(
                    children: [
                      StatCard(
                        title: 'Total Matkul',
                        value: '$totalCourses',
                        icon: Icons.book,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        title: 'Total SKS',
                        value: '$totalCredits SKS',
                        icon: Icons.credit_card,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Daftar Mata Kuliah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rendering List Courses
                  Expanded(
                    child: ListView.builder(
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index] as Map<String, dynamic>;
                        return CourseItemCard(course: course);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// REUSABLE WIDGET 1: Profile Header Card
// ==========================================
class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String nim;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.nim,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundImage: AssetImage('assets/images/profile.jpg'),
              child: Icon(Icons.person, size: 36),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: $nim',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// REUSABLE WIDGET 2: Summary Stat Card
// ==========================================
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// REUSABLE WIDGET 3: Course Item Card
// ==========================================
class CourseItemCard extends StatelessWidget {
  final Map<String, dynamic> course;

  const CourseItemCard({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final String status = course['status'] as String? ?? 'planned';
    final String grade = course['grade'] as String? ?? '-';

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (status == 'done') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'active') {
      statusColor = Colors.blue;
      statusIcon = Icons.play_circle_fill;
    } else if (status == 'planned') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: Text(
            course['code'] as String? ?? '',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        title: Text(
          course['title'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // Menampilkan credits (SKS) dan Nilai (Grade) tambahan
        subtitle: Text(
          '${course['credits']} SKS • Nilai: $grade',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}