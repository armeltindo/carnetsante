# Carnet Santé Familial

Application mobile Flutter de gestion de la santé familiale, avec synchronisation Supabase et fonctionnement offline-first.

## Fonctionnalités

- **Membres de la famille** : profils, groupe sanguin, allergies, antécédents
- **Traitements** : médicaments ponctuels avec rappels automatiques
- **Traitements périodiques** : antipaludiques, déparasitage, vaccins (calcul auto de la prochaine date)
- **Historique médical** : consultations, diagnostics, symptômes
- **Constantes** : température, tension, glycémie, poids avec graphiques
- **Documents** : ordonnances, analyses (upload Supabase Storage)
- **Rappels** : notifications locales, fonctionne sans internet
- **Dark mode** : interface claire/sombre
- **Offline-first** : tout fonctionne sans connexion, sync auto dès retour

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Flutter 3.x |
| State Management | Riverpod 2 |
| Navigation | GoRouter |
| Local Storage | Hive |
| Backend | Supabase (PostgreSQL) |
| Auth | Supabase Auth |
| Fichiers | Supabase Storage |
| Notifications | flutter_local_notifications |
| Graphiques | fl_chart |

## Architecture

```
lib/
├── core/          # Constantes, thème, routeur, utilitaires
├── domain/        # Entités + interfaces repositories (Clean Architecture)
├── data/          # Implémentations (Hive local + Supabase remote)
├── services/      # Notifications, sync, connectivité
└── presentation/  # Écrans + providers Riverpod
```

## Installation

### 1. Cloner le projet

```bash
git clone https://github.com/armeltindo/carnetsante.git
cd carnetsante
```

### 2. Configurer Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Exécuter les migrations dans l'éditeur SQL :
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_rls_policies.sql`
3. Créer le bucket Storage `medical-documents` (privé)
4. Copier vos clés API

### 3. Configurer les variables d'environnement

```bash
# Pour le développement local:
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Ou modifiez directement `lib/core/constants/app_constants.dart`.

### 4. Installer les dépendances

```bash
flutter pub get
```

### 5. Générer les fichiers Hive

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 6. Lancer l'application

```bash
flutter run
```

## Déploiement

### Android

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### iOS

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

### Web (Vercel)

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

Puis déployer le dossier `build/web/` sur Vercel.

#### Variables d'environnement Vercel

Dans le dashboard Vercel, configurez :
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Et dans `vercel.json` :

```json
{
  "buildCommand": "flutter build web --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY",
  "outputDirectory": "build/web"
}
```

## Configuration Supabase Auth

Dans le dashboard Supabase → Authentication → URL Configuration :

- **Site URL** : `https://your-app.vercel.app` (ou `io.supabase.carnetsante://login-callback/` pour mobile)
- **Redirect URLs** : Ajouter `io.supabase.carnetsante://login-callback/`

## Données de test

Exécuter `supabase/migrations/003_seed_data.sql` après avoir remplacé l'UUID utilisateur.

## Contribution

1. Fork le projet
2. Créer une branche feature : `git checkout -b feature/ma-feature`
3. Commit : `git commit -m "feat: ma feature"`
4. Push et créer une PR

## Licence

MIT
