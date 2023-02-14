jsonparse(JSONString, Object)
jsonparse ha in ingresso una stringa scritta in JSON e in uscita ha un oggetto chiamato jsonobj().
Abbiamo deciso di trasformare la stringa in una lista di caratteri ASCII tramite l'uso di string_codes/2.
I codici ASCII che abbiamo dovuto gestire sono: 
\n = 10,
spazio vuoto = 32.
" = 34,
, = 44,
: = 58,   
[ = 91, 
] = 93,
{ = 123,    
} = 125,
0 = 48,
9 = 57,
+ = 43,
- = 45,
. = 46,
E = 69,
e = 101.

Svolgimento jsonparse:
1- trasformare l'intera stringa JSON in caratteri ASCII;
2- togliere tutti \n;
3- conteggio delle parentesi graffe e quadre. In caso il numero delle parentesi aperte sia differente da quello delle chiuse il programma fallisce;
4- richaima il parsing.

Il parsing gestisce gli oggetti. Può avere in ingresso 123 e 125 consecutivamente (quindi {}), ritornerà quindi jsonobj([]).
In caso contrario dovrà leggere i Members al suo interno tramite parsemembers.

Svolgimento parsemembers:
1- trova i vari Attribute, li trasforma in stringa e li salva all'interno di jsonobj([]);
2- richiama parseval per trovare il Value;
3- controlla la presenza di MoreMembers, in caso non siano presenti termina l'esecuzione.

Il parseval gestisce eventuali : duplicati, successivamente ricava il Value tramite parsvalue.
Il parsevalue gestisce i diversi tipi di Value in base al primo carattere della lista.
- se trova le " richiama parsestring; (string)
- se trova un numero, un + o un - allora richiama parsenumber; (number)
- se trova la { allora richiama parsing; (jsonobj([]))
- se trova la [ allora richiama parseelements; (jsonarray([]))


jsonaccess(Jsonobj, Fields, Result)
jsonaccess ha in ingresso un jsonobj([]) e l'Attribute di cui vogliamo ricavare il Value. In uscita abbiamo il Value ricavato.
Fields può contenere:
- una lista vuota, restituisco quindi lo stesso jsonobj([]) che ho in entrata.
- una stringa o una lista contenente una sola stringa, resituisco quindi tutto il Value
- una lista contenente una stringa e un numero, restituisco quindi l'elemento nella posizione del numero all'interno dell'array ricercato.
  in caso il Value collegato all'Attribute non sia un jsonarray([]) fallisco.

searchattributes controlla la tipologia dell'oggetto passato, gestendo il caso di jsonobj([]) e jsonarray([]).

searchvalue cerca all'interno della lista l'Attribute e ritorna il Value collegato.

searchkeyvalue cerca il valore nella posizione richiesta all'interno dell'jsonarray([])


jsonread(FileName, JSON)
jsonread avrà in ingresso una file.json e in uscita avrà un jsonobj().
Il jsonread fa:
1- apre il Filename in lettura;
2- salva il contenuto del Filename in una stringa scritta in sintassi JSON;
3- chiude il Filename,
4- richiama il jsonparse. 


jsondump(JSON, FileName)
jsondumb avrà in ingresso un jsonobj([]) e in un uscita un file.json.
Il jsondumb fa:
1- apre il Filename in scrittura;
2- trasforma il jsonobj in una stringa scritta in sintassi JSON chiamando writejson;
3- scrive sul file la stringa;
4- chiude il Filename. 

writejson gestisce la ricostruzione della stringa tramite l'oggetto passatogli. In caso di jsonobj([]) o jsonarray([]) vuoti scriverà "{}" o "[]".
Se l'oggetto è un jsonobj([]) scriverà "{\n", richiama writemembers per scrivere i Members e aggiunge in fondo alla stringa "\n}".
Se l'oggetto è un jsonarray([]) scriverà "[", richiama writelements per scrivere i Elements e aggiunge in fondo alla stringa "]".
Per concatenare le stringhe usiamo string_concat/3

writemembers scrive l'Attribute tra due " e richiama writevalue.
Controlla che jsonobj([]) sia terminato, altrimenti scrive ",\n" e ripete per tutti i Member

writelements richiama writevalue.
Controlla che jsonarray([]) sia terminato, altrimenti scrive ", " e ripete per tutti gli Element

writevalue scrive in una stringa il Value richiesto.
In caso il Value sia un jsonobj([]) o un jsonarray([]) richiama writejson per il contenuto di essi.
Il writevalue deve compredere se la Value è una stringa, un jsonarray, un jsonobj o un numero.
