uses graph,crt;
// информация о программе
const
    isBeta=true; // флаг бета-версии
    buildNum='23'; buildDate='27.04.2015 02:38';

    appName='GraphEditor';
    appVersion='1.0 beta';
    appAuthor='Vyacheslav Makhonin [BPS]';
    appCreate='April 2015';

    // Типы граф. объектов и их цвета
    oTStr:array[1..3] of string[15]=('Line', 'Rect', 'Circle');

    oCStr:array[0..15] of string[15]=('Black', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Brown', 'LightGray', 'DarkGray', 'UghtBlue', 'LightGreen', 'LightCyan', 'LightRed', 'LightMagenta', 'Yellow', 'White');

// создаём тип граф. объекта
type
    drawObject=record
        oType:byte; // тип: 1 - линия, 2 - прямоугольник, 3 - круг/окружность
        color:byte; // цвет
        fill:boolean; // заливка
        x, y, c1, c2:word; // координаты и размер/радиус
    end;

var
    g,h,menx:integer;
    c:string[2];
    maxx,maxy:word;
    obj:drawObject;
    f:file of drawObject;

procedure objInfo;
begin
    // вывод информации об объекте
    write('Object ', filepos(f), ': ');
    with obj do begin
        write(oTStr[oType]);
        if not(oType=1) then write(', Fill: ', fill);
        writeln(', Color: ', oCStr[color]);
        write('    x1:', x, ' x2:',y);
        if otype=3 then writeln(' rad:', c1)
        else writeln(' x2:', c1,' y2:', c2);
    end;
end;

procedure draw; // вывод объекта
begin
    if obj.oType=1 then with obj do begin
        setcolor(color);
        line(x, y, c1, c2);
    end
    else if obj.oType=2 then with obj do begin
        if fill=true then begin
            setfillstyle(1, color);
            bar(x, y, c1, c2);
        end else begin
            setcolor(color);
            rectangle(x, y, c1, c2);
        end;
    end else if obj.oType=3 then with obj do begin
        setcolor(color);
        if fill=true then begin
            setfillstyle(1, color);
            FillEllipse(x, y, c1, c1);
        end else begin
            Circle(x, y, c1);
        end;
    end;
    objInfo;
end;

procedure drawFF; // чтение объекта из файла и его вывод
begin
    close(f);
    reset(f);
    writeln('-----');
    while not Eof(f) do begin
        read(f,obj);
        draw;
    end;
    writeln('-----');
end;

procedure menuChange(const ix:word); // отрисовка меню
begin
    maxx:=getmaxx();
    setfillstyle(1, 0);
    ClearViewPort; // чистим экран
    setcolor(7);
    // выводим пункты
    outtextxy(30, 70, 'Create/Open');
    outtextxy(30, 120, 'Help');
    outtextxy(30, 170, 'Quit');
    outtextxy(30, 220, 'Clean screen');
    // рисуем активный элемент меню
    setfillstyle(1, 7);
    bar(0, ix, maxx, ix+50);
    setcolor(0);
    // вывод надписи в зависимости от пункта
    case menx of
        50:outtextxy(30, menx+20, 'Create/Open');
        100:outtextxy(30, menx+20, 'Help');
        150:outtextxy(30, menx+20, 'Quit');
        200:outtextxy(30, menx+20, 'Clean screen');
    end;
end;


procedure workS;
var
    r:char; i:byte; objNum:longint;
begin
    restorecrtmode;
    r:=' ';

    while(r<>'X') do begin
        writeln('Object types:');
        writeln('1 - Line, 2 - Rect, 3 - Circle');
        writeln('Enter your type (or: X for main menu, L for object viewer):');
        readln(r);
        if (r='1') or (r='2') or (r='3') then begin
            val(r,obj.oType);
            if (r='2') or (r='3') then begin
                writeln('Fill? [Y/N]');
                C:=ReadKey;
                if (C='Y') or (C='y') or (C='Н') or (C='н') then obj.fill:=true
                else obj.fill:=false;
            end;
            writeln('Set color (enter 99 for list)');
            readln(obj.color);

            // Вывод списка цветов
            while obj.color=99 do begin
                writeln;
                for i:=0 to 15 do writeln(i, ' - ', oCStr[i]);
                writeln;
                writeln('Set color (enter 99 for list)');
                readln(obj.color);
            end;

            // установка начальных x и y
            writeln('Set X');
            readln(obj.x);
            writeln('Set Y');
            readln(obj.y);
            case r of
               '1':writeln('Set final X');
               '2':writeln('Set final X');
               '3':writeln('Set radius');
            end;
            readln(obj.c1);
            if not (r='3') then begin
                writeln('Set final Y');
                readln(obj.c2);
            end else obj.c2:=0;
            write(f, obj);
            draw;
        end

        //менеджер объектов
        else if r='L' then begin
            if obj.oType=0 then writeln('Empty file!')
            else begin
                writeln('Number of object [1..', filesize(f), ']:');
                readln(objNum);

                seek(f, objNum-1);
                read(f, obj);
                objInfo;

                seek(f, filesize(f)-1);
                read(f, obj);
            end;
        end;

    end;

    close(f);
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
    setcolor(7);
    // вводим имя файла
    outTextXY(30, 70, 'Enter file name to the work window (or X if you want to go to the menu)');
    writeln('Enter file name (or X for main menu):');
    readln(fname);
    // при вводе X - переходим в основное меню
    if fname='X' then begin
        menuChange(menx);
        C:=' ';
    // иначе - загружаем файл
    end else begin
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
    C:=' ';
end;

procedure clean; // чистим экран и выводим инфу о проекте
begin
    clrscr;
    writeln(appName); writeln('By ', appAuthor);
    writeln('Version: ', appVersion);
    writeln(appCreate);
    // вывод бета-инфы
    if isBeta=true then begin
        writeln;
        writeln('Beta version'); write('Build ', buildNum, ', ', buildDate);
        writeln; writeln;
    end;
end;

procedure initial; // инициализация всех глобальных переменных
begin
    fillchar(g,ofs(obj)-ofs(g)+sizeof(obj),0)
end;

begin
    initial;
    clean;
    g:=detect;
    initGraph(g, h, '');
    // если граф. модуль не загружается - вырубаем программу
    if GraphResult <> grOk then begin
        writeln('Graphics module error! Reboot program now! (or drop it :3)');
        readLn;
        Halt(1);
    end;

    maxx:=getmaxx(); maxy:=getMaxY(); // получаем разрешение рабочей области
    menx:=50; // присваиваем переменной "Пункт меню" первое значение
    menuChange(menx); // отрисовываем меню в нужном месте

    // основное меню
    C:=' ';
    while (C=' ') do begin
        C:=ReadKey; obj.x:=ord(C[1]); // читаем код нажатой клавишы
        if (ord(c[1])=72) and (menx>50) then begin
            menx:=menx-50; menuChange(menx); C:=' '; // если вверх - поднимаемся на 1 пункт
        end else if (ord(c[1])=80) and (menx<200) then begin
            menx:=menx+50; menuChange(menx); C:=' '; // если вниз - опускаемся
        end else if ord(c[1])=13 then begin
            // при нажатии Enter проверяем значение переменной menx, и,
            // в зависимости от него, переходим к нужной процедуре
            case menx of
                50:start;
                100:help;
                150:Halt(0);
                200:clean;
            end;
        end;
        C:=' '; // опустошаем переменную с клавишей для повторного прохождения цикла
    end;


    closeGraph;
end.
