/*
  Добавление комментария схемы после ее автосоздания
  Используется в 'pgmig init'
*/

SELECT pgmig.comment('n', 'rpc', 'RPC interface');
