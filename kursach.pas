uses crt, WinCrt, WinGraph;

// информация о программе
const
    isBeta = true; // флаг бета-версии
    buildNum = '52'; buildDate = '08.05.2015 13:50';

    appName = 'GraphEditor';
    appVersion = '1.0 beta';
    appAuthor = 'Vyacheslav Makhonin [BPS]';
    appCreate = 'April 2015';

    // Типы граф. объектов и их цвета
    oTStr: array[1..3] of string[15]=('Line', 'Rect', 'Circle');

    oCStr: array[0..15] of string[15]=('Black', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Brown', 'LightGray', 'DarkGray', 'UghtBlue', 'LightGreen', 'LightCyan', 'LightRed', 'LightMagenta', 'Yellow', 'White');
    // допустимые символы для имени файла
    nameSet: set of char = ['0'..'9', 'a'..'z', 'A'..'Z', '.', '_'];
    numSet: set of char = ['0'..'9'];

    // Коды клавиш
    UP = 72; DOWN = 80; ENTER = 13;

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
    f: file of drawObject;

// внутренняя процедура - обмен значений
// для корректной работы WinGraph
procedure swap(var a, b: word);
var
    t: word;
begin
    t:=a; a:=b; b:=t;
end;


// поле ввода. Располагается на экране в зависимости от dmns
procedure inputField(const dmns: byte; var inStr: string; const drStr: string; const SetS: chset);
begin
    C:=' '; SetColor(7); SetFillStyle(0, 0);
    OutTextXY(30, 70 + (dmns * 100), drStr);
    while(ord(C[1]) <> ENTER) do
    begin
        C:=WinCrt.ReadKey;
        if ord(C[1])=0 then WinCrt.ReadKey;
        // при вводе Backspace - удаляем последний символ
        if (ord(C[1])=8) and (ord(inStr[0])<>0) then
        begin
            inStr[0]:=chr(ord(inStr[0])-1); bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100)); OutTextXY(30, 120 + (dmns * 100), inStr);
        end
        // иначе - записываем
        else if chr(ord(C[1])) in SetS then
        begin
            inStr:=inStr+C; bar(0, 100 + (dmns * 100), maxx, 150 + (dmns * 100)); OutTextXY(30, 120 + (dmns * 100), inStr);
        end;
    end;
end;


procedure objInfo(const gr: boolean);
var s1, s2, temp, temp2: string;
begin
    // вывод информации об объекте
    write('Object ', filepos(f), ': ');
    with obj do
    begin
        s1:=oTStr[oType];
        if not(oType=1) then
        begin
            if fill = true then temp:='True' else temp:='false';
            s1:=s1 + (', Fill: ' + temp);
        end;
        s1:=s1 + (', Color: ' + oCStr[color]);
        str(x, temp); str(y, temp2);

        s2:=('    x1:' + temp + ' x2:' + temp2);
        str(c1, temp); str(c2, temp2);
        if otype=3 then s2:=s2 + (' rad:' + temp)
        else s2:=s2 + (' x2:' + temp +' y2:' + temp2);
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
        if fill=true then
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
        if fill=true then
        begin
            SetFillStyle(1, color);
            FillEllipse(x, y, c1, c1);
        end
        else
        begin
            Circle(x, y, c1);
        end;
    end;
    objInfo(false);
end;


procedure drawFF; // чтение объекта из файла и его вывод
begin
    close(f);
    reset(f);
    writeln('-----');
    while not Eof(f) do
    begin
        read(f,obj);
        draw;
    end;
    writeln('-----');
end;


procedure menuChange(const ix: word); // отрисовка меню
var
    t: string;

begin
    maxx:=getmaxx();
    SetFillStyle(1, 0);
    SetColor(7);
    ClearViewPort; // чистим экран

    // Информация об авторе
    t:=appName + ' | ' + appAuthor + ' | ' + appVersion + ' | ' + appCreate;
    if isBeta = true then
    begin
        t:=t + ' | Build ' + buildNum + ' | ' + buildDate;
    end;
    OutTextXY(((maxx div 2) - (TextWidth(t) div 2)), 20, t);
    Line(0, 40, maxx, 40);

    // выводим пункты
    OutTextXY(30, 70, 'Create/Open');
    OutTextXY(30, 120, 'Help');
    OutTextXY(30, 170, 'Quit');
    OutTextXY(30, 220, 'Clean screen');

    // рисуем активный элемент меню
    SetFillStyle(1, 7);
    Bar(0, ix, maxx, ix+50);
    SetColor(0);
    // вывод надписи в зависимости от пункта
    case menx of
        50: OutTextXY(30, menx + 20, 'Create/Open');
        100: OutTextXY(30, menx + 20, 'Help');
        150: OutTextXY(30, menx + 20, 'Quit');
        200: OutTextXY(30, menx + 20, 'Clean screen');
    end;
end;


procedure workS;
var
    r, t: string; i: byte; objNum: longint;
    fm: byte; // указатель на порядок поля
begin
    r:='';

    while(r <> 'X') and (r <> 'x') do
    begin
        fm:=0; r:='';
        WinCrt.ReadKey;
        SetActivePage(1); SetVisualPage(1); ClearViewPort;
        SetColor(7);
        OutTextXY(30, 30, 'Object types:');
        OutTextXY(30, 50, '1 - Line, 2 - Rect, 3 - Circle');
        inputField(fm, r, 'Enter your type (or: X for main menu, L for object viewer):', nameSet);
        if (r = '1') or (r[1] = '2') or (r = '3') then
        begin
            val(r, obj.oType);
            if (r = '2') or (r = '3') then
            begin
                fm:=fm + 1;
                OutTextXY(30, 170, 'Fill? [Y/N]');
                C:=WinCrt.ReadKey; OutTextXY(30, 120, chr(ord(C[1])));
                if (C = 'Y') or (C = 'y') or (C = 'Н') or (C = 'н') then obj.fill:=true
                else obj.fill:=false;
            end; fm:=fm + 1; r:='';
            inputField(fm, r, 'Set color (enter "help" for list)', nameSet);

            // Вывод списка цветов
            while r = 'help' do
            begin
                for i:=0 to 15 do
                begin
                    Str(i, r);
                    r:= r + ' - ' + oCStr[i];
                    OutTextXY(600, 20 + (i * 15), r);
                end;
                r:='';
                inputField(fm, r, 'Set color (enter "help" for list)', nameSet);
            end;

            val(r, obj.color);
            // установка начальных x и y
            bar(0, 100 + (fm * 100), maxx, 150 + (fm * 100)); OutTextXY(30, 120 + (fm * 100), r);
            fm:=fm + 1; r:='';
            inputField(fm, r, 'Set X', numSet);
            val(r, obj.x);
            fm:=fm + 1; r:='';
            inputField(fm, r, 'Set Y', numSet);
            val(r, obj.y);
            fm:=fm + 1; r:='';
            case obj.oType of
               1, 2:inputField(fm, r, 'Set final X', numSet);
               3:inputField(fm, r, 'Set radius', numSet);
            end;
            val(r, obj.c1);

            if not (obj.oType = 3) then
            begin
                r:='';
                fm:=fm + 1;
                inputField(fm, r, 'Set final Y', numSet);
                val(r, obj.c2);
            end
            else obj.c2:=0;
            write(f, obj);
            SetActivePage(0); SetVisualPage(0);
            draw;
        end

        //менеджер объектов
        else if (r = 'L') or (r = 'l') then
        begin
            r:='';
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
                    r:='';
                    inputField(0, r, ('Number of object [1..' + t + ']:'), numSet);
                    val(r, objNum);
                end;

                seek(f, objNum-1);
                read(f, obj);
                ClearViewPort; draw;
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
    menx:=50;
    menuChange(menx);
    C:=' ';
end;


procedure start; // загрузка файла
var
    fname:string;
begin
    ClearViewPort;
    fname:='';

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

procedure help; //todo заглушка
begin
    C:=' '; SetVisualPage(1); SetActivePage(1);
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
    fillchar(g, ofs(obj)-ofs(g)+sizeof(obj), 0)
end;

begin
    initial;
    clean;
    g:=VGA; h:=mFullScr;
    initGraph(g, h, '');
    // если граф. модуль не загружается - вырубаем программу
    if GraphResult <> grOk then
    begin
        writeln('Graphics module error! Reboot program now! (or drop it :3)');
        readLn;
        Halt(1);
    end;

    maxx:=GetMaxX(); maxy:=GetMaxY(); // получаем разрешение рабочей области

    menx:=50; // присваиваем переменной "Пункт меню" первое значение
    menuChange(menx); // отрисовываем меню в нужном месте

    // основное меню
    C:=' ';
    while (C=' ') do begin
        C:=WinCrt.ReadKey; obj.x:=ord(C[1]); // читаем код нажатой клавишы
        if (ord(c[1]) = UP) and (menx > 50) then
        begin
            menx:=menx-50; menuChange(menx); C:=' '; // если вверх - поднимаемся на 1 пункт
        end
        else if (ord(c[1]) = DOWN) and (menx < 200) then
        begin
            menx:=menx+50; menuChange(menx); C:=' '; // если вниз - опускаемся
        end
        else if ord(c[1]) = ENTER then
        begin
            // при нажатии Enter проверяем значение переменной menx, и,
            // в зависимости от него, переходим к нужной процедуре
            case menx of
                50: start;
                100: help;
                150: Exit;
                200: clean;
            end;
        end;
        C:=' '; // опустошаем переменную с клавишей для повторного прохождения цикла
    end;
    closeGraph;
end.
