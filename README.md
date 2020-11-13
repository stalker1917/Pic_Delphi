# Pic_Delphi
Programming PIC controllers via Delphi

Данный проект позволяет в несколько строчек кода на Дельфи запустить контроллер и подать напряжение на любую ножку. Также поддерживаются таймеры и порты USART.   На выходе получается код Си , который можено запустить, проверить, допустим что светодиод мигает и далее уже писать проект на Си. В перспективе на Дельфи можно будет писать и другие части программы. К программе прилагается код, который настраивает взаимодействие контроллера в Blue-Tooth модулем HC-06.

Пока поддерживается только два вида контроллеров, но будут добавленны и другие. Уже даже в такой сырой версии проект может сэкономить значительное время на настройку контроллеров и таймеров.

Также в Дельфи можно отлаживать код программы. Работу таймеров можно отслеживать в реальном времени.

Для работы надо открыть файлы Project1.dpr и usercode.pas и отредактировать их под конкретную реализацию контроллера. Получившиеся файлы вставить в проект Timer_init, прилагаемый к релизу.

Что сейчас поддерживается
-Контроллер PIC18F4520, PIC32MZ с возможностью писать один код на две платформы.
-Таймеры.
-USART.
-Операторы присваивания, сложения и т.д. в Паскале. Функции inc,dec
-Глобальные переменные
-Глобальные константы
-if,case,for
-Процедуры без параметров и локальных переменных. 


