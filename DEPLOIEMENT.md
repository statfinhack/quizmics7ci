# Déploiement QuizAgent — Guide complet

> Pour chaque nouveau projet (RGPH, EMI-CIV, SURGO…), suivre les 3 étapes dans l'ordre.

---

## ÉTAPE 1 — Supabase (base de données)

### 1.1 Créer le projet
1. [supabase.com](https://supabase.com) → **New project**
2. Nom : ex. `quizagent-rgph`
3. Région : **West EU (Frankfurt)**
4. Cliquer **Create new project** — attendre ~2 min

### 1.2 Récupérer les clés
**Settings → API** — noter :
- **Project URL** : `https://XXXXXXXX.supabase.co`
- **anon public key** : `sb_publishable_XXXXXX`

**Settings → Database → Connection string → Transaction pooler** — noter :
- URL (port 6543) : `postgresql://postgres.XXXXX:MOT_DE_PASSE@aws-0-eu-central-1.pooler.supabase.com:6543/postgres`

### 1.3 Créer les tables et politiques RLS
**SQL Editor → New query** → coller tout le fichier `SUPABASE_SETUP.sql` → **Run**

---

## ÉTAPE 2 — GitHub (pages agents)

### 2.1 Créer le repo
1. GitHub → **New repository** : ex. `quizagent-rgph` (⚠️ doit être **Public** pour GitHub Pages gratuit)
2. Pousser les fichiers du dossier `agent/` :
```
quizagent-rgph/
├── agent/
│   ├── config.js       ← SEUL FICHIER À MODIFIER
│   ├── index.html
│   ├── quiz.html
│   ├── result.html
│   └── correction.html
└── .nojekyll
```

### 2.2 Modifier config.js (SEULE modification nécessaire)
```javascript
const PROJECT_NAME = "QuizAgent RGPH";          // ← nom du projet
const SUPA_URL     = "https://NOUVEAU.supabase.co";  // ← URL Supabase étape 1.2
const SUPA_KEY     = "sb_publishable_NOUVELLE_CLE";  // ← clé anon étape 1.2
```

### 2.3 Activer GitHub Pages
**Settings → Pages** → Source : `Deploy from a branch` → branch `main` → dossier `/ (root)` → **Save**

URL agents : `https://TON_COMPTE.github.io/quizagent-rgph/agent/`

---

## ÉTAPE 3 — Render (admin Streamlit)

### 3.1 Créer le service
1. [render.com](https://render.com) → **New → Web Service**
2. Connecter le repo GitHub `quizagent-rgph`
3. Paramètres :
   - **Runtime** : Python 3
   - **Build command** : `pip install -r requirements.txt`
   - **Start command** : `streamlit run app.py --server.port $PORT --server.address 0.0.0.0`
   - **Plan** : Starter ($7/mo) pour la persistance

### 3.2 Variables d'environnement
| Variable | Valeur |
|---|---|
| `DATABASE_URL` | URL Transaction Pooler Supabase (port 6543) |
| `APP_TITLE` | `QuizAgent RGPH` |
| `APP_SUBTITLE` | `Évaluation des agents de terrain` |
| `ORG_NAME` | `ANStat / Cabinet WELMAT` |
| `ADMIN_PASSWORD` | Ton mot de passe admin |

### 3.3 Déployer
Cliquer **Create Web Service** → attendre 3-4 minutes → URL Render = interface admin.

---

## Résumé — Changer de projet

| Fichier / Endroit | Ce qu'on change |
|---|---|
| `agent/config.js` | `PROJECT_NAME`, `SUPA_URL`, `SUPA_KEY` |
| Variables Render | `APP_TITLE`, `DATABASE_URL`, `ADMIN_PASSWORD` |
| Supabase | Nouveau projet + SUPABASE_SETUP.sql |
| `app.py`, `database.py`, `config.py` | **Rien** — déjà généralisés |

---

## Correction bug RLS (soumission quiz bloquée)

Si les agents voient `"Erreur lors de la soumission : new row violates row-level security policy for table 'answers'"`,
exécuter dans SQL Editor :

```sql
CREATE POLICY "public_insert_answers" ON answers
  FOR INSERT TO anon WITH CHECK (true);
```

Ce SQL est déjà inclus dans `SUPABASE_SETUP.sql`.
