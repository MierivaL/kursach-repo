uses
    crt, WinCrt, WinGraph;

// информация о программе
const
    isBeta = true; // флаг бета-версии
    buildNum = '105'; buildDate = '18.05.2015 15:52';

    appName = 'GraphEditor';
    appVersion = '1.0 beta';
    appAuthor = 'Vyacheslav Makhonin [BPS]';
    appCreate = 'April 2015';

    // Типы граф. объектов и их цвета
    oTStr: array[1..3] of string[15] = ('Line', 'Rect', 'Circle');

    oCStr: array[0..15] of string[15] = ('Black', 'Blue', 'Green', 'Cyan',
                                       'Red', 'Magenta', 'Brown', 'LightGray',
                                       'DarkGray', 'UghtBlue', 'LightGreen', 'LightCyan',
                                       'LightRed', 'LightMagenta', 'Yellow', 'White');

    // допустимые символы для имени файла
    nameSet: set of char = ['0'..'9', 'a'..'z', 'A'..'Z', '.', '_'];
    numSet: set of char = ['0'..'9'];

    // Коды клавиш
    UP = 72; DOWN = 80; LEFT = 75; RIGHT = 77; ENTER = 13; ESC = 27;

    // использование предыдущего изображения в качестве фона в граф. редакторе
    // 1 - использовать, остальное - не использовать
    // недостатки - уменьшение скорости работы в редакторе и мерцания в нём же
    bitmapUse = 0;

// создаём тип граф. объекта
type
    int = integer;
    drawObject = record
        oType: byte; // тип: 1 - линия, 2 - прямоугольник, 3 - круг/окружность
        color: byte; // цвет
        fill: boolean; // заливка
        x, y, c1, c2: word; // координаты и размер/радиус
    end;
    chset = set of char;

var
    g, h, menx: integer;
    c: string[2];
    maxx, maxy: word;
    obj: drawObject;
    p: pointer;
    f: file of drawObject;

// внутренняя процедура - обмен значений
// для корректной работы WinGraph
procedure swap(var a, b: word);
var
    t: word;
begin
    t := a; a := b; b := t;
end;


// поле ввода. Располагается на экране в зависимости от dmns
// dmns: положение на экране. Начиная с 0
// inStr: строка, в которую записываем текст
// drStr: строка с описанием поля ввода
// SetS: множество доступных символов
procedure inputField(const dmns: byte; var inStr: string; const drStr: string; const SetS: chset);
begin
    C := ' '; SetColor(7); SetFillStyle(0, 0);
    OutTextXY(30, 70 + (dmns * 100), drStr);
    while(ord(C[1]) <> ENTER) do
    begin
        C := WinCrt.ReadKey;
        if ord(C[1])=0 then WinCrt.ReadKey;
        // при вводе Backspace - удаляем последний символ
        if (ord(C[1])=8) and (ord(inStr[0])<>0) then
        begin
            inStr[0] := chr(ord(inStr[0])-1); bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100)); OutTextXY(30, 120 + (dmns * 100), inStr);
        end
        // иначе - записываем
        else if chr(ord(C[1])) in SetS then
        begin
            inStr := inStr+C; bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100)); OutTextXY(30, 120 + (dmns * 100), inStr);
        end else if (ord(C[1]) = ESC) and (isBeta = true) then Halt(0); // выход из программы во время ввода по нажатию Esc в Beta-режиме
    end;
end;


procedure objInfo(const gr: boolean);
var
    s1, s2, temp, temp2: string;
begin
    // вывод информации об объекте
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


procedure draw; // вывод объекта
begin
    //WinGraph fix for rects
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


procedure drawFF; // чтение объекта из файла и его вывод
begin
    close(f);
    reset(f);
    writeln('-----');
    while not Eof(f) do
    begin
        read(f, obj);
        draw;
        objInfo(false);
    end;
    writeln('-----');
end;


procedure menuChange(const ix: word); // отрисовка меню
var
    t: string;

begin
    maxx := getmaxx();
    SetFillStyle(1, 0);
    SetColor(7);
    ClearViewPort; // чистим экран

    // Информация об авторе
    t := appName + ' | ' + appAuthor + ' | ' + appVersion + ' | ' + appCreate;
    if isBeta = true then
    begin
        t := t + ' | Build ' + buildNum + ' | ' + buildDate;
    end;
    OutTextXY(((maxx div 2) - (TextWidth(t) div 2)), 20, t);
    Line(0, 40, maxx, 40);

    // выводим пункты
    OutTextXY(30, 70, 'Create/Open');
    OutTextXY(30, 120, 'About');
    OutTextXY(30, 170, 'Quit');
    OutTextXY(30, 220, 'Clean CRT-log screen');

    // рисуем активный элемент меню
    SetFillStyle(1, 7);
    Bar(0, ix, maxx, ix+50);
    SetColor(0);
    // вывод надписи в зависимости от пункта
    case menx of
        50: OutTextXY(30, menx + 20, 'Create/Open');
        100: OutTextXY(30, menx + 20, 'About');
        150: OutTextXY(30, menx + 20, 'Quit');
        200: OutTextXY(30, menx + 20, 'Clean CRT-log screen');
    end;
end;

procedure getMemForBitMap;
var
    Size: longint;
begin
    Size := ImageSize(0, 0, maxx, maxy);
    GetMem(P, Size);
end;

procedure drawBitMap;
begin
    PutImage(0, 0, P^, XORPut);
end;

procedure loadBitMap; // загрузка ранее нарисованного изображения. Для граф. редактора
begin
    SetActivePage(0);
    GetImage(0, 0, maxx, maxy, P^);
    SetActivePage(1);
end;

procedure setStartXY;
var
    r, t: string;
begin
    obj.x := 10; obj.y := 10; C := ' ';
    while(ord(C[1]) <> ENTER) do
    begin
        ClearViewPort;
        if bitmapUse = 1 then drawBitMap;
        if obj.oType in [1..2] then begin obj.c1 := obj.x+10; obj.c2 := obj.y + 10; end
        else begin obj.c1 := 10; obj.c2 := 10; end;
        draw;
        setColor(7);
        str(obj.x, r); str(obj.y, t);
        OutTextXY(30, 30, 'Set X [' + r + '] and Y[' + t + ']');
        C := WinCrt.ReadKey;
        if (ord(C[1]) = UP) and (obj.y > 0) then dec(obj.y)
        else if (ord(C[1]) = DOWN) and (obj.y < maxy) then inc(obj.y)
        else if (ord(C[1]) = LEFT) and (obj.x > 0) then dec(obj.x)
        else if (ord(C[1]) = RIGHT) and (obj.x < maxx) then inc(obj.x);
    end;
end;

procedure setFinalXY;
var
    r, t: string;
    tx, ty, tc1, tc2: word;
begin
    C := ' ';
    tx := obj.x; ty := obj.y;
    tc2 := obj.c2; tc1 := obj.c1;
    while(ord(C[1]) <> ENTER) do
    begin
        ClearViewPort;
        if bitmapUse = 1 then drawBitMap;
        draw;
        setColor(7);
        str(obj.c1, r); str(obj.c2, t);
        OutTextXY(30, 30, 'Set final X [' + r + '] and Y[' + t + ']');
        C := WinCrt.ReadKey;
        if (ord(C[1]) = UP) and (tc2 > 0) then dec(tc2)
        else if (ord(C[1]) = DOWN) and (tc2 < maxy) then inc(tc2)
        else if (ord(C[1]) = LEFT) and (tc1 > 0) then dec(tc1)
        else if (ord(C[1]) = RIGHT) and (tc1 < maxx) then inc(tc1);

        obj.x := tx; obj.y := ty;
        obj.c1 := tc1; obj.c2 := tc2;
    end;
end;

procedure setRadius;
var
    r, t: string;
begin
    C := ' ';
    while(ord(C[1]) <> ENTER) do
    begin
        ClearViewPort;
        if bitmapUse = 1 then drawBitMap;
        draw;
        setColor(7);
        str(obj.c1, r); str(obj.c2, t);
        OutTextXY(30, 30, 'Set radius [' + r + ']');
        C := WinCrt.ReadKey;

        if ((ord(C[1]) = LEFT) or (ord(C[1]) = DOWN)) and (obj.c1 > 0) then dec(obj.c1)
        else if ((ord(C[1]) = RIGHT) or (ord(C[1]) = UP)) and (obj.c1 < maxx) then inc(obj.c1);

        obj.c2 := obj.c1;
    end;
end;

procedure setObjPar;
begin
    if bitmapUse = 1 then loadBitMap;
    setStartXY;
    if obj.oType in [1..2] then setFinalXY
    else setRadius;
end;

procedure workS;
var
    r, t: string; i: byte; objNum: longint;
    fm: byte; // указатель на порядок поля
begin
    r := '';

    while(r <> 'X') and (r <> 'x') do
    begin
        fm := 0; r := '';
        WinCrt.ReadKey;
        SetActivePage(1); SetVisualPage(1); ClearViewPort;
        SetColor(7);
        OutTextXY(30, 30, 'Object types:');
        OutTextXY(30, 50, '1 - Line, 2 - Rect, 3 - Circle');
        inputField(fm, r, 'Enter your type (or: X for main menu, L for object viewer):', nameSet);
        if (r = '1') or (r[1] = '2') or (r = '3') then
        begin
            val(r, obj.oType);
            fm := fm + 1;
            if (r = '2') or (r = '3') then
            begin
                OutTextXY(30, 170, 'Fill? [Y/N]');
                C := WinCrt.ReadKey;
                if (C = 'Y') or (C = 'y') or (C = 'Н') or (C = 'н') then
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
                inputField(fm, r, 'Set color (enter "help" for list)', nameSet);
                val(r, obj.color);
            end;

            val(r, obj.color);
            // установка начальных x и y
            setObjPar;

            write(f, obj);
            ClearViewPort;
            SetActivePage(0); SetVisualPage(0);
            draw;
            objInfo(false);
        end

        //менеджер объектов
        else if (r = 'L') or (r = 'l') then
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
                draw;
                objInfo(true);


                seek(f, filesize(f)-1);
                read(f, obj);
            end;
            WinCrt.ReadKey;
            setActivePage(0); setVisualPage(0);
        end;

    end;

    close(f);
    SetActivePage(0); SetVisualPage(0);
    CLearViewPort;
    menx := 50;
    menuChange(menx);
    C := ' ';
end;


procedure start; // загрузка файла
var
    fname:string;

begin
    ClearViewPort;
    fname := '';

    // вводим имя файла

    inputField(0, fname, 'Enter file name [0-9a-z._]', nameSet);

    if (ord(C[1])=ENTER) and (fname<>'') then
    begin
        assign(f, fname);
        {$I-} // директива - игнорирование ошибок при открытии файла
              // для проверки на его наличие
        reset(f);
        {$I+}
        ClearViewPort;
        if IOResult=0 then drawFF // если файл найден - запускаем процедуру отрисовки его объектов
        else rewrite(f); // иначе - создаём его
        workS; // переход к добавлению новых объектов
    end;
end;

procedure about; // Окно "О программе"
var
    t: string;
begin
    C := ' '; SetVisualPage(1); SetActivePage(1);
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

procedure clean; // чистим экран и выводим инфу о проекте
begin
    clrscr;
    writeln(appName); writeln('By ', appAuthor);
    writeln('Version: ', appVersion);
    writeln(appCreate);
    // вывод бета-инфы
    if isBeta=true then
    begin
        writeln;
        writeln('Beta version'); write('Build ', buildNum, ', ', buildDate);
        writeln; writeln;
    end;
end;

procedure initial; // инициализация всех глобальных переменных
begin
    fillchar(g, ofs(obj) - ofs(g) + sizeof(obj), 0)
end;

begin
    initial;
    clean;
    g := VGA; h := mFullScr;
    initGraph(g, h, '');
    // если граф. модуль не загружается - выключаем программу
    if GraphResult <> grOk then
    begin
        writeln('Graphics module error! Reboot program now! (or drop it :3)');
        readLn;
        Halt(1);
    end;

    maxx := GetMaxX(); maxy := GetMaxY(); // получаем разрешение рабочей области


    // Если сипользуем битмап - выделяем место под него
    if bitmapUse = 1 then getMemForBitmap;


    menx := 50; // присваиваем переменной "Пункт меню" первое значение
    menuChange(menx); // отрисовываем меню в нужном месте

    // основное меню
    C := ' ';
    while (C=' ') do begin
        C := WinCrt.ReadKey; obj.x := ord(C[1]); // читаем код нажатой клавишы
        if (ord(c[1]) = UP) and (menx > 50) then
        begin
            menx := menx-50; menuChange(menx); C := ' '; // если вверх - поднимаемся на 1 пункт
        end
        else if (ord(c[1]) = DOWN) and (menx < 200) then
        begin
            menx := menx+50; menuChange(menx); C := ' '; // если вниз - опускаемся
        end
        else if ord(c[1]) = ENTER then
        begin
            // при нажатии Enter проверяем значение переменной menx, и,
            // в зависимости от него, переходим к нужной процедуре
            case menx of
                50: start;
                100: about;
                150: Halt(0);
                200: clean;
            end;
        end;
        C := ' '; // опустошаем переменную с клавишей для повторного прохождения цикла
    end;
    closeGraph;
end.
