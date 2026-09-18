ALLOWED_REPORTS = {"daily", "weekly"}


def build_report_argv(kind: str) -> list[str]:
    """Retourner une liste d'arguments; ne jamais exécuter de shell."""
    raise NotImplementedError("à compléter avec une allowlist")
