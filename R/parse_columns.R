#' Extract column-level lineage from a SQL expression
#'
#' For each output column in the SELECT, returns the source table alias and
#' source column it was derived from (recursing through CTEs and sub-queries).
#'
#' @param sql           Character. A SQL SELECT statement or expression.
#' @param dialect       Character. SQL dialect: `"duckdb"` (default),
#'   `"sqlite"`, `"postgres"`, `"mysql"`, `"tsql"`, `"bigquery"`,
#'   `"snowflake"`.
#' @param source_tables Named character vector mapping table aliases to node
#'   IDs, e.g. `c(e = "encounters_node", b = "bed_stays_node")`. Optional.
#'
#' @return A data frame with columns:
#'   \describe{
#'     \item{output_column}{The alias or name of the SELECT expression.}
#'     \item{source_table}{Table alias the column was traced back to.}
#'     \item{source_column}{Column name at the source table.}
#'     \item{expression}{The full SQL expression text.}
#'     \item{is_computed}{`TRUE` when the value is derived, not a direct copy.}
#'   }
#' @export
sg_parse_columns <- function(sql, dialect = "duckdb", source_tables = NULL) {
  .sqlglot()  # ensure sqlglot importable

  mod    <- .get_py_module("column_lineage")
  result <- mod$extract_column_lineage(sql, dialect, source_tables)

  if (!is.null(result[["error"]])) {
    cli::cli_warn("SQLGlot parse error: {result[['error']]}")
    return(.empty_lineage_df())
  }

  rows <- result[["results"]]
  if (length(rows) == 0) return(.empty_lineage_df())

  do.call(rbind, lapply(rows, function(row) {
    data.frame(
      output_column = as.character(row[["output_column"]]),
      source_table  = as.character(row[["source_table"]]),
      source_column = as.character(row[["source_column"]]),
      expression    = as.character(row[["expression"]]),
      is_computed   = as.logical(row[["is_computed"]]),
      stringsAsFactors = FALSE
    )
  }))
}

.empty_lineage_df <- function() {
  data.frame(
    output_column = character(),
    source_table  = character(),
    source_column = character(),
    expression    = character(),
    is_computed   = logical(),
    stringsAsFactors = FALSE
  )
}
