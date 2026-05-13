#' Translate SQL between dialects
#'
#' Transpiles SQL from one dialect to another using the SQLGlot transpiler.
#'
#' @param sql  Character. SQL to translate.
#' @param from Character. Source dialect (default `"duckdb"`).
#' @param to   Character. Target dialect: `"postgres"`, `"mysql"`, `"tsql"`,
#'   `"bigquery"`, `"snowflake"`, `"spark"`, `"sqlite"`.
#'
#' @return Character scalar. The translated SQL string. On translation error
#'   a warning is emitted and the original SQL is returned unchanged.
#' @export
sg_translate <- function(sql, from = "duckdb", to) {
  if (missing(to)) cli::cli_abort("{.arg to} is required.")

  .sqlglot()

  mod    <- .get_py_module("translate")
  result <- mod$translate_sql(sql, from, to)

  if (!is.null(result[["error"]])) {
    cli::cli_warn("SQLGlot translation error: {result[['error']]}")
  }

  as.character(result[["sql"]])
}
