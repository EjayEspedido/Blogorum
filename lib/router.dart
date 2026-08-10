import 'package:blogorum/pages/FeedPage.dart';
import 'package:go_router/go_router.dart';
import 'pages/login.dart';
import 'pages/posts_page.dart';
import 'pages/create_post.dart';
import 'pages/edit_post.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

final router = GoRouter(
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentUser != null;
    final path = state.matchedLocation;

    final isProtected = path == '/createPost' || path.startsWith('/editPost/');

    if (!loggedIn && isProtected) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => FeedPage()),

    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    GoRoute(
      path: '/posts/:id',
      builder: (context, state) {
        return PostPage(postID: state.pathParameters['id']!);
      },
    ),

    GoRoute(path: '/createPost', builder: (context, state) => CreatePost()),

    GoRoute(
      path: '/editPost/:id',
      builder: (context, state) {
        return EditPost(postID: state.pathParameters['id']!);
      },
    ),
  ],
);
