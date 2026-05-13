"""Boolean expression decomposition using sqlglot."""

import sqlglot
import sqlglot.expressions as exp


def decompose_boolean(sql_expr, dialect="duckdb"):
    """
    Decompose a SQL boolean expression into a tree.

    The expression is wrapped in a SELECT/WHERE to parse it as a full
    statement, then the WHERE clause is walked recursively.

    Returns a nested dict:
        {
            "op": "AND" | "OR" | "NOT" | "LEAF",
            "children": [...],      # non-LEAF nodes
            "expr": str,            # LEAF nodes
            "columns": [str, ...],  # LEAF nodes
            "error": str,           # present when parse failed
        }
    """
    try:
        wrapped = f"SELECT * FROM t WHERE {sql_expr}"
        parsed = sqlglot.parse_one(wrapped, dialect=dialect)
        where = parsed.find(exp.Where)
        if where is None:
            return _leaf(sql_expr, [])
        return _walk(where.this)
    except Exception as exc:
        return {
            "op": "LEAF",
            "expr": sql_expr,
            "columns": [],
            "error": str(exc),
        }


def _walk(node):
    if isinstance(node, exp.And):
        return {"op": "AND", "children": [_walk(node.left), _walk(node.right)]}
    if isinstance(node, exp.Or):
        return {"op": "OR", "children": [_walk(node.left), _walk(node.right)]}
    if isinstance(node, exp.Not):
        return {"op": "NOT", "children": [_walk(node.this)]}
    if isinstance(node, exp.Paren):
        return _walk(node.this)
    # Leaf: anything that is not a boolean combinator
    cols = [c.name for c in node.find_all(exp.Column)]
    return _leaf(node.sql(dialect="duckdb"), cols)


def _leaf(expr_str, columns):
    return {"op": "LEAF", "expr": expr_str, "columns": columns}
