import 'dart:ui' show Size;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:flutter_ui_fundamentals/course_state.dart';
import 'package:flutter_ui_fundamentals/main.dart';
import 'package:flutter_ui_fundamentals/repositories/course_repository.dart';
import 'package:flutter_ui_fundamentals/services/course_service.dart';
import 'package:flutter_ui_fundamentals/models/course.dart';

class FakeCourseService extends CourseService {
  final List<Course> courses;
  int loadCoursesCount = 0;

  FakeCourseService(this.courses);

  @override
  Future<List<Course>> loadCourses() async {
    loadCoursesCount++;
    return courses;
  }
}

Widget withCourseState(Widget child, {List<Course> courses = const []}) {
  return ChangeNotifierProvider<CourseState>(
    create: (_) =>
        CourseState(repository: CourseRepository(FakeCourseService(courses))),
    child: child,
  );
}

void main() {
  test('CourseState toggles favorites and notifies listeners', () {
    final state = CourseState(repository: CourseRepository(CourseService()));
    var notificationCount = 0;
    state.addListener(() => notificationCount++);

    state.toggleFavorite('MOB01');
    expect(state.favorites, contains('MOB01'));
    expect(notificationCount, 1);

    state.toggleFavorite('MOB01');
    expect(state.favorites, isNot(contains('MOB01')));
    expect(notificationCount, 2);

    state.dispose();
  });

  test('Course.fromJson creates a typed course model', () {
    final course = Course.fromJson({
      'code': 'MOB03',
      'title': 'Flutter UI Fundamentals',
      'credits': 3,
      'status': 'active',
    });

    expect(course.code, 'MOB03');
    expect(course.title, 'Flutter UI Fundamentals');
    expect(course.credits, 3);
    expect(course.status, 'active');
    expect(course.grade, '-');
  });

  testWidgets('CourseService loads typed courses from the JSON asset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final courses = await CourseService().loadCourses();

    expect(courses, hasLength(5));
    expect(courses.first, isA<Course>());
    expect(courses.first.code, 'MOB01');
    expect(courses.first.title, 'Git & GitHub');
    expect(courses.first.credits, 2);
    expect(courses.first.status, 'done');
  });

  test('CourseRepository delegates course loading to its service', () async {
    const expectedCourse = Course(
      code: 'TEST01',
      title: 'Repository test',
      credits: 3,
      status: 'active',
    );
    final service = FakeCourseService([expectedCourse]);
    final repository = CourseRepository(service);
    final courses = await repository.getCourses();

    expect(courses, [expectedCourse]);
    expect(service.loadCoursesCount, 1);
  });

  testWidgets('dashboard loads student information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: HomePage(
            studentFuture: Future.value({
              'student': {'name': defaultStudentName, 'nim': defaultStudentNim},
              'courses': [
                Course(
                  code: 'MOB01',
                  title: 'Git & GitHub',
                  credits: 2,
                  status: 'done',
                  grade: 'A',
                ),
              ],
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(ProfileHeaderCard), findsOneWidget);
    expect(find.text('Course Explorer'), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Gede Rifki Swastika Utama'), findsOneWidget);
    expect(find.text('NIM: 2415051095'), findsOneWidget);
    expect(find.text('Buka Detail'), findsOneWidget);
    expect(find.byType(ProfileHeaderCard), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CircleAvatar && widget.backgroundImage is AssetImage,
      ),
      findsOneWidget,
    );
  });

  testWidgets('MyApp provides CourseState above the navigation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final context = tester.element(find.byType(MainNavigationPage));
    expect(
      Provider.of<CourseState>(context, listen: false),
      isA<CourseState>(),
    );
  });

  testWidgets('feedback validates, confirms, loads, and shows a result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FeedbackPage()));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('feedback-name')))
          .controller!
          .text,
      defaultStudentName,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('feedback-nim')))
          .controller!
          .text,
      defaultStudentNim,
    );

    await tester.tap(find.byKey(const ValueKey('submit-feedback')));
    await tester.pumpAndSettle();
    expect(find.text('Komentar minimal 5 karakter'), findsOneWidget);
    expect(find.text('Feedback terkirim'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('feedback-comment')),
      'Bagus',
    );
    await tester.tap(find.byKey(const ValueKey('submit-feedback')));
    await tester.pumpAndSettle();

    expect(find.text('Kirim feedback?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel-feedback')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('feedback-loading')), findsNothing);
    expect(find.text('Feedback berhasil dikirim'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('submit-feedback')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-feedback')));
    await tester.pump();
    expect(find.byKey(const ValueKey('feedback-loading')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Feedback berhasil dikirim'), findsOneWidget);
    expect(find.byKey(const ValueKey('feedback-result')), findsOneWidget);
    expect(find.text('Nama: $defaultStudentName'), findsOneWidget);
    expect(find.text('NIM: $defaultStudentNim'), findsOneWidget);
    expect(find.text('Komentar: Bagus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation switches between Home, Courses, and Profile', (
    WidgetTester tester,
  ) async {
    Future<void> pumpTabTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: MainNavigationPage(
            studentFuture: Future.value({
              'student': {
                'name': 'Gede Rifki Swastika Utama',
                'nim': '2415051095',
              },
              'courses': <Course>[],
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(HomePage), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.byKey(const ValueKey('tab-courses')));
    await pumpTabTransition();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('Courses'), findsOneWidget);
    expect(find.text('Course Explorer'), findsOneWidget);
    expect(find.byType(CoursesPage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-profile')));
    await pumpTabTransition();
    for (
      var frame = 0;
      frame < 20 &&
          find.byKey(const ValueKey('profile-student-name')).evaluate().isEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-student-name')), findsOneWidget);
    expect(find.text('Gede Rifki Swastika Utama'), findsOneWidget);
    expect(find.text('NIM: 2415051095'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tab-home')));
    await pumpTabTransition();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text('Buka Detail'), findsOneWidget);
  });

  testWidgets('favorite state is shared between Home and Courses', (
    WidgetTester tester,
  ) async {
    final courses = <Course>[
      const Course(
        code: 'MOB01',
        title: 'Git & GitHub',
        credits: 2,
        status: 'done',
        grade: 'A',
      ),
      const Course(
        code: 'MOB02',
        title: 'Dart Fundamentals',
        credits: 2,
        status: 'done',
        grade: 'A',
      ),
    ];
    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: MainNavigationPage(
            studentFuture: Future.value({
              'student': {'name': defaultStudentName, 'nim': defaultStudentNim},
              'courses': courses,
            }),
          ),
        ),
        courses: courses,
      ),
    );
    await tester.pump();
    await tester.pump();

    final favoriteKey = const ValueKey('course-favorite-MOB01');
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
    await tester.tap(find.byKey(favoriteKey));
    await tester.pump();
    expect(find.text('Favorite: 1'), findsNothing);

    expect(
      find.descendant(
        of: find.byKey(favoriteKey),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('tab-courses')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(
        of: find.byKey(favoriteKey),
        matching: find.byIcon(Icons.favorite),
      ),
      findsOneWidget,
    );
    expect(find.text('Favorite: 1'), findsOneWidget);

    await tester.tap(find.byKey(favoriteKey));
    await tester.pump();
    expect(find.text('Favorite: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Course Explorer shows identity and five courses responsively', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final courses = List.generate(
      5,
      (index) => {
        'code': 'CRS0$index',
        'title': 'Course $index',
        'credits': 3,
        'status': 'active',
        'grade': 'A',
      },
    );
    final studentFuture = Future.value({
      'student': {'name': defaultStudentName, 'nim': defaultStudentNim},
      'courses': courses,
    });
    for (final (width, columns) in [(390.0, 1), (1200.0, 3)]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        withCourseState(
          MaterialApp(home: CoursesPage(studentFuture: studentFuture)),
          courses: courses.map(Course.fromJson).toList(),
        ),
      );
      await tester.pump();
      for (
        var frame = 0;
        frame < 20 && find.text('5 mata kuliah').evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Course Explorer'), findsOneWidget);
      expect(find.text(defaultStudentName), findsOneWidget);
      expect(find.text('NIM: $defaultStudentNim'), findsOneWidget);
      expect(find.byType(CourseItemCard), findsNWidgets(5));
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        columns,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Column list has a bounded, scrollable viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BoundedListDemoPage()));
    await tester.pump();

    final list = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('bounded-course-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(list.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the selected page when switching navigation layouts', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(700, 900);

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: MainNavigationPage(
            studentFuture: Future.value({
              'student': {
                'name': 'Gede Rifki Swastika Utama',
                'nim': '2415051095',
              },
              'courses': <Course>[],
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-courses')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(CoursesPage), findsOneWidget);

    tester.view.physicalSize = const Size(1000, 900);
    await tester.pump();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    expect(find.byType(CoursesPage), findsOneWidget);

    tester.view.physicalSize = const Size(700, 900);
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(CoursesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selects the layout at each breakpoint', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final layouts = [
      (599.0, CompactLayout, 'Compact'),
      (600.0, MediumLayout, 'Medium'),
      (839.0, MediumLayout, 'Medium'),
      (840.0, ExpandedLayout, 'Expanded'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentResponsiveLayout(
            name: 'Gede Rifki Swastika Utama',
            nim: '2415051095',
          ),
        ),
      ),
    );
    await tester.pump();

    for (final (width, layoutType, category) in layouts) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pump();

      expect(find.byType(layoutType), findsOneWidget);
      expect(find.textContaining(category), findsOneWidget);
      expect(find.text('Gede Rifki Swastika Utama'), findsOneWidget);
      expect(find.text('NIM: 2415051095'), findsOneWidget);
    }
  });

  testWidgets('shows 2:1 panels and wraps six skill chips on narrow screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: LayoutPracticeSection()),
        ),
      ),
    );
    await tester.pump();

    final panelAWidth = tester
        .getSize(find.byKey(const ValueKey('panel-a')))
        .width;
    final panelBWidth = tester
        .getSize(find.byKey(const ValueKey('panel-b')))
        .width;
    final wrapChips = find.descendant(
      of: find.byType(Wrap),
      matching: find.byType(Chip),
    );

    expect(panelAWidth / panelBWidth, closeTo(2, 0.02));
    expect(wrapChips, findsNWidgets(6));
    expect(find.text('Row biasa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('course grid uses one, two, and three columns by width', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final courses = [
      {'code': 'C01', 'title': 'Course one', 'credits': 2, 'status': 'done'},
      {'code': 'C02', 'title': 'Course two', 'credits': 3, 'status': 'active'},
      {
        'code': 'C03',
        'title': 'Course three',
        'credits': 4,
        'status': 'planned',
      },
    ];
    final breakpoints = [(390.0, 1), (700.0, 2), (1000.0, 3)];

    for (final (width, expectedColumns) in breakpoints) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        withCourseState(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CourseGrid(
                  courses: courses.map(Course.fromJson).toList(),
                  studentName: 'Mahasiswa Tes',
                  studentNim: '123456',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, expectedColumns);
      expect(find.byType(CourseItemCard), findsNWidgets(courses.length));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('profile form scrolls when the keyboard reduces the viewport', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 700);

    await tester.pumpWidget(const MaterialApp(home: ProfileFormPage()));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('profile-form-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));

    await tester.ensureVisible(find.byKey(const ValueKey('profile-bio')));
    await tester.tap(find.byKey(const ValueKey('profile-bio')));
    await tester.showKeyboard(find.byKey(const ValueKey('profile-bio')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('profile-save')));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('profile-save'))).bottom,
      lessThanOrEqualTo(420),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens DetailPage and returns with both back controls', (
    WidgetTester tester,
  ) async {
    Future<void> pumpRouteTransition() async {
      await tester.pump();
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: HomePage(
            studentFuture: Future.value({
              'student': {
                'name': 'Gede Rifki Swastika Utama',
                'nim': '2415051095',
              },
              'courses': <Course>[],
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('open-detail')));
    await pumpRouteTransition();

    expect(find.byType(DetailPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DetailPage),
        matching: find.text('Detail Mahasiswa'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DetailPage),
        matching: find.text('Gede Rifki Swastika Utama'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DetailPage),
        matching: find.text('NIM: 2415051095'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('detail-pop')));
    await pumpRouteTransition();
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-detail')));
    await pumpRouteTransition();
    final appBarBackButton = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.arrow_back),
    );
    expect(appBarBackButton, findsOneWidget);
    await tester.tap(appBarBackButton);
    await pumpRouteTransition();

    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('course cards open detail with course and student data', (
    WidgetTester tester,
  ) async {
    final course = {
      'code': 'MOB01',
      'title': 'Flutter UI Fundamentals',
      'credits': 3,
      'status': 'active',
    };

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: Scaffold(
            body: CourseGrid(
              courses: [Course.fromJson(course)],
              studentName: 'Gede Rifki Swastika Utama',
              studentNim: '2415051095',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CourseItemCard));
    await tester.pumpAndSettle();

    expect(find.byType(CourseDetailPage), findsOneWidget);
    expect(find.text('Flutter UI Fundamentals'), findsOneWidget);
    expect(find.text('Kode: MOB01'), findsOneWidget);
    expect(find.text('Kredit: 3 SKS'), findsOneWidget);
    expect(find.text('Status: ACTIVE'), findsOneWidget);
    expect(find.text('Gede Rifki Swastika Utama'), findsOneWidget);
    expect(find.text('NIM: 2415051095'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('favorite-course')));
    await tester.pumpAndSettle();

    expect(find.byType(CourseDetailPage), findsNothing);
    expect(find.text('Course ditambahkan ke favorite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('course card toggles favorite and shows info on long press', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    final course = {
      'code': 'MOB01',
      'title': 'Flutter UI Fundamentals',
      'credits': 3,
      'status': 'active',
    };

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: CourseItemCard(
                  course: Course.fromJson(course),
                  onTap: () async {
                    tapped = true;
                    await Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final favoriteButton = find.byKey(const ValueKey('course-favorite-MOB01'));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(favoriteButton);
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tapped, isFalse);

    await tester.tap(favoriteButton);
    await tester.pump();
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.longPress(find.byType(CourseItemCard));
    await tester.pumpAndSettle();
    expect(
      find.text('Kode: MOB01\nKredit: 3 SKS\nStatus: ACTIVE'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Flutter UI Fundamentals'),
      ),
      findsOneWidget,
    );
    expect(tapped, isFalse);

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rapid repeated course taps start only one navigation action', (
    WidgetTester tester,
  ) async {
    var openCount = 0;
    final course = {
      'code': 'MOB02',
      'title': 'Dart Fundamentals',
      'credits': 2,
      'status': 'done',
    };

    await tester.pumpWidget(
      withCourseState(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: CourseItemCard(
                  course: Course.fromJson(course),
                  onTap: () async {
                    openCount++;
                    await Future<void>.delayed(
                      const Duration(milliseconds: 500),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CourseItemCard));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byType(CourseItemCard));
    await tester.pump(const Duration(milliseconds: 50));

    expect(openCount, 1);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
