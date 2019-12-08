/*
  Tables and functions for stored proc doc registering



is_set | is_scalar | result      | func_result | comment
 -     | +         | type name   | NULL        | single scalar type
 -     | -         | [type name] | RECORDS     | single row of complex type
 +     | +         | type name   | NULL        | set of scalar
 +     | -         | type name   | RECORDS     | named table or view
 +     | -         | NULL        | RECORDS     | unnamed table


 +     |             name
*/

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION method(
  a_code    TEXT
, a_nspname TEXT
, a_proname TEXT
, a_anno    TEXT DEFAULT NULL
, a_args    JSON DEFAULT NULL
, a_result  JSON DEFAULT NULL
, a_sample  TEXT DEFAULT NULL
) RETURNS TEXT VOLATILE LANGUAGE 'plpgsql'
SET SEARCH_PATH FROM CURRENT AS
$_$
  BEGIN
    DELETE FROM func_anno WHERE code = a_code;
    IF a_anno IS NOT NULL THEN
      PERFORM pgmig.comment('f', a_nspname || '.' || a_proname, a_anno);
    END IF;
    INSERT INTO func_anno (
        code,   nspname,   proname,   sample
    ) VALUES (
      a_code, a_nspname, a_proname, a_sample
    );
    INSERT INTO func_arg_anno (
       func_code, is_in, code,  anno
    ) SELECT
          a_code,  true,  key, value
        FROM json_each_text(a_args)
      UNION
      SELECT
          a_code, false,  key, value
        FROM json_each_text(a_result)
    ;
  RETURN a_code;
END;
$_$;
SELECT pgmig.comment('f', 'method', 'Register RPC method');

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add(
  a_proname TEXT
, a_anno    TEXT DEFAULT NULL
, a_args    JSON DEFAULT NULL
, a_result  JSON DEFAULT NULL
, a_sample  TEXT DEFAULT NULL
) RETURNS TEXT VOLATILE LANGUAGE 'sql' AS
$_$
  SELECT rpc.method($1, current_schema(), $1, $2, $3, $4, $5)
$_$;
COMMENT ON FUNCTION add(TEXT, TEXT, JSON, JSON, TEXT) IS 'Register RPC method with the same name as internal func';

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION nsp_clear(
  a_nspname TEXT
) RETURNS SETOF TEXT VOLATILE LANGUAGE 'sql'
SET SEARCH_PATH FROM CURRENT AS
$_$
  DELETE FROM func_anno WHERE nspname = a_nspname RETURNING code
  ;
$_$;
COMMENT ON FUNCTION nsp_clear(TEXT) IS 'Delete methods of given namespace';
