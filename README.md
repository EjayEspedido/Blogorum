# Blogorum

A modern forum-style blog website built with Flutter and Supabase.

Blogorum allows users to create, browse, search, edit, and interact with posts in a simple social blogging experience.

## Features

* User authentication

  * Sign up and log in
  * Forgot password support
  * User profiles
* Posts

  * Create posts
  * Edit posts
  * Delete posts
  * Search posts by title
  * Search posts by username
  * Pagination
  * Pull-to-refresh
* Likes

  * Like and unlike posts
  * Like counts
  * Logged-in users only
* Comments

  * Add comments
  * Edit comments
  * Delete comments
  * Comment counts
* Images

  * Upload images to posts
  * Delete uploaded images when posts are removed or edited
* UI

  * Responsive web interface
  * Light and dark themes
  * Navigation sidebar
  * Top navigation bar
  * Floating navigation controls

## Tech Stack

| Technology       | Purpose              |
| ---------------- | -------------------- |
| Flutter          | Frontend framework   |
| Dart             | Programming language |
| Supabase         | Backend and database |
| PostgreSQL       | Database             |
| Supabase Auth    | User authentication  |
| Supabase Storage | Image storage        |

## Project Structure

```
lib/
├── main.dart
├── pages/
│   ├── FeedPage.dart
│   ├── login.dart
│   └── ...
├── widgets/
│   ├── post_card.dart
│   ├── commentCard.dart
│   ├── commentList.dart
│   ├── topBar.dart
│   └── ...
├── services/
│   ├── getPosts.dart
│   ├── getComments.dart
│   └── ...
└── ...
```

> The exact folder structure may vary depending on the current implementation.

## Getting Started

### Prerequisites

Make sure you have the following installed:

* [Flutter](https://flutter.dev/)
* Dart
* A Supabase project
* Git

Check your Flutter installation with:

```bash
flutter doctor
```

### Installation

Clone the repository:

```
git clone <YOUR_REPOSITORY_URL>
cd blogorum
```

Install dependencies:

```
flutter pub get
```

### Supabase Configuration

Blogorum uses Supabase for authentication, database operations, and storage.

Create a Supabase project and configure the required database tables, authentication, and storage buckets.

Then configure the Supabase credentials used by the Flutter application.

**Do not commit private Supabase credentials or service-role keys to GitHub.**

## Running the Project

Run the application locally with:

```
flutter run
```

For Flutter Web:

```
flutter run -d chrome
```

## Building for Web

To create a production web build:

```
flutter build web
```

The generated files will be placed in:

```
build/web/
```

## Database

The application uses PostgreSQL through Supabase.

The database handles data such as:

* Users / profiles
* Posts
* Comments
* Likes

Row Level Security (RLS) policies are used to control which users can create, update, delete, and interact with data.

## Authentication

Authentication is handled through Supabase Auth.

Users can:

* Register an account
* Log in
* Log out
* Reset their password
* Access authenticated features

Some actions, such as liking posts, require the user to be logged in.

## Search

Blogorum supports searching across the feed.

Search can be used to find:

* Post titles
* Posts created by a specific user

## Development

Before committing changes, it is recommended to run:

```
flutter analyze
```

and:

```
flutter test
```

If everything is clean, build the web version to verify that the project compiles successfully:

```
flutter build web
```

## Roadmap

Potential future improvements include:

* Better mobile optimization
* More advanced profile pages
* Notifications
* Post categories or tags
* Rich text editing
* Improved image handling
* More detailed user settings
* Additional moderation features

## License

This project is currently for educational and development purposes.

A formal open-source license can be added later if the project is intended for public contribution or redistribution.

---

Built with Flutter and Supabase.
