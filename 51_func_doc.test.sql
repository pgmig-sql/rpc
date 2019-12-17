
SAVEPOINT test_begin;
select assert_count(3);

-- -----------------------------------------------------------------------------

--  метод rpc.index исключаем, т.к. он может отсутствовать, если переназначен в другом пакете
SELECT assert_eq('index'
, (SELECT jsonb_agg(row_to_json(r)) FROM rpc.index('{rpc}') r WHERE code <> 'index' order by 1)
, '[
  {
    "anno": "Описание аргументов процедуры",
    "code": "func_args",
    "is_ro": true,
    "is_set": true,
    "result": null,
    "sample": "{\"a_code\": \"func_args\"}",
    "nspname": "rpc",
    "proname": "func_args",
    "is_struct": true
  },
  {
    "anno": "Описание результата процедуры",
    "code": "func_result",
    "is_ro": true,
    "is_set": true,
    "result": null,
    "sample": "{\"a_code\": \"func_args\"}",
    "nspname": "rpc",
    "proname": "func_result",
    "is_struct": true
  }
]
'
);
ROLLBACK TO SAVEPOINT test_begin;

-- -----------------------------------------------------------------------------

SELECT assert_eq('func_args'
, (SELECT row_to_json(r) FROM rpc.func_args('func_args') r)::jsonb
, '{
        "arg": "a_code",
        "anno": "Имя процедуры",
        "type": "text",
        "def_val": null,
        "required": true
    }'
);

ROLLBACK TO SAVEPOINT test_begin;

-- -----------------------------------------------------------------------------
SELECT assert_eq('func_result'
, (SELECT jsonb_agg(row_to_json(r)) FROM rpc.func_result('func_args') r)
, '[
        {
            "arg": "arg",
            "anno": "Имя аргумента",
            "type": "text"
        },
        {
            "arg": "type",
            "anno": "Тип аргумента",
            "type": "text"
        },
        {
            "arg": "required",
            "anno": "Значение обязательно",
            "type": "boolean"
        },
        {
            "arg": "def_val",
            "anno": "Значение по умолчанию",
            "type": "text"
        },
        {
            "arg": "anno",
            "anno": "Описание",
            "type": "text"
        }
    ]'
);

ROLLBACK TO SAVEPOINT test_begin;
