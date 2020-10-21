# Кастомный коннектор для Facebook Ads

### Наши курсы по обработке данных:
1) Курс по коннекторам в Excel (4 часа): https://directprorf.ru/excel?utm_source=github
2) Большой курс по обработке данных в Power Query (8 часов): https://directprorf.ru/pq?utm_source=github

### Как воспользоваться коннектором:

1) Скачайте файл MEZ: https://github.com/morinad/fb_ads_pq/raw/master/FBads.mez
2) Перенесите файл в папку C:\Users\USERNAME\Documents\Power BI Desktop\Custom Connectors, подставив USERNAME своего компьютера.
3) Откройте Power BI, зайдите в Файл -> Параметры и настройки -> Параметры -> Глобальные -> Безопасность, выберите "Разрешить загрузку любого расширения без проверок и предупреждений".
4) Перезапустите Power BI. Нажмите на кнопку "Получить данные", в поиске введите "FB" и выберите коннектор FB Ads.

### 2 способа получения токена Facebook:
1) Можно получить токен аккаунта в коде страницы: https://www.facebook.com/ads/manager/account_settings/account_billing/.
Способ 1 опасен тем, что при частом использовании токена Facebbok может воспринять это как взлом аккаунта и попросить поменять пароль.
2) Можно создать приложение в Facebook и получить через него.
Способ 2 неудобен тем, что токен живёт 2-3 месяца, потом его нужно менять.

### Полезные ссылки:
Подробное видео по использованию коннектора: https://youtu.be/B8BWwRFWtOc

Список приложений Facebook Ads: https://developers.facebook.com/apps/

Получение токенов ФБ (маркер доступа): https://developers.facebook.com/tools/explorer/

Отладчик токенов: https://developers.facebook.com/tools/debug/accesstoken/

Токен аккаунта в коде страницы: https://www.facebook.com/ads/manager/account_settings/account_billing/


