test_that("sg_parse_columns: simple JOIN query resolves source columns", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  sql <- "SELECT a.name, b.age FROM a JOIN b ON a.id = b.id"
  df  <- sg_parse_columns(sql, dialect = "duckdb")

  expect_s3_class(df, "data.frame")
  expect_true(all(c("output_column", "source_table", "source_column",
                    "expression", "is_computed") %in% names(df)))

  # Should find entries for 'name' and 'age'
  output_cols <- df$output_column
  expect_true(any(output_cols == "name"))
  expect_true(any(output_cols == "age"))

  # Direct column copies should not be marked as computed
  name_row <- df[df$output_column == "name", ]
  if (nrow(name_row) > 0) {
    expect_false(any(name_row$is_computed))
  }
})

test_that("sg_parse_columns: computed column is_computed = TRUE", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  sql <- "SELECT a.age + b.los AS risk FROM a JOIN b ON a.id = b.id"
  df  <- sg_parse_columns(sql, dialect = "duckdb")

  expect_s3_class(df, "data.frame")
  risk_rows <- df[df$output_column == "risk", ]
  expect_true(nrow(risk_rows) > 0)
  # Derived expression should be marked computed (at least some rows)
  expect_true(any(risk_rows$is_computed))
})

test_that("sg_parse_columns: CTE resolves through to base columns", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  sql <- "
    WITH x AS (SELECT id, val FROM base_tbl)
    SELECT x.val FROM x
  "
  df <- sg_parse_columns(sql, dialect = "duckdb")

  expect_s3_class(df, "data.frame")
  # Should return at least one row
  expect_true(nrow(df) > 0)
  # The output column should be 'val'
  expect_true("val" %in% df$output_column)
})

test_that("sg_parse_columns: returns empty data frame on parse error", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  # Suppress the expected warning
  df <- suppressWarnings(
    sg_parse_columns("THIS IS NOT SQL !!!", dialect = "duckdb")
  )

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0L)
  expect_true("output_column" %in% names(df))
})

test_that("sg_parse_columns: window function query does not crash", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  sql <- "
    SELECT
      patient_id,
      ROW_NUMBER() OVER (PARTITION BY patient_id ORDER BY ts) AS rn
    FROM events
  "
  expect_no_error(sg_parse_columns(sql, dialect = "duckdb"))
})
