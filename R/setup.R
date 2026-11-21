#' Install the sqlglot Python dependency
#'
#' Creates a Python virtual (or conda) environment and installs the
#' `sqlglot` package into it.
#'
#' @param envname Character. Name of the Python environment to use.
#' @param method  Character. Installation method forwarded to
#'   [reticulate::py_install()]. Use `"auto"` to let reticulate decide.
#' @return Invisibly, the result of [reticulate::py_install()].
#' @export
sqlglot_install <- function(envname = "r-sqlglot", method = "auto") {
  reticulate::py_install("sqlglot", envname = envname, method = method)
}

#' Check whether sqlglot is importable in the current Python session
#'
#' @return Logical scalar.
#' @export
sqlglot_available <- function() {
  reticulate::py_module_available("sqlglot")
}

# Package-level cache for the sqlglot Python module itself
.sg_cache <- new.env(parent = emptyenv())

# Lazy accessor — aborts with a helpful message if sqlglot is not installed.
.sqlglot <- function() {
  if (is.null(.sg_cache$mod)) {
    if (!sqlglot_available()) {
      cli::cli_abort(c(
        "Python package {.pkg sqlglot} is not installed.",
        "i" = "Run {.run sqlglotR::sqlglot_install()} to install it."
      ))
    }
    .sg_cache$mod <- reticulate::import("sqlglot", delay_load = FALSE)
  }
  .sg_cache$mod
}
