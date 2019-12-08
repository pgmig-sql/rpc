/*
  Functions for stored proc definition fetching

*/

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pg_func_args(a_nspname TEXT, a_proname TEXT)
  RETURNS TABLE(arg TEXT, type TEXT, id INT, required BOOL, def_val TEXT) STABLE LANGUAGE 'plpgsql' AS
$_$
  -- a_code:  название функции
  DECLARE
    v_i          INTEGER;
    v_args       TEXT;
    v_defs       TEXT[];
    v_def        TEXT;
    v_arg        TEXT;
    v_type       TEXT;
    v_default    TEXT;
    v_required   BOOL;
    v_offset     INTEGER;
  BEGIN
    SELECT INTO v_args
      pg_get_function_arguments(p.oid)
      FROM pg_catalog.pg_proc p
      JOIN pg_namespace n ON (n.oid = p.pronamespace)
     WHERE n.nspname = a_nspname
       AND p.proname = a_proname
    ;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Function not found: %', a_proname;
    END IF;
    IF v_args = '' THEN
      -- ф-я не имеет аргументов
      RETURN;
    END IF;

    RAISE DEBUG 'args: %',v_args;

    v_defs := regexp_split_to_array(v_args, E',\\s+');
    FOR v_i IN 1 .. pg_catalog.array_upper(v_defs, 1) LOOP
      v_def := v_defs[v_i];
      RAISE DEBUG 'PARSING ARG DEF (%)', v_def;
      IF v_def !~ E'^(IN)?OUT ' THEN
        v_def := 'IN ' || v_def;
      END IF;
      IF split_part(v_def, ' ', 1) = 'OUT' THEN
        CONTINUE;
      END IF;
      IF split_part(v_def, ' ', 3) IN ('', 'DEFAULT') THEN
        -- аргумент без имени - автогенерация невозможна
        RAISE EXCEPTION 'No required arg name for % arg id %', a_proname, v_i;
      END IF;

      v_required := FALSE;
      v_offset := 4;
      IF v_def ~ '^.+ timestamp with time zone ' THEN
        v_offset := 7;
      END IF;
      IF split_part(v_def, ' ', v_offset) = 'DEFAULT' THEN
        v_default := substr(v_def, strpos(v_def, ' DEFAULT ') + 9);
        v_default := regexp_replace(v_default, '::[^:]+$', '');
        IF v_default = 'NULL' THEN
          v_default := NULL;
        ELSE
          v_default := btrim(v_default, chr(39)); -- '
        END IF;
      ELSE
        v_default := NULL;
        v_required := TRUE;
      END IF;
      v_arg  := regexp_replace(split_part(v_def, ' ', 2), '^' || rpc.pg_func_arg_prefix(), '');
      v_type := split_part(v_def, ' ', 3);
      RAISE DEBUG '   column %: name=%, type=%, req=%, def=%', v_i, v_arg, v_type, v_required, v_default;
      RETURN QUERY SELECT v_arg, v_type, v_i, v_required, v_default;
    END LOOP;
    RETURN;
  END;
$_$;
SELECT pgmig.comment('f', 'pg_func_args', 'Function arguments definition');

-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION pg_func_result(
  a_nspname TEXT
, a_proname TEXT
) RETURNS TABLE(
  arg     TEXT
, type     TEXT
, comment  TEXT
) STABLE LANGUAGE 'plpgsql' AS
$_$
  DECLARE
    v_is_struct  BOOL;
    v_res_type   TEXT;
    v_res_def    TEXT;
    v_defs       TEXT[];
    v_i          INTEGER;
  BEGIN
    SELECT INTO v_is_struct, v_res_type, v_res_def
      (format_type(p.prorettype, NULL) = 'record' OR t.typtype = 'c')
    , NULLIF(rpc.pg_type_name(p.prorettype), 'record')
    , pg_get_function_result(p.oid)
    FROM pg_catalog.pg_proc p
      LEFT JOIN pg_type t ON (t.oid = p.prorettype)
      WHERE p.pronamespace = to_regnamespace(a_nspname)
        AND p.proname = a_proname
    ;
    IF v_res_def = '' THEN
      -- function has no results (VOID)
      RETURN;
    ELSIF NOT v_is_struct THEN
      -- function returns scalar type
      RETURN;
    END IF;

    IF v_res_type IS NULL THEN
      -- anon table, left(v_res_def, 6) = 'TABLE('
      v_res_def := regexp_replace(v_res_def,'(TABLE\()(.+)\)',E'\\2','i');
      RETURN QUERY SELECT
        split_part(dt, ' ', 1)
      , split_part(dt, ' ', 2)
      , NULL::TEXT
        FROM regexp_split_to_table(v_res_def, E',\\s+') dt
      ;
    ELSE
      -- Always: ELSIF left(v_res_def, 6) = 'SETOF ' THEN
      RETURN QUERY SELECT
        attname::TEXT
      , CASE WHEN t.typtype ='e' THEN 'text'
        ELSE rpc.pg_type_name(CASE WHEN t.typtype ='d' THEN t.typbasetype ELSE atttypid END) END
      , col_description(attrelid, attnum) AS anno
        FROM pg_catalog.pg_attribute a
        LEFT JOIN pg_type t ON (t.oid = a.atttypid)
       WHERE attrelid = v_res_type::regclass
         AND attnum > 0
         AND NOT attisdropped
       ORDER BY attnum
      ;
    END IF;
    RETURN;
  END;
$_$;
SELECT pgmig.comment('f', 'pg_func_result', 'Function result of complex type columns definition');
