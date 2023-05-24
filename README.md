# Asm ellipse

## Opis:

Proszę napisać program uruchamiany z parametrami będącymi dwoma liczbami całkowitych z przedziału (od 0 do 200), reprezentującymi dwie osie (średnice) elipsy: wielką i małą. Następnie, program powinien stabilnie wyświetlić na ekranie w trybie graficznym "VGA: 320x200 256-kolorów" odpowiednią elipsę. Klawisze ze strzałkami powinny umożliwiać dynamiczną zmianę długości osi, a program na bieżąco powinien wówczas aktualizować wygląd elipsy na ekranie. Klawisze: "gór-dół" powinny zmieniać oś pionową, a klawisze: "lewo-prawo" oś poziomą. Wciśnięcie klawisza "Esc", powinno poprawnie zakańczać program.

 

Przykłady wywołania Programu:

 

program2 150 40

 

program2 200 120

 
# Zawartość

* ellipse.asm - kod źródłowy programu
* DOSXNT.386, DOSXNT.EXE, LINK.EXE, ML.ERR, ML.EXE - pliki kompilatora

# Kompilowanie

Aby skompilować program należy wykonać w programie w programie DosBox w katalogu z programem i kompilatorem polecenie:

```
ml ellipse.asm
```

Aby uruchomić program należy w tym samym katalogu wykonać polecenie:
```
ellipse [x_ax] [y_ax]
```

gdzie x_ax to półoś pozioma, a y_ax to półoś pionowa elipsy.
