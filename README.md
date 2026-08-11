# Blogorum

**Blogorum** is a forum-style blog web application built with **Flutter, Provider, go_router, and Supabase**.

It combines blogging and social features, allowing users to create and manage posts, upload multiple images, interact through likes and comments, search for posts and users, manage their profiles, and hide posts from their feed.

**Live Demo:** https://blogorum.netlify.app

## Features

### Authentication

* Email and password registration
* Login and logout
* Forgot password
* Authentication-aware navigation
* User profiles

### Posts

* Create, edit, and delete posts
* Upload multiple images per post
* Add and remove images when editing posts
* Paginated public feed
* Refresh feed
* Hide and unhide posts
* Post detail pages
* Multiple-image galleries with navigation

### Search

* Search posts by title
* Search posts by username

### Likes

* Like and unlike posts
* Display like counts
* Like interactions available to authenticated users

### Comments

* Add, edit, and delete comments
* Upload multiple images with comments
* Add and remove comment images
* Display comment counts

### Profiles

* View user profiles
* Update display name
* Upload, update, and delete profile photos

### UI

* Responsive web layout
* Light and dark themes
* Sidebar navigation
* Search bar
* Create-post shortcut
* Post actions menu
* Image galleries with navigation controls

## Screenshots

### Feed — Light Mode

![Blogorum feed in light mode](screenshots/feed-light.png)

### Feed — Dark Mode

![Blogorum feed in dark mode](screenshots/feed-dark.png)

### User Profile

![Blogorum user profile](screenshots/profile.png)

### Hidden Posts

![Blogorum hidden posts](screenshots/hidden-posts.png)

### Create Post

![Blogorum create post page](screenshots/create-post.png)

### Post Detail

![Blogorum post detail page](screenshots/post-detail.png)

### Comments

![Blogorum comments](screenshots/comments.png)

### Comment Interaction Demo

![Blogorum comment interaction demo](screenshots/comments-demo.gif)

## Tech Stack

| Technology       | Purpose                              |
| ---------------- | ------------------------------------ |
| Flutter          | Cross-platform application framework |
| Dart             | Programming language                 |
| go_router        | Routing and navigation               |
| Supabase         | Backend platform                     |
| PostgreSQL       | Relational database                  |
| Supabase Auth    | User authentication                  |
| Supabase Storage | Image storage                        |

## Architecture

Blogorum uses Flutter for the application layer and Supabase for backend services.

```text
Flutter
├── UI / Pages
├── Reusable Components
├── Provider
│   ├── Authentication / Profile State
│   └── Theme State
├── go_router
└── Supabase Flutter SDK
    ├── Authentication
    ├── PostgreSQL Database
    └── Storage
```

Provider is used for shared application state, while local widget state is used for page-specific UI state.

Supabase handles authentication, database operations, and image storage. Row Level Security (RLS) policies are used to control access to user-owned data and interactions.

## Getting Started

### Prerequisites

* Flutter SDK
* Dart SDK
* A Supabase project

Verify your Flutter installation:

```bash
flutter doctor
```

### Installation

Clone the repository:

```bash
git clone https://github.com/EjayEspedido/Blogorum.git
cd Blogorum
```

Install dependencies:

```bash
flutter pub get
```

### Supabase Configuration

Blogorum requires a Supabase project configured with:

* PostgreSQL database tables
* Row Level Security (RLS) policies
* Authentication settings
* Storage buckets for uploaded images

The application uses the public Supabase project configuration required by the Flutter client.

**Never commit Supabase service-role keys, passwords, or other private credentials to the repository.**

## Running the Project

Run the application locally:

```bash
flutter run
```

Run the web version in Chrome:

```bash
flutter run -d chrome
```

Build the production web version:

```bash
flutter build web
```

The production files are generated in:

```text
build/web/
```

## Database

Blogorum uses Supabase PostgreSQL for application data, including:

* User profiles
* Posts
* Comments
* Likes
* Hidden posts

Row Level Security policies are used to enforce access control for user-generated content and interactions.

## Development

Before committing changes, run:

```bash
flutter analyze
```

Run the test suite:

```bash
flutter test
```

It is also recommended to verify the production web build:

```bash
flutter build web
```

## Current Limitations

* Mobile optimization still needs improvement.
* Search is currently limited to post titles and usernames.
* Notifications are not implemented yet.
* Moderation and reporting features are not implemented yet.

## Planned Features

* Improve mobile responsiveness.
* Expand search to support broader keyword searching.
* Add notifications.
* Add post categories and tags.
* Expand user profile features.
* Add moderation and reporting tools.

---

**Built with Flutter and Supabase.**
