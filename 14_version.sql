/*
  Регистрация версии пакета
  При build вылетит ошибка, если текущая версия больше этой
*/

SELECT poma.pkg_version(:'PKG', 0.1);