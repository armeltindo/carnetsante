import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/family/family_screen.dart';
import '../../presentation/family/family_member_form_screen.dart';
import '../../presentation/family/family_member_detail_screen.dart';
import '../../presentation/treatments/treatments_screen.dart';
import '../../presentation/treatments/treatment_form_screen.dart';
import '../../presentation/periodic_treatments/periodic_treatments_screen.dart';
import '../../presentation/periodic_treatments/periodic_treatment_form_screen.dart';
import '../../presentation/medical_history/medical_history_screen.dart';
import '../../presentation/medical_history/medical_record_form_screen.dart';
import '../../presentation/vitals/vitals_screen.dart';
import '../../presentation/vitals/vital_form_screen.dart';
import '../../presentation/documents/documents_screen.dart';
import '../../presentation/reminders/reminders_screen.dart';
import '../../presentation/shared/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/family',
            builder: (_, __) => const FamilyScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const FamilyMemberFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => FamilyMemberDetailScreen(
                  memberId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => FamilyMemberFormScreen(
                      memberId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/treatments',
            builder: (_, state) => TreatmentsScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => TreatmentFormScreen(
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => TreatmentFormScreen(
                  treatmentId: state.pathParameters['id'],
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/periodic-treatments',
            builder: (_, state) => PeriodicTreatmentsScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => PeriodicTreatmentFormScreen(
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => PeriodicTreatmentFormScreen(
                  treatmentId: state.pathParameters['id'],
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/medical-history',
            builder: (_, state) => MedicalHistoryScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => MedicalRecordFormScreen(
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => MedicalRecordFormScreen(
                  recordId: state.pathParameters['id'],
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/vitals',
            builder: (_, state) => VitalsScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => VitalFormScreen(
                  memberId: state.uri.queryParameters['memberId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/documents',
            builder: (_, state) => DocumentsScreen(
              memberId: state.uri.queryParameters['memberId'],
            ),
          ),
          GoRoute(
            path: '/reminders',
            builder: (_, __) => const RemindersScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page introuvable: ${state.error}'),
      ),
    ),
  );
});
