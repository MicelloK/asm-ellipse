.387 

;===========================================================================

data segment

x_ax dw 0
y_ax dw 0

x_pt dw 0
y_pt dw 0

x dw 0
y dw 0

key_code db 0

color db 15

exception_msg db "Blad danych wejsciowych$"

data ends

;===========================================================================

code segment
start:
    ;/INICJALIZACJA STOSU/
    mov ax, seg stack
    mov ss, ax
    mov sp, offset stack_t

    ;/PARSOWANIE WEJŚCIA/
    mov ax, seg data
    mov es, ax

    call parse_input

    ;/INICJALIZACJA TRYBU GRAFICZNEGO/
    mov ax, 13h
    xor ah, ah
    int 10h


    mov ax, 30
    mov word ptr es:[x], ax
    call find_y

    call draw_elipse

    main_loop:
        call handle_key
        jmp main_loop





    










gui_exit:
    ; /WYJŚCIE Z TRYBU GRAFICZNEGO/
    call clear_screen
    mov al, 3h
    xor ah, ah
    int 10h

exit:
    ; /ZAKOŃCZENIE PROGRAMU/
    xor al, al
    mov ah, 4ch
    int 21h

exception:
    ;/WYŚWIETLENIE KOMUNIKATU O BŁĘDZIE/
    mov ax, seg data
    mov ds, ax
    mov dx, offset exception_msg
    mov ah, 9h
    int 21h
    jmp exit

;===========================================================================
; funkcje pomocnicze
;===========================================================================

parse_input:
    mov si, 082h - 1
    call skip_spaces
    ; arg1
    mov di, offset x_ax
    call parse_arg

    call skip_spaces
    ; arg2
    mov di, offset y_ax
    call parse_arg

    ;sprawdzanie czy nie ma wiecej argumentow
    cmp byte ptr ds:[si], 0Dh ; 0Dh - enter
    jne exception

    ret
    
; si - offset na poczatek
; di - offset na x_ax
parse_arg:
    xor ax, ax
    parse_loop:
        mov cl, byte ptr ds:[si]
        cmp cl, 0Dh
        je parse_end
        cmp cl, ' '
        je parse_end
        cmp cl, '0'
        jl exception
        cmp cl, '9'
        jg exception
        sub cl, '0'
        mov bx, 10
        mul bx
        add ax, cx
        inc si
        jmp parse_loop
    parse_end:
        cmp ax, 200
        jg exception

        mov bx, 2
        div bx
        mov word ptr es:[di], ax
        ret

skip_spaces:
    inc si
    mov cl, byte ptr ds:[si]
    cmp cl, ' '
    je skip_spaces
    ret

clear_screen:
    push es
    mov ax, 0A000h
    mov es, ax

    xor di, di
    mov cx, 64000

    cld
    rep stosb

    pop es

    ret

show_point:
    mov ax, seg data
    mov es, ax

    mov ax, word ptr es:[y_pt]
    mov bx, 320
    mul bx

    mov bx, word ptr es:[x_pt]
    add bx, ax

    mov ax, 0A000h
    mov ds, ax
    mov al, byte ptr es:[color]
    mov byte ptr ds:[bx], al

    ret

draw_points:
    ; (x, y)
    mov ax, 160
    add ax, word ptr es:[x]
    mov word ptr es:[x_pt], ax

    mov ax, 100
    sub ax, word ptr es:[y]
    mov word ptr es:[y_pt], ax

    call show_point

    ; (x, -y)
    mov ax, 160
    add ax, word ptr es:[x]
    mov word ptr es:[x_pt], ax

    mov ax, 100
    add ax, word ptr es:[y]
    mov word ptr es:[y_pt], ax

    call show_point

    ; (-x, y)
    mov ax, 160
    sub ax, word ptr es:[x]
    mov word ptr es:[x_pt], ax

    mov ax, 100
    sub ax, word ptr es:[y]
    mov word ptr es:[y_pt], ax

    call show_point

    ; (-x, -y)
    mov ax, 160
    sub ax, word ptr es:[x]
    mov word ptr es:[x_pt], ax

    mov ax, 100
    add ax, word ptr es:[y]
    mov word ptr es:[y_pt], ax

    call show_point
    
    ret

draw_elipse:
    call clear_screen
    call check_bnd
    mov word ptr es:[x], 0
    mov ax, word ptr es:[x_ax]
    mov cx, ax

    draw_x_loop:
        call find_y
        call draw_points
        inc word ptr es:[x]
        loop draw_x_loop

    mov word ptr es:[y], 0
    mov ax, word ptr es:[y_ax]
    mov cx, ax

    draw_y_loop:
        call find_x
        call draw_points
        inc word ptr es:[y]
        loop draw_y_loop
    
    ret

find_y:
    finit

    fild word ptr es:[x]
    fimul word ptr es:[x]
    fidiv word ptr es:[x_ax]
    fidiv word ptr es:[x_ax]
    fld1
    fsub
    fchs
    fimul word ptr es:[y_ax]
    fimul word ptr es:[y_ax]
    fsqrt
    fist word ptr es:[y]

    ret

find_x:
    fild word ptr es:[y]
    fimul word ptr es:[y]
    fidiv word ptr es:[y_ax]
    fidiv word ptr es:[y_ax]
    fld1
    fsub
    fchs
    fimul word ptr es:[x_ax]
    fimul word ptr es:[x_ax]
    fsqrt
    fist word ptr es:[x]

    ret

handle_key:
    in al, 60h
    cmp al, 1
    je gui_exit

    cmp al, byte ptr es:[key_code]
    je key_end
    mov byte ptr es:[key_code], al

    cmp al, 75
    je left_key

    cmp al, 77
    je right_key

    cmp al, 72
    je up_key

    cmp al, 80
    je down_key

    cmp al, 57
    je space_key

    cmp al, 24
    je o_key

    key_end:
        ret

    left_key:
        dec word ptr es:[x_ax]
        call draw_elipse
        ret

    right_key:
        inc word ptr es:[x_ax]
        call draw_elipse
        ret

    up_key:
        inc word ptr es:[y_ax]
        call draw_elipse
        ret

    down_key:
        dec word ptr es:[y_ax]
        call draw_elipse
        ret

    space_key:
        call change_color
        call draw_elipse
        ret

    o_key:
        call make_circle
        call draw_elipse
        ret

check_bnd:
    mov ax, word ptr es:[x_ax]
    cmp ax, 1
    jge check_x_bnd
    mov word ptr es:[x_ax], 1
    jmp check_y_bnd

    check_x_bnd:
        cmp ax, 160
        jl check_y_bnd
        mov word ptr es:[x_ax], 159

    check_y_bnd:
        mov ax, word ptr es:[y_ax]
        cmp ax, 1
        jge check_end
        mov word ptr es:[y_ax], 1
        jmp check_bnd_end

    check_end:
        cmp ax, 100
        jl check_bnd_end
        mov word ptr es:[y_ax], 99

    check_bnd_end:
        ret

change_color:
    mov al, byte ptr es:[color]
    inc al
    cmp al, 16
    je reset_color
    mov byte ptr es:[color], al
    ret

    reset_color:
        mov byte ptr es:[color], 1
        ret

make_circle:
    mov ax, word ptr es:[x_ax]
    mov bx, word ptr es:[y_ax]

    cmp ax, bx
    jge x_bigger

    mov word ptr es:[y_ax], ax
    ret

    x_bigger:
        mov word ptr es:[x_ax], bx
        ret





code ends

;===========================================================================

stack segment stack
    dw 300 dup(?)
    stack_t dw ?
stack ends
    
end start
