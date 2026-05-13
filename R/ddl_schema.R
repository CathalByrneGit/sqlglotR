#' Parse DDL statements to extract schema information
#'
#' Parses one or more `CREATE TABLE` statements and returns the table
#' structure: column definitions, primary keys, and foreign key references.
#'
#' @param ddl     Character. One or more `CREATE TABLE` statements as a
#'   single string (statements separated by semicolons).
#' @param dialect Character. SQL dialect of the DDL. Default `"duckdb"`.
#'
#' @return A list of table specs. Each spec is a named list:
#'   \describe{
#'     \item{table_name}{Character. The table name.}
#'     \item{columns}{Data frame with columns `name`, `type`, `nullable`,
#'       `is_pk`.}
#'     \item{primary_keys}{Character vector of PK column names.}
#'     \item{foreign_keys}{List of FK specs, each with `columns`,
#'       `ref_table`, `ref_columns`.}
#'   }
#' @export
sg_extract_ddl_schema <- function(ddl, dialect = "duckdb") {
  .sqlglot()

  mod    <- .get_py_module("ddl_schema")
  tables <- mod$extract_ddl_schema(ddl, dialect)

  lapply(tables, function(tbl) {
    cols_raw <- tbl[["columns"]]
    cols_df  <- if (length(cols_raw) == 0L) {
      data.frame(name = character(), type = character(),
                 nullable = logical(), is_pk = logical(),
                 stringsAsFactors = FALSE)
    } else {
      do.call(rbind, lapply(cols_raw, function(col) {
        data.frame(
          name     = as.character(col[["name"]]),
          type     = as.character(col[["type"]]),
          nullable = as.logical(col[["nullable"]]),
          is_pk    = as.logical(col[["is_pk"]]),
          stringsAsFactors = FALSE
        )
      }))
    }

    fks_raw <- tbl[["foreign_keys"]]
    fks     <- lapply(fks_raw, function(fk) {
      list(
        columns     = as.character(unlist(fk[["columns"]])),
        ref_table   = as.character(fk[["ref_table"]]),
        ref_columns = as.character(unlist(fk[["ref_columns"]]))
      )
    })

    list(
      table_name   = as.character(tbl[["table_name"]]),
      columns      = cols_df,
      primary_keys = as.character(unlist(tbl[["primary_keys"]])),
      foreign_keys = fks
    )
  })
}
