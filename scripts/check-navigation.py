#!/usr/bin/env python3
"""Validate the canonical README navigation without external dependencies."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
README = ROOT / "README.md"
LINK = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
EXPECTED = {
    "course-materials/course/cours_complet.pdf",
    *{f"course-materials/td-guides/TD{i:02d}_{name}.pdf" for i, name in [
        (1, "autopsie_requete"), (2, "modele_menace_checkout"),
        (3, "revue_architecture_api"), (4, "cellule_incident")
    ]},
    *{f"course-materials/tp-guides/TP{i:02d}_{name}.pdf" for i, name in [
        (1, "observer_le_flux"), (2, "session_cookie_csrf"), (3, "autorisation_bola"),
        (4, "injections_xss_csrf"), (5, "fichiers_upload_ssrf_commande"),
        (6, "api_proxy_conteneurs"), (7, "base_devsecops_observabilite")
    ]},
}

def main() -> int:
    text = README.read_text(encoding="utf-8")
    errors: list[str] = []
    rows = re.findall(r"^\| Séance (\d{2}) \|", text, re.M)
    if rows != [f"{i:02d}" for i in range(1, 15)]:
        errors.append(f"séances README: {rows!r}")
    for target in LINK.findall(text):
        if re.match(r"^[a-z]+://", target) or target.startswith(("#", "mailto:")):
            continue
        clean = unquote(target.split("#", 1)[0])
        if clean and not (ROOT / clean).exists():
            errors.append(f"lien absent: {target}")
    for target in sorted(EXPECTED):
        if not (ROOT / target).is_file():
            errors.append(f"ressource canonique absente: {target}")
    if re.search(r"06_formateur|corrig[ée]|leaders-university|notes_formateur", text, re.I):
        errors.append("référence privée dans le README public")
    for problem in errors:
        print(f"[FAIL] {problem}")
    if errors:
        return 1
    print("[PASS] navigation: 14 séances, liens et ressources canoniques")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())

