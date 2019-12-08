/*
  Создание схемы БД
  Используется в 'pgmig init'
*/

-- Создание схемы
CREATE SCHEMA IF NOT EXISTS rpc;

-- Далее все объекты будут создаваться  этой схеме
SET SEARCH_PATH = rpc, 'public';
