﻿--[[
    WARNING: This file is automatically generated. DO NOT modify this file manually, as your changes will be lost the next time this file is regenerated.
    Instead, modify the source files used to generate this file, and then regenerate the file using the appropriate tool.
]]

--- @class WowUkrainizerInternals
local ns = select(2, ...);

if (not ns._db) then return end

ns._db.GlobalStrings = {
	[2409225384] = "(Святилище)",
	[2557811203] = "(Зона PvP)",
	[1126997378] = "(Спірна територія)",
	[2071201537] = "(Зона бойових дій)",
	[1388461174] = "Ви слідуєте за %s.",
	[2301139724] = "Ви припиняєте слідувати за %s.",
	[1323062153] = "(Територія %s)",
	[4006453393] = "Карта світу",
	[3233326665] = "Світ",
	[3652479236] = "Карта та журнал завдань",
	[2544283312] = "Карта",
	[4073452649] = "Рівень улюбленців",
	[2264627923] = "Відкрито нову місцевість!",
	[4148976868] = "Відкрито: %s. Отримано: %d досвіду",
	[4073621111] = "Відкрито: %s",
	[2915182079] = "Рейд",
	[3967329008] = "Підземелля",
	[528560634] = "Головне меню",
	[2541508997] = "Підтримка",
	[3395656142] = "Крамниця",
	[453783521] = "Що нового?",
	[2380060431] = "Налаштування",
	[1109766933] = "Режим редагування",
	[460068014] = "Макроси",
	[2755263243] = "Додатки",
	[1982074522] = "Рейтинг",
	[1116636179] = "Вийти",
	[1021299913] = "Вийти з гри",
	[995233482] = "Повернутися до гри",
	[181857325] = "Персонаж",
	[1764070078] = "Таланти та книга заклинань",
	[1559549977] = "Досягнення",
	[338328340] = "Журнал завдань",
	[2510603714] = "Гільдії та спільноти",
	[2587204904] = "Пошук групи",
	[3251906489] = "Колекції бойового загону",
	[3688507604] = "Путівник по пригодах",
	[4142066923] = "Путівник по підземеллях",
	[1660715572] = "Репутація",
	[2879888740] = "Валюта",
	[3434792140] = "Книга заклинань",
	[2530527920] = "Професії",
	[71268301] = "Спілкування",
	[3835910914] = "Канали чату",
	[3980282667] = "Гільдія",
	[1904179167] = "Пошук гільдії",
	[895159839] = "Додаткова ціль",
	[3825719821] = "Додаткові події у відкритому світі, які дають досвід та різноманітні нагороди.",
	[1557334855] = "Кампанія",
	[1850996925] = "Завдання, які продовжують основну сюжетну лінію.",
	[1003987577] = "Активності",
	[2983880738] = "Обмежені в часі активності",
	[4092020059] = "Пересування",
	[3171309817] = "Завдання",
	[1970096037] = "Вхід у печеру",
	[655153786] = "Вхід у печеру або іншу місцевість.",
	[938572861] = "Вибій",
	[462681386] = "Пригода з цінними нагородами, що розрахована на групу до п'яти гравців з будь-якою бойовою роллю.",
	[3011319329] = "Місце розкопок",
	[632659307] = "Місце археологічних розкопок, де ви можете знайти артефакти.",
	[1785495131] = "Режим з цінними нагородами, що розрахований на групу з п'яти гравців.",
	[1003423764] = "Подія",
	[2597577125] = "Різноманітні активності з цінними нагородами, що прив'язані до певного оновлення.",
	[460849350] = "Пункт перельоту",
	[4294091658] = "Дозволяє переміститися в іншу місцевість в межах континенту.",
	[4181433507] = "Позначки",
	[2572796571] = "Столиця",
	[3271016683] = "Центральна локація з НІПами, діяльностями та доступними завданнями.",
	[1049792378] = "Важливі",
	[3363910096] = "Завдання, які розблоковують важливий функціонал і нагороди, та вчать вас основним механікам гри.",
	[1653697205] = "Виконуються",
	[124438418] = "Завдання, які наразі виконуються.",
	[3283224806] = "Легендарні",
	[4203731299] = "Завдання, які надають легендарні нагороди.",
	[194977661] = "Місцеві оповіді",
	[792516064] = "Завдання, що розкривають місцеві культури та побічні пригоди.",
	[444112738] = "Мета",
	[2845661838] = "Обмежені в часі завдання, які надають цінні нагороди для прикінцевої гри.",
	[3867851311] = "Битви улюбленців",
	[172918771] = "Змагання у битвах улюбленців з НІП.",
	[721517159] = "Складний режим, який потребує великої групи гравців та надає цінні нагороди.",
	[3982664215] = "Рідкісний",
	[2765639856] = "Рідкісний (Елітний)",
	[2736695335] = "Рідкісне особливе створіння, з якого може випасти цінна здобич.",
	[3131363864] = "Особливе створіння, яке надає різноманітні нагороди.",
	[2366057016] = "Повторювані",
	[4198361543] = "Обмежені в часі завдання.",
	[1399595282] = "Пункт телепорту",
	[4010455859] = "Телепортує вас в іншу місцевість.",
	[3092325269] = "Можна здати",
	[2439063605] = "Завдання, які можна здати.",
	[1946854377] = "Світовий бос",
	[2179239195] = "Складний світовий бос, який дає цінні нагороди, та потребує групи з великою кількістю гравців.",
	[785639805] = "Локальне завдання",
	[1844941721] = "Діяльності у відкритому світі, що дають різноманітні нагороди.",
	[3628935683] = "Назад",
	[2507742204] = "Рівень %d",
	[3893999571] = "Пасивна здібність",
	[2020603620] = "Опис збігається",
	[201213233] = "Точний збіг",
	[1168756116] = "Збіги",
	[952350560] = "Назва збігається",
	[3963609348] = "Частковий збіг",
	[3818382858] = "Приховування пасивних здібностей призупинено під час пошуку",
	[2879635569] = "Пошук здібностей і ключових слів",
	[3116341330] = "Немає на панелі дій",
	[2034414417] = "Тимчасово заблоковано",
	[1341604910] = "Зверніться до свого наставника",
	[2895730733] = "Ранг %d",
	[2423741638] = "Загальні",
	[2643829451] = "Вихованець",
	[1085844336] = "Таланти",
	[151129191] = "Стор. %d",
	[700758360] = "Стор. %d/%d",
	[1133700390] = "Спеціалізація",
	[177636829] = "Таланти — %s",
	[2827945711] = "Пов'язані таланти (%s %s)",
	[1944610164] = "Приховати пасивні здібності",
	[2495672392] = "Звідси ви можете перетягнути здібності на панель дій. Активні здібності відсортовано перед пасивними.",
	[3072279189] = "Недоступно для прив'язування до кнопки миші",
	[1647284823] = "Активовано",
	[238643990] = "Активувати",
	[2455215738] = "Приклад здібностей",
	[2508819333] = "Основна характеристика: %s",
	[1817103969] = "Расова здібність",
	[3975727123] = "Привілей гільдії",
	[3931986580] = "Расова здібність (пасивна)",
	[633536749] = "Бойові улюбленці",
	[1884117680] = "Талант",
	[2267844833] = "Талант, Зміна форми",
	[3426605919] = "Зміна форми",
	[2306689633] = "Ви втратите будь-які незбережені зміни, якщо продовжите.",
	[3821560037] = "Увімкнено",
	[3543308264] = "Доєднайтесь до режиму війни, що активує глобальне PvP, збільшуючи нагороди та досвід за завдання на {1}%, а також вмикаючи PvP-таланти у відкритому світі.",
	[2683619847] = "Режим війни",
	[4066118191] = "Бонус від режиму війни збільшено до {1}%.",
	[2308787932] = "Режим війни: заклик до зброї",
	[3558955490] = "Ліве дерево",
	[711108972] = "Праве дерево",
	[136185554] = "Скинути таланти",
	[2419334826] = "Всі",
	[1446771406] = "Ви досягли максимальної кількості шаблонів. Видаліть шаблон з будь-якої вашої спеціалізації, щоб звільнити комірку.",
	[983021426] = "Ви повинні витратити всі доступні очки талантів, щоб поділитися цим шаблоном",
	[433745963] = "Стандартний шаблон",
	[3500753286] = "Новий шаблон",
	[2229118364] = "Налаштування шаблону",
	[2685891229] = "Імпортувати",
	[1013224307] = "Скопіювати в буфер обміну, |cnNORMAL_FONT_COLOR:(щоб поділитися онлайн)|r",
	[1742184540] = "Надіслати в чат",
	[2025862989] = "{ffffff00|Готовий набір талантів, який підходить для більшості контенту}",
	[3080482937] = "{ff00bff3|Стартовий набір}",
	[2359384332] = "Пов'язане з талантом, який ви шукали",
	[307867489] = "Пошук збігів",
	[1552616826] = "Пошук точних збігів",
	[314205088] = "На вимкненій панелі дій",
	[2721583028] = "Не на панелі дій",
	[3313592546] = "На панелі дій, що належить іншій стійці",
	[4118283266] = "Скопіювати код шаблону",
	[3841544313] = "Поділитись",
	[823685840] = "Код шаблону скопійовано до буфера обміну.",
	[272707097] = "Вибір цього таланту ускладнить освоєння стартового набору.",
	[3101237510] = "Зміна талантів все ще триває, спробуйте пізніше.",
	[134371170] = "Застосувати зміни",
	[1479528149] = "Скасувати поточні зміни",
	[4150500985] = "Для того, щоб розблокувати цей рядок, потрібно витратити ще {1} оч.",
	[2228708624] = "Талант не вибрано.",
	[2435347017] = "Комірка для PvP-таланту",
	[940524830] = "Розблокується на %d-му рівні",
	[112036651] = "Натисніть, щоб вибрати талант.",
	[1059261737] = "ОБЕРІТЬ",
	[3324808796] = "Згорнути",
	[1960683845] = "Розгорнути",
	[384613572] = "ГЕРОЇЧНІ ТАЛАНТИ",
	[1916897451] = "БУДЕ РОЗБЛОКОВАНО НА %d-МУ РІВНІ",
	[86536935] = "ДОСТУПНО ОЧОК",
	[1515787955] = "Ви повинні витратити всі доступні очки талантів, щоб застосувати зміни",
	[70471795] = "Це неможливо зробити, коли ви мертві.",
	[2629589877] = "Ви повинні перебувати у Штормовії, Вальдраккені, чи Дорноґалі, щоб увімкнути режим війни.",
	[3758237218] = "Це може бути вимкнено у будь-якій зоні відпочинку, однак може бути ввімкнено лише у Штормовії, Вальдраккені та Дорноґалі.",
	[3214599208] = "Ви повинні перебувати в Орґріммарі, Вальдраккені, чи Дорноґалі, щоб увімкнути режим війни.",
	[4183704220] = "Це може бути вимкнено у будь-якій зоні відпочинку, однак може бути ввімкнено лише в Орґріммарі, Вальдраккені та Дорноґалі.",
	[2941119360] = "Витратьте ще {1} оч. талантів, щоб розблокувати цей рядок",
	[1893606548] = "Скасувати",
	[1145984629] = "Продовжити",
	[3235508270] = "Розблокується на %d-му рівні.",
	[1230373563] = "Ви не додали це на панель дій",
	[152707009] = "Ви додали це на панель дій, яка прихована або вимкнена",
	[2347032437] = "Ви додали це на панель дій, але в іншій стійці",
	[131993511] = "Клацніть правою кнопкою миші, щоб очистити всі вузли історії",
	[3847490364] = "Натисніть, щоб вивчити",
	[1269457485] = "Клацніть, утримуючи клавішу Shift, щоб переглянути всі дотичні вузли історії",
	[3341134561] = "Цей PvP талант неактивний, оскільки у вас відсутній потрібний талант",
	[395171831] = "Клацніть правою кнопкою миші, щоб прибрати з вивчених",
	[890313169] = "Цей вузол не активний",
	[2344877936] = "Це вже вивчено",
	[3978875082] = "Вартість: %s",
	[225844698] = "Ви не можете дозволити собі цей вибір",
	[1146627155] = "Оберіть інший варіант",
	[1788740851] = "Ви не додали цю здібність на панель дій",
	[1246289297] = "{ffff2020|Для того щоб розблокувати цей талант потрібно витратити ще {1} оч.}",
	[1629743382] = "Неможливо змінити таланти в бою.",
	[2558973053] = "Ви не можете змінити таланти в бою",
	[3177267154] = "{ffff2020|Для того щоб розблокувати цей талант потрібно витратити ще {1} оч.}",
	[3190014643] = "Клацніть лівою кнопкою миші, щоб вибрати талант.",
	[405778245] = "Цей талант надається вашій спеціалізації автоматично і не може бути прибраним з вивчених",
	[569140717] = "Немає активних зв'язків. З'єднайте через інші вузли або забудьте цей талант.",
	[3118668103] = "Новий сезон!",
	[442396665] = "Закрити",
	[1622607650] = "Розпочати завдання",
	[2336437924] = "<Натисніть Shift + ПКМ, щоб оглянути артефакт>",
	[3355824036] = "<Натисніть Shift + ПКМ, щоб переглянути азеритові сили>",
	[3080847032] = "<Натисніть Shift + ПКМ, щоб переглянути азеритові сутності>",
	[4150569281] = "<Клацніть ПКМ, щоб відкрити>",
	[2011544437] = "<Клацніть ПКМ, щоб прочитати>",
	[2607040019] = "<Натисніть ПКМ, щоб оглянути споряджений артефакт>",
	[471931400] = "<Натисніть Shift + ПКМ, щоб інкрустувати>",
	[3470081827] = "|cff00ff00<Виробник: %s>|r",
	[479794020] = "Рівень покращення: %s/%s",
	[1951177239] = "Рівень покращення: %s %s/%s",
	[1965344521] = "Рівень покращення: %d/%d",
	[1587380305] = "Використання: Додає цю модель до колекції вашого бойового загону.",
	[2764323363] = "Не продається",
	[3217860112] = "Покращення предмета",
	[2092199996] = "(%s шкоди за секунду)",
	[3246035733] = "Унікальний",
	[3238567971] = "Унікальний-споряджуваний",
	[24238040] = "Прив'язаний до бойового загону",
	[403010308] = "Персональний",
	[776654626] = "Прив'язаний до бойового загону до споряджання",
	[7242169] = "Стає персональним при спорядженні",
	[1955371321] = "Стає персональним при отриманні",
	[2093284307] = "Стає персональним при використанні",
	[2928698411] = "Якість: %s",
	[959313450] = "Потрібен %d-й рівень",
	[3194654445] = "Ви ще не отримали цю модель.",
	[1613337585] = "Ви вже отримали цю модель",
	[2748261209] = "Міцність %d / %d",
	[3436727752] = "Рівень покращення: %s %d/%d",
	[1467061317] = "Рівень предмета: %d",
	[3007134559] = "Дворучна",
	[2575926768] = "Набої",
	[2992214183] = "Сорочка",
	[3361582252] = "Груди",
	[4142432590] = "Стопи",
	[1544025394] = "Палець",
	[4266244357] = "Руки",
	[3304586546] = "Голова",
	[1830289563] = "Неосновна рука",
	[711276878] = "Ноги",
	[7640378] = "Шия",
	[2035758478] = "Неможливо спорядити",
	[372033662] = "Спорядження для професії",
	[1396975407] = "Знаряддя для професії",
	[2604666088] = "Сагайдак",
	[2592560741] = "Далекобійна",
	[1895486488] = "Реліквія",
	[1260866124] = "Неосновна рука",
	[1813108732] = "Плечі",
	[3006229085] = "Гербова накидка",
	[2911238262] = "Метальна",
	[3621082430] = "Аксесуар",
	[3651403502] = "Талія",
	[1038824811] = "Одноручна",
	[884290046] = "Основна рука",
	[1252789455] = "Зап'ясток",
	[859600634] = "Основна атака",
	[3202350235] = "Броня: %s",
	[3218688554] = "Посох",
	[1811135501] = "Жезл",
	[161428129] = "Кинджал",
	[515939545] = "Меч",
	[2010385399] = "Дробильна",
	[2089796118] = "Щит",
	[2492276390] = "Сокира",
	[3028299880] = "Держакова",
	[1594992228] = "Кулачна",
	[3080246546] = "Глефи",
	[2504481501] = "Лук",
	[1263933297] = "Арбалет",
	[2603206346] = "Вогнепальна",
	[484289536] = "Тканина",
	[3885461952] = "Лати",
	[1396633619] = "Кольчуга",
	[3241853961] = "Шкіра",
	[4130237028] = "Ви ще не отримали цю модель",
	[657665631] = "Набори спорядження: |cFFFFFFFF%s|r",
	[2381163414] = "Ціна продажу",
	[3588822618] = "Швидкість атаки %s",
	[3089522949] = "%s - %s шкоди",
	[2054182023] = "Незнищенний",
	[4142024951] = "Якщо ви заміните цей предмет, ваші характеристики зазнають таких змін:",
	[1285337546] = "Якщо ви заміните ці предмети, ваші характеристики зазнають таких змін:",
	[3299408321] = "Зараз споряджено",
	[3427614263] = "Дослідник",
	[1215926633] = "Мандрівник",
	[2552466937] = "Ветеран",
	[4204547422] = "Чемпіон",
	[3564917104] = "Герой",
	[1276679099] = "Легенда",
	[3974243073] = "При споряджанні з",
	[2793610831] = "(Коли |c%s%s|r в основній руці)",
	[3052682868] = "(Коли |c%s%s|r в неосновній руці)",
	[2113808050] = "Натисніть %s, щоб перемкнутися між вашими предметами для основної руки.",
	[3232576725] = "Натисніть %s, щоб перемкнутися між вашими предметами для неосновної руки.",
	[1196288179] = "Зайдіть у меню \"Призначення клавіш\", щоб налаштувати перемикання між предметами для основної руки (рекомендована комбінація — Shift+C).",
	[289973788] = "Зайдіть у меню \"Призначення клавіш\", щоб налаштувати перемикання між предметами для неосновної руки (рекомендована комбінація — Shift+C).",
	[3429128476] = "Блакитне гніздо",
	[64628185] = "Зубчасте гніздо",
	[3623322771] = "Кристалічне гніздо",
	[1401626429] = "Гніздо панування",
	[2356749665] = "Гніздо для пахощів",
	[2252887272] = "Охоплене Ша гніздо",
	[2012010909] = "Особливе гніздо",
	[2598732030] = "Призматичне гніздо",
	[1014793585] = "Первісне гніздо",
	[2873491944] = "Гніздо для блакитних перфокарт",
	[1758047087] = "Гніздо для червоних перфокарт",
	[1075671590] = "Гніздо для жовтих перфокарт",
	[2278149390] = "Червоне гніздо",
	[3241911510] = "Механічне гніздо",
	[1415666464] = "Жовте гніздо",
	[1303788736] = "Класи: %s",
	[1999950683] = "Застосувати",
	[3248598694] = "Не можна змінити спорядження на арені",
	[1912002026] = "Не можна змінити спорядження під час бою",
	[2458434169] = "Не можна змінити спорядження у цю мить",
	[128088108] = "Не можна змінити спорядження, поки у підземеллі діє міфічний ключ",
	[221858010] = "Не можна змінити спорядження на рейтингових полях бою",
	[376964685] = "Не можна змінити спорядження у Торґасті",
	[1108879849] = "До відновлення:",
	[4190378831] = "Зібрано (%d/%d)",
	[2865308074] = "Ви вже завершили це завдання.",
	[2462032292] = "Ви вже завершили це щоденне завдання сьогодні.",
	[3204863906] = "Ви вже виконуєте це завдання.",
	[816918237] = "Для виконання цього завдання потрібне активне доповнення.",
	[499605166] = "У вас недостатній рівень для цього завдання.",
	[1704233787] = "У вас немає необхідних предметів. Перевірте інвентар.",
	[681807098] = "У вас недостатньо золота для цього завдання.",
	[3410851354] = "Ви ще не вивчили необхідне заклинання.",
	[3565089249] = "Це завдання недоступне для вашої раси.",
	[2176503737] = "Шкалу цілі завдання не заповнено",
	[3550953111] = "Завдання проігноровано",
	[2239385481] = "Ваш журнал завдань повний.",
	[3713494649] = "Ви маєте вибрати нагороду.",
	[4156790888] = "Ви не відповідаєте вимогам для виконання цього завдання.",
	[2008332103] = "Ви не можете виконувати більше одного обмеженого в часі завдання.",
	[2068197633] = "Синхронізацію групи вже активовано.",
	[1600467404] = "Ви вже в режимі синхронізації групи.",
	[4178577481] = "Синхронізація групи поки недоступна.",
	[3446465421] = "Синхронізація групи зараз недоступна.",
	[361418177] = "Не вдалося синхронізувати групу, бо учасник групи знаходиться на іншому континенті.",
	[3208521914] = "Ви не можете ввімкнути синхронізацію групи під час бою.",
	[1136110155] = "Не вдалося синхронізувати групу, бо учасник групи перебуває у битві улюбленців.",
	[1132243968] = "Ви в рейді.",
	[3132995885] = "Ваш запит на приєднання до синхронізованої групи відхилено.",
	[2893876920] = "Ви вийшли з режиму синхронізації групи.",
	[2882054826] = "Не вдалося синхронізувати групу, бо учасник групи перебуває в підземеллі зі старим режимом нагород.",
	[3201517547] = "Ви не можете ввімкнути синхронізацію групи, допоки учасник групи перебуває в бою.",
	[1689499675] = "Синхронізацію групи не активовано.",
	[664456164] = "Ви не в групі.",
	[989736503] = "Ви не є учасником синхронізованої групи.",
	[3714348822] = "Ви не лідер синхронізованої групи.",
	[270073046] = "Не вдалося синхронізувати групу, бо учасник групи не завершив свої початкові завдання.",
	[3807381551] = "Учасник групи відхилив запит на синхронізацію групи.",
	[921689251] = "Не вдалося синхронізувати групу, бо учасник групи є тестовим персонажем.",
	[91611604] = "Не вдалося синхронізувати групу, бо учасник групи з іншої фракції.",
	[836655425] = "Завдання були повторно синхронізовані.",
	[2772298130] = "Синхронізацію групи ввімкнено.",
	[2608020796] = "Синхронізацію групи вимкнено.",
	[249886760] = "Час запиту на синхронізацію групи сплинув.",
	[624491248] = "Сталася невідома помилка при спробі синхронізації групи.",
	[1654384515] = "Завдання більше не ігнорується",
	[2446567660] = "Ціль досягнуто.",
	[999076499] = "Взято завдання: %s",
	[262136370] = "%s вбито: %d/%d",
	[4118620638] = "Гравців убито: %d/%d",
	[517970603] = "\"%s\" виконано.",
	[4272146628] = "\"%s\" провалено. Інвентар повний.",
	[1962746835] = "Не вдалося здати \"%s\". Унікальна нагорода цього завдання вже є у вашому інвентарі. Приберіть її, щоб завершити завдання.",
	[875826716] = "\"%s\" провалено.",
	[3050345634] = "Ви вже виконали таку кількість щоденних завдань сьогодні: %d",
	[3194295532] = "Завдання \"%s\" було прибрано зі журналу завдань.",
	[2608590714] = "%s (Виконано)",
	[2530564604] = "Переможено гравців у битвах улюбленців: %d/%d",
	[4069685545] = "%s прийняв ваше завдання.",
	[1646095992] = "%s вже виконав це завдання.",
	[3596993308] = "%s не зміг поділитися з вами завданням \"%s\". Ви вже виконали його.",
	[1464953241] = "%s зайнятий.",
	[2080091530] = "%s має невідповідний клас для цього завдання.",
	[3505307490] = "%s не зміг поділитися з вами завданням \"%s\". У вас невідповідний клас для цього завдання.",
	[1025455781] = "Неможливо поділитися завданнями у міжфракційній групі.",
	[4254198852] = "%s мертвий.",
	[2528284583] = "%s не зміг поділитися з вами завданням \"%s\". Ви мертві.",
	[535241316] = "%s відхилив ваше завдання.",
	[3377592871] = "Сьогодні це завдання недоступне для %s.",
	[3158341791] = "%s не зміг поділитися з вами завданням \"%s\". Сьогодні вам воно недоступне.",
	[2751565054] = "%s не є власником відповідного доповнення для цього завдання.",
	[2664631253] = "%s не зміг поділитися з вами завданням \"%s\". Ви не володієте відповідним доповненням для цього завдання.",
	[2263141414] = "У %s занадто висока репутація для цього завдання.",
	[305608995] = "%s не зміг поділитися з вами завданням \"%s\". У вас занадто висока репутація для цього завдання.",
	[1297594880] = "У %s занадто високий рівень для цього завдання.",
	[3660832590] = "%s не зміг поділитися з вами завданням \"%s\". У вас занадто високий рівень для цього завдання.",
	[3509635925] = "Це завдання недоступне для %s.",
	[916640133] = "%s не зміг поділитися з вами завданням \"%s\". Вам воно недоступне.",
	[2278152442] = "У %s повний журнал завдань.",
	[3356430262] = "%s не зміг поділитися з вами завданням \"%s\". У вас повний журнал завдань.",
	[3703010765] = "У %s занадто низька репутація для цього завдання.",
	[445333232] = "%s не зміг поділитися з вами завданням \"%s\". У вас занадто низька репутація для цього завдання.",
	[4149861279] = "У %s недостатній рівень для цього завдання.",
	[2755360919] = "%s не зміг поділитися з вами завданням \"%s\". У вас недостатній рівень для цього завдання.",
	[1453160765] = "%s повинен пройти Край вигнанців, щоб прийняти це завдання.",
	[4248791388] = "%s не зміг поділитися з вами завданням \"%s\". Ви повинні пройти Край вигнанців, щоб прийняти це завдання.",
	[3201211448] = "Цим завданням неможливо поділитися.",
	[990329666] = "Сьогодні цим завданням неможливо поділитися.",
	[113899970] = "У %s повинен бути гарнізон, щоб прийняти це завдання.",
	[2698039587] = "%s не зміг поділитися з вами завданням \"%s\". У вас повинен бути гарнізон, щоб прийняти його.",
	[65159223] = "%s вже виконує це завдання.",
	[1960720256] = "%s не зміг поділитися з вами завданням \"%s\". Ви вже виконуєте його.",
	[3838764751] = "%s ще не виконав усі попередні завдання, щоб розблокувати це завдання.",
	[2290455889] = "%s не зміг поділитися з вами завданням \"%s\". Ви повинні виконати попередні завдання, щоб розблокувати його.",
	[1507986146] = "%s має невідповідну расу для цього завдання.",
	[606698601] = "%s не зміг поділитися з вами завданням \"%s\". У вас невідповідна раса для цього завдання.",
	[384725895] = "Ділимося завданням з %s...",
	[414792356] = "Час передачі завдання сплинув.",
	[845706358] = "%s надто далеко, аби прийняти це завдання.",
	[1146130647] = "%s у союзі з невідповідним ковенантом для цього завдання.",
	[3899308531] = "%s не зміг поділитися з вами завданням \"%s\". Ви в союзі з невідповідним ковенантом для нього.",
	[3960858897] = "%s невідповідної фракції для цього завдання.",
	[3378762475] = "%s не зміг поділитися з вами завданням \"%s\". Ви невідповідної фракції для нього.",
	[3662137789] = "Досвіду отримано: %d.",
	[1672400986] = "Отримано %s.",
	[2375871731] = "%s відхилив запит на синхронізацію групи.",
	[2394783879] = "%s не може долучитися до синхронізації групи.",
	[2779153321] = "<Натисніть, щоб переглянути деталі завдання>",
	[3899841544] = "Відмовитись від завдання",
	[3201424402] = "Доступне завдання",
	[1520028626] = "Доступні завдання",
	[983708436] = "Відмовитись",
	[2735104986] = "Колекції",
	[508003565] = "Відкрити колекції",
	[968443198] = "Поточні завдання",
	[731324689] = "Щоденний",
	[3184614002] = "Провалено",
	[3483582225] = "Прощавай",
	[3225016429] = "Честь",
	[2582753560] = "Ви зможете обрати одну з цих винагород:",
	[1412854787] = "Ви також отримаєте:",
	[705804663] = "Вивчіть заклинання:",
	[3774893773] = "Необхідно коштів:",
	[2386879143] = "Журнал мандрівника",
	[3594205912] = "Показати завдання на карті",
	[2153556690] = "Припинити відстеження",
	[1826108517] = "Відкрити досягнення",
	[182049493] = "Відкрити подробиці завдання",
	[3729677105] = "Завдання",
	[1984596275] = "Цілі",
	[399146395] = "Неподалік знаходяться члени групи, які виконують це завдання:",
	[3707079622] = "Професія",
	[3028023320] = "Знаходиться вище",
	[1382737883] = "Знаходиться нижче",
	[1350016219] = "Завдання призупинено",
	[215413151] = "Ви повторно проходите це завдання",
	[150744087] = "Можна здати",
	[1513136720] = "Прийняти",
	[1194678071] = "Завершити завдання",
	[2555539391] = "Відмовитись",
	[1422328748] = "Опис",
	[1968440718] = "Цілі завдання",
	[2953231036] = "Необхідні предмети:",
	[3313211597] = "Виконання цього завдання, коли \"Синхронізація групи\" увімкнена, може принести винагороду:",
	[1460269770] = "Це буде застосовано на вас:",
	[3621348884] = "Ви зможете обрати одну з цих винагород:",
	[2094226663] = "Оберіть свою винагороду:",
	[2350774399] = "Ви отримаєте цих послідовників:",
	[4007614220] = "Ви отримаєте цих послідовників:",
	[3401302330] = "Ви отримаєте:",
	[3584142987] = "Ви вивчите наступне:",
	[990016224] = "Ви отримаєте титул:",
	[2944653765] = "Вам буде розблоковано доступ до наступного:",
	[3358209493] = "Нагороди",
	[3096062092] = "Поділитися завданням",
	[1167762123] = "Сценарій",
	[2151422229] = "Показати карту",
	[2981118587] = "Відстежувати завдання",
	[3469259406] = "Відстежувати",
	[1967486269] = "Не відстежувати завдання",
	[748778216] = "Не відстежувати",
	[1939630227] = "Завершивши цю главу, ви отримаєте винагороду:",
	[1827938288] = "Щотижневий",
	[2941900059] = "Бонус від Режиму війни",
	[1362972821] = "Досвід:",
	[444421164] = "Додаткові цілі",
	[4254143324] = "Арена випробувань",
	[227272517] = "Локальні завдання",
	[912701099] = "Усі цілі",
	[1214043990] = "0/1 %s (Необов'язково)",
	[3052885364] = "%s (Необов'язково)",
	[1283697456] = "У цього завдання немає цілей, які можна відстежувати",
	[2095799940] = "Натисніть, щоб завершити завдання",
	[784940412] = "Натисніть, щоб завершити",
	[1712543937] = "Натисніть, щоб переглянути завдання",
	[1110488776] = "Завдання виконано!",
	[154906229] = "Виявлено завдання!",
	[1991293512] = "Завдання виконано",
	[3696000359] = "Клацніть мишкою на завдання, утримуючи Shift, щоб додати чи забрати його зі списку відстеження.",
	[4024162423] = "Можна відстежувати лише %d завдань одночасно.",
	[2933419040] = "Показати кінцевий пункт призначення",
	[2888731936] = "Показати маршрут",
	[3350888648] = "Персонаж",
	[3595254532] = "Характеристики",
	[936917770] = "Посилення",
	[1254741444] = "Плечі",
	[3502818861] = "Характеристики персонажа",
	[2092401980] = "Звання",
	[2178106580] = "Керування спорядженням",
	[4161737467] = "У вас немає жодного звання.",
	[3124919081] = "Ця функція стає доступною на {1} рівні.",
	[2787259978] = "Ця функція розблокується, коли ви оберете фракцію.",
	[569951958] = "Ця функція поки що недоступна.",
	[2290308330] = "Ця функція недоступна, поки ви не оберете фракцію.",
	[904927269] = "Спорядити",
	[2966765606] = "Зберегти",
	[1890320425] = "Гаразд",
	[3350884305] = "Новий набір",
	[2094327417] = "Введіть назву набору (до 16 символів):",
	[2637281895] = "Зараз вибрано",
	[592391050] = "Натисніть, щоб переглянути в списку",
	[848836732] = "Виберіть піктограму:",
	[165543386] = "Видалити",
	[3134222846] = "Налаштування",
	[1145341624] = "Усі піктограми",
	[3946955372] = "Предмети",
	[3898715350] = "Заклинання",
	[1065047008] = "Змінити назву/піктограму",
	[2997878588] = "Прив'язати до спеціалізації:",
	[2994179272] = "Цієї піктограми немає в переліку",
	[1078183605] = "Ігнорувати цю комірку",
	[2138998259] = "Враховувати цю комірку",
	[2275647595] = "Помістити в сумку",
	[3033261355] = "Ви впевнені, що хочете видалити цей набір спорядження: «%s»?",
	[2790883024] = "Так",
	[3248434449] = "Ні",
	[562234577] = "У вас вже є набір спорядження з назвою «%s». Бажаєте його перезаписати?",
	[1596427027] = "Бажаєте зберегти цей набір спорядження: «%s»?",
	[1108560757] = "{1} {declension|предмет|предмети|предметів}",
	[2166970997] = "{1} {declension|предмет|предмети|предметів} в інвентарі",
	[52406159] = "Споряджено {1} {declension|предмет|предмети|предметів}",
	[1346242350] = "Бракує елемента: %s",
	[447334577] = "Бракує елемента: %s %d",
	[1353752731] = "Перстень",
	[2140731502] = "Повернути вліво",
	[1446056845] = "Повернути мінікарту",
	[2947675916] = "Повернути вправо",
	[512499572] = "ЛКМ на персонажа та потягніть, щоб повернути.",
	[1334479587] = "Наблизити",
	[3847515610] = "Віддалити",
	[1084758888] = "Коліщатко миші вниз",
	[879934433] = "Коліщатко миші вверх",
	[1392126836] = "Скинути розташування",
	[329483256] = "Споряджено {1} {declension|предмет|предмети|предметів}",
	[3962105290] = "{1} {declension|предмет|предмети|предметів} в інвентарі",
	[1666928045] = "{1} {declension|предмет|предмети|предметів}",
	[3230668162] = "Збільшує вашу шкоду та зцілення на {1}% та зменшує вхідну шкоду на {2}%.\n\nУніверсальність: {3} [{4}%/{5}%]",
	[1923227658] = "Рівень предметів: {1}",
	[3206587982] = "Рівень предметів: {1} (споряджених — {2})",
	[3436972676] = "Середній рівень предметів вашого спорядження.",
	[2387098979] = "Середній рівень предметів вашого спорядження.\n\nРівень PvP-предметів: {1}",
	[2697130722] = "Швидкість атаки (в секундах)",
	[3590179451] = "Шкода",
	[1336717336] = "Збільшує силу атаки ваших прислужників на {1} та їхню шкоду від магії на {2}.",
	[2032095862] = "Ваша шкода від темної магії збільшує силу атаки ваших прислужників на {1} та їхню шкоду від магії на {2}.",
	[711415160] = "Ваша шкода від вогню збільшує силу атаки ваших прислужників на {1} та їхню шкоду від магії на {2}.",
	[789122850] = "Щоб користуватися перевагами майстерності, потрібно вибрати спеціалізацію.",
	[1178855040] = "Швидкість пересування",
	[3661418623] = "Швидкість бігу: {1}%",
	[1064532885] = "Швидкість польоту: {1}%",
	[2908735976] = "Швидкість плавання: {1}%",
	[2487779579] = "Зменшення вхідної фізичної шкоди: {1}%\n{ff888888|(У бою з рівним по силі ворогом)}",
	[1273954080] = "(Проти поточної цілі: {1}%)",
	[2577709058] = "Максимальний запас здоров'я. Коли запас здоров'я падає до нуля, ви гинете.",
	[2353491889] = "Максимальний запас здоров'я. Коли запас здоров'я істоти падає до нуля, вона гине.",
	[1975589484] = "Максимальний запас мани. Мана витрачається на застосування заклинань.",
	[538490837] = "Максимальний запас гніву. Гнів витрачається при застосуванні здібностей і накопичується, коли персонаж атакує ворогів або отримує шкоду.",
	[2533895068] = "Максимальний запас концентрації. Концентрація витрачається при застосуванні здібностей і поступово відновлюється.",
	[790220709] = "Максимальний запас енергії. Енергія витрачається при застосуванні здібностей і поступово відновлюється.",
	[3839370067] = "Максимальний запас сили рун.",
	[1362750929] = "[Похитування] відкладає {1}% вхідної шкоди.",
	[3302676163] = "{ff808080|Ця характеристика марна для вас}",
	[198539975] = "({1}% проти поточної цілі)",
	[2356970897] = "Показник ухилення {1} надає {2}% шансу ухилення.\n{ff888888|(до зниження ефективності показника)}",
	[2826207695] = "Блокування зменшує шкоду від атаки на {1}%.\n{ff888888|(У бою з рівним по силі ворогом)}",
	[2903847306] = "Показник парирування {1} надає {2}% шансу парирування.\n{ff888888|(до граничного значення показника)}",
	[102060419] = "Збільшує діапазон шкоди ваших атак та здібностей.",
	[1084983086] = "Швидкість атаки збільшена на {1}%.",
	[2903719296] = "Збільшує шкоду, завдану зброєю ближнього бою на {1} в секунду.\nЗбільшує силу заклинань на {2}.",
	[2219968717] = "Збільшує шкоду, завдану зброєю дальнього бою на {1} в секунду.",
	[3253844838] = "Збільшує шкоду, завдану зброєю ближнього бою на {1} в секунду.",
	[147107967] = "Збільшує шкоду та зцілення від заклинань.",
	[1091765477] = "Ймовірність завдати додаткової шкоди та відновити більше здоров'я.\n\nШанс критичного удару: {1} [+{2}%]\n\nЗбільшує шанс парирування на {3}%.",
	[1728813367] = "Ймовірність завдати додаткової шкоди та відновити більше здоров'я.\n\nШанс критичного удару: {1} [+{2}%]",
	[2992030036] = "Обсяг енергії, який відновлюється щосекунди.",
	[37812283] = "Обсяг концентрації, який відновлюється щосекунди.",
	[3076754799] = "Час відновлення для кожної вашої руни.",
	[2368923565] = "Обсяг мани, що відновлюється раз в {1} сек.",
	[3189597100] = "Збільшує швидкість пересування.\n\nСтрімкість: {1} [+{2}%]",
	[4269127137] = "Зцілює вас на частину завданої шкоди та вихідного зцілення.\n\nСамозцілення: {1} [+{2}%]",
	[206350257] = "Зменшує вхідну шкоду від атак по площі.\n\nУникнення: {1} [+{2}%]",
	[13369628] = "Збільшує запас здоров'я на {1}.",
	[1382292389] = "Збільшує діапазон шкоди ваших заклинань.",
	[3371067483] = "Збільшує діапазон шкоди ваших атак та здібностей.\n\nЗбільшує шанс парирування на {1}%.\n{ff888888|(до граничного значення показника)}",
	[859931974] = "Збільшує діапазон шкоди ваших атак та здібностей.\n\nЗбільшує шанс ухилення на {1}%.\n{ff888888|(до граничного значення показника)}",
	[1580989612] = "Зменшує всю шкоду, завдану іншими гравцями та їхніми вихованцями або прислужниками.\n\nСтійкість: {1} (+{2}% до стійкості)",
	[216087033] = "Збільшує швидкість атаки та застосування заклинань.\n\nШвидкість: {1} [+{2}%]",
	[3340870310] = "Збільшує швидкість атаки та відновлення рун.\n\nШвидкість: {1} [+{2}%]",
	[1206619303] = "Збільшує швидкість атаки, застосування заклинань та відновлення енергії.\n\nШвидкість: {1} [+{2}%]",
	[3643630546] = "Збільшує швидкість атаки та відновлення концентрації.\n\nШвидкість: {1} [+{2}%]",
	[1073901085] = "Збільшує швидкість атаки та відновлення енергії.\n\nШвидкість: {1} [+{2}%]",
	[397629812] = "Ви впевнені, що бажаєте видалити цей макрос?",
	[2622073557] = "Створити",
	[997323488] = "Вийти",
	[2359202961] = "Символи: {1}/{2}",
	[3158200543] = "Введіть назву макроса (до 16 символів):",
	[3394369399] = "Введіть макрос:",
	[566392011] = "Макроси %s",
	[359948756] = "Загальні макроси",
	[2604949006] = "Рівень предметів",
}

