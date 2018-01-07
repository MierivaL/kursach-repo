program GraphicsEditor;


uses
    crt, WinCrt, WinGraph;

{ создаём тип граф. объекта }
type
    int = integer;
    graphObject = record
        oType: byte; { тип: 1 - линия, 2 - прямоугольник, 3 - круг/окружность }
        color: byte; { цвет }
        fill: boolean; { заливка }
        x, y, c1, c2: word; { координаты и размер/радиус }
    end;
    chset = set of char;

{ информация о программе }
const
    {включение режима для стандартного Graph}
    fpcGraph = false;

    isBeta = true; { флаг бета-версии }
    buildNum = '237'; buildDate = '26.05.2015 08:14';

    appName = 'Graphics Editor';
    appVersion = '1.0-beta.113';
    appAuthor = 'Vyacheslav Makhonin [BPS]';
    appCreate = 'April-May 2015';

    { Типы граф. объектов и их цвета }
    oTStr: array[1..3] of string[15] = (
    'Line', 'Rect', 'Circle'
    );

    oCStr: array[0..15] of string[15] = (
    'Black', 'Blue', 'Green', 'Cyan',
    'Red', 'Magenta', 'Brown', 'LightGray',
    'DarkGray', 'UghtBlue', 'LightGreen', 'LightCyan',
    'LightRed', 'LightMagenta', 'Yellow', 'White'
    );

    { допустимые символы для имени файла }
    nameSet: set of char = ['0'..'9', 'a'..'z', 'A'..'Z', '.', '_', '\', ':'];
    numSet: set of char = ['0'..'9'];

    { Клавиши }
    UP: chset = [#72, 'W', 'w'];
    LEFT: chset = [#75, 'A', 'a'];
    DOWN: chset = [#80, 'S', 's'];
    RIGHT: chset = [#77, 'D', 'd'];
    KEYL: chset = ['L', 'l'];
    KEYF: chset = ['F', 'f'];
    KEYX: chset = ['X', 'x'];

    ENTER = #13; ESC = #27; BKPSPC = #8;

var
    g, h, menx: integer;
    speed: byte; // Скорость перемещения курсора
    keySymb, prevKeySymb: char;
    maxx, maxy: word;
    obj: graphObject;
    { useBitmap: использование предыдущего изображения в качестве фона в граф. редакторе }
    { 1 - использовать, остальное - не использовать }
    { недостатки - уменьшение скорости работы в редакторе и мерцания в нём же }
    useBitmap: byte;
    { debugMode - функии отладки }
    debugMode: boolean;
    { временная переменная }
    temp: string;
    p: pointer;
    f: file of graphObject;

{ Загрузка файла конфигурации }
procedure commandLine;
var
    t: string;
    cFile: text;
begin
    assign(cFile, 'commandline.txt');
    {$I-} { директива - игнорирование ошибок при открытии файла }
          { для проверки на его наличие }
    reset(cFile);
    {$I+}
    {Если файл есть - читаем его и выполняем команды}
    if IOResult = 0 then
    begin
        while not Eof(cFile) do
        begin
            readln(cFile, t);
            if t = 'debugMode := true;' then debugMode := true; {Дебаг-режим}

            if t = 'useBitmap := soft;' then useBitmap := 1; {"мягкий" Bitmap-режим}
            if t = 'useBitmap := true;' then useBitmap := 2; {полноценный Bitmap-режим}
        end;
        close(cFile);
    end;
end;

{ Упрощение процедуры ввода }
procedure keyEnter;
begin
	keySymb := WinCrt.ReadKey;
	if keySymb = #0 then
	begin
	    prevKeySymb := keySymb;
	    keySymb := WinCrt.ReadKey;
	end;
end;

{ внутренняя процедура - обмен значений }
{ для корректной работы WinGraph }
procedure swap(var a, b: word);
var
    t: word;
begin
    t := a;
    a := b;
    b := t;
end;


{ поле ввода. Располагается на экране в зависимости от dmns }
{ dmns: положение на экране. Начиная с 0 }
{ inStr: строка, в которую записываем текст }
{ drStr: строка с описанием поля ввода }
{ SetS: множество доступных символов }
procedure inputField(const dmns: byte; var inStr: string; const drStr: string; const SetS: chset);
begin
    keySymb := ' ';
    SetColor(7);
    SetFillStyle(0, 0);
    bar(30, 70 + (dmns * 100), textwidth(drStr), textheight(drStr) + (dmns * 100));
    bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100));
    OutTextXY(30, 70 + (dmns * 100), drStr);
    while(keySymb <> ENTER) do
    begin
        keyEnter;
        { при вводе Backspace - удаляем последний символ }
        if ((keySymb = BKPSPC) and (ord(inStr[0]) <> 0)) or (keySymb in SetS) then
        begin

            bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100));
            { удаление символов }
            if (keySymb = BKPSPC) and (ord(inStr[0]) <> 0)then inStr[0] := chr(ord(inStr[0]) - 1);
            { добавление символов }
            if (keySymb in SetS) then inStr := inStr + keySymb;

            OutTextXY(30, 120 + (dmns * 100), inStr);
       end else if (keySymb = ESC) and (debugMode = true) then Halt(0); { выход из программы во время ввода по нажатию Esc в Beta-режиме }
    end;
end;


procedure objInfo(const gr: boolean);
var
    s1, s2, temp, temp2: string;
begin
    { вывод информации об объекте }
    write('Object ', filepos(f), ': ');
    with obj do
    begin
        s1 := oTStr[oType];
        if not(oType=1) then
        begin
            if fill = true then temp := 'True' else temp := 'false';
            s1 := s1 + (', Fill: ' + temp);
        end;
        s1 := s1 + (', Color: ' + oCStr[color]);
        str(x, temp); str(y, temp2);

        s2 := ('    x1:' + temp + ' x2:' + temp2);
        str(c1, temp); str(c2, temp2);
        if otype=3 then s2 := s2 + (' rad:' + temp)
        else s2 := s2 + (' x2:' + temp +' y2:' + temp2);
    end;
    if gr=true then
    begin
        SetColor(7); OutTextXY(30, 20, s1); OutTextXY(30, 50, s2);
    end
    else
    begin
        writeln(s1); writeln(s2);
    end;
end;


procedure drawObject; { вывод объекта }
begin
    { WinGraph fix for rects }
    with obj do begin
        if (oType = 2) then
        begin
            if (x>c1) then swap(x, c1);
            if (y>c2) then swap(y, c2);
        end;
    end;

    if obj.oType = 1 then with obj do
    begin
        SetColor(color);
        line(x, y, c1, c2);
    end
    else
    if obj.oType = 2 then with obj do
    begin
        SetColor(color);
        if fill = true then
        begin
            SetFillStyle(1, color);
            bar(x, y, c1, c2);
        end
        else
        begin
            rectangle(x, y, c1, c2);
        end;
    end
    else
    if obj.oType = 3 then with obj do
    begin
        SetColor(color);
        if fill = true then
        begin
            SetFillStyle(1, color);
            FillEllipse(x, y, c1, c1);
        end
        else
        begin
            Circle(x, y, c1);
        end;
    end;
end;


procedure drawFF; { чтение объекта из файла и его вывод }
begin
    close(f);
    reset(f);
    writeln('-----');
    while not Eof(f) do
    begin
        read(f, obj);
        drawObject;
        if debugMode = true then objInfo(false);
    end;
    writeln('-----');
end;


procedure menuChange(const ix: word); { отрисовка меню }
var
    t: string;

begin
    SetFillStyle(1, 0);
    SetColor(7);
    ClearViewPort; { чистим экран }

    { Информация об авторе }
    t := appName + ' | ' + appAuthor + ' | ' + appVersion + ' | ' + appCreate;
    if debugMode = true then
    begin
        t := t + ' | Build ' + buildNum + ' | ' + buildDate;
    end;
    OutTextXY(((maxx div 2) - (TextWidth(t) div 2)), 20, t);
    Line(0, 40, maxx, 40);

    { выводим пункты }
    OutTextXY(30, 70, 'Create/Open');
    OutTextXY(30, 120, 'About');
    OutTextXY(30, 170, 'Quit');
    if debugMode = true then OutTextXY(30, 220, 'Clean CRT-log screen');

    { рисуем активный элемент меню }
    SetFillStyle(1, 7);
    Bar(0, ix, maxx, ix+50);
    SetColor(0);
    { вывод надписи в зависимости от пункта }
    case menx of
        50: OutTextXY(30, menx + 20, 'Create/Open');
        100: OutTextXY(30, menx + 20, 'About');
        150: OutTextXY(30, menx + 20, 'Quit');
        200: OutTextXY(30, menx + 20, 'Clean CRT-log screen');
    end;
end;

procedure getMemForBitMap; { выделение памяти для изображения }
var
    Size: longint;
begin
    Size := ImageSize(0, 0, maxx, maxy);
    GetMem(P, Size);
end;

procedure loadBitMap; { загрузка ранее нарисованного изображения. Для граф. редактора }
begin
    SetActivePage(0);
    GetImage(0, 0, maxx, maxy, P^);
    SetActivePage(1);
end;

procedure drawBitMap; { вывод изображения }
begin
    PutImage(0, 0, P^, XORPut);
end;


procedure softDrawBitmap;
begin
    drawBitMap;
    drawObject;;
    WinCrt.ReadKey;
end;


procedure changeSpeed;
begin
    case speed of
        1: speed := 10;
        10: speed := 50;
        50: speed := 1;
    end;
end;

procedure setStartXY;
var
    r, t, st: string;
begin
    obj.x := 10; obj.y := 10; keySymb := ' ';
    while(keySymb <> ENTER) do
    begin
        ClearViewPort;
        if useBitmap = 2 then drawBitMap;
        if obj.oType in [1..2] then begin obj.c1 := obj.x+10; obj.c2 := obj.y + 10; end
        else begin obj.c1 := 10; obj.c2 := 10; end;
        drawObject;;
        setColor(7);
        str(obj.x, r); str(obj.y, t); str(speed, st);
        OutTextXY(30, 30, 'Set X [' + r + '] and Y[' + t + '], speed: ' + st);
        keyEnter;
        if (keySymb in UP) and (obj.y > (speed - 1)) then obj.y := obj.y - speed;
        if (keySymb in DOWN) and (obj.y < maxy - speed) then obj.y := obj.y + speed;
        if (keySymb in LEFT) and (obj.x > (speed - 1)) then obj.x := obj.x - speed;
        if (keySymb in RIGHT) and (obj.x < maxx - speed) then obj.x := obj.x + speed;
        if (keySymb in KEYL) and (useBitmap = 1) then softDrawBitmap;
        if (keySymb in KEYF) then changeSpeed;
    end;
end;

procedure setFinalXY;
var
    r, t, st: string;
    tx, ty, tc1, tc2: word;
begin
    keySymb := ' ';
    tx := obj.x; ty := obj.y;
    tc2 := obj.c2; tc1 := obj.c1;
    while(keySymb <> ENTER) do
    begin
        ClearViewPort;
        if useBitmap = 2 then drawBitMap;
        drawObject;
        setColor(7);
        str(obj.c1, r); str(obj.c2, t); str(speed, st);
        OutTextXY(30, 30, 'Set final X [' + r + '] and Y[' + t + ']' + ', speed: ' + st);
        keyEnter;
        if (keySymb in UP) and (tc2 > (speed - 1)) then tc2 := tc2 - speed;
        if (keySymb in DOWN) and (tc2 < maxy - speed) then tc2 := tc2 + speed;
        if (keySymb in LEFT) and (tc1 > (speed - 1)) then tc1 := tc1 - speed;
        if (keySymb in RIGHT) and (tc1 < maxx - speed) then tc1 := tc1 + speed;
        if (keySymb in KEYL) and (useBitmap = 1) then softDrawBitmap;
        if (keySymb in KEYF) then changeSpeed;

        obj.x := tx; obj.y := ty;
        obj.c1 := tc1; obj.c2 := tc2;
    end;
end;

procedure setRadius;
var
    r, t, st: string;
begin
    keySymb := ' ';
    while(keySymb <> ENTER) do
    begin
        ClearViewPort;
        if useBitmap = 2 then drawBitMap;
        drawObject;
        setColor(7);
        str(obj.c1, r); str(obj.c2, t); str(speed, st);
        OutTextXY(30, 30, 'Set radius [' + r + '], speed: ' + st);
        keyEnter;

        if ((keySymb in LEFT) or (keySymb in DOWN)) and (obj.c1 > (speed - 1)) then obj.c1 := obj.c1 - speed;
        if ((keySymb in RIGHT) or (keySymb in UP)) and (obj.c1 < maxx - speed) then obj.c1 := obj.c1 + speed;
        if (keySymb in KEYL) and (useBitmap = 1) then softDrawBitmap;
        if (keySymb in KEYF) then changeSpeed;

        obj.c2 := obj.c1;
    end;
end;

procedure setObjPar;
begin
    setStartXY;
    if obj.oType in [1..2] then setFinalXY
    else setRadius;
end;

procedure workS;
var
    r, t: string; i: byte; objNum: longint;
    fm: byte; { указатель на порядок поля }
begin
    r := ' ';

    while not (r[1] in KEYX) do
    begin
        fm := 0; r := '';
        WinCrt.ReadKey;
        if (useBitmap <> 0) or (fpcGraph = true) then loadBitMap;
        SetActivePage(1); SetVisualPage(1); ClearViewPort;
        SetColor(7);
        OutTextXY(30, 30, 'Object types:');
        OutTextXY(30, 50, '1 - Line, 2 - Rect, 3 - Circle');
        inputField(fm, r, 'Enter your type (or: X for main menu, L for object viewer):', nameSet);
        if (r = '1') or (r = '2') or (r = '3') then
        begin
            val(r, obj.oType);
            fm := fm + 1;
            if (r = '2') or (r = '3') then
            begin
                OutTextXY(30, 170, 'Fill? [Y/N]');
                keyEnter;
                if (keySymb = 'Y') or (keySymb = 'y') or (keySymb = 'Н') or (keySymb = 'н') then
                begin
                    obj.fill := true;
                    OutTextXY(30, 220, 'Yes');
                end else begin
                    obj.fill := false;
                    OutTextXY(30, 220, 'No');
                end;
            end;
            fm := fm + 1;
            for i := 0 to 15 do
            begin
                Str(i, r);
                if i > 0 then SetColor(i);
                r :=  r + ' - ' + oCStr[i];
                OutTextXY(600, 20 + (i * 15), r);
            end;
            SetColor(7);
            r := '16';
            val(r, obj.color);
            while not (obj.color in [0..15]) do
            begin
                r := '';
                inputField(fm, r, 'Set color (enter "help" for list)', numSet);
                val(r, obj.color);
            end;

            val(r, obj.color);
            { установка начальных x и y }
            setObjPar;

            write(f, obj);
            ClearViewPort;
            SetActivePage(0); SetVisualPage(0);
            drawObject;
            objInfo(false);
        end

        { менеджер объектов }
        else if (r[1] in KEYL) then
        begin
            r := '';
            ClearViewPort;
            if filesize(f) = 0 then
            begin
                OutTextXY(30, 70, 'Empty file!');
            end
            else
            begin
                str(filesize(f), t);

                while (r < '1') or (r > t) do
                begin
                    ClearViewPort;
                    r := '';
                    inputField(0, r, ('Number of object [1..' + t + ']:'), numSet);
                    val(r, objNum);
                end;

                seek(f, objNum-1);
                read(f, obj);
                ClearViewPort;
                drawObject;
                objInfo(true);
                if debugMode = true then objInfo(false);


                seek(f, filesize(f)-1);
                read(f, obj);
            end;
            WinCrt.ReadKey;
            setActivePage(0); setVisualPage(0);
        end;
        {правка для станд. Graph}
        if fpcGraph = true then
        begin
            drawBitmap;
            drawObject;
        end;
    end;

    close(f);
    SetActivePage(0); SetVisualPage(0);
    CLearViewPort;
    menx := 50;
    menuChange(menx);
    keySymb := ' ';
end;


procedure start; { загрузка файла }
var
    fname:string;

begin
    ClearViewPort;
    fname := '';

    { вводим имя файла }

    inputField(0, fname, 'Enter file name [0-9a-z._] (or "x" for main menu)', nameSet);

    if (keySymb = ENTER) and (fname<>'') then
    begin
        if (fname[1] in KEYX) then
        begin
            keySymb := ' ';
            menuChange(menx);
        end else begin
            assign(f, fname);
            {$I-} { директива - игнорирование ошибок при открытии файла }
                  { для проверки на его наличие }
            reset(f);
            {$I+}
            ClearViewPort;
            if IOResult=0 then drawFF { если файл найден - запускаем процедуру отрисовки его объектов }
            else rewrite(f); { иначе - создаём его }
            workS; { переход к добавлению новых объектов }
        end;
    end;
end;

procedure about; { Окно "О программе" }
var
    t: string;
begin
    keySymb := ' '; SetVisualPage(1); SetActivePage(1);
    ClearViewPort;
    SetColor(7);
    t := 'Graphics Editor by BPS';
    OutTextXY((maxx div 2) - (TextWidth(t) div 2), 40, t);
    t := '(built in Free Pascal 2.4.0 + WinGraph)';
    OutTextXY((maxx div 2) - (TextWidth(t) div 2), 90, t);
    OutTextXY(30, 190, '- Graphics interface');
    OutTextXY(30, 290, '- 3 types of object: line, circle, rect');
    OutTextXY(30, 390, '- Ability to view characteristics of any objects');
    t := 'Press any key to continue';
    OutTextXY((maxx div 2) - (TextWidth(t) div 2), maxy - 150, t);
    WinCrt.readkey;
    SetVisualPage(0); SetActivePage(0);
end;

procedure clean; { чистим экран и выводим инфу о проекте }
begin
    clrscr;
    writeln(appName); writeln('By ', appAuthor);
    writeln('Version: ', appVersion);
    writeln(appCreate);
    { вывод бета-инфы }
    if debugMode = true then
    begin
        writeln;
        writeln('Beta version'); write('Build ', buildNum, ', ', buildDate);
        writeln; writeln;
    end;
    writeln('Use graphics window!');
end;

procedure initial; { инициализация всех глобальных переменных }
begin
    fillchar(g, ofs(obj) - ofs(g) + sizeof(obj), 0)
end;

begin
    initial;

    commandLine; {Загрузка файла конфигурации}
    clean;
    g := VGA; h := mFullScr;
    initGraph(g, h, '');
    { если граф. модуль не загружается - выключаем программу }
    if GraphResult <> grOk then
    begin
        writeln('Graphics module error! Reboot program now! (or drop it :3)');
        readLn;
        Halt(1);
    end;

    maxx := GetMaxX(); maxy := GetMaxY(); { получаем разрешение рабочей области }


    { Если сипользуем битмап - выделяем место под него }
    if (useBitmap <> 0) or (fpcGraph = true) then getMemForBitmap;

    { Устанавливаем скорость для редактора }
    speed := 1;


    menx := 50; { присваиваем переменной "Пункт меню" первое значение }
    menuChange(menx); { отрисовываем меню в нужном месте }

    { основное меню }
    keySymb := ' ';
    while (keySymb = ' ') do begin
        keyEnter;

        if (keySymb in UP) and (menx > 50) then
        begin
            menx := menx-50; menuChange(menx); keySymb := ' '; { если вверх - поднимаемся на 1 пункт }
        end;
        if (keySymb in DOWN) and (((menx < 200) and (debugMode = true)) or (menx < 150))then
        begin
            menx := menx+50; menuChange(menx); keySymb := ' '; { если вниз - опускаемся }
        end;
        if keySymb = ENTER then
        begin
            { при нажатии Enter проверяем значение переменной menx, и, }
            { в зависимости от него, переходим к нужной процедуре }
            case menx of
                50: start;
                100: about;
                150: Halt(0);
                200: clean;
            end;
        end;
        keySymb := ' '; { опустошаем переменную с клавишей для повторного прохождения цикла }
    end;
    closeGraph;
end.
