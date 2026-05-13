"""SQL dialect translation using sqlglot."""

import sqlglot


def translate_sql(sql, from_dialect, to_dialect):
    """
    Transpile *sql* from *from_dialect* to *to_dialect*.

    Returns a dict:
        {"sql": str, "error": None | str}

    On failure the original SQL is returned and "error" is set.
    """
    try:
        translated = sqlglot.transpile(
            sql,
            read=from_dialect,
            write=to_dialect,
            pretty=False,
        )
        result_sql = translated[0] if translated else sql
        return {"sql": result_sql, "error": None}
    except Exception as exc:
        return {"sql": sql, "error": str(exc)}
