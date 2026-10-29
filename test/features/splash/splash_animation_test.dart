import 'package:bizos/core/constants/app_images.dart';
import 'package:bizos/core/theme/app_colors.dart';
import 'package:bizos/core/theme/app_theme.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_event.dart';
import 'package:bizos/features/auth/presentation/bloc/auth_state.dart';
import 'package:bizos/features/auth/presentation/screens/auth_onboarding_screen.dart';
import 'package:bizos/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthBloc extends Fake implements AuthBloc {
  final AuthState _state;

  FakeAuthBloc([AuthState? state]) : _state = state ?? AuthInitial();

  @override
  AuthState get state => _state;

  @override
  Stream<AuthState> get stream => Stream.value(_state);

  @override
  void add(AuthEvent event) {}

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Voryn Splash Animation & Motion Tests', () {
    testWidgets(
      'Renders Voryn gradient logo with Fade, Scale, and Slide transitions',
      (tester) async {
        final fakeBloc = FakeAuthBloc();
        bool completed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider<AuthBloc>.value(
              value: fakeBloc,
              child: SplashScreen(
                onAnimationComplete: () {
                  completed = true;
                },
              ),
            ),
          ),
        );

        // Verify logo transitions exist
        expect(find.byType(FadeTransition), findsWidgets);
        expect(find.byType(ScaleTransition), findsWidgets);
        expect(find.byType(SlideTransition), findsWidgets);

        // Verify Image asset uses Voryn gradient logo
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final imageWidget = tester.widget<Image>(imageFinder);
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals(AppImages.vorynGradientLogo));

        await tester.pump(const Duration(milliseconds: 1450));
        expect(completed, isTrue);
      },
    );

    testWidgets(
      'Applies splashScreenLightBackground in Light mode',
      (tester) async {
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            home: BlocProvider<AuthBloc>.value(
              value: fakeBloc,
              child: SplashScreen(onAnimationComplete: () {}),
            ),
          ),
        );

        final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          lightScaffold.backgroundColor,
          equals(AppColors.splashScreenLightBackground),
        );
      },
    );

    testWidgets(
      'Applies darkBg in Dark mode',
      (tester) async {
        final fakeBloc = FakeAuthBloc();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: BlocProvider<AuthBloc>.value(
              value: fakeBloc,
              child: SplashScreen(onAnimationComplete: () {}),
            ),
          ),
        );

        final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(darkScaffold.backgroundColor, equals(AppTheme.darkBg));
      },
    );

    testWidgets(
      'Animation sequence completes in approx 1.4s and invokes onAnimationComplete',
      (tester) async {
        final fakeBloc = FakeAuthBloc();
        bool animationFinished = false;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: fakeBloc,
              child: SplashScreen(
                onAnimationComplete: () {
                  animationFinished = true;
                },
              ),
            ),
          ),
        );

        // Initially not finished
        expect(animationFinished, isFalse);

        // Advance 700ms (midway through Phase A & B)
        await tester.pump(const Duration(milliseconds: 700));
        expect(animationFinished, isFalse);

        // Advance remaining duration to reach 1400ms completion
        await tester.pump(const Duration(milliseconds: 750));
        expect(animationFinished, isTrue);
      },
    );

    testWidgets(
      'Honors reduced-motion accessibility preference immediately',
      (tester) async {
        final fakeBloc = FakeAuthBloc();
        bool animationFinished = false;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: BlocProvider<AuthBloc>.value(
                value: fakeBloc,
                child: SplashScreen(
                  onAnimationComplete: () {
                    animationFinished = true;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        // With disableAnimations, finishes immediately without animation delay
        expect(animationFinished, isTrue);
      },
    );

    testWidgets(
      'Standalone mode: Navigates to AuthOnboardingScreen when unauthenticated',
      (tester) async {
        final fakeBloc = FakeAuthBloc(AuthUnauthenticated());

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: fakeBloc,
            child: const MaterialApp(
              home: SplashScreen(),
            ),
          ),
        );

        // Complete 1.4s animation
        await tester.pump(const Duration(milliseconds: 1450));
        // Complete 350ms route transition
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(AuthOnboardingScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
      },
    );

    testWidgets(
      'Holding resting state when isWaitingForAuth is true',
      (tester) async {
        final fakeBloc = FakeAuthBloc(AuthLoading());

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AuthBloc>.value(
              value: fakeBloc,
              child: const SplashScreen(isWaitingForAuth: true),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(SplashScreen), findsOneWidget);

        // Remains on splash screen without crashing or navigating prematurely
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(SplashScreen), findsOneWidget);
      },
    );
  });
}
