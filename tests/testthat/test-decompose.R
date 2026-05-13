test_that("sg_decompose_boolean: AND produces AND tree with two LEAF children", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree <- sg_decompose_boolean("a > 3 AND b = TRUE")

  expect_s3_class(tree, "sg_bool_tree")
  expect_equal(tree$op, "AND")
  expect_length(tree$children, 2L)
  expect_equal(tree$children[[1]]$op, "LEAF")
  expect_equal(tree$children[[2]]$op, "LEAF")
})

test_that("sg_decompose_boolean: nested AND/OR/NOT", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree <- sg_decompose_boolean("(a > 3 OR b < 2) AND NOT c")

  expect_equal(tree$op, "AND")
  expect_length(tree$children, 2L)

  left  <- tree$children[[1]]
  right <- tree$children[[2]]

  # Left branch should be OR
  expect_equal(left$op, "OR")
  expect_length(left$children, 2L)
  expect_equal(left$children[[1]]$op, "LEAF")
  expect_equal(left$children[[2]]$op, "LEAF")

  # Right branch should be NOT wrapping a LEAF
  expect_equal(right$op, "NOT")
  expect_length(right$children, 1L)
  expect_equal(right$children[[1]]$op, "LEAF")
})

test_that("sg_decompose_boolean: function call leaf does not crash", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  expr <- "COALESCE(a, 0) > 5 AND b IS NULL"
  expect_no_error({
    tree <- sg_decompose_boolean(expr)
  })
  expect_s3_class(tree, "sg_bool_tree")
  # Root should be AND with two leaves
  expect_equal(tree$op, "AND")
  expect_length(tree$children, 2L)
})

test_that("sg_leaves: returns all leaf nodes", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree   <- sg_decompose_boolean("a > 1 AND b < 2 AND c = 3")
  leaves <- sg_leaves(tree)

  expect_type(leaves, "list")
  expect_true(length(leaves) >= 2L)
  expect_true(all(vapply(leaves, function(l) l$op == "LEAF", logical(1L))))
})

test_that("sg_decompose_boolean: single predicate returns LEAF", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree <- sg_decompose_boolean("x = 42")

  expect_equal(tree$op, "LEAF")
  expect_true("x" %in% tree$columns)
})

test_that("sg_decompose_boolean: columns extracted in leaf", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree <- sg_decompose_boolean("a > 3 AND b = TRUE")
  leaves <- sg_leaves(tree)

  all_cols <- unlist(lapply(leaves, `[[`, "columns"))
  expect_true("a" %in% all_cols)
  expect_true("b" %in% all_cols)
})

test_that("print.sg_bool_tree: prints without error", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  tree <- sg_decompose_boolean("a > 1 AND (b < 2 OR NOT c)")
  expect_output(print(tree))
})
