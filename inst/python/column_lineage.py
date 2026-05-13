"""Column-level lineage extraction using sqlglot."""

import sqlglot
import sqlglot.lineage as lineage_mod


def extract_column_lineage(sql, dialect="duckdb", source_tables=None):
    """
    Extract column-level lineage from a SQL SELECT statement.

    Returns a dict:
        {
            "error": None | str,
            "results": [
                {
                    "output_column": str,
                    "source_table":  str,
                    "source_column": str,
                    "expression":    str,
                    "is_computed":   bool,
                }
            ]
        }
    """
    try:
        parsed = sqlglot.parse_one(sql, dialect=dialect)
    except sqlglot.errors.ParseError as exc:
        return {"error": str(exc), "results": []}

    # Build sources dict for lineage resolver if caller provided table mapping.
    sources = None
    if source_tables:
        sources = {alias: alias for alias in source_tables}

    results = []

    for sel in parsed.find_all(sqlglot.exp.Select):
        for expr in sel.expressions:
            output_col = expr.alias or (
                expr.name if hasattr(expr, "name") and expr.name else str(expr)
            )
            try:
                node = lineage_mod.lineage(
                    column=output_col,
                    sql=sql,
                    dialect=dialect,
                    sources=sources,
                )
                found_any = False
                for source in _walk_lineage_node(node):
                    results.append(
                        {
                            "output_column": output_col,
                            "source_table": source.get("table", ""),
                            "source_column": source.get("column", ""),
                            "expression": str(expr),
                            "is_computed": source.get("is_computed", False),
                        }
                    )
                    found_any = True
                if not found_any:
                    results.append(
                        {
                            "output_column": output_col,
                            "source_table": "",
                            "source_column": "",
                            "expression": str(expr),
                            "is_computed": True,
                        }
                    )
            except Exception:
                results.append(
                    {
                        "output_column": output_col,
                        "source_table": "",
                        "source_column": "",
                        "expression": str(expr),
                        "is_computed": True,
                    }
                )

    return {"error": None, "results": results}


def _walk_lineage_node(node, visited=None):
    """Recursively walk a sqlglot lineage tree to leaf source columns."""
    if visited is None:
        visited = set()
    node_id = id(node)
    if node_id in visited:
        return
    visited.add(node_id)

    if not node.downstream:
        # Leaf — actual source column reference
        name = node.name or ""
        if "." in name:
            table, col = name.split(".", 1)
        else:
            table, col = "", name
        yield {"table": table, "column": col, "is_computed": False}
    else:
        for child in node.downstream:
            yield from _walk_lineage_node(child, visited)
