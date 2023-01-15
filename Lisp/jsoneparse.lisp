; 873401 Dituri Daniele
; 856524 Gria Spinelli Federico

; jsonparse (JSON)
(defun jsonparse (JSON)
    (cond
        ((null JSON) nil)
        ((equal JSON "") (error "stringa vuota"))
        ((equal JSON "{}") '(JSONOBJ))
        ((equal JSON "[]") '(JSONARRAY))
        (t (parsing (liststring JSON)))
    )
)

; controlla che inizi con { e richiama parsemembers
(defun parsing (jsonlist)
    (cond
        ((equal (first jsonlist) #\{) 
            (append (list 'JSONOBJ) (parsemembers (rest jsonlist)))
        )
        ((equal (first jsonlist) #\[) 
            (append (list 'JSONARRAY) (parseelements (rest jsonlist)))
        )
        (t (error "errore sintassi json (parsing)"))
    )
)

(defun liststring (JSON)
    (checkp
        (createnumberlist
            (delnls
                (createstringlist (coerce JSON 'list) 0 nil)
            )
            nil
        )
    )
)

; gesione dei members di JSONOBJ
(defun parsemembers (jsonlist)
    (cond
        ((null jsonlist) nil)
        ((equal (first jsonlist) #\})
            nil
        )
        ((and (equal (first jsonlist) #\,) (stringp (second jsonlist)))
            (parsemembers (rest jsonlist))
        )
        ((and (stringp (first jsonlist)) (equal (second jsonlist) #\:))
            (cond
                ((and 
                    (equal (third jsonlist) #\{)
                    (equal (fourth jsonlist) #\}))
                    (append 
                        (list (cons 
                            (first jsonlist)
                            (list (list 'JSONOBJ))
                        ))
                        (parsemembers (rest (rest (rest (rest jsonlist)))))
                    )
                )
                ((equal (third jsonlist) #\{) 
                    (append (list (cons
                            (first jsonlist)
                            (list (parsing (rest (rest jsonlist))))
                        ))
                        (parsemembers (closeobj (rest (rest (rest jsonlist))) 0))
                    )
                )
                ((and 
                    (equal (third jsonlist) #\[)
                    (equal (fourth jsonlist) #\]))
                    (append 
                        (list (cons 
                            (first jsonlist)
                            (list (list 'JSONARRAY))
                        ))
                        (parsemembers (rest (rest (rest (rest (rest jsonlist))))))
                    )
                )
                ((equal (third jsonlist) #\[) 
                    (append
                        (list (cons
                                (first jsonlist)
                            (list (append
                                (list 'JSONARRAY)
                                (parseelements (rest (rest (rest jsonlist))))
                            ))
                        ))
                        (parsemembers (closearray (rest (rest (rest jsonlist))) 0))
                    )
                )
                ((equal (fourth jsonlist) #\,) 
                    (cons (append (list (first jsonlist)) 
                            (list (third jsonlist)))
                            (parsemembers 
                                (rest (rest (rest (rest jsonlist))))
                            )
                    )
                )
                ((equal (fourth jsonlist) #\})
                    (list (append (list (first jsonlist)) 
                            (list (third jsonlist))
                        )
                    )
                )
                (t (error "Errore nel Value (parsemembers)"))
            )
        )
        (t (error "Errore nell'Attribute (parsemembers)"))
    )
)

; gestione dei possibili elements degli array
(defun parseelements (jsonlist)
    (cond
        ((equal (first jsonlist) #\])
            nil
        )
        ((equal (first jsonlist) #\,) (parseelements (rest jsonlist)))
        ((and (equal (first jsonlist) #\{) (equal (second jsonlist) #\}))
            (append 
                (list (list 'JSONOBJ))
                (parseelements (rest (rest jsonlist)))
            )
        )
        ((equal (second jsonlist) #\,)
            (cond 
                ((or (stringp (first jsonlist)) 
                        (numberp (first jsonlist)))
                    (append 
                        (list (first jsonlist))
                        (parseelements (rest (rest jsonlist)))
                    )
                )
                (t (error "Errore nel Value (parseelements 2)"))
            )
        )
        ((equal (first jsonlist) #\{)
            (append 
                (list (parsing jsonlist))
                (parseelements (closeobj (rest jsonlist) 0))
            )
        )
        ((and (equal (first jsonlist) #\[) (equal (second jsonlist) #\]))
            (append 
                (list (list 'JSONARRAY))
                (parseelements (rest (rest jsonlist)))
            )
        )
        ((equal (first jsonlist) #\[)
            (cons
                (cons
                    'JSONARRAY
                    (parseelements (rest jsonlist))
                )
                (parseelements (closearray (rest jsonlist) 0))
            )
        )
        ((equal (second jsonlist) #\])
            (cond
                ((or (stringp (first jsonlist)) 
                    (numberp (first jsonlist)))
                    (list (first jsonlist))
                )
                (t (error "Errore nel Value (parseelements 3)"))
            )
        )
        (t (error "Errore nel Value (parseelements 1)"))
    )
    
)

; trova la partesi chiusa e restituisce la parte dopo
(defun closeobj (jsonlist cont)
    (cond
        ((equal (first jsonlist) #\{)
            (closeobj (rest jsonlist) (+ cont 1))
        )
        ((and (equal (first jsonlist) #\}) (equal cont 0))
            (rest jsonlist)
        )
        ((equal (first jsonlist) #\}) 
            (closeobj (rest jsonlist) (- cont 1))
        )
        (t (closeobj (rest jsonlist) cont))
    )
)

; trova la partesi chiusa e restituisce la parte dopo
(defun closearray (jsonlist cont)
    (cond
        ((equal (first jsonlist) #\[)
            (closearray (rest jsonlist) (+ cont 1))
        )
        ((and (equal (first jsonlist) #\]) (equal cont 0))
            (rest jsonlist)
        )
        ((equal (first jsonlist) #\]) 
            (closearray (rest jsonlist) (- cont 1))
        )
        (t (closearray (rest jsonlist) cont))
    )
)

; createstringlist (list completa, contatore, temporanea)
; sistema la lista di caratteri in una di lista di stringhe, char e numeri
(defun createstringlist (jsonlist cont tmp) 
    (cond
        ((and (null tmp) (null jsonlist)) nil)
        ((null jsonlist) (list (coerce tmp 'string)))
        ((equal (first jsonlist) #\")
            (createstringlist (rest jsonlist) (+ cont 1) tmp)
        )
        ((= cont 0)
            (cons (car jsonlist) (createstringlist (cdr jsonlist) cont tmp)) 
        )
        ((= cont 1)
            (createstringlist (rest jsonlist) cont 
                (append tmp (list (first jsonlist)))
            )
        ) 
        ((= cont 2)
            (cons   (coerce tmp 'string)
                    (createstringlist jsonlist 0 nil))
        )
        (t (error "Errore di sintassi (createstringlist)"))
    )
)

; createstringlist (list completa, temporanea)
; gestiste i numeri con e senza segno raggruppandoli in una variabile sola
(defun createnumberlist (jsonlist tmp)
        (cond
            ((and (null jsonlist) (null tmp)) nil)
            ((null jsonlist) (list (listnumber tmp)))
            ((and 
                    (or
                        (equal (first jsonlist) #\,)
                        (equal (first jsonlist) #\})
                        (equal (first jsonlist) #\])
                    )
                    (not (null tmp))
                )
                (cons (listnumber tmp) 
                    (cons (first jsonlist) 
                        (createnumberlist (rest jsonlist) nil)))
            )
            ((stringp (first jsonlist))
	            (cons (first jsonlist)
	            (createnumberlist (rest jsonlist) tmp))
            )
            (
                (or
                    (and 
                        (<= (char-int (first jsonlist)) 57) 
                        (>= (char-int (first jsonlist)) 48)
                    )
                    (equal (first jsonlist) #\+)
                    (equal (first jsonlist) #\-)
                    (equal (first jsonlist) #\.)
                )
                (createnumberlist (rest jsonlist)
                    (append tmp (list (first jsonlist)))
                )
            )
            ((and (standard-char-p (first jsonlist)) (null tmp))
	            (cons (first jsonlist)
	            (createnumberlist (rest jsonlist) tmp))
            )
            (t (error "Errore di sintassi (createnumberlist)"))
        )
    
)

; listnumber decide se il number è un float o un integer
(defun listnumber (tmp)
    (let ((number (coerce tmp 'string)))
        (if (null (find #\. number))
            (parse-integer number)
            (parse-float number)
        )
    ) 
)

; cancella tutti #\Newline e #\Space della jsonlist
(defun delnls (jsonlist)
    (cond
        ((null jsonlist) nil)
        ((equal (first jsonlist) '#\Newline) (delnls (rest jsonlist)))
        ((equal (first jsonlist) '#\Space) (delnls (rest jsonlist)))
        (t (cons (first jsonlist) (delnls (rest jsonlist))))
    )
)

; controllo delle parentesi
(defun checkp (jsonlist)
    (let (
            (x (graffe jsonlist 0)) 
            (y (quadre jsonlist 0))
        )
        (cond 
            ((and (= x 0) (= y 0)) jsonlist)
            (t (error "parentesi non bilanciate"))
        )
    )
)

; controllo delle parentesi graffe
(defun graffe (jsonlist cont)
    (cond
        ((null jsonlist) cont)
        ((equal (first jsonlist) #\{)
            (graffe (rest jsonlist) (+ cont 1))
        )
        ((equal (first jsonlist) #\}) 
            (graffe (rest jsonlist) (- cont 1))
        )
        (t (graffe (rest jsonlist) cont))
    )
)

; controllo delle parentesi quadre
(defun quadre (jsonlist cont)
    (cond
        ((null jsonlist) cont)
        ((equal (first jsonlist) #\[)
            (quadre (rest jsonlist) (+ cont 1))
        )
        ((equal (first jsonlist) #\]) 
            (quadre (rest jsonlist) (- cont 1))
        )
        (t (quadre (rest jsonlist) cont))
    )
)

; jsonaccess, legge l'attribute richiesto e restituisce il suo value
; questa verrà letta una sola volta searchvalue sarà ricorsiva, credo sia meglio così
; OPTIONAL si usa nel caso di parametri falcoltativi 
; REST nel caso ci siano più di una variabile, magari non sappiamo quante variali optionali ci siano
; ASSOC risponde a una query; gli serve una lista in ingresso e il quesioto (non credo possiamo usarlo)
; LENGTH da il numero di lunghezza (non so come spiegarlo se non esempio: (lunghezza "abc") => 3)
(defun jsonaccess (jsonobj &optional field &rest morefield)
    (cond 
        ((null field) jsonobj)
        ((equal (first jsonobj) 'JSONOBJ)
            (cond
                ((and (null morefield) (stringp field))
                    (searchvalue (rest jsonobj) field)
                )
                ((and (null morefield) (listp field))
                    (searchvalue (rest jsonobj) (first field))
                )
                ((not (null morefield))

                )
            )
        )
        ((and (equal (first jsonobj) 'JSONARRAY) (null morefield))
            
        )

        
        (t (error "Errore (jsonaccess)")) 
        
    )
)

(defun searchvalue (jsonobj field)
    (cond
        ((null jsonobj) (error "Field cercato non presente"))
        ((equal (first (first jsonobj)) field)
            (second (first jsonobj))
        )
        (t (searchvalue (rest jsonobj) field))
    )
)

; jsonread apre un file in lettura
; legge i char e li trasforma in unica stringa
; fa il jsonparse
(defun jsonread (FileName)
    (with-open-file
        (In FileName 
            :if-does-not-exist :error
		    :direction :input)
        (jsonparse (Intostring In))
    )
)

; trasforma in un' unica stringa i char letti dal file
(defun Intostring (file)
    (let ((jsonstring (read-char file nil 'eof)))
        (if (eq jsonstring 'eof) 
            ""
            (string-append jsonstring (Intostring file))
        )
    )
)



; jsondumb, jsonlist parsata quindi jsonobj a 
; scrive una stringa JSON su un file
(defun jsondumb ()
    (cond
        ; caso di JSONOBJ mette { ma coma fa a sapere quando finire avendo liste nelle liste
        ; caso di JSONARRAY 
    )

)
