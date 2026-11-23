# sqlglotR

R interface to the Python [SQLGlot](https://github.com/tobymao/sqlglot) SQL
parser and transpiler, via reticulate. It provides SQL dialect translation,
column-level lineage extraction, boolean expression decomposition and DDL
schema extraction.

## Installation

```r
remotes::install_github("CathalByrneGit/sqlglotR")
```

sqlglotR needs Python (>= 3.8) and the Python `sqlglot` package (>= 23.0).
Install `sqlglot` into a reticulate-managed environment with:

```r
sqlglotR::sqlglot_install()                 # environment "r-sqlglot"
sqlglotR::sqlglot_install(envname = "my-env", method = "virtualenv")
```

`sqlglot_install()` is a thin wrapper around `reticulate::py_install()`.
`envname` and `method` are passed straight to it.

Check that it worked:

```r
sqlglotR::sqlglot_available()
#> [1] TRUE
```

If `sqlglot` isn't available, the `sg_*()` functions stop with an error that
points you to `sqlglot_install()`.

## Usage

```r
library(sqlglotR)

# Translate between dialects
sg_translate('SELECT * FROM t LIMIT 5', from = "duckdb", to = "tsql")

# Column-level lineage
sg_parse_columns("SELECT a, b + c AS d FROM t")

# Decompose a WHERE clause into an AND/OR/NOT tree
tree <- sg_decompose_boolean("(a > 3 OR b < 2) AND NOT c")
sg_leaves(tree)

# Extract table schemas from DDL
sg_extract_ddl_schema("CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT)")
```

## Tests

Every test is skipped with
`skip_if_not(sqlglotR::sqlglot_available(), ...)`, so the suite passes, with
all tests skipped, on machines without Python or `sqlglot`. To run the tests
for real, install `sqlglot` first (see above).
