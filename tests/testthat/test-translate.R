test_that("sg_translate: basic DuckDB to Postgres translation succeeds", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  result <- sg_translate("SELECT 1 AS n", from = "duckdb", to = "postgres")

  expect_type(result, "character")
  expect_true(nzchar(result))
})

test_that("sg_translate: DuckDB to TSQL basic SELECT", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  result <- sg_translate(
    "SELECT id, name FROM patients",
    from = "duckdb",
    to   = "tsql"
  )

  expect_type(result, "character")
  expect_true(nzchar(result))
  # T-SQL uses square-bracket quoting or plain identifiers
  expect_match(result, "SELECT", ignore.case = TRUE)
})

test_that("sg_translate: date truncation translates across dialects", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  # DATE_TRUNC is supported in DuckDB and PostgreSQL; translation should succeed
  result <- sg_translate(
    "SELECT DATE_TRUNC('month', ts) AS month_start FROM events",
    from = "duckdb",
    to   = "postgres"
  )

  expect_type(result, "character")
  expect_true(nzchar(result))
})

test_that("sg_translate: EPOCH_MS translation does not crash", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  # EPOCH_MS(ts) is DuckDB-specific; translation to postgres should not error
  result <- suppressWarnings(
    sg_translate("SELECT EPOCH_MS(ts) FROM t", from = "duckdb", to = "postgres")
  )

  expect_type(result, "character")
  expect_true(nzchar(result))
})

test_that("sg_translate: missing 'to' argument raises error", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  expect_error(sg_translate("SELECT 1"), "to")
})

test_that("sg_translate: DuckDB to Snowflake translation", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  result <- sg_translate(
    "SELECT id FROM t WHERE id IN (1, 2, 3)",
    from = "duckdb",
    to   = "snowflake"
  )

  expect_type(result, "character")
  expect_true(nzchar(result))
})
