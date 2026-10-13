import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'course_state.dart';
import 'models/course.dart';
import 'services/course_service.dart';

const defaultStudentName = 'Gede Rifki Swastika Utama';
const defaultStudentNim = '2415051095';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourseState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Course Explorer',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const MainNavigationPage(),
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  final Future<Map<String, dynamic>>? studentFuture;

  const MainNavigationPage({super.key, this.studentFuture});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late final CourseService _courseService;
  late final Future<Map<String, dynamic>> _studentFuture;
  final _pageStackKey = GlobalKey();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _courseService = CourseService();
    _studentFuture = widget.studentFuture ?? _courseService.loadStudentData();
  }

  List<Widget> _buildPages() => [
    HomePage(studentFuture: _studentFuture),
    CoursesPage(studentFuture: _studentFuture),
    ProfilePage(studentFuture: _studentFuture),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Scaffold(
            body: _buildPageStack(),
            bottomNavigationBar: _buildNavigationBar(),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _buildNavigationRail(),
              const VerticalDivider(width: 1),
              Expanded(child: _buildPageStack()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageStack() {
    return IndexedStack(
      key: _pageStackKey,
      index: _selectedIndex,
      children: _buildPages(),
    );
  }

  NavigationBar _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationDestination(
          key: ValueKey('tab-home'),
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          key: ValueKey('tab-courses'),
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Courses',
        ),
        NavigationDestination(
          key: ValueKey('tab-profile'),
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  NavigationRail _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: Text('Courses'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profile'),
        ),
      ],
    );
  }
}

class HomePage extends StatefulWidget {
  final Future<Map<String, dynamic>>? studentFuture;

  const HomePage({super.key, this.studentFuture});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>> studentFuture;

  @override
  void initState() {
    super.initState();
    // Inisialisasi Future hanya sekali saat widget dibuat
    studentFuture = widget.studentFuture ?? CourseService().loadStudentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Explorer'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Edit profil',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const ProfileFormPage(),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: studentFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
            final courses = CourseService.parseCourses(
              data['courses'] as List<dynamic>,
            );

            final String studentName =
                student['name'] as String? ?? 'Gede Rifki Swastika Utama';
            final String studentId = student['nim'] as String? ?? '2415051095';

            // Menghitung Statistik Dinamis dengan aman
            final int totalCourses = courses.length;
            final totalCredits = courses.fold<int>(
              0,
              (sum, course) => sum + course.credits,
            );

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Latihan Container Responsif (Menggunakan double.infinity alih-alih lebar tetap 500)
                Center(
                  child: StudentResponsiveLayout(
                    name: studentName,
                    nim: studentId,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: FilledButton.icon(
                    key: const ValueKey('open-detail'),
                    onPressed: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              DetailPage(name: studentName, nim: studentId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka Detail'),
                  ),
                ),

                const SizedBox(height: 8),

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

                const SizedBox(height: 16),

                const Text(
                  'Daftar Mata Kuliah',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                CourseGrid(
                  courses: courses,
                  studentName: studentName,
                  studentNim: studentId,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CoursesPage extends StatelessWidget {
  final Future<Map<String, dynamic>> studentFuture;

  const CoursesPage({super.key, required this.studentFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Explorer'),
        actions: [
          IconButton(
            key: const ValueKey('open-bounded-list-demo'),
            tooltip: 'Demo list di dalam Column',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const BoundedListDemoPage(),
                ),
              );
            },
            icon: const Icon(Icons.view_list_outlined),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Data course tidak tersedia.'));
          }

          final student = snapshot.data!['student'] as Map<String, dynamic>;
          final courses = CourseService.parseCourses(
            snapshot.data!['courses'] as List<dynamic>,
          );
          final studentName = student['name'] as String? ?? defaultStudentName;
          final studentNim = student['nim'] as String? ?? defaultStudentNim;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                  title: Text(studentName),
                  subtitle: Text('NIM: $studentNim'),
                ),
              ),
              const SizedBox(height: 16),
              const FavoriteCountLabel(),
              const SizedBox(height: 12),
              Text(
                '${courses.length} mata kuliah',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              CourseGrid(
                courses: courses,
                studentName: studentName,
                studentNim: studentNim,
              ),
            ],
          );
        },
      ),
    );
  }
}

class FavoriteCountLabel extends StatelessWidget {
  const FavoriteCountLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteCount = context.watch<CourseState>().favorites.length;
    return Text(
      'Favorite: $favoriteCount',
      key: const ValueKey('favorite-count'),
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class BoundedListDemoPage extends StatelessWidget {
  const BoundedListDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scrollable Course List')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'List di dalam Column',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                key: const ValueKey('bounded-course-list'),
                itemCount: 30,
                itemBuilder: (context, index) => ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text('Course ${index + 1}'),
                  subtitle: const Text('Daftar ini memiliki tinggi terbatas.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final Future<Map<String, dynamic>> studentFuture;

  const ProfilePage({super.key, required this.studentFuture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: studentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Data profil tidak tersedia.'));
          }

          final student = snapshot.data!['student'] as Map<String, dynamic>;
          final name =
              student['name'] as String? ?? 'Gede Rifki Swastika Utama';
          final nim = student['nim'] as String? ?? '2415051095';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: const AssetImage(
                    'assets/images/profile.jpg',
                  ),
                  onBackgroundImageError: (exception, stackTrace) {},
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                key: const ValueKey('profile-student-name'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('NIM: $nim', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ProfileFormPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profil'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('open-feedback'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const FeedbackPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Beri Feedback'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: defaultStudentName);
  final _nimController = TextEditingController(text: defaultStudentNim);
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, String>? _submittedFeedback;

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim feedback?'),
        content: const Text('Pastikan komentar sudah sesuai sebelum dikirim.'),
        actions: [
          TextButton(
            key: const ValueKey('cancel-feedback'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const ValueKey('confirm-feedback'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (shouldSubmit != true || !mounted) return;

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submittedFeedback = {
        'name': _nameController.text.trim(),
        'nim': _nimController.text.trim(),
        'comment': _commentController.text.trim(),
      };
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback berhasil dikirim')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              key: const ValueKey('feedback-name'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('feedback-nim'),
              controller: _nimController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'NIM',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'NIM wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('feedback-comment'),
              controller: _commentController,
              minLines: 4,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Komentar',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().length < 5
                  ? 'Komentar minimal 5 karakter'
                  : null,
            ),
            const SizedBox(height: 24),
            if (_isSubmitting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    key: ValueKey('feedback-loading'),
                  ),
                ),
              )
            else
              FilledButton.icon(
                key: const ValueKey('submit-feedback'),
                onPressed: _submitFeedback,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Kirim Feedback'),
              ),
            if (_submittedFeedback case final feedback?) ...[
              const SizedBox(height: 16),
              Card(
                key: const ValueKey('feedback-result'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feedback terkirim',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Nama: ${feedback['name']}'),
                      Text('NIM: ${feedback['nim']}'),
                      const SizedBox(height: 4),
                      Text('Komentar: ${feedback['comment']}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String name;
  final String nim;

  const DetailPage({super.key, required this.name, required this.nim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Mahasiswa')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: const AssetImage('assets/images/profile.jpg'),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('NIM: $nim'),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const ValueKey('detail-pop'),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key});

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const ValueKey('profile-form-scroll'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.indigo.shade50,
                    backgroundImage: const AssetImage(
                      'assets/images/profile.jpg',
                    ),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('profile-name'),
                  initialValue: 'Gede Rifki Swastika Utama',
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('profile-nim'),
                  initialValue: '2415051095',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'NIM',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'NIM wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('profile-email'),
                  initialValue: 'rifki@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Masukkan email yang valid'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('profile-program'),
                  initialValue: 'Pendidikan Teknik Informatika',
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Program studi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('profile-phone'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('profile-bio'),
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Tentang saya',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('profile-save'),
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Simpan profil'),
                ),
              ],
            ),
          ),
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
  final String layoutCategory;
  final Color accentColor;
  final _ProfileLayoutStyle layoutStyle;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.nim,
    this.layoutCategory = 'Profil Mahasiswa',
    this.accentColor = const Color.fromARGB(255, 194, 199, 228),
    this.layoutStyle = _ProfileLayoutStyle.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: switch (layoutStyle) {
        _ProfileLayoutStyle.compact => const Color.fromARGB(255, 213, 219, 219),
        _ProfileLayoutStyle.medium => const Color.fromARGB(255, 234, 195, 195),
        _ProfileLayoutStyle.expanded => const Color.fromARGB(
          255,
          220,
          223,
          225,
        ),
      },
      elevation: layoutStyle == _ProfileLayoutStyle.medium ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (layoutStyle == _ProfileLayoutStyle.medium)
              Container(
                width: 4,
                height: 64,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            CircleAvatar(
              radius: layoutStyle == _ProfileLayoutStyle.compact ? 28 : 32,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              backgroundImage: const AssetImage('assets/images/profile.jpg'),
              onBackgroundImageError: (exception, stackTrace) {},
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
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  if (layoutStyle != _ProfileLayoutStyle.expanded) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Layout $layoutCategory',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (layoutStyle == _ProfileLayoutStyle.expanded)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Layout\n$layoutCategory',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StudentResponsiveLayout extends StatelessWidget {
  final String name;
  final String nim;

  const StudentResponsiveLayout({
    super.key,
    required this.name,
    required this.nim,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget layout = constraints.maxWidth < 600
            ? CompactLayout(name: name, nim: nim)
            : constraints.maxWidth < 840
            ? MediumLayout(name: name, nim: nim)
            : ExpandedLayout(name: name, nim: nim);

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600),
          child: layout,
        );
      },
    );
  }
}

class LayoutPracticeSection extends StatelessWidget {
  const LayoutPracticeSection({super.key});

  static const skills = [
    'Dart',
    'Flutter',
    'UI Design',
    'Git',
    'Firebase',
    'REST API',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Latihan Row & Wrap',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                key: const ValueKey('panel-a'),
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 131, 214, 207),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Panel A'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                key: const ValueKey('panel-b'),
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 229, 75, 28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Panel B'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Wrap'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: skills.map((skill) => Chip(label: Text(skill))).toList(),
        ),
        const SizedBox(height: 4),
        const Text('Row biasa'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: skills
                .map(
                  (skill) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(label: Text(skill)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class CourseGrid extends StatelessWidget {
  final List<Course> courses;
  final String studentName;
  final String studentNim;

  const CourseGrid({
    super.key,
    required this.courses,
    required this.studentName,
    required this.studentNim,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 840
            ? 2
            : 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: courses.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 4,
            mainAxisExtent: 152,
          ),
          itemBuilder: (context, index) {
            final course = courses[index];
            return CourseItemCard(
              course: course,
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => CourseDetailPage(
                      course: course,
                      studentName: studentName,
                      studentNim: studentNim,
                    ),
                  ),
                );
                if (result == true && context.mounted) {
                  final courseCode = course.code;
                  final courseState = context.read<CourseState>();
                  if (!courseState.favorites.contains(courseCode)) {
                    courseState.toggleFavorite(courseCode);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course ditambahkan ke favorite'),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class CourseDetailPage extends StatelessWidget {
  final Course course;
  final String studentName;
  final String studentNim;

  const CourseDetailPage({
    super.key,
    required this.course,
    required this.studentName,
    required this.studentNim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Mata Kuliah')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  Text('Kode: ${course.code}'),
                  const SizedBox(height: 12),
                  Text('Kredit: ${course.credits} SKS'),
                  const SizedBox(height: 12),
                  Text('Status: ${course.status.toUpperCase()}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Mahasiswa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/profile.jpg'),
            ),
            title: Text(studentName),
            subtitle: Text('NIM: $studentNim'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('favorite-course'),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.favorite_outline),
            label: const Text('Pilih / Favorite'),
          ),
        ],
      ),
    );
  }
}

enum _ProfileLayoutStyle { compact, medium, expanded }

class CompactLayout extends StatelessWidget {
  final String name;
  final String nim;

  const CompactLayout({super.key, required this.name, required this.nim});

  @override
  Widget build(BuildContext context) => ProfileHeaderCard(
    name: name,
    nim: nim,
    layoutCategory: 'Compact',
    accentColor: Colors.teal,
    layoutStyle: _ProfileLayoutStyle.compact,
  );
}

class MediumLayout extends StatelessWidget {
  final String name;
  final String nim;

  const MediumLayout({super.key, required this.name, required this.nim});

  @override
  Widget build(BuildContext context) => ProfileHeaderCard(
    name: name,
    nim: nim,
    layoutCategory: 'Medium',
    accentColor: Colors.deepOrange,
    layoutStyle: _ProfileLayoutStyle.medium,
  );
}

class ExpandedLayout extends StatelessWidget {
  final String name;
  final String nim;

  const ExpandedLayout({super.key, required this.name, required this.nim});

  @override
  Widget build(BuildContext context) => ProfileHeaderCard(
    name: name,
    nim: nim,
    layoutCategory: 'Expanded',
    accentColor: Colors.blue,
    layoutStyle: _ProfileLayoutStyle.expanded,
  );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
class CourseItemCard extends StatefulWidget {
  final Course course;
  final Future<void> Function() onTap;

  const CourseItemCard({super.key, required this.course, required this.onTap});

  @override
  State<CourseItemCard> createState() => _CourseItemCardState();
}

class _CourseItemCardState extends State<CourseItemCard> {
  bool _isOpeningDetails = false;

  Future<void> _openDetails() async {
    if (_isOpeningDetails) return;

    setState(() => _isOpeningDetails = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _isOpeningDetails = false);
    }
  }

  void _showCourseInfo() {
    final course = widget.course;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.title),
        content: Text(
          'Kode: ${course.code}\n'
          'Kredit: ${course.credits} SKS\n'
          'Status: ${course.status.toUpperCase()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final status = course.status;

    Color statusColor = const Color.fromARGB(255, 240, 239, 239);
    IconData statusIcon = Icons.help_outline;

    if (status == 'done') {
      statusColor = const Color.fromARGB(255, 66, 176, 69);
      statusIcon = Icons.check_circle;
    } else if (status == 'active') {
      statusColor = Colors.blue;
      statusIcon = Icons.play_circle_fill;
    } else if (status == 'planned') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _isOpeningDetails ? null : _openDetails,
        onLongPress: _showCourseInfo,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.code,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  Consumer<CourseState>(
                    builder: (context, courseState, child) {
                      final isFavorite = courseState.favorites.contains(
                        course.code,
                      );
                      return IconButton(
                        key: ValueKey('course-favorite-${course.code}'),
                        tooltip: isFavorite
                            ? 'Hapus dari favorite'
                            : 'Tambah ke favorite',
                        onPressed: () => context
                            .read<CourseState>()
                            .toggleFavorite(course.code),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                      );
                    },
                  ),
                  Container(
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${course.credits} SKS • Nilai: ${course.grade}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
