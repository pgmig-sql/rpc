/*
  Functions for stored proc documentation fetching

  TODO: if search_path contains i18n_?? and exists i18n_??.rpc_func_?? - get anno from there
*/

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION index(a_nsp TEXT[] DEFAULT NULL) RETURNS SETOF func_def
  STABLE LANGUAGE 'sql' SECURITY DEFINER
SET SEARCH_PATH FROM CURRENT AS
$_$
  SELECT *
    FROM func_def
    WHERE a_nsp IS NULL OR array_length(a_nsp, 1) = 0 OR nspname = ANY(a_nsp)
    ORDER BY code
$_$;

SELECT add('index', 'Список описаний процедур'
, '{"a_nsp":   "Схема БД"}'
);

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION func_args(a_code TEXT) RETURNS TABLE (
  arg     TEXT
, type     TEXT
, required BOOL
, def_val  TEXT
, anno     TEXT
) STABLE LANGUAGE 'sql' SECURITY DEFINER
SET SEARCH_PATH FROM CURRENT AS
$_$
  WITH q_def (n, p) AS (
    SELECT nspname, proname FROM func_def where code = $1
  )
  SELECT f.arg, type, required, def_val, d.anno
   FROM q_def q, pg_func_args(q.n, q.p) f
   LEFT OUTER JOIN func_arg_anno d ON (d.code = f.arg AND d.func_code = $1 AND d.is_in)
$_$;

SELECT add('func_args', 'Описание аргументов процедуры'
, '{"a_code":   "Имя процедуры"}'
, a_result := '{
    "arg":     "Имя аргумента"
  , "type":     "Тип аргумента"
  , "required": "Значение обязательно"
  , "def_val":  "Значение по умолчанию"
  , "anno":     "Описание"
  }'
, a_sample := '{"a_code": "func_args"}'
);

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION func_result(a_code TEXT) RETURNS TABLE (
  arg TEXT
, type TEXT
, anno TEXT
) STABLE LANGUAGE 'sql' SECURITY DEFINER
SET SEARCH_PATH FROM CURRENT AS
$_$
  WITH q_def (n, p) AS (
    SELECT nspname, proname FROM func_anno where code = $1
  )
  SELECT f.arg, f.type, COALESCE(d.anno, f.comment)
   FROM q_def q, pg_func_result(q.n, q.p) f
   LEFT OUTER JOIN func_arg_anno d ON (d.code = f.arg AND d.func_code = $1 AND NOT d.is_in)
$_$;

SELECT add('func_result', 'Описание результата процедуры'
, '{"a_code": "Имя процедуры"}'
, a_result := '{
    "arg":   "Имя аргумента"
  , "type":   "Тип аргумента"
  , "anno":   "Описание"
  }'
, a_sample := '{"a_code": "func_args"}'
);
