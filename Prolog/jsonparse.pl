%%%% -*- Mode: Prolog -*-

%%%% jsonparse.pl
%%%% 873401 Dituri Daniele
%%%% 856524 Gria Spinelli Federico

% i codici ASCII che ci interessano per il progetto
% A = 65, Z = 90.
% a = 97, z = 122.
% 0 = 48, 9 = 57.

% cio che dobbiamo gestire: 
% \n = 10,
% spazio bianco = 32.    // alcuni
% '"' = 34,
% , = 44,
% : = 58,   
% [ = 91, 
% ] = 93,
% { = 123,    
% } = 125. 
% simboli utili per i numeri sono
% + = 43,
% - = 45,
% . = 46,
% E = 69,
% e = 101.

%% jsonparse
% Caso base principale:
% Oggetto e array sono vuoti
jsonparse('{}', jsonobj([])).
jsonparse('[]', jsonarray([])).

% Caso passo principale:
% JSONString non è vuoto
% Codifica tutta la stringa in codici ascii
% Cancella \n
% Inizia il parsing
jsonparse(JSONString, Object) :-
    string_codes(JSONString, TMP),
    delnl(TMP, JSONCodes),
    checkp(JSONCodes),
    parsing(JSONCodes, Object), !.

% Verifica che JSONCodes inizi con {
% se {} (quindi 123 125) ritorna oggetto vuoto
% Inizi il parsing dei Members e cancella la parentesi aperta {
parsing([123, 125 | _], jsonobj([])).
parsing([123 | Xs], jsonobj(Members)):-
    parsemembers(Xs, Members).

% Cancella gli spazi vuoti fino alle prime " che incotra
% Trova l'Attribute e lo trasforma in String
% Trova il Value e lo gestisce
% Ripete fino alla fine di JSONCodes
parsemembers([], []).
parsemembers(X, [(Attribute, Value) | Members]) :-
    delspace(X, JSONCodes),
    parsestring(JSONCodes, Attribute, Xs),
    delspace(Xs, Other),
    parseval(Other, Value, MM),
    delspace(MM, MoreMembers),
    checkmembers(MoreMembers, Members).
% controlla che la pair finisce con la virgola quindi non sono finiti i Member
% o se finisce con la } quindi finisce l'oggetto
checkmembers([44 | Xs], Members) :-
    parsemembers(Xs, Members), !.
checkmembers([125 | _], []).

% controlla che finisce la ]
parseelements([93 | _], []).
parseelements(X, [Value | Elements]):-
    delspace(X, Other),
    parsevalue(Other, Value, ME),
    delspace(ME, MoreElements),
    checkelements(MoreElements, Elements).
% controlla se dopo c'è una virgole 
% o se c'è una ]
checkelements([44 | Xs], Elements) :-
    parseelements(Xs, Elements), !.
checkelements([93 | _], []).

% Salva in StringCodes i codici ASCII compresi tra 2 " (34)
% Trasforma StringCodes in una stringa
parsestring([34 | Xs], String, Ys) :-
    parsestr(Xs, StringCodes, Ys),
    atom_string(StringCodes, String), !.
parsestr([34 | Xs], [], Xs).
parsestr([X | Xs], [X | Zs], Ys) :-
    parsestr(Xs, Zs, Ys).


% gestistione di tutti i tipi di value, quindi tutto ciò che c'è dopo i :
parseval([58 | Xs], Value, MoreMembers) :-
    delspace(Xs, X),
    parsevalue(X, Value, MoreMembers).
parsevalue([58 | _], _, _) :- !, fail.

% stringa
parsevalue([34 | Xs], Value, MoreMembers) :-
    parsestring([34 | Xs], Value, MoreMembers).

% number semblice o con un segno d'avanti
% number con secgno +
parsevalue([43 | Xs], Value, MoreMembers) :-
    parsenumber(Xs, ValueCodes, MoreMembers),
    atom_string([43 | ValueCodes], ValueString),
    number_string(Value, ValueString).    
% number con segno -
parsevalue([45 | Xs], Value, MoreMembers) :-
    parsenumber(Xs, ValueCodes, MoreMembers),
    atom_string([45 | ValueCodes], ValueString),
    number_string(Value, ValueString).
% number semplice
parsevalue([X | Xs], Value, MoreMembers) :-
    between(48, 57, X),
    parsenumber([X | Xs], ValueCodes, MoreMembers),
    atom_string(ValueCodes, ValueString),
    number_string(Value, ValueString).

% object
parsevalue([123 | Xs], Members, MoreMembers) :-
    parsing([123 | Xs], Members),
    delparg(Xs, MoreMembers).

% array 
% trova e cancella la parentesi aperta [, salva gli elementi 
% cancella la parentesi chiusa ]
parsevalue([91 | Xs], jsonarray(Elements), MoreMembers) :-
    parseelements(Xs, Elements),
    delparq(Xs, MoreMembers).

% un numero può essere scritto così:     +1.3e-2   e   -1.5E3 
parsenumber([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumber(Xs, Ys, Other).

% numero con la virgola
parsenumber([46 | Xs], [46 | Ys], Other) :-
    parsenumbervirg(Xs, Ys, Other).
% numero con la E
parsenumber([69 | Xs], [69 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% numero con la e
parsenumber([101 | Xs], [101 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% caso base in cui hai letto tutto
parsenumber(Xs, [], Xs).

%% parsenumbervirg
% numeri con la virgola 
parsenumbervirg([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumbervirg(Xs, Ys, Other).
% caso in cui numero virgola ed E (-1.5E3)
parsenumbervirg([69 | Xs], [69 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% caso in cui numero virgola ed e (+1.3e-2) 
parsenumbervirg([101 | Xs], [101 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% % caso base in cui hai letto tutto
parsenumbervirg(Xs, [], Xs).

%% parsenumberel
% caso in cui numero virgola ed e (+1.3e-2) 
% dopo può esserci un numero semplice con segno
parsenumberel([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumberel2(Xs, Ys, Other).
parsenumberel([43 | Xs], [43 | Ys], Other) :-
    parsenumberel2(Xs, Ys, Other).
parsenumberel([45 | Xs], [45 | Ys], Other) :-
    parsenumberel2(Xs, Ys, Other).
parsenumberel2([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumberel2(Xs, Ys, Other).
parsenumberel2(Xs, [], Xs).
   
% Cancella tutti i \n
delnl([],[]).
delnl([10 | Xs], Ys) :-
    delnl(Xs, Ys).
delnl([X | Xs], [X | Ys]) :-
    delnl(Xs, Ys).

% Cancella le ripetizioni degli spazi vuoti
delspace([],[]).
delspace([32 | Xs], Ys) :-
    delspace(Xs, Ys).
delspace(Xs, Xs).

% Cancella le parentesi chiuse }
delparg([123 | Xs], Ys) :-
    !,
    delparg(Xs, Zs),
    delparg(Zs, Ys).
delparg([125 | Xs], Xs).
delparg([_ | Xs], Ys) :-
    delparg(Xs, Ys).

% Cancella le parentesi chiuse ]
delparq([91 | Xs], Ys) :-
    !,
    delparq(Xs, Zs),
    delparq(Zs, Ys).
delparq([93 | Xs], Xs).
delparq([_ | Xs], Ys) :-
    delparq(Xs, Ys).

%% jsonread
% legge il file chiamato FileName in lettura, 
% lo legge, 
% chiude il file,
% chiama jsonparse che fa tutta la gestione del JSON
jsonread(FileName, JSON) :-
    open(FileName, read, In),
    read_stream_to_codes(In, X),
    close(In),
    jsonparse(X, JSON).

jsondump(JSON, FileName) :-
    open(FileName, write, Out),
    writejson(JSON, String),
    write(Out, String),
    close(Out).

writejson(jsonobj([]), String) :-
    String = "{}".

writejson(jsonarray([]), String) :-
    String = "[]".

writejson(JSON, String) :-
    jsonobj([X | Xs]) = JSON,
    !,
    string_concat("{", "\n", Str1),
    writemembers([X | Xs], Str2),
    string_concat(Str1, Str2, Str3),
    string_concat(Str3, "\n}", String).

writejson(JSON, String) :-
    jsonarray([X | Xs]) = JSON,
    !,
    string_concat("[", "", Str1),
    writeelements([X | Xs], Str2),
    string_concat(Str1, Str2, Str3),
    string_concat(Str3, "]", String).

writemembers([], String) :-
    String = "".
writemembers([(Attribute, Value) | Xs], String) :-
    string_concat('\"', Attribute, Str1),
    string_concat(Str1, '\"', Str2),
    string_concat(Str2, " : ", Str3),
    writevalue(Value, Str4),
    string_concat(Str3, Str4, Str5),
    checkwrite(Xs, Str6),
    string_concat(Str5, Str6, Str7),
    writemembers(Xs, Str8),
    string_concat(Str7, Str8, String).

checkwrite([], "").
checkwrite([_ | _], ",\n").

writeelements([], String) :-
    String = "".
writeelements([Value | Xs], String) :-
    writevalue(Value, Str1),
    checkarray(Xs, Str2),
    string_concat(Str1, Str2, Str3),
    writeelements(Xs, Str4),
    string_concat(Str3, Str4, String).

checkarray([], "").
checkarray([_ | _], ", ").

writevalue(jsonobj([]), "{}").
writevalue(Value, String) :-
    jsonobj([X | Xs]) = Value,
    !,
    writejson(jsonobj([X | Xs]), String).

writevalue(jsonarray([]), "[]").
writevalue(Value, String) :-
    jsonarray([X | Xs]) = Value,
    !,
    writejson(jsonarray([X | Xs]), String).

writevalue(Value, String) :-
    string(Value),
    !,
    string_concat('\"', Value, Str1),
    string_concat(Str1, '\"', String).

writevalue(Value, String) :-
    number(Value),
    !,
    number_string(Value, String).

% controllo delle parentisi {[]} 
% conta numero parentisi aperte { e conta le chiuse }
% contrlla se sono uguali true e va avanti, non va avanti
% conta numero parentisi aperte [ e conta le chiuse ]
% contrlla se sono uguali true e va avanti, se è false fallisce
checkp(JSONCodes) :-
    aperteg(JSONCodes, X),
    chiuseg(JSONCodes, Y),
    X is Y,
    aperteq(JSONCodes, Z),
    chiuseq(JSONCodes, W),
    Z is W.

% Conteggio parentesi graffe aperte
aperteg([], 0).
aperteg([123 | Xs], C) :-
    aperteg(Xs, NC),
    C is NC + 1.
aperteg([X | Xs], C) :-
    X \= 123,
    aperteg(Xs, C).

% Conteggio parentesi graffe chiuse
chiuseg([], 0).
chiuseg([125 | Xs], C) :-
    chiuseg(Xs, NC),
    C is NC + 1.
chiuseg([X | Xs], C) :-
    X \= 125,
    chiuseg(Xs, C).

% Conteggio parentesi quadre aperte
aperteq([], 0).
aperteq([91 | Xs], C) :-
    aperteq(Xs, NC),
    C is NC + 1.
aperteq([X | Xs], C) :-
    X \= 91,
    aperteq(Xs, C).

% Conteggio parentesi quadre chiuse
chiuseq([], 0).
chiuseq([93 | Xs], C) :-
    chiuseq(Xs, NC),
    C is NC + 1.
chiuseq([X | Xs], C) :-
    X \= 93,
    chiuseq(Xs, C).


%% jsonaccess(Jsonobj, Fields, Result)
% i diversi casi base in cui deve fallire
jsonaccess(jsonobj(Members), [], jsonobj(Members)) :- !.
jsonaccess(jsonarray(), [], _) :- !, fail.
jsonaccess(jsonarray([]), [], _) :- !, fail.

% scritto correttamente di tutti i 3 possibili modi in cui può essere scritto
jsonaccess(Jsonobj, X, Result) :-
    searchattributes(Jsonobj, X, Result).
jsonaccess(Jsonobj, [X], Result) :-
    searchattributes(Jsonobj, X, Result).
jsonaccess(Jsonobj, [X | Xs], Result) :-
    searchattributes(Jsonobj, X, TMP),
    !,
    jsonaccess(TMP, Xs, Result).

%% searchattributes(Object, Fields, Result)
% ricerca tra gli attribute quello uguale a quello richiesto (X)
% cerca il suo value 
% caso di un oggetto
searchattributes(Obj, X, Result) :-
    jsonobj([Y | Ys]) = Obj,
    !,
    searchvalue([Y | Ys], X, Result).
% caso di un array
searchattributes(Array, X, TMP) :-
    jsonarray([Y | Ys]) = Array,
    !,
    searchkeyvalue([Y | Ys], X, TMP).

% salva il value nel Result se gli attribute sono uguali
searchvalue([], _, _) :- !, fail.
searchvalue([(Attribute, Value) | _], Attribute, Result) :-
    !,
    Result = Value.
searchvalue([_ | Xs], X, Result) :-
    searchvalue(Xs, X, Result).

% cerca nell'array il value interessato in base al il numero inserito nel comando (key)
searchkeyvalue([], [_], _) :- !, fail.
searchkeyvalue([Y | _], 0, Result) :-
    !,
    Result = Y.
% la ricerca la fa con un contatore che si decrementa in base alla key
searchkeyvalue([_ | Ys], X, Result) :-
    Z is X - 1,
    searchkeyvalue(Ys, Z, Result).

%%%% end of file -- jsonparse.pl