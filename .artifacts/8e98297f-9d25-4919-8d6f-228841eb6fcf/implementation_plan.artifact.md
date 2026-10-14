# Implementation Plan - Favorite Status on DetailPage, FavoritesPage, and Cross-Screen Consistency

## Problem Description

The user wants to implement three new features/improvements:
1. **56. Tampilkan status favorite pada DetailPage**: Show favorite status and a toggle button directly on `CourseDetailPage`.
2. **57. Buat FavoritesPage yang hanya menampilkan course favorite**: Create a `FavoritesPage` that displays only favorite courses.
3. **58. Toggle dari list/detail dan pastikan screen lain ikut konsisten**: Ensure that toggling favorites from any screen (list, grid, detail, or favorites page) immediately updates all other screens in real-time via `CourseState`.

## User Review Required

> [!IMPORTANT]
> - `FavoritesPage` will be added as a new navigation destination (tab) in `MainNavigationPage` (Home, Courses, Favorites, Profile) and also accessible via navigation.
> - `CourseDetailPage` will be updated to use `Consumer<CourseState>` so users can view and toggle the favorite status directly.

## Open Questions

- None. The architecture with `CourseState` and `ChangeNotifier` already supports reactive updates.

## Proposed Changes

### [main.dart]

#### [MODIFY] [main.dart](file:///C:/flutter_ui_fundamentals/flutter_ui_fundamentals/lib/main.dart)
- Update `MainNavigationPage` navigation bar and rail to include a 4th tab: **Favorites** (`FavoritesPage`).
- Update `CourseDetailPage` to wrap content with `Consumer<CourseState>` or use `context.watch<CourseState>()`, displaying favorite status and a toggle action button.
- Implement `FavoritesPage` widget that fetches/loads courses and filters them by `courseState.favorites`.

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure existing tests pass and add new unit/widget tests for `FavoritesPage` and favorite toggling from `CourseDetailPage`.

### Manual Verification
- Deploy/run app on device or emulator and verify:
  1. Toggling favorite on `CourseItemCard` updates `FavoritesPage` and `CourseDetailPage`.
  2. Toggling favorite on `CourseDetailPage` updates Home, Courses, and `FavoritesPage`.
  3. `FavoritesPage` correctly lists only favorited courses or shows empty state when none are favorited.
