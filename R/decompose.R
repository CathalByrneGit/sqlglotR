#' Decompose a SQL boolean expression into a tree of sub-expressions
#'
#' Parses the WHERE-clause body using the SQLGlot AST and returns a nested
#' list that mirrors the boolean structure: `AND`, `OR`, `NOT` operator nodes
#' containing `LEAF` terminal nodes that hold the atomic predicates.
#'
#' @param sql_expr Character. A SQL boolean expression (the body of a WHERE
#'   clause, without the `WHERE` keyword).
#' @param dialect  Character. SQL dialect. Default `"duckdb"`.
#'
#' @return An S3 object of class `"sg_bool_tree"`. A nested list with either:
#'   \describe{
#'     \item{op}{One of `"AND"`, `"OR"`, `"NOT"`, `"LEAF"`.}
#'     \item{children}{List of child `sg_bool_tree` nodes (non-LEAF only).}
#'     \item{expr}{The SQL text of the leaf predicate (LEAF only).}
#'     \item{columns}{Character vector of column references in the leaf (LEAF only).}
#'   }
#'   On any parse failure the whole expression is returned as a single LEAF.
#' @export
sg_decompose_boolean <- function(sql_expr, dialect = "duckdb") {
  .sqlglot()

  mod    <- .get_py_module("bool_decompose")
  result <- mod$decompose_boolean(sql_expr, dialect)

  tree <- py_tree_to_r(result)
  class(tree) <- c("sg_bool_tree", "list")
  tree
}

#' Flatten a boolean tree to its leaf predicates
#'
#' Recursively collects all `LEAF` nodes from an `sg_bool_tree`.
#'
#' @param tree An `sg_bool_tree` object (as returned by [sg_decompose_boolean()]).
#' @return A list of `sg_bool_tree` leaf nodes.
#' @export
sg_leaves <- function(tree) {
  if (tree$op == "LEAF") return(list(tree))
  unlist(lapply(tree$children, sg_leaves), recursive = FALSE)
}

#' @export
print.sg_bool_tree <- function(x, ..., .indent = 0L) {
  pad <- strrep("  ", .indent)
  if (x$op == "LEAF") {
    col_str <- if (length(x$columns) > 0L)
      paste0("  (cols: ", paste(x$columns, collapse = ", "), ")")
    else ""
    cat(pad, "[LEAF] ", x$expr, col_str, "\n", sep = "")
  } else {
    cat(pad, "[", x$op, "]\n", sep = "")
    for (child in x$children) print.sg_bool_tree(child, .indent = .indent + 1L)
  }
  invisible(x)
}
