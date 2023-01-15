%%%% -*- Mode: Prolog -*-

%%%% jsonparse.pl
%%%% 873401 Dituri Daniele
%%%% 856524 Gria Spinelli Federico

%% jsonparse(JSONString, Object)
% Oggetto e array sono vuoti
jsonparse('{}', jsonobj([])).
jsonparse('[]', jsonarray([])).

% JSONString non è un oggetto vuoto
% Codifica tutta la stringa in codici ascii
% Cancella \n
% Inizia il parsing
jsonparse(JSONString, Object) :-
    string_codes(JSONString, TMP),
    delnl(TMP, JSONCodes),
    checkp(JSONCodes),
    parsing(JSONCodes, Object), !.

% conteggio delle parentisi {[]} 
% conta numero { e }
% se il numero è uguale prosegue altrimenti fallisce
% conta numero [ e ]
% se il numero è uguale prosegue altrimenti fallisce
checkp(JSONCodes) :-
    aperteg(JSONCodes, X),
    chiuseg(JSONCodes, Y),
    X is Y,
    aperteq(JSONCodes, Z),
    chiuseq(JSONCodes, W),
    Z is W.

% Verifica che JSONCodes inizi con {
% se {} (quindi 123 125) ritorna jsonobj vuoto
% Inizi il parsing dei Members
parsing([123, 125 | _], jsonobj([])).
parsing([123 | Xs], jsonobj(Members)):-
    parsemembers(Xs, Members).

% Cancella tutti gli eventuali spazi vuoti dove necessario
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

% Controllo sui Members
% Se il Pair passato termina con una virgola esegue il parsemembers
% Se termina con } termina il parsing
checkmembers([44 | Xs], Members) :-
    parsemembers(Xs, Members), !.
checkmembers([125 | _], []).

% Cancella tutti gli eventuali spazi vuoti dove necessario
% Trova il Value e lo gestisce
% Ripete fino alla fine dell'array
parseelements([93 | _], []).
parseelements(X, [Value | Elements]):-
    delspace(X, Other),
    parsevalue(Other, Value, ME),
    delspace(ME, MoreElements),
    checkelements(MoreElements, Elements).

% Controllo sugli Elements
% Se il Value passato termina con una virgola esegue il parseelements
% Se termina con ] termina il parsing
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

% Controllo sulla presenza dei : dopo l'Attribute
% gestione di eventuali : ripetuti con un fail
% gestione del Value
parseval([58 | Xs], Value, MoreMembers) :-
    delspace(Xs, X),
    parsevalue(X, Value, MoreMembers).
parsevalue([58 | _], _, _) :- !, fail.

% Value = string
parsevalue([34 | Xs], Value, MoreMembers) :-
    parsestring([34 | Xs], Value, MoreMembers).

% Value = number
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

% Value = jsonobj()
% Gestione delle parentesi
parsevalue([123 | Xs], Members, MoreMembers) :-
    parsing([123 | Xs], Members),
    delparg(Xs, MoreMembers).

% Value = jsonarray()
% Gestione delle parentesi
parsevalue([91 | Xs], jsonarray(Elements), MoreMembers) :-
    parseelements(Xs, Elements),
    delparq(Xs, MoreMembers).

% Gestione dei number
% Primo elemento della lista number
parsenumber([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumber(Xs, Ys, Other).
% Primo elemento della lista ,
parsenumber([46 | Xs], [46 | Ys], Other) :-
    parsenumbervirg(Xs, Ys, Other).
% Primo elemento della lista E
parsenumber([69 | Xs], [69 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% Primo elemento della lista e
parsenumber([101 | Xs], [101 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% Parsing del numero terminato
parsenumber(Xs, [], Xs).

% Gestione della virgola 
parsenumbervirg([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumbervirg(Xs, Ys, Other).
% Gestione dei numeri con il carattere E (5E3 = 5000)
parsenumbervirg([69 | Xs], [69 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% Gestione dei numeri con il carattere e (7e-2 = 0.07)
parsenumbervirg([101 | Xs], [101 | Ys], Other) :-
    parsenumberel(Xs, Ys, Other).
% Parsing del numero con la virgola terminato
parsenumbervirg(Xs, [], Xs).

% Gestione dei numeri con e ed E
% Primo elemento della lista number
parsenumberel([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumberel2(Xs, Ys, Other).
% Primo elemento della lista +
parsenumberel([43 | Xs], [43 | Ys], Other) :-
    parsenumberel2(Xs, Ys, Other).
% Primo elemento della lista -
parsenumberel([45 | Xs], [45 | Ys], Other) :-
    parsenumberel2(Xs, Ys, Other).

% Gestione delle segno e dei cratteri e ed E ripetuti
parsenumberel2([X | Xs], [X | Ys], Other) :-
    between(48, 57, X),
    parsenumberel2(Xs, Ys, Other).
parsenumberel2(Xs, [], Xs).

% Cancella i \n in tutta la lista
delnl([],[]).
delnl([10 | Xs], Ys) :-
    delnl(Xs, Ys).
delnl([X | Xs], [X | Ys]) :-
    delnl(Xs, Ys).

% Cancella tutti gli spazi vuoti ripetuti
delspace([],[]).
delspace([32 | Xs], Ys) :-
    delspace(Xs, Ys).
delspace(Xs, Xs).

% Gestione di eventuali jsonobj annidati
delparg([123 | Xs], Ys) :-
    !,
    delparg(Xs, Zs),
    delparg(Zs, Ys).
delparg([125 | Xs], Xs).
delparg([_ | Xs], Ys) :-
    delparg(Xs, Ys).

% Gestione dei jsonarray eventualmente anche annidati
delparq([91 | Xs], Ys) :-
    !,
    delparq(Xs, Zs),
    delparq(Zs, Ys).
delparq([93 | Xs], Xs).
delparq([_ | Xs], Ys) :-
    delparq(Xs, Ys).

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
% caso base:
% se Fields è una lista vuota Jsonobj = Result
% se Jsonobj = jsonarray() fallisce
jsonaccess(jsonobj(Members), [], jsonobj(Members)) :- !.
jsonaccess(jsonarray(), [], _) :- !, fail.
jsonaccess(jsonarray([]), [], _) :- !, fail.

% caso passo:
% Fields = string
% Fields = [string]
% Fields = [string, number]
jsonaccess(Jsonobj, X, Result) :-
    searchattributes(Jsonobj, X, Result).
jsonaccess(Jsonobj, [X], Result) :-
    searchattributes(Jsonobj, X, Result).
jsonaccess(Jsonobj, [X | Xs], Result) :-
    searchattributes(Jsonobj, X, TMP),
    !,
    jsonaccess(TMP, Xs, Result).

% ricerca tra gli Attribute di jsonobj() quello richiesto da Fields
% ricerca il value associato
searchattributes(Obj, X, Result) :-
    jsonobj([Y | Ys]) = Obj,
    !,
    searchvalue([Y | Ys], X, Result).
% ricerca il value associato
searchattributes(Array, X, TMP) :-
    jsonarray([Y | Ys]) = Array,
    !,
    searchkeyvalue([Y | Ys], X, TMP).

% ricerco l'Attribute all'interno di jsonobj()
% salvo il Value associato all'Attribute richiesto in Result
% se l'Attribute richiesto non viene trovato fallisce
searchvalue([], _, _) :- !, fail.
searchvalue([(Attribute, Value) | _], Attribute, Result) :-
    !,
    Result = Value.
searchvalue([_ | Xs], X, Result) :-
    searchvalue(Xs, X, Result).

% ricerco il Value all'interno di jsonarray() tramite un contatore
% decremento il contatore
% quando il contatore raggiunge 0 salvo Value in Result
% se la lista termina prima che il contatore raggiunga 0 fallisce
searchkeyvalue([], [_], _) :- !, fail.
searchkeyvalue([Y | _], 0, Result) :-
    !,
    Result = Y.
searchkeyvalue([_ | Ys], X, Result) :-
    Z is X - 1,
    searchkeyvalue(Ys, Z, Result).


%% jsonread(FileName, JSON)
% apre il file chiamato FileName in lettura
% salva il contenuto in X 
% chiude il file
% chiama jsonparse sul file JSON appena letto
jsonread(FileName, JSON) :-
    open(FileName, read, In),
    read_stream_to_codes(In, X),
    close(In),
    jsonparse(X, JSON).


%% jsondump(JSON, FileName)
% apre il file chiamato FileName in scrittura
% salva la stringa in sintassi JSON in String
% scrive sul file il contenuto di String
% chiude il file
jsondump(JSON, FileName) :-
    open(FileName, write, Out),
    writejson(JSON, String),
    write(Out, String),
    close(Out).

% caso base:
% Oggetto e array sono vuoti
writejson(jsonobj([]), String) :-
    String = "{}".
writejson(jsonarray([]), String) :-
    String = "[]".

% caso passo:
% JSON = jsonobj()
% concatena in un stringa "{\nMembers\n}"
writejson(JSON, String) :-
    jsonobj([X | Xs]) = JSON,
    !,
    string_concat("{", "\n", Str1),
    writemembers([X | Xs], Str2),
    string_concat(Str1, Str2, Str3),
    string_concat(Str3, "\n}", String).
% JSON = jsonoarray() 
% concatena in un stringa "[Elements]"
writejson(JSON, String) :-
    jsonarray([X | Xs]) = JSON,
    !,
    string_concat("[", "", Str1),
    writeelements([X | Xs], Str2),
    string_concat(Str1, Str2, Str3),
    string_concat(Str3, "]", String).

% concatena in una stringa "\"Attribute\" : Value,\n MoreMembers"
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
% controllo sul Pair
% se sono presenti altri Pair concatena ",\n"
% altrimenti concatena con "" (stringa vuota)
checkwrite([], "").
checkwrite([_ | _], ",\n").

% concatena in una stringa "Value, MoreElements"
writeelements([], String) :-
    String = "".
writeelements([Value | Xs], String) :-
    writevalue(Value, Str1),
    checkarray(Xs, Str2),
    string_concat(Str1, Str2, Str3),
    writeelements(Xs, Str4),
    string_concat(Str3, Str4, String).
% controllo sul Element
% se sono presenti altri Elements concatena ", "
% altrimenti concatena con "" (stringa vuota)
checkarray([], "").
checkarray([_ | _], ", ").

% scrittura dei Value
% Value = jsonobj() 
writevalue(jsonobj([]), "{}").
writevalue(Value, String) :-
    jsonobj([X | Xs]) = Value,
    !,
    writejson(jsonobj([X | Xs]), String).
% Value = jsonarray()
writevalue(jsonarray([]), "[]").
writevalue(Value, String) :-
    jsonarray([X | Xs]) = Value,
    !,
    writejson(jsonarray([X | Xs]), String).
% Value = string
writevalue(Value, String) :-
    string(Value),
    !,
    string_concat('\"', Value, Str1),
    string_concat(Str1, '\"', String).
% Value = number
writevalue(Value, String) :-
    number(Value),
    !,
    number_string(Value, String).


%%%% end of file -- jsonparse.pl
