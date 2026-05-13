test_that("sg_extract_ddl_schema: simple table parsed correctly", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  ddl <- "
    CREATE TABLE patients (
      id   INTEGER PRIMARY KEY,
      name TEXT    NOT NULL,
      age  INTEGER
    );
  "
  schema <- sg_extract_ddl_schema(ddl, dialect = "duckdb")

  expect_type(schema, "list")
  expect_length(schema, 1L)

  tbl <- schema[[1]]
  expect_equal(tbl$table_name, "patients")
  expect_s3_class(tbl$columns, "data.frame")
  expect_equal(nrow(tbl$columns), 3L)
  expect_true("id" %in% tbl$columns$name)
  expect_true("name" %in% tbl$columns$name)
  expect_true("age" %in% tbl$columns$name)
})

test_that("sg_extract_ddl_schema: primary key detected", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  ddl <- "
    CREATE TABLE orders (
      order_id INTEGER PRIMARY KEY,
      amount   DOUBLE
    );
  "
  schema <- sg_extract_ddl_schema(ddl)
  tbl    <- schema[[1]]

  # PK column
  pk_col <- tbl$columns[tbl$columns$name == "order_id", ]
  expect_true(pk_col$is_pk)
  expect_true("order_id" %in% tbl$primary_keys)
})

test_that("sg_extract_ddl_schema: NOT NULL reflected in nullable flag", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  ddl <- "
    CREATE TABLE items (
      id   INTEGER NOT NULL,
      note TEXT
    );
  "
  schema <- sg_extract_ddl_schema(ddl)
  tbl    <- schema[[1]]

  id_col   <- tbl$columns[tbl$columns$name == "id",   ]
  note_col <- tbl$columns[tbl$columns$name == "note", ]

  expect_false(id_col$nullable)
  expect_true(note_col$nullable)
})

test_that("sg_extract_ddl_schema: foreign key extracted", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  ddl <- "
    CREATE TABLE patients (
      id INTEGER PRIMARY KEY,
      name TEXT
    );
    CREATE TABLE encounters (
      enc_id     INTEGER PRIMARY KEY,
      patient_id INTEGER REFERENCES patients(id),
      ts         TIMESTAMP
    );
  "
  schema <- sg_extract_ddl_schema(ddl)

  expect_length(schema, 2L)

  enc_tbl <- schema[[which(vapply(schema, `[[`, "", "table_name") == "encounters")]]
  expect_true(length(enc_tbl$foreign_keys) > 0L)

  fk <- enc_tbl$foreign_keys[[1]]
  expect_true("patient_id" %in% fk$columns)
  expect_equal(fk$ref_table, "patients")
})

test_that("sg_extract_ddl_schema: multiple tables returned", {
  skip_if_not(sqlglotR::sqlglot_available(), "sqlglot Python package not available")

  ddl <- "
    CREATE TABLE a (x INTEGER);
    CREATE TABLE b (y TEXT);
    CREATE TABLE c (z DOUBLE);
  "
  schema <- sg_extract_ddl_schema(ddl)

  expect_length(schema, 3L)
  names_out <- vapply(schema, `[[`, "", "table_name")
  expect_setequal(names_out, c("a", "b", "c"))
})
