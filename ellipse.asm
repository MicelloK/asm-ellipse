.387                                                        ; dyrektywa o zmiennym przecinku

;===========================================================================================;
;                                          DANE                                             ;    
;===========================================================================================;

data segment

x_r dw 0                                                    ; promień x
y_r dw 0                                                    ; promień y

x_pt dw 0                                                   ; punkt x wykorzystywany do rysowania
y_pt dw 0                                                   ; punkt y wykorzystywany do rysowania

x dw 0                                                      ; punkt x wykorzystywany do obliczeń
y dw 0                                                      ; punkt y wykorzystywany do obliczeń

key_code db 0                                               ; ostatnio wciśnięty klawisz

color db 15                                                 ; kolor elipsy

exception_msg db "Blad danych wejsciowych$"                 ; komunikat o błędzie

data ends

;===========================================================================================;
;                                       KOD PROGRAMU                                        ;
;===========================================================================================;

code segment
start:
    ;/INICJALIZACJA STOSU/
    mov ax, seg stack
    mov ss, ax
    mov sp, offset stack_top

    ;/PARSOWANIE WEJŚCIA/
    mov ax, seg data
    mov es, ax

    call parse_input

    ;/INICJALIZACJA TRYBU GRAFICZNEGO/
    mov ax, 13h
    xor ah, ah
    int 10h

    ;/RYSOWANIE ELIPSY/
    call draw_elipse
    main_loop:
        call handle_key
        jmp main_loop

gui_exit:
    ;/WYJŚCIE Z TRYBU GRAFICZNEGO/
    call clear_screen
    mov al, 3h                                              ; kod trybu tekstowego
    xor ah, ah 
    int 10h

exit:
    ;/ZAKOŃCZENIE PROGRAMU/
    xor al, al
    mov ah, 4ch                                             ; kod wyjścia
    int 21h

exception:
    ;/WYŚWIETLENIE KOMUNIKATU O BŁĘDZIE/
    mov ax, seg data
    mov ds, ax
    mov dx, offset exception_msg                            ; adres komunikatu
    mov ah, 9h                                              ; kod wyświetlenia tekstu
    int 21h
    jmp exit                                                ; wyjście z programu

;=================================================================================================;
;                                            FUNCKJE                                              ;           
;=================================================================================================;

;-------------------------------------------------------------------------------------------------;
; funkcja parsująca wejście                                                                       ;
; x_r: pierwsza liczba na wiejściu                                                                ;
; y_r: druga liczba na wejściu                                                                    ;
;-------------------------------------------------------------------------------------------------;
parse_input:
    mov si, 082h - 1                                        ; -1 bo inkrementacja na początku (skip_spaces)
    call skip_spaces                                        ; funkcja zwraca si na pierwszy znak po spacjach
    ; arg1
    mov di, offset x_r                                      ; parsowanie do x_r
    call parse_arg

    call skip_spaces                                        ; funkcja zwraca si na pierwszy znak po spacjach
    ; arg2
    mov di, offset y_r                                      ; parsowanie do y_r
    call parse_arg

    ;/SPRAWDZENIE CZY NIE MA NADMIAROWYCH ZNAKÓW/
    cmp byte ptr ds:[si], 0Dh                               ; 0Dh - enter
    jne exception

    ret
    
;-------------------------------------------------------------------------------------------------;
; funkcja parsująca argument na liczbę                                                            ;
; si: offset na początek argumentu                                                                ;
; di: offset na zmienną do której zapisać liczbę                                                  ;
;-------------------------------------------------------------------------------------------------;
parse_arg:
    xor ax, ax
    parse_loop:
        mov cl, byte ptr ds:[si]                            ; wczytanie znaku
        cmp cl, 0Dh                                         ; 0Dh - enter
        je parse_end                                        ; jeżeli enter to koniec parsowania
        cmp cl, ' ' 
        je parse_end                                        ; jeżeli spacja to koniec parsowania
        cmp cl, '0'
        jl exception                                        ; jeżeli znak < '0' to błąd
        cmp cl, '9'
        jg exception                                        ; jeżeli znak > '9' to błąd
        sub cl, '0'                                         ; odejmuje wartość '0' od znaku i otrzymuję wartość liczby
        mov bx, 10
        mul bx                                              ; mnożę przez 10
        add ax, cx                                          ; dodaję wartość znaku
        inc si                                              ; inkrementacja si
        jmp parse_loop
    parse_end:
        cmp ax, 200                                         ; sprawdzam czy wartość jest mniejsza od 200
        jg exception                                        ; jeżeli większa to błąd

        mov bx, 2
        div bx                                              ; zamieniam półoś na promień
        mov word ptr es:[di], ax                            ; zapisuję do wartość do [di]
        ret


;-------------------------------------------------------------------------------------------------;
; funkcja pomijająca spacje                                                                       ;
; si: offset na początek argumentu                                                                ;
;-------------------------------------------------------------------------------------------------;
skip_spaces:
    inc si
    mov cl, byte ptr ds:[si]                                ; wczytanie znaku
    cmp cl, ' '
    je skip_spaces                                          ; jeżeli spacja to inkrementacja si i powtórzenie
    ret

;-------------------------------------------------------------------------------------------------;
; funkcja czyszcząca ekran                                                                        ;
;-------------------------------------------------------------------------------------------------;
clear_screen:
    push es                                                 ; zapisanie es, żeby nie stracić
    mov ax, 0A000h                                          ; segment pamięci graficznej
    mov es, ax                                              ; zapisanie do es

    xor di, di                                              ; di = 0
    mov cx, 64000                                           ; 320 * 200

    cld                                                     ; ustawienie flagi kierunku na rosnący
    rep stosb                                               ; powtórz stosb cx razy

    pop es                                                  ; przywrócenie es

    ret

;-------------------------------------------------------------------------------------------------;
; funkcja zapalająca punkt                                                                        ;
; x_pt: współrzędna x                                                                             ;
; y_pt: współrzędna y                                                                             ;
; color: kolor                                                                                    ;
;-------------------------------------------------------------------------------------------------;
show_point:
    mov ax, seg data
    mov es, ax                                              ; es - segment danych

    mov ax, word ptr es:[y_pt] ; ax = y
    mov bx, 320
    mul bx                                                  ; ax = y * 320

    mov bx, word ptr es:[x_pt]
    add bx, ax                                              ; bx = x + y * 320

    mov ax, 0A000h                                          ; 0A000h - segment pamięci graficznej
    mov ds, ax 
    mov al, byte ptr es:[color]                             ; al = kolor
    mov byte ptr ds:[bx], al                                ; zapisanie koloru do pamięci graficznej

    ret

;-------------------------------------------------------------------------------------------------;
; funkcja zapalająca cztery punkty symetryczne względem środka                                    ;
; x: współrzędna x                                                                                ;
; y: współrzędna y                                                                                ;
;-------------------------------------------------------------------------------------------------;
draw_points:
    ; (x, y)
    mov ax, 160
    add ax, word ptr es:[x]                                 ; ax = 160 + x
    mov word ptr es:[x_pt], ax                              ; zapisanie do x_pt

    mov ax, 100
    sub ax, word ptr es:[y]                                 ; ax = 100 - y
    mov word ptr es:[y_pt], ax                              ; zapisanie do y_pt

    call show_point

    ; (x, -y)
    mov ax, 160
    add ax, word ptr es:[x]                                 ; ax = 160 + x
    mov word ptr es:[x_pt], ax                              ; zapisanie do x_pt

    mov ax, 100
    add ax, word ptr es:[y]                                 ; ax = 100 + y
    mov word ptr es:[y_pt], ax                              ; zapisanie do y_pt

    call show_point

    ; (-x, y)
    mov ax, 160
    sub ax, word ptr es:[x]                                 ; ax = 160 - x
    mov word ptr es:[x_pt], ax                              ; zapisanie do x_pt

    mov ax, 100
    sub ax, word ptr es:[y]                                 ; ax = 100 - y
    mov word ptr es:[y_pt], ax                              ; zapisanie do y_pt

    call show_point

    ; (-x, -y)
    mov ax, 160
    sub ax, word ptr es:[x]                                 ; ax = 160 - x
    mov word ptr es:[x_pt], ax                              ; zapisanie do x_pt

    mov ax, 100
    add ax, word ptr es:[y]                                 ; ax = 100 + y
    mov word ptr es:[y_pt], ax                              ; zapisanie do y_pt

    call show_point
    
    ret


;-------------------------------------------------------------------------------------------------;
; funkcja ryująca elipsę                                                                          ;
;-------------------------------------------------------------------------------------------------;
draw_elipse:
    call clear_screen
    call check_bnd                                          ; sprawdzanie czy promień nie jest za duży
    mov word ptr es:[x], 0                                  ; x = 0
    mov ax, word ptr es:[x_r]
    mov cx, ax                                              ; cx = x_r

    draw_x_loop:
        call find_y                                         ; obliczanie y
        call draw_points                                    ; rysowanie odbitych punktów
        inc word ptr es:[x]                                 ; inkrementacja x
        loop draw_x_loop                                    ; powtórz draw_x_loop x_r razy

    mov word ptr es:[y], 0                                  ; y = 0
    mov ax, word ptr es:[y_r]
    mov cx, ax                                              ; cx = y_r

    draw_y_loop:
        call find_x                                         ; obliczanie x
        call draw_points                                    ; rysowanie odbitych punktów
        inc word ptr es:[y]                                 ; inkrementacja y
        loop draw_y_loop                                    ; powtórz draw_y_loop y_r razy
    
    ret

;-------------------------------------------------------------------------------------------------;
; funkcja obliczająca y na podstawie x                                                            ;
; x: współrzędna x                                                                                ;
;-------------------------------------------------------------------------------------------------;
find_y:
    finit                                                   ; inicjalizacja procesora

    fild word ptr es:[x]                                    ; x
    fimul word ptr es:[x]                                   ; x^2
    fidiv word ptr es:[x_r]                                 ; x^2 / x_r
    fidiv word ptr es:[x_r]                                 ; x^2 / x_r^2
    fld1                                                    ; 1
    fsub                                                    ; 1 - x^2 / x_r^2
    fchs                                                    ; -1 + x^2 / x_r^2
    fimul word ptr es:[y_r]                                 ; y_r * (-1 + x^2 / x_r^2)
    fimul word ptr es:[y_r]                                 ; y_r^2 * (-1 + x^2 / x_r^2)
    fsqrt                                                   ; sqrt(y_r^2 * (-1 + x^2 / x_r^2))
    fist word ptr es:[y]                                    ; zapisanie do y

    ret

;-------------------------------------------------------------------------------------------------;
; funkcja obliczająca x na podstawie y                                                            ;
; y: współrzędna y                                                                                ;
;-------------------------------------------------------------------------------------------------;
find_x:
    fild word ptr es:[y]                                    ; y
    fimul word ptr es:[y]                                   ; y^2
    fidiv word ptr es:[y_r]                                 ; y^2 / y_r
    fidiv word ptr es:[y_r]                                 ; y^2 / y_r^2
    fld1                                                    ; 1
    fsub                                                    ; 1 - y^2 / y_r^2
    fchs                                                    ; -1 + y^2 / y_r^2
    fimul word ptr es:[x_r]                                 ; x_r * (-1 + y^2 / y_r^2)
    fimul word ptr es:[x_r]                                 ; x_r^2 * (-1 + y^2 / y_r^2)
    fsqrt                                                   ; sqrt(x_r^2 * (-1 + y^2 / y_r^2))
    fist word ptr es:[x]                                    ; zapisanie do x

    ret

;-------------------------------------------------------------------------------------------------;
; funkcja obsługująca klawiature                                                                  ;
; możliwe klawisze: LEFT, RIGHT, UP, DOWN, ESC, SPACE, L, G                                       ;
;-------------------------------------------------------------------------------------------------;
handle_key:
    in al, 60h                                              ; wprowadzenie kodu klawisza do al
    cmp al, 1 
    je gui_exit                                             ; jeśli klawisz to ESC to wyjdź z programu

    cmp al, byte ptr es:[key_code]                          ; key_code - kod ostatniego wciśniętego klawisza
    je key_end                                              ; jeśli klawisz jest taki sam jak poprzedni to zakończ
    mov byte ptr es:[key_code], al                          ; zapisanie kodu klawisza do key_code

    cmp al, 75
    je left_key                                             ; jeśli klawisz to strzałka w lewo to wykonaj left_key

    cmp al, 77
    je right_key                                            ; jeśli klawisz to strzałka w prawo to wykonaj right_key

    cmp al, 72
    je up_key                                               ; jeśli klawisz to strzałka w górę to wykonaj up_key

    cmp al, 80
    je down_key                                             ; jeśli klawisz to strzałka w dół to wykonaj down_key

    cmp al, 57
    je space_key                                            ; jeśli klawisz to spacja to wykonaj space_key

    cmp al, 38
    je l_key                                                ; jeśli klawisz to L to wykonaj l_key

    cmp al, 34
    je g_key                                                ; jeśli klawisz to R to wykonaj r_key

    key_end:
        ret

    left_key:
        dec word ptr es:[x_r]                               ; zmniejsz promień x_r o 1
        call draw_elipse
        ret

    right_key:
        inc word ptr es:[x_r]                               ; zwiększ promień x_r o 1
        call draw_elipse
        ret

    up_key:
        inc word ptr es:[y_r]                               ; zwiększ promień y_r o 1
        call draw_elipse
        ret

    down_key:
        dec word ptr es:[y_r]                               ; zmniejsz promień y_r o 1
        call draw_elipse
        ret

    space_key:
        call change_color                                   ; zmień kolor
        call draw_elipse
        ret

    l_key:
        call make_le_circle                                 ; zrób okrąg (do mniejszego promienia)
        call draw_elipse
        ret

    g_key:
        call make_gr_circle                                 ; zrób okrąg (do większego promienia)
        call draw_elipse
        ret

;-------------------------------------------------------------------------------------------------;
; funkcja sprawdzająca czy promień mieści się w granicach                                         ;
; jeśli nie to ustawia promień na graniczną wartość                                               ;
; x_r: promień x                                                                                  ;
; y_r: promień y                                                                                  ;
;-------------------------------------------------------------------------------------------------;
check_bnd:
    mov ax, word ptr es:[x_r]
    cmp ax, 1                                               ; sprawdz czy x_r jest większy od 1
    jge check_x_bnd                                         ; jeśli tak to sprawdzaj czy x_r jest mniejszy od 160
    mov word ptr es:[x_r], 1                                ; jeśli nie to ustaw x_r na 1
    jmp check_y_bnd                                         ; sprawdz y_r

    check_x_bnd:
        cmp ax, 160 
        jl check_y_bnd                                      ; jeśli x_r jest mniejszy od 160 to sprawdzaj y_r
        mov word ptr es:[x_r], 159                          ; jeśli nie to ustaw x_r na 159

    check_y_bnd:
        mov ax, word ptr es:[y_r]
        cmp ax, 1                                           ; sprawdz czy y_r jest większy od 1
        jge check_end                                       ; jeśli tak to sprawdzaj czy y_r jest mniejszy od 100
        mov word ptr es:[y_r], 1                            ; jeśli nie to ustaw y_r na 1
        jmp check_bnd_end                                   ; zakończ sprawdzanie

    check_end:
        cmp ax, 100
        jl check_bnd_end                                    ; jeśli y_r jest mniejszy od 100 to zakończ sprawdzanie
        mov word ptr es:[y_r], 99                           ; jeśli nie to ustaw y_r na 99

    check_bnd_end:
        ret

;-------------------------------------------------------------------------------------------------;
; funkcja zmieniająca kolor na następny                                                           ;
;-------------------------------------------------------------------------------------------------;
change_color:
    mov al, byte ptr es:[color]
    inc al                                                  ; zwiększ kolor o 1
    cmp al, 16                                              ; sprawdz czy kod koloru jest poprawny 
    je reset_color                                          ; jeśli przekroczy zakres to ustaw kolor na 1 (biały)
    mov byte ptr es:[color], al                             ; zapisz kolor
    ret

    reset_color:
        mov byte ptr es:[color], 1                          ; ustaw kolor na 1 (0 - czarny)
        ret

;-------------------------------------------------------------------------------------------------;
; funkcja zokrąglająca elipsę do większego promienia                                              ;
;-------------------------------------------------------------------------------------------------;
make_gr_circle:
    mov ax, word ptr es:[x_r]                               ; zapisz x_r do ax
    mov bx, word ptr es:[y_r]                               ; zapisz y_r do bx

    cmp ax, bx                                              ; sprawdz który promień jest większy
    jge xg_bigger                                           ; jeśli x_r jest większy to zapisz y_r do x_r

    mov word ptr es:[x_r], bx                               ; jeśli y_r jest większy to zapisz x_r do y_r
    ret

    xg_bigger:
        cmp ax, 99                                          ; 99 to maksymalny promień
        jge xg_bnd                                          ; sprawdz czy x_r jest większy od 100
        mov word ptr es:[y_r], ax                           ; zapisz x_r do y_r
        ret

        xg_bnd:
            mov word ptr es:[y_r], 99                       ; jeśli x_r jest większy od 100 to zapisz 99 do y_r
            mov word ptr es:[x_r], 99                       ; zapisz 99 do x_r
            ret

;-------------------------------------------------------------------------------------------------;
; funkcja zokrąglająca elipsę do mniejszego promienia                                             ;
;-------------------------------------------------------------------------------------------------;
make_le_circle:
    mov ax, word ptr es:[x_r]                               ; zapisz x_r do ax
    mov bx, word ptr es:[y_r]                               ; zapisz y_r do bx

    cmp ax, bx                                              ; sprawdz który promień jest większy
    jge xl_bigger                                           ; jeśli x_r jest większy to zapisz y_r do x_r

    mov word ptr es:[y_r], ax                               ; jeśli y_r jest większy to zapisz x_r do y_r
    ret

    xl_bigger:
        mov word ptr es:[x_r], bx                           ; zapisz y_r do x_r
        ret

code ends

;===================================================================================================;
;                                       KONIEC PROGRAMU                                             ;
;===================================================================================================;

stack segment stack
    dw 300 dup(?)
    stack_top dw ?
stack ends
    
end start
