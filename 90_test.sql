/*
    Тесты
*/

-- -----------------------------------------------------------------------------
SELECT poma.test('index'); -- BOT
/*
  Тест index
  метод rpc.index может отсутствовать, если переназначен в другом пакете
*/
SELECT * FROM rpc.index(:'PKG') WHERE code <> 'index' ORDER BY code; -- EOT

-- -----------------------------------------------------------------------------
SELECT poma.test('func_args'); -- BOT
/*
  Тест func_args
*/
SELECT * FROM rpc.func_args('func_args'); -- EOT

-- -----------------------------------------------------------------------------
SELECT poma.test('func_result'); -- BOT
/*
  Тест func_result
*/
SELECT * FROM rpc.func_result('func_args') ORDER BY arg; -- EOT

-- -----------------------------------------------------------------------------
SELECT poma.test('index_result'); -- BOT
/*
  Тест func_result
  метод rpc.index может отсутствовать, если переназначен в другом пакете
*/
-- SELECT * FROM rpc.func_result('index') ORDER BY arg; -- EOT
