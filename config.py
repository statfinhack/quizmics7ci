"""
config.py — Configuration centralisée
Priorité : st.secrets → variables d'environnement → valeurs par défaut
"""

import os
import streamlit as st


def _get(key: str, default: str = "") -> str:
    """Lit une valeur dans l'ordre : st.secrets → os.environ → default."""
    try:
        val = st.secrets.get(key)
        if val is not None:
            return str(val)
    except Exception:
        pass
    return os.environ.get(key, default)


# ── Paramètres de l'application ──────────────────────────────────────────────
ADMIN_PASSWORD: str = _get("ADMIN_PASSWORD", "admin2026")
APP_TITLE:      str = _get("APP_TITLE",      "QuizAgent CI")
DB_PATH:        str = _get("DB_PATH",         "data/quiz_app.db")

# ── Informations affichées ────────────────────────────────────────────────────
APP_SUBTITLE:   str = _get("APP_SUBTITLE", "Plateforme d'évaluation des agents")
ORG_NAME:       str = _get("ORG_NAME",    "")

# ── Supabase (projet 2) ───────────────────────────────────────────────────────
# URL + clé anon/publique : publiques par conception (déjà dans agent/config.js)
SUPABASE_URL:      str = _get("SUPABASE_URL",      "https://rmmizzwnierlvnojemna.supabase.co")
SUPABASE_ANON_KEY: str = _get("SUPABASE_ANON_KEY", "sb_publishable_YzddlCUxqC66kaJiP7du4g_mOSf1yGY")
# DATABASE_URL (Transaction pooler, port 6543) est lue directement par database.py
