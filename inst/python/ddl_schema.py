"""DDL (CREATE TABLE) schema extraction using sqlglot."""

import sqlglot
import sqlglot.expressions as exp


def extract_ddl_schema(ddl, dialect="duckdb"):
    """
    Parse one or more CREATE TABLE statements and return schema info.

    Returns a list of dicts:
        [
            {
                "table_name":   str,
                "columns":      [{"name", "type", "nullable", "is_pk"}, ...],
                "primary_keys": [str, ...],
                "foreign_keys": [{"columns", "ref_table", "ref_columns"}, ...]
            }
        ]
    """
    tables = []

    for statement in sqlglot.parse(ddl, dialect=dialect):
        if not isinstance(statement, exp.Create):
            continue

        tbl_node = statement.find(exp.Table)
        if tbl_node is None:
            continue
        table_name = tbl_node.name

        cols, pks, fks = [], [], []

        for col_def in statement.find_all(exp.ColumnDef):
            col_type  = col_def.kind.sql() if col_def.kind else "TEXT"
            nullable  = not any(
                isinstance(c.args.get("this"), exp.NotNullColumnConstraint)
                for c in col_def.args.get("constraints", [])
            )
            is_pk = any(
                isinstance(c.args.get("this"), exp.PrimaryKeyColumnConstraint)
                for c in col_def.args.get("constraints", [])
            )
            cols.append(
                {
                    "name":     col_def.name,
                    "type":     col_type,
                    "nullable": nullable,
                    "is_pk":    is_pk,
                }
            )
            if is_pk:
                pks.append(col_def.name)

        # Table-level PRIMARY KEY constraint
        for pk_constraint in statement.find_all(exp.PrimaryKey):
            for ident in pk_constraint.find_all(exp.Identifier):
                pk_name = ident.name
                if pk_name not in pks:
                    pks.append(pk_name)
                # Mark column as pk
                for col in cols:
                    if col["name"] == pk_name:
                        col["is_pk"] = True

        # FOREIGN KEY constraints
        for fk in statement.find_all(exp.ForeignKey):
            fk_cols = [i.name for i in fk.find_all(exp.Identifier)
                       if i.find_ancestor(exp.Reference) is None]
            ref_node = fk.find(exp.Reference)
            ref_table   = ""
            ref_columns = []
            if ref_node is not None:
                ref_tbl = ref_node.find(exp.Table)
                if ref_tbl:
                    ref_table = ref_tbl.name
                ref_columns = [i.name for i in ref_node.find_all(exp.Identifier)]
            fks.append(
                {
                    "columns":     fk_cols,
                    "ref_table":   ref_table,
                    "ref_columns": ref_columns,
                }
            )

        tables.append(
            {
                "table_name":   table_name,
                "columns":      cols,
                "primary_keys": pks,
                "foreign_keys": fks,
            }
        )

    return tables
