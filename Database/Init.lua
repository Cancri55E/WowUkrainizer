--- @class WowUkrainizerInternals
local ns = select(2, ...);

-- Constants
ns.FACTION_ALLIANCE = "Альянс"
ns.FACTION_HORDE = "Орда"

ns.LEVEL_TRANSLATION = "Рівень"
ns.LEADER_TRANSLATION = "Ватажок"

ns.SPELL_PASSIVE_TRANSLATION = "Пасивний"
ns.SPELL_RANK_TRANSLATION = "Pівень"
ns.SPELL_NEXT_RANK_TRANSLATION = "Наступний рівень:"

ns.TALENT_REPLACES_TRANSLATION = "Замінює"
ns.TALENT_REPLACED_BY_TRANSLATION = "Замінено на"
ns.TALENT_UPGRADE_TRANSLATION = "Оновлення"

ns.PET_LEVEL_TRANSLATION = "Супутник {1} рівня"
ns.PET_CAPTURABLE_TRANSLATION = "Mожна приручити"
ns.PET_COLLECTED_TRANSLATION = "Зібрано ({1}/{2})"

ns.IS_TRIVIAL_QUEST_POSTFIX_TRANSLATION = " (низький рівень)"
ns.ABANDON_QUEST_CONFIRM_UA = "Відмовитися від \"%s\"?"
ns.YES_UA = "Так"
ns.NO_UA = "Ні"

---@type WowUkrainizerDatabase
ns._db = {}

ns._db.Changelogs = {
    {
        version = "1.13.0",
        date = "06 серпня 2024",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description = [[|cffFFD150Новий функціонал: Переклади підказок предметів.|r

Тепер ви побачите локалізовані підказки при наведенні вказівника миші на ігрові предмети (обладунки, зброя та ін.).

Переклад все ще в процесі. Команда активно працює над перекладом назв, описів та ефектів певних предметів.

|cffFFD150Увага! Пам'ятайте, назви предметів ніколи не перекладаються за допомогою ШІ.|r
]]
    },
    {
        version = "1.12.4",
        date = "04 серпня 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description = [[Виправлено помилку, яка виникала, коли гравець відкривав карту на якій відбувається подія 'Сяйні спогади'.]]
    },
    {
        version = "1.12.2",
        date = "02 серпня 2024",
        color = "blue",
        type = "Покращення",
        author = "Cancri",
        title = nil,
        description = [[Додано переклад для вікна |cffFFD150"Що нового?"|r. Це дозволить вам своєчасно дізнаватися про останні нововведення в доповненні.

Виправлено текстові помилки та неточності в налаштуваннях доповнення]]
    },
    {
        version = "1.12.1",
        date = "01 серпня 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description = "Виправлено помилку, яка виникала, коли гравець використовував заклинання з книги заклинань або панелі дій."
    },
    {
        version = "1.12.0",
        date = "27 липня 2024",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description = [[|cffFFD150Вітаю всіх з виходом пре-патчу Внутрішньої Війни!|r

Друзі, наразі були виправлені критичні помилки, які заважали запуску додатка. Проте, через постійні перебої зі світлом у країні, оновлення під нову версію гри ще в процесі, і старий функціонал може частково не працювати.

Я витрачаю весь свій вільний час на доробку додатка та обіцяю, що докладу всіх зусиль, щоб виправити наявні недоліки й додати максимум нового функціоналу до релізу Внутрішньої Війни.

Хочу щиро подякувати всім гравцям, які вірять у додаток і грають українською. Ваша підтримка неймовірно важлива і надає сил для подальшої роботи над проєктом!
]]
    },
    {
        version = "1.11.1",
        date = "25 березня 2024",
        color = "blue",
        type = "Покращення",
        author = "Cancri",
        title = nil,
        description = "На прохання гравців додана можливість окремо керувати перекладами у вікні \"Карта та журнал завдань\""
    },
    {
        version = "1.11.0",
        date = "22 березня 2024",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description =
        [[|cffFFD150Додані переклади ігрових локацій.|r

Відтепер при переході між локаціями, над мінікартою та на карті будуть відображатися перекладені назви локацій.
На момент виходу оновлення перекладена більшість локацій, але не всі.

Оновлено перелік причетних з яким ви можете ознайомитися в налаштуваннях.]]
    },
    {
        version = "1.10.4",
        date = "16 травня 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлено помилку що виникали при переході до вікна завдань."
    },
    {
        version = "1.10.3",
        date = "16 травня 2024",
        color = "blue",
        type = "Виправлення та Покращення",
        author = "Cancri",
        title = nil,
        description =
        [[Виправлена проблема з неправильною заміною тега {sex} в шильдиках НІП.

За допомогою ШІ було оновлено та перекладено 1500 завдань в Пандарії. Тепер перекладено приблизно 99% всіх завдань доповнення "Тумани Пандарії".

Додаток оновлено до версії клієнту 10.2.7

|cffFFD150УВАГА! Якщо ви бажаєте бачити перекладені мапи в грі ми підготували для вас окреме доповнення WowUkrainizer: Maps Pack котре можете завантажити за цим посиланням |cFFe6095ehttps://www.wowinterface.com/downloads/info26737-WowUkrainizerMapsPack.html |r]]
    },
    {
        version = "1.10.2",
        date = "19 березня 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлено помилку що виникала при відображенні підказки для таланту без активних зв'язків з іншими талантами (такі таланти позначаються червоним кольором)."
    },
    {
        version = "1.10.1",
        date = "10 березня 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлена помилка з аномально великим розміром тексту шильдиків (nameplates) на деяких клієнтах, коли встановлені стандартні адаптовані або власні шрифти."
    },
    {
        version = "1.10.0",
        date = "05 березня 2024",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description = [[Перероблені налаштування додатка, та виправлені проблеми зі шрифтами з увімкненим ElvUI.
Додана форма покрокового налаштування при першому запуску гри з додатком.
Додаток оновлено до версії клієнту 10.2.5
Оновлено перелік причетних з яким ви можете ознайомитися в налаштуваннях.

|cffFFD150УВАГА! Це остання версія яка буде виходити з тегом -alpha. Тому, будь ласка, оновить додаток до release версії (в CurseForge клієнті натисніть ПКМ на додатку -> Release Type -> Release)|r]]
    },
    {
        version = "1.9.6",
        date = "24 лютого 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Додано вікно-сповіщення, яке з'являтиметься при запуску доповнення на клієнті гри з не англійською мовою інтерфейсу."
    },
    {
        version = "1.9.5",
        date = "22 лютого 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлено помилки з відображенням непереведених назв завдань та некоректним відображенням додаткових кнопок у доповненні Immersion."
    },
    {
        version = "1.9.4",
        date = "19 лютого 2024",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлено помилку, яка виникала при спробі перекласти шильдики (nameplates) неворожих НІП в середині групового контенту (рейди, підземелля тощо), через те що Blizzard забороняють маніпуляції з ними. Були внесені зміни що запобігають виникненню цієї помилки, а текст буде залишатися англійським."
    },
    {
        version = "1.9.3",
        date = "18 лютого 2024",
        color = "blue",
        type = "Покращення",
        author = "Cancri",
        title = nil,
        description =
        "Додано підтримку доповнення Immersion. Тепер гравці які його використовують зможуть вмикати переклад завдань."
    },
    {
        version = "1.9.2",
        date = "11 грудня 2023",
        color = "red",
        type = "Виправлення",
        author = "Cancri",
        title = nil,
        description = "Виправлено помилку, через яку додаток міг не підставляти наявні машинні переклади для завдань."
    },
    {
        version = "1.9.1",
        date = "10 грудня 2023",
        color = "blue",
        type = "Виправлення та Покращення",
        author = "Cancri",
        title = nil,
        description =
        "Виправлена проблема з неправильною заміною тега $p на ім'я гравця в описі завдань.\n\nЗа допомогою ШІ було оновлено та перекладено додатково 100 завдань на Драконячих островах. Тепер перекладено приблизно 95% всіх завдань на драконячих островах."
    },
    {
        version = "1.9.0",
        date = "10 грудня 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description =
        "Ми додали changelogs для нашого додатка! Тепер ви можете дізнатися про всі новинки і поліпшення, натиснувши кнопку \"Що нового?\" у налаштуваннях. Також, при першому запуску після оновлення, вам автоматично покажуться зміни в новій версії."
    },
    {
        version = "1.8.19",
        date = "06 грудня 2023",
        color = "blue",
        type = "Машинний переклад",
        author = "Cancri",
        title = nil,
        description = "За допомогою ШІ було перекладенно більше 1000 завдань на Драконячих островах."
    },
    {
        version = "1.8.18",
        date = "01 грудня 2023",
        color = "blue",
        type = "Машинний переклад",
        author = "Cancri",
        title = nil,
        description =
        "За допомогою ШІ було перекладенно 969 завдань в наступних локаціях:  Dun Morogh, Elwynn Forest, Dragon Isles, Ohnahran Plains, Thaldraszus, The Azure Span та Valdrakken."
    },
    {
        version = "1.8.17",
        date = "25 листопада 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = "Переклади завдань від ШІ",
        description =
        [[Додано нову функцію! Тепер якщо для завдання немає перекладу від людини, буде використовуватися машинний переклад згенерований за допомогою ШІ (штучного інтелекту).

Щоб позначити, що читаєте саме машинний переклад, у верхньому правому кутку вікна з завданням з'явиться піктограма з головою робота.

Крім того, в налаштуваннях тепер можна повністю вимкнути функцію машинних перекладів, якщо вони для вас не потрібні. За замовчуванням машинні переклади увімкнені.]]
    },
    {
        version = "1.8.16",
        date = "25 листопада 2023",
        color = "blue",
        type = "Покращення",
        author = "Cancri",
        title = nil,
        description = [[Додано іконку додатка до мінікарти.

Завдяки їй ви швидко можете дізнатися поточну версію додатка, відкрити налаштування (ЛКМ) та перезавантажити ігровий інтерфейс (Shift+ЛКМ).]]
    },
    { version = "1.8.15", date = "25 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено помилку, коли при наявності перекладу текст завершення завдання був порожній у журналі цілей та підказці." },
    { version = "1.8.14", date = "25 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено помилку, коли при наявності перекладу вікно привітання для завдання було не перекладене." },
    { version = "1.8.13", date = "22 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено помилку, коли випадаюче меню для рецептів професії, які ви відстежуєте, було порожнім." },
    { version = "1.8.12", date = "20 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено помилку, коли підказки заклять у книзі заклять не перекладались якщо був встановленний ElvUI." },
    { version = "1.8.10", date = "8 листопада 2023", color = "green", type = "Різне", author = "Cancri", title = nil, description = "Оновлено файл TOC додатку до версії 10.2.0 та списком причетних." },
    { version = "1.8.7", date = "6 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлена помилка з неправильними шрифтами, коли вибрана опція \"використовувати шрифт за замовчуванням\"." },
    { version = "1.8.6", date = "6 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено тег відмінювання для назви класу." },
    { version = "1.8.5", date = "5 листопада 2023", color = "blue", type = "Покращення", author = "Cancri", title = nil, description = "Додано переклад для випадаючого меню журналу завдань та трекера цілей." },
    { version = "1.8.4", date = "5 листопада 2023", color = "blue", type = "Покращення", author = "Cancri", title = nil, description = "Додано переклад підказок для кнопок на карті світу та точок інтересу на карті світу і міні-карті." },
    { version = "1.8.3", date = "4 листопада 2023", color = "blue", type = "Покращення", author = "Cancri", title = nil, description = "Додано переклади для повідомлень про прогрес завдань (жовтий текст який з'являється зверху екрана, наприклад при вбивстві НІП)." },
    { version = "1.8.2", date = "4 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Інформаційна підказка (tooltip) НІП тепер містить перекладену інформацію про завдання та цілі до яких він відноситься, а також коректно перекладає тип НІП." },
    { version = "1.8.1", date = "4 листопада 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Кнопка \"змінити переклад\" приховується якщо у завдання немає перекладу." },
    {
        version = "1.8.0",
        date = "1 листопада 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = "Переклади завдань",
        description =
        [[Відтепер додаток вміє відображати переклади для завдань. Окрім цього переклади будуть відображатися також для цілей та завдань які ви відстежуєте.

Відкривши вікно з текстом завдання ви побачите нову кнопку для перемикання між оригінальним текстом і перекладом. А також окрему кнопку натиснувши на яку ви зможете скопіювати посилання на wowhead.com для цього завдання.

Якщо вам не цікаві переклади завдань, то ви можете вимкнути їх в налаштуваннях.]]
    },
    {
        version = "1.7.0",
        date = "11 жовтня 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description =
        [[Відтепер в грі перекладене головне меню та підказки в кнопках швидкого доступу (персонаж, здібності й таланти тощо).]]
    },
    { version = "1.6.7", date = "11 жовтня 2023", color = "blue", type = "Покращення", author = "Cancri", title = nil, description = "Для перекладачів став доступним тег {sex|%s|%s}. Це дає можливість автоматично обирати правильний переклад в залежності від того, яка стать в НІП, наприклад продавець / продавчиня." },
    { version = "1.6.6", date = "2 жовтня 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлено некоректну заміну числових значень з незакритого кольорового тега в описі заклинання." },
    { version = "1.6.5", date = "14 серпня 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Виправлена некоректна заміна тега для відмінювання слів коли він знаходився всередині інших тегів." },
    { version = "1.6.4", date = "6 серпня 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Додано перевірку, що не потрібно перекладати ім'я НІП, якщо воно приховане, щоб уникнути помилки під час гри." },
    { version = "1.6.3", date = "27 липня 2023", color = "red", type = "Виправлення", author = "Cancri", title = nil, description = "Видалено зайву двокрапку, коли в відеоролику немає імені оповідача." },
    {
        version = "1.6.0",
        date = "26 липня 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description = [[Відтепер додаток вміє перекладати субтитри в кат-сценах та "балакучих головах".]]
    },
    {
        version = "1.5.0",
        date = "23 липня 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description =
        [[Відтепер додаток вміє перекладати повідомлення від НІП які ви бачите в чаті, або в "бульбашках" над головою.

Увага! Blizzard забороняють змінювати текст в бульбашках в середині групового контенту (рейди, підземелля тощо.) тому в них український текст буде лише в чаті!]]
    },
    { version = "1.4.1", date = "22 липня 2023", color = "green", type = "Рефакторинг", author = "melles1991", title = nil, description = "Покращено код для зручнішого керування модулями перекладів та шрифтами." },
    { version = "1.4.0", date = "20 липня 2023", color = "green", type = "Різне", author = "Cancri", title = nil, description = "Покращено автоматичну збірку та розгортання додатка на CurseForge. Вдосконалено процес випуску нових версій додатка." },
    {
        version = "1.3.1",
        date = "20 липня 2023",
        color = "purple",
        type = "Новий функціонал",
        author = "Cancri",
        title = nil,
        description =
        [[Додано нову функцію! Тепер є можливість перекладати субтитри відеороликів. Спочатку будуть додаватися субтитри для відеороликів поточного доповнення, а потім всіх інших.

Також було додано сторінку зі списком причетних (перекладачі, редактори, стрімери тощо) до налаштувань.]]
    },
    { version = "1.3.0", date = "20 липня 2023", color = "green", type = "Різне", author = "Cancri", title = nil, description = "Оновлено файл TOC додатку до версії 10.1.5." },
}
