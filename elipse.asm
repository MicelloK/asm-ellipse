.387 

;===========================================================================

data segment

args db 200 dup('$')
x_ax db 0
y_ax db 0

key_code db 0

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
    ; mov ax, 13h
    ; xor ah, ah
    ; int 10h












gui_exit:
    ; /WYJŚCIE Z TRYBU GRAFICZNEGO/
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
    mov si, 082h
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
; di - offset na x_ax/y_ax
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
        mov byte ptr es:[di], al
        ret

skip_spaces:
    inc si
    mov cl, byte ptr ds:[si]
    cmp cl, ' '
    je skip_spaces
    ret

    
    






code ends

;===========================================================================

stack segment stack
    dw 300 dup(?)
    stack_t dw ?
stack ends
    
end start
