# Graphics Editor by BPS

# <a href="https://github.com/MierivaL/kursach-repo/releases/tag/v1.0-beta.113">Build 113</a> (26.05.2015)
***(залит 07.01.2018)***
* Возможность управления клавишами WASD в графическом меню
* Подхват параметров запуска из файла **commandline.txt**
  * **debugMode** - вывод отладочной информации
  * **useBitmap** - вывод между полноценным и "мягким" выводом изображения
* Перехват и обработка клавиш вынесены в процедуру **keyEnter**
* Флаг **fpcGraph** для возможности запуска программы со стандартным модулем Graph среды
* Рефакторинг кода

# <a href="https://github.com/MierivaL/kursach-repo/releases/tag/v1.0-beta.105">Build 105</a> (18.05.2015)
 * Фикс битмап-режима. Теперь работает :)

# Build 104 (18.05.2015)
 * Новый редактор объектов. После установки цвета мы можем управлять размещением объекта в визуальном редакторе.
 * ОПЦИОНАЛЬНО: для редактора фоном может служить ещё не изменённый рисунок. **НЕСТАБИЛЬНО, МОЖЕТ НЕ РАБОТАТЬ ВООБЩЕ!!!**
 * Вынесено objInfo из процедуры draw
 * Убрана возможность утсановки несуществующего цвета, приводящая к вылету программы при попытке применения данного объекта

# <a href="https://github.com/MierivaL/kursach-repo/releases/tag/v1.0-beta.61">Build 61</a> (18.05.2015)
 * Поле с вводом цвета всегда отображается в одном месте и не перекрывает список цветов

# Build 59 (17.05.2015)
 * Код-стайл и комменты :)
 * Возвращение Halt(0) для выхода

# Build 54 (12.05.2015)
 * Исправление окна About - добавлена очистка экрана перед его отображением

# <a href="https://github.com/MierivaL/kursach-repo/releases/tag/v1.0-beta.53">Build 53</a> (08.05.2015)
 * Возможность использования клавиш L и X в нижнем регистре
 * Окно Help заменено окном About и функционирует

# Build 49 (07.05.2015)
 * Вставка кодов клавиш ENTER, UP и DOWN в поле констант
 * FullScreen-режим
 * Отображение информации об авторе в основном меню

# Build 40 (29.04.2015)
 * Замена стандартного Graph внешним WinGraph
 * Параметры: режим VGA, разрешение 1024x768
 * Фикс отображения прямоугольников для WinGraph - изначально они не отображались, если начальные координаты были больше конечных
 * Фикс inputField - убрано съезжание текста в бок при изменении положения поля
 * Переделан менеджер объектов - работа в граф. окне + вывод просматриваемого объекта (спасибо WinGraph за это)
 * Убрана недоработка с попыткой создания пустого файла
 * Мелкие исправления графического режима

# Build 23.2 (28.04.2015)
 * Попытка реальзации управления в графическом режиме, минуя консоль (Забаговано и неполноценно)
 * (следствие из первого) Реализация текстового ввода внутри графического окна (процедура inputField)
 * Фикс отображения закрашенных окружностей
 * Разочарование в стандартном графическом модуле FPC :(

# <a href="https://github.com/MierivaL/kursach-repo/releases/tag/v1.0-beta.23">Build 23.1</a> (28.04.2015)
 * Переделано отображение информации об объектах - более понятная информация
 * Отображение информации об определённом объекте по его номеру
 * Возможность получить список доступных цветов при создании объекта

# Build 18 (27.04.2015)
 * Первый релиз
