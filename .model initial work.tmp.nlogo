;;;;;;;;;;;;;;;;;;;;;;
;; TIPURI DE AGENTI ;;
;;;;;;;;;;;;;;;;;;;;;;
breed [neangajati neangajat]
breed [angajati angajat]
breed [furnizori furnizor]

angajati-own [
  ilc ;; individual learning capacity
  nivel-comp ;; lista de 12 valori (C1–C12)
  motivatie ;; 0.0 – 1.0
  istoric-formare ;; lista cu "universitate" / "training"
  tick-nivel-comp-atins
  invata-de-la ;; va fi atribuit random intre "universitate" / "training"
]

neangajati-own [
  ilc ;; individual learning capacity
  nivel-comp ;; lista de 12 valori (C1–C12)
  motivatie ;; 0.0 – 1.0
  istoric-formare ;; lista cu "universitate" / "training"
  tick-nivel-comp-atins
  invata-de-la ;; va fi atribuit random intre "universitate" / "training"
]

furnizori-own[
  tip ;; universitate / learning center
]

globals [
  ALREADY-FITTING-AGENTS
  FITTING-AGENTS-FOR-JOB
  NR-OF-EXPECTED-COMPETENCIES
  JOB-COMPETENCY-ARRAY
  EMPLOYEES-NONEMPLOYEES-MEAN-COMPETENCY-LIST
]

to setup
  clear-all

  init-globals
  print "Competencies: 1 2 3 4 5 6 7 8 9 10 11 12"
  set JOB-COMPETENCY-ARRAY  read-competency-list

  print (word "             " JOB-COMPETENCY-ARRAY)

  init-employees
  init-non-employees

  set ALREADY-FITTING-AGENTS search-already-fitting
  print (word "Already fitting agents for job before simulation: " ALREADY-FITTING-AGENTS)
  print (word "Total nr. of employees: " count angajati)
  print (word "Total nr. of non-employees: " count neangajati)

  reset-ticks
end

to go
  let total-agents-that-will-be-checked (count (turtle-set angajati neangajati) - length ALREADY-FITTING-AGENTS) ;; Excludem agentii care sunt 'already-fitting' dupa procedura de setup
                                                                                                                 ;; Modelul se va opri (nu are sens) daca nu exista posibilitatea unui nr. de agenti care sa intre in procesul de invatare suficient de mare incat nr. de joburi sa fie atins
  if (total-agents-that-will-be-checked < nr-of-jobs) [
    error "The number of agents that should follow courses for enhancing their competencies in order to achieve the required number of agents fitting the job can never be reached!"
  ]

  ;; Modelul se va opri atunci cand numarul de agenti 'fitting-for-job' este atins, in functie de comp. acestora
  if (check-if-required-fitting-agents = true) [
;    update-plots
    stop
  ]

  update-competencies-for-agents
  print "NEW TICK"
  tick
end

;; Fn helper pentru citirea listei competentelor din input
; - arunca eroare in situatia in care nu exista 12 competente in lista
; - intoarce o lista ce contine valorile competentelor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report read-competency-list
  let res-list []
  let group-char-temp ""
  ;; Iteram prin fiecare caracter din input-box-ul 'JobCompetencyList'
  foreach n-values length JobCompetencyList [idx -> idx][idx ->
    let curr-char item idx JobCompetencyList
    ;; Cum in input-string putem avea elem. de tipul "1.5 2.5", acestea trebuie tratate ca fiind un element in lista (splituite in functie de curr-char=" ")
    ifelse curr-char = " " [
      if group-char-temp != "" [ ;; Daca avem o 'grupare' de caractere (ex: "1.5"), le adaugam in lista
        check-if-allowed-character group-char-temp
        set res-list lput group-char-temp res-list
        set group-char-temp ""
      ]
    ] [
      set group-char-temp word group-char-temp curr-char
    ]
  ]
  ;; Adaugam ultima 'grupare' de caractere in lista, de asemenea
  if group-char-temp != "" [ set res-list lput group-char-temp res-list ]
  check-if-expected-nr-of-competencies res-list
  report res-list
end

;; Fn helper pentru validarea nr. de competente
; - arunca eroare in situatia in care este intalnit un char neasteptat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to check-if-expected-nr-of-competencies [competency-list]
  if (length competency-list != NR-OF-EXPECTED-COMPETENCIES)[
    error word "There should be 12 competencies list! Nr. of competencies provided: " length competency-list
  ]
end

;; Fn helper pentru validarea chars din input
; - arunca eroare in situatia in care este intalnit un char neasteptat
; - trebuie sa fie intre 1-5 sau 'x'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to check-if-allowed-character [char]

  if (char != "x")[
    carefully [
      let float-value-of-char read-from-string char
      if (float-value-of-char < 1 or float-value-of-char > 5) [
        error "Error that will be catched below"
      ]
    ] [
      error "Only characters between [1;5] && \"x\" are allowed for the competencies list!"
    ]
  ]

end

;; Fn helper pentru initializarea var globale
; - arunca eroare in situatia in care este intalnit un char neasteptat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to init-globals
  set NR-OF-EXPECTED-COMPETENCIES 12
  set JOB-COMPETENCY-ARRAY []
  set EMPLOYEES-NONEMPLOYEES-MEAN-COMPETENCY-LIST [4.53	4.42	3.66	3.17	2.16	3.14	2.87	2.06	2.0	2.5	4.12	4.56]
  set ALREADY-FITTING-AGENTS []
  set FITTING-AGENTS-FOR-JOB []
end

;; Fn helper pentru initializarea angajatilor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to init-employees
  create-angajati nr-employees [
    set ilc (random 101) / 100 ;; initializam 'ilc' cu valoare intre 0-1 (eg. 0, 0.01,...)
    set motivatie (random 101) / 100 ;; initializam 'motivatie' cu valoare intre 0-1 (eg. 0, 0.01,...)
    set tick-nivel-comp-atins [0 0 0 0 0 0 0 0 0 0 0 0] ;; Cate tickuri i-au luat agentului pentru atingerea nivelului jobului, de la C1....C12
    set istoric-formare [] ;; empty-list, momentan nu a invatat nimic
    set invata-de-la one-of ["university" "training"] ;; initializam random cu 'university' sau 'training'. In functie de asta, metode diferite vor fi folosite pentru cresterea nivel-comp in cadrul ticks

    set nivel-comp [] ;; initializam 'nivel-comp' cu empty-list; Ulterior, lista va fi populata

    ;; Populam fiecare dintre C1..C12 cu valori distribuite normal
    foreach n-values length JOB-COMPETENCY-ARRAY [idx -> idx][idx ->
      let global-mean-competency-for-idx item idx EMPLOYEES-NONEMPLOYEES-MEAN-COMPETENCY-LIST
      let normal-distribution-competency random-normal global-mean-competency-for-idx 0.5

      ;; Pentru a evita valorile out-of-expected-values
      if (normal-distribution-competency > 5) [set nivel-comp lput 5 nivel-comp]  ;; Initializam cu max., daca este peste valoarea maxima
      if (normal-distribution-competency < 1) [set nivel-comp lput 1 nivel-comp]  ;; Initializam cu min., daca este sub valoarea minima
      if (normal-distribution-competency >= 1 and normal-distribution-competency <= 5) [set nivel-comp lput normal-distribution-competency nivel-comp]
    ]
  ]
end

;; Fn helper pentru initializarea neangajatilor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to init-non-employees
  create-neangajati nr-non-employees [
    set ilc (random 101) / 100 ;; initializam 'ilc' cu valoare intre 0-1 (eg. 0, 0.01,...)
    set motivatie (random 101) / 100 ;; initializam 'motivatie' cu valoare intre 0-1 (eg. 0, 0.01,...)
    set tick-nivel-comp-atins [0 0 0 0 0 0 0 0 0 0 0 0] ;; Cate tickuri i-au luat agentului pentru atingerea nivelului jobului, de la C1....C12
    set istoric-formare [] ;; empty-list, momentan nu a invatat nimic
    set invata-de-la one-of ["university" "training"] ;; initializam random cu 'university' sau 'training'. In functie de asta, metode diferite vor fi folosite pentru cresterea nivel-comp in cadrul ticks

    set nivel-comp [] ;; initializam 'nivel-comp' cu empty-list; Ulterior, lista va fi populata

    ;; Populam fiecare dintre C1..C12 cu valori distribuite normal
    foreach n-values length JOB-COMPETENCY-ARRAY [idx -> idx][idx ->
      let global-mean-competency-for-idx item idx EMPLOYEES-NONEMPLOYEES-MEAN-COMPETENCY-LIST
      let normal-distribution-competency random-normal global-mean-competency-for-idx 0.5

      ;; Pentru a evita valorile out-of-expected-values
      if (normal-distribution-competency > 5) [set nivel-comp lput 5 nivel-comp]  ;; Initializam cu max., daca este peste valoarea maxima
      if (normal-distribution-competency < 1) [set nivel-comp lput 1 nivel-comp]  ;; Initializam cu min., daca este sub valoarea minima
      if (normal-distribution-competency >= 1 and normal-distribution-competency <= 5) [set nivel-comp lput normal-distribution-competency nivel-comp]

    ]
  ]
end

;; Fn helper pentru determinarea agentilor care ating deja pragul dorit al job comp.
; - un agent atinge pragul dorit al job comp. in situatia in care toate comp. sale sunt >= decat job comp. != 'x'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report search-already-fitting
  let fitting-agents []
  ask (turtle-set angajati neangajati) [
    print (word "Check if already suitable for job for: " self)
    let is-fitting true

    let idx 0

    while [(idx < length JOB-COMPETENCY-ARRAY) and (is-fitting = true)][

      let stringified-comp-searched-for item idx JOB-COMPETENCY-ARRAY
      let current-employee-comp-level item idx nivel-comp

      if (stringified-comp-searched-for != "x") [
        let float-comp-searched-for read-from-string stringified-comp-searched-for
        print (word "Job Competency [" idx "] = min. " float-comp-searched-for)
        print (word "Cur Competency [" idx "] = " current-employee-comp-level)

        if (current-employee-comp-level < float-comp-searched-for)[
          set is-fitting false
          print (word "Candidate not fitting due to Competency " (idx + 1) )
        ]
      ]
      set idx idx + 1
    ]

    if (is-fitting = true) [
      set fitting-agents lput self fitting-agents
    ]
  ]

  report fitting-agents
end

to update-competencies-for-agents
  update-competency-level-university
  update-competency-level-learning-centre
end

;; Fn helper apelata in cadrul fiecarui tick pentru cresterea comp. agentilor in functie de cursuri universitare.
; - in cadrul cursurilor universitare, toate comp. agentului vor creste
; - toate comp. agentului vor creste in functie de formula: %-learn-from-university * ILC * motivatie
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-competency-level-university
  let fitting-agents []
  ask (turtle-set angajati neangajati) with [
    not member? self ALREADY-FITTING-AGENTS and ;; Excludem agentii care deja ating competentele dorite ale jobului
    not member? self FITTING-AGENTS-FOR-JOB and
    invata-de-la = "university"                 ;; Ar trebui luati in considerare doar agentii carora le-a fost assignat 'university' (init-employees && init-nonemployees)
  ][
    ;; Iteram prin fiecare competenta a agentului pentru a o updata cu noua valoare
    foreach n-values length nivel-comp [idx -> idx][idx ->
      let curr-competency item idx nivel-comp
      let value-to-add ( (%-learn-from-university) / 100 * ilc * motivatie * curr-competency)

      let updated-curr-competency 0
      if ( (curr-competency + value-to-add) > 5)  [set updated-curr-competency 5] ;; Cresterea nu ar trebui sa depaseasca pragul de '5'
      if ( (curr-competency + value-to-add) <= 5) [set updated-curr-competency (curr-competency + value-to-add)]

      set nivel-comp replace-item idx nivel-comp updated-curr-competency  ;; Updatam nivel-comp al agentului cu noua valoare, dupa urmarea cursurilor universitare, pt tickul curent
    ]

    print (word "Update competencies from university for: " self "; New competencies: " nivel-comp)
  ]
end

;; Fn helper apelata in cadrul fiecarui tick pentru cresterea comp. agentilor in functie de cursuri formare.
; - in cadrul cursurilor de formare, criteriile vor fi considerate & updatate secvential, nu toate odata. Ex: job[5 3] agent[3 2] => agent [4 2] => agent [5 2] => agent [5 3]
; - comp. agentului va creste in functie de formula: %-learn-from-university * ILC * motivatie
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-competency-level-learning-centre
  let fitting-agents []
  ask (turtle-set angajati neangajati) with [
    not member? self ALREADY-FITTING-AGENTS and ;; Excludem agentii care deja ating competentele dorite ale jobului
    not member? self FITTING-AGENTS-FOR-JOB  and
    invata-de-la = "training"                 ;; Ar trebui luati in considerare doar agentii carora le-a fost assignat 'training' (init-employees && init-nonemployees)
  ][
    let idx 0
    let all-job-comp-level-reached true
    ;; Loop-ul se va opri la prima comp. care nu este >= job comp. Doar aceasta va fi updatata. Ulterior, in cadrul tickurilor, se va continua cu urmatoarele
    while [idx < length nivel-comp and all-job-comp-level-reached = true][

      ;; Validam job-competency-array[idx], intrucat acesta ar trebui sa fie != 'x'

      if (item idx JOB-COMPETENCY-ARRAY != "x")[

        let job-comp-for-idx read-from-string item idx JOB-COMPETENCY-ARRAY
        if (item idx nivel-comp < job-comp-for-idx)[ ;; Verificam nivel-comp[i] vs job-comp[i]. Daca este sub nivelul asteptat, va trebui doar sa updatam nivel-comp si sa iesim din loop

          let curr-competency item idx nivel-comp
          let value-to-add ( (%-learn-from-training-centre) / 100 * ilc * motivatie * curr-competency)

          let updated-curr-competency 0
          if ( (curr-competency + value-to-add) > 5)  [set updated-curr-competency 5] ;; Cresterea nu ar trebui sa depaseasca pragul de '5'
          if ( (curr-competency + value-to-add) <= 5) [set updated-curr-competency (curr-competency + value-to-add)]

          print (word "Update competencies from learning centre for: " self " on comp[" idx "]: " curr-competency " => " updated-curr-competency)
          set nivel-comp replace-item idx nivel-comp updated-curr-competency  ;; Updatam nivel-comp al agentului cu noua valoare, dupa urmarea cursurilor universitare, pt tickul curent

          set all-job-comp-level-reached false
        ]
      ]


      set idx idx + 1
    ]
  ]
end

;; Fn helper apelata in cadrul fiecarui tick. Aceasta fn. verifica daca criteriul de oprire al modelului este atins.
; - itereaza prin toti agentii care nu sunt deja 'fitting' sau nu au devenit 'fitting' in urma cursurilor urmate
; - adauga agentii care au devenit 'fit-for-job' in lista globala
; - intoarce 'true' in situatia in care nr. dorit de agenti a fost atins; 'false' altfel (modelul va continua pentru FALSE)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report check-if-required-fitting-agents
  ifelse (length FITTING-AGENTS-FOR-JOB >= nr-of-jobs)[   ;; Daca deja exista suficienti agenti dintre cei cu comp. 'updatate', programul ar trebui sa se opreasca
    report true
  ][ ;; Altfel, verificam daca exista alti agenti care pot fi 'fitting-for-job'

    ask (turtle-set angajati neangajati) with [
      not member? self ALREADY-FITTING-AGENTS and not member? self FITTING-AGENTS-FOR-JOB  ;; Excludem agentii care deja ating competentele dorite ale jobului
    ] [
      if (check-if-agent-fitting = true)[ ;; In situatia in care agentul este 'fitting-for-job', il adaugam in lista 'FITTING-AGENTS-FOR-JOB'
        set FITTING-AGENTS-FOR-JOB lput self FITTING-AGENTS-FOR-JOB
      ]
    ]
  ]
  print (word "Fitting agents after updates: " FITTING-AGENTS-FOR-JOB)
  report length FITTING-AGENTS-FOR-JOB >= nr-of-jobs
end

;; Fn helper pentru a verifica daca agentul curent poate fi calificat pentru job-ul dorit
; - verifica comp. care sunt diferite de 'x'. Ex. comp. cautate pentru job: [4 x x 1] => doar comp[0] si comp[3] trebuie atinse
; - in situatia in care comp. agentului sunt min. egale cu cele cautate => el este 'fitting-for-job' (TRUE), altfel FALSE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report check-if-agent-fitting

  foreach n-values length JOB-COMPETENCY-ARRAY [idx -> idx][idx ->

    let stringified-comp-searched-for item idx JOB-COMPETENCY-ARRAY

    if (stringified-comp-searched-for != "x") [
      let float-comp-searched-for read-from-string stringified-comp-searched-for
      let current-employee-comp-level item idx nivel-comp

      ;; Daca competenta(i) a fost atinsa in iteratia curenta, updatam idx. respectiv in tick-nivel-comp-atins
      ;; Excludem comp. care deja au fost atinse
      if ( (current-employee-comp-level >= float-comp-searched-for) and (item idx tick-nivel-comp-atins = 0) ) [
        let current-ticks ticks
        set tick-nivel-comp-atins replace-item idx tick-nivel-comp-atins current-ticks  ;; Updatam 'cat timp i-a luat agentului sa atinga comp(i)'
      ]

      ;; Fail-fast pentru prima comp. pentru care agentul nu este inca 'fitting'
      if (current-employee-comp-level < float-comp-searched-for)[
        print (word "Current agent: " self " is not yet prepared for job due to comp[" (idx + 1) "]")
        report false
      ]
    ]
  ]

  report true
end
@#$#@#$#@
GRAPHICS-WINDOW
500
18
937
456
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

INPUTBOX
58
227
252
287
JobCompetencyList
x x x 5 x 5 x x x x x 2
1
0
String

BUTTON
60
44
123
77
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
58
135
230
168
nr-employees
nr-employees
0
100
4.0
1
1
NIL
HORIZONTAL

SLIDER
59
178
231
211
nr-non-employees
nr-non-employees
0
100
3.0
1
1
NIL
HORIZONTAL

BUTTON
60
87
123
120
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
294
138
497
171
%-learn-from-university
%-learn-from-university
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
57
298
229
331
nr-of-jobs
nr-of-jobs
0
100
4.0
1
1
NIL
HORIZONTAL

PLOT
55
363
424
513
Agenti ce se potrivesc jobului
ticks
Nr. persoane
0.0
0.0
0.0
0.0
true
true
"" ""
PENS
"Pers. potrivite jobului" 1.0 0 -16777216 true "" "plot length FITTING-AGENTS-FOR-JOB"

SLIDER
293
181
496
214
%-learn-from-training-centre
%-learn-from-training-centre
0
100
20.0
1
1
NIL
HORIZONTAL

PLOT
1043
32
1424
182
Bar-chart with job-comp-list
NIL
NIL
1.0
12.0
1.0
5.0
false
false
"  let res-list []\n  let group-char-temp \"\"\n  ;; Iteram prin fiecare caracter din input-box-ul 'JobCompetencyList'\n  foreach n-values length JobCompetencyList [idx -> idx][idx ->\n    let curr-char item idx JobCompetencyList\n    ;; Cum in input-string putem avea elem. de tipul \"1.5 2.5\", acestea trebuie tratate ca fiind un element in lista (splituite in functie de curr-char=\" \")\n    ifelse curr-char = \" \" [\n      if group-char-temp != \"\" [ ;; Daca avem o 'grupare' de caractere (ex: \"1.5\"), le adaugam in lista\n        check-if-allowed-character group-char-temp\n        set res-list lput group-char-temp res-list\n        set group-char-temp \"\"\n      ]\n    ] [\n      set group-char-temp word group-char-temp curr-char\n    ]\n  ]\n  ;; Adaugam ultima 'grupare' de caractere in lista, de asemenea\n  if group-char-temp != \"\" [ set res-list lput group-char-temp res-list ]\n  \n\n;; Creare bar-chart pe baza valorilor  \nlet i 0\nforeach res-list [ val ->\n  if val != \"x\" [\n    ;; Plot the value at index 'i'\n    plotxy i (read-from-string val)\n  ]\n  set i i + 1\n]" ""
PENS
"pen-0" 1.0 1 -7500403 true "" ""

PLOT
969
228
1169
493
Initial avg. values for comp.
NIL
NIL
1.0
12.0
1.0
5.0
false
false
"  let all-agents (turtle-set angajati neangajati)\n  let initial-avg-comp-list []\n \n  foreach n-values 12 [idx -> idx][idx ->\n    let mean-comp-idx mean [item idx nivel-comp] of all-agents\n    set initial-avg-comp-list lput mean-comp-idx initial-avg-comp-list\n  ]\n  \n  ;; Creare bar-chart pe baza valorilor  \nlet i 0\nforeach initial-avg-comp-list [ val ->\n  if val != \"x\" [\n    ;; Plot the value at index 'i'\n    plotxy i val\n  ]\n  set i i + 1\n]" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1207
228
1436
492
Final avg. values for comp
NIL
NIL
1.0
12.0
1.0
5.0
false
false
"\n    let all-agents (turtle-set angajati neangajati)\n    let final-avg-comp-list []\n    \n    foreach n-values 12 [idx -> idx][idx ->\n      let mean-comp-idx mean [item idx nivel-comp] of all-agents\n      set final-avg-comp-list lput mean-comp-idx final-avg-comp-list\n    ]\n    \n    ;; Creare bar-chart pe baza valorilor  \n    let i 0\n    foreach final-avg-comp-list [ val ->\n      if val != \"x\" [\n        ;; Plot the value at index 'i'\n        plotxy i val\n      ]\n      set-plot-pen-color black\n      set i i + 1\n    ]" "\n    let all-agents (turtle-set angajati neangajati)\n    let final-avg-comp-list []\n    \n    foreach n-values 12 [idx -> idx][idx ->\n      let mean-comp-idx mean [item idx nivel-comp] of all-agents\n      set final-avg-comp-list lput mean-comp-idx final-avg-comp-list\n    ]\n    \n    ;; Creare bar-chart pe baza valorilor  \n          set-plot-pen-color green\n    let i 0\n    foreach final-avg-comp-list [ val ->\n      if val != \"x\" [\n        ;; Plot the value at index 'i'\n        plotxy i val\n      ]\n      set i i + 1\n    ]"
PENS
"default" 1.0 1 -16777216 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
