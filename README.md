# Carnet Santé Familial

Application web PWA de gestion de la santé familiale, avec synchronisation Supabase.

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Frontend | Next.js 14 (App Router) |
| Language | TypeScript |
| UI | Tailwind CSS + Radix UI |
| State | TanStack React Query |
| Backend | Supabase (PostgreSQL + Auth + Storage) |
| Graphiques | Recharts |
| Formulaires | React Hook Form + Zod |
| Déploiement | Vercel |

## Fonctionnalités

- **Membres de la famille** : profils, groupe sanguin, allergies, photo
- **Traitements** : médicaments avec suivi actif/inactif
- **Traitements périodiques** : antipaludiques, déparasitage, vaccins (calcul auto de la prochaine date)
- **Historique médical** : consultations, diagnostics, symptômes
- **Constantes** : température, tension, glycémie, poids avec graphiques
- **Documents** : ordonnances, analyses (upload Supabase Storage)
- **Rappels** : notifications navigateur, récurrence configurable
- **PWA** : installable sur mobile et desktop

## Installation locale

### 1. Cloner le projet

```bash
git clone https://github.com/armeltindo/carnetsante.git
cd carnetsante
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer les variables d'environnement

```bash
cp .env.example .env.local
```

Remplissez `.env.local` avec vos clés Supabase :

```
NEXT_PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Configurer Supabase

1. Créer un projet sur [supabase.com](https://supabase.com)
2. Exécuter les migrations dans l'éditeur SQL :
   - `supabase/migrations/001_initial_schema.sql`
   - `supabase/migrations/002_rls_policies.sql`
3. Créer le bucket Storage `medical-documents` (privé)
4. Dans Authentication → URL Configuration, ajouter `http://localhost:3000` aux Redirect URLs

### 5. Lancer l'application

```bash
npm run dev
```

## Déploiement Vercel

1. Importer le dépôt dans [vercel.com](https://vercel.com)
2. Dans **Settings → Environment Variables**, ajouter :
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
3. Dans **Settings → Build & Development Settings** :
   - Framework Preset : **Next.js**
   - Build Command : laisser vide (auto-détecté)
   - Output Directory : laisser vide
4. Déployer

Dans Supabase → Authentication → URL Configuration, ajouter l'URL de production aux Redirect URLs.

## Licence

MIT
