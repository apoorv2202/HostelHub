# 🏠 HostelHub

> A real-time hostel management and campus services platform built with Flutter, Supabase, and Squidex CMS.

HostelHub is a mobile-first hostel management platform designed to bring everyday hostel services into a single application. It provides students and hostel staff with dedicated workflows for food ordering, maintenance requests, identity management, and hostel operations.

## ✨ Features

### 👨‍🎓 Student Portal

* Secure student registration and authentication
* Digital hostel/college ID management
* View and manage personal information
* Submit hostel maintenance and service requests
* Track request status in real time
* Access the campus night canteen
* Browse available food items
* Add items to cart and place orders
* Multiple payment method support

### 🍱 Night Canteen

* Real-time food availability
* Stock-aware ordering
* Cart management
* Order processing
* Role-specific canteen management

### 🛠️ Service Management

* Students can create maintenance/service tickets
* Staff can view and manage assigned requests
* Real-time updates for ticket status
* Separate workflows for different hostel staff roles

### 🔐 Authentication & Security

* Multi-role authentication
* Student, Canteen, Cleaner, and Warden workflows
* Supabase Row-Level Security (RLS)
* Private storage buckets for sensitive documents
* Environment-based configuration
* Role-based access control

## 🏗️ Architecture

```text
┌─────────────────────────────┐
│       Flutter Client        │
│                             │
│  Student │ Canteen │ Staff  │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│          Supabase           │
│                             │
│ Auth │ PostgreSQL │ Storage  │
│      │    + RLS   │         │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│        Squidex CMS          │
│                             │
│      Content Management     │
└─────────────────────────────┘
```

## 🛠️ Tech Stack

| Technology   | Purpose                                      |
| ------------ | -------------------------------------------- |
| Flutter      | Cross-platform mobile application            |
| Dart         | Application development                      |
| Supabase     | Authentication, PostgreSQL database, storage |
| PostgreSQL   | Relational data storage                      |
| Supabase RLS | Database-level authorization                 |
| Squidex CMS  | Content management                           |
| Git & GitHub | Version control                              |

## 🔒 Security

HostelHub uses multiple layers of security:

* Supabase Row-Level Security policies
* Role-based authorization
* Private storage buckets
* Environment variables for configuration
* No production secrets committed to the repository

> **Note:** Never commit your `.env` file or private API credentials to the repository. Use `.env.example` as a reference for required configuration.

## ⚙️ Getting Started

### Prerequisites

Make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio or another Flutter-compatible IDE
* A Supabase project
* A Squidex project

### Installation

Clone the repository:

```bash
git clone https://github.com/apoorv2202/HostelHub.git
cd HostelHub
```

Install dependencies:

```bash
flutter pub get
```

### Environment Configuration

Create a local `.env` file using `.env.example` as a template:

```text
.env.example → copy → .env
```

Fill in the required environment variables with your own project credentials.

**Do not commit `.env` to Git.**

Run the application:

```bash
flutter run
```

## 📁 Project Structure

```text
HostelHub/
├── android/
├── ios/
├── lib/
│   ├── ...
├── assets/
├── web/
├── windows/
├── .env.example
├── .gitignore
├── LICENSE
├── README.md
├── pubspec.yaml
└── ...
```

## 🔑 Environment Variables

The project uses environment variables for external services.

See `.env.example` for the required configuration:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

SQUIDEX_CLIENT_ID=your_client_id
SQUIDEX_CLIENT_SECRET=your_client_secret
SQUIDEX_APP_NAME=hostel-hub
SQUIDEX_API_URL=your_squidex_api_url
```

Use your own credentials locally.

## 🚀 Future Improvements

* Push notifications for service requests and orders
* Online payment integration
* Admin analytics dashboard
* Advanced order tracking
* Hostel-wide announcements
* Automated deployment pipeline
* Expanded staff management tools

## 📄 License

This project is licensed under the MIT License.

See the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Apoorv Anand**

Built as a full-stack mobile application project exploring Flutter, backend services, authentication, database security, and real-time application architecture.

