# Internal environment for caching loaded Python modules
.py_env <- new.env(parent = emptyenv())

# Lazy-load a Python module from inst/python/ and cache it.
.get_py_module <- function(module_name) {
  if (is.null(.py_env[[module_name]])) {
    inst_dir <- system.file("python", package = "sqlglotR")
    if (!nzchar(inst_dir)) {
      cli::cli_abort(
        "Could not find inst/python/ in the sqlglotR package installation."
      )
    }
    .py_env[[module_name]] <- reticulate::import_from_path(
      module_name,
      path = inst_dir
    )
  }
  .py_env[[module_name]]
}

#' Recursively convert a Python boolean-tree dict to an R sg_bool_tree list.
#'
#' @param node A named list (as returned by reticulate from a Python dict).
#' @return A nested list with class `c("sg_bool_tree", "list")`.
#' @keywords internal
py_tree_to_r <- function(node) {
  if (is.null(node)) return(NULL)

  op     <- as.character(node[["op"]])
  result <- list(op = op)

  if (op == "LEAF") {
    result$expr    <- as.character(rlang::`%||%`(node[["expr"]], ""))
    result$columns <- as.character(unlist(rlang::`%||%`(node[["columns"]], list())))
    err <- node[["error"]]
    if (!is.null(err)) result$error <- as.character(err)
  } else {
    result$children <- lapply(node[["children"]], py_tree_to_r)
  }

  class(result) <- c("sg_bool_tree", "list")
  result
}

# Convert a list of Python row-dicts to a data.frame with consistent columns.
.rows_to_df <- function(rows, col_names, col_types) {
  if (length(rows) == 0) {
    df <- as.data.frame(
      lapply(col_types, function(f) f(character(0))),
      stringsAsFactors = FALSE
    )
    names(df) <- col_names
    return(df)
  }

  do.call(rbind, lapply(rows, function(row) {
    vals <- mapply(function(nm, f) f(row[[nm]]),
                   col_names, col_types, SIMPLIFY = FALSE)
    as.data.frame(vals, stringsAsFactors = FALSE)
  }))
}
