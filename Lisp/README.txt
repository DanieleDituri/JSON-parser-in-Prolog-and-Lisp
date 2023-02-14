873401 Dituri Daniele

jsonparse(JSON)
jsonparse ha in ingresso una stringa scritta in JSON e in uscita una lista (JSONOBJ ("Attribute" "Value") ...).
svolgimento del jsonparse: 
Comincia considerando ogni caso come la stringa NULL, la stringa vuota. Successivametne controlla i casi mostrati nel testo
cioè i JSONOBJ e JSONARRY vuoti.
Abbiamo deciso di trasformare la stringa JSON in una lista di più facile utilizzo tramite liststring.

svolgimento di liststring:
1- liststring ha il compito di creare una lista con tutti gli elementi del JSON separati.
2- attraverso coerce abbiamo cambiato la striga in una lista di char.
3- passa la lista al createstringlist che raggruppa i char in stringhe sfruttando le virgolette per spezzare le stringhe in modo corretto.
4- eliminiamo tutto ciò che è superfluo: #\Newline e #\Space.
5- createnumberlist raggruppa i numeri dividendo gli integer e i Float. 
6- checkp controlla il numero delle parentesi quadre e graffe aperte e chiuse

parsing gestisce gli oggetti e gli array iniziali, facendo cominciare la jsonlist con JSONOBJ o JSONARRAY.
parsemember crea una lista da 2 elementi con all'interno gli Attribute e i Value.
In questa funzione si gestiscono tutti i tipi di value inclusi gli oggetti annidati. 
Mentre gli array vengono gestiti da parseelements. 


jsonaccess (jsonobj &optional field &rest morefield)
Legge l'attribute richiesto e restituisce il suo value.
in input abbiamo il jsonobj, un Attribute e altri campi nel caso in cui vogliamo un risultato situato in un array o in oggetti annidati.
Field e morefield sono facoltativi, potrebbe non esserci quando li richiamo, per questo motivo abbiamo usato &optional e &rest. In questo caso:
- optional si usa nel caso di parametri falcoltativi. 
- rest nel caso ci siano più variabile facoltativi.
Ogni volta che trovo l'Attribute viene richiamata searchvalue. Per la ricerca di un array richiama searcharray. 


jsonread (FileName)
Apre un file JSON in lettura. legge il file e lo trasforma in unica stringa. Esegue successivamente il jsonparse su tutta la stringa.
Se il file non esiste il programma va in errore.


jsondumb (JSON FileName)
Apre un file JSON in scrittura. Trasforma una lista JSONOBJ in un'unica stringa in sintassi JSON che verra inserita nel file. 
Per la gestione degli oggetti usiamo stringobj per costrure la stringa; quando c'è un array viene richiamata stringarray.



