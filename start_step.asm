  section .bss
w:      resb 4
h:      resb 4
M1:     resb 8
M2:     resb 8
c:      resb 4
T:      resb 8

        section .text
        global start, step


start:
        mov     [w], edi
        mov     [h], esi
        movss   [c], xmm0

        mov     rax, [rdx]
        mov     [M1], rax

        mov     rax, [rdx + 8]
        mov     [M2], rax

        ret


step:
        mov     [T], rdi

        call    evolve
        call    move_T
        call    copy

        ret


evolve:
        mov     rdi, [M1]       ; M1 base address
        mov     rsi, [M2]       ; M2 base address

        movss   xmm0, [c]
        shufps  xmm0, xmm0, 0h  ; broadcast - for multiplications

        xor     rcx, rcx        ; loop counter (y)
e_l1:
        mov     rdx, 1          ; loop counter (x), starting from 1st column
e_l2:
        call    getpos
        mov     r8, rax

        call    up_down
        call    remainder

        inc     edx             ; loop 2
        cmp     edx, [w]
        jl      e_l2

        inc     ecx             ; loop 1
        cmp     ecx, [h]
        jl      e_l1

        ret


;; handle two neighbours above and two below, pos: r8, y: ecx, x: edx, M1: rdi, c: xmm0
up_down:
        xorps   xmm1, xmm1
        xor     r11, r11

up_down_high:
        cmp     ecx, 0          ; check if there are neighbours above
        je      up_down_low

        add     r11, 1b
        mov     r9, r8          ; calculate upper neighbours' position in r9
        sub     r9d, [w]        ; they are one row higher
        sub     r9d, 1          ; they are one column to the left

        movhps  xmm1, [rdi + r9*4]

up_down_low:
        mov     r10d, [h]
        dec     r10d
        cmp     ecx, r10d       ; check if there are neighbours below
        je      up_down_calc

        add     r11, 10b
        mov     r10, r8         ; calculate lower neighbours' position in r10
        add     r10d, [w]       ; they are one row lower
        sub     r10d, 1         ; they are one column to the left

        movlps  xmm1, [rdi + r10*4]

up_down_calc:
        movss   xmm2, [rdi + r8*4]
        shufps  xmm2, xmm2, 0h  ; broadcast - for subtractions

        subps   xmm1, xmm2      ; neighbours - me

        cmp     r11, 01b
        jne     up_down_1

        dpps    xmm1, xmm0, 11000001b ; sum of c*(neighbour_i - me)
        jmp     up_down_fin

up_down_1:
        cmp     r11, 10b
        jne     up_down_2

        dpps    xmm1, xmm0, 00110001b
        jmp     up_down_fin

up_down_2:
        cmp     r11, 11b
        jne     up_down_fin

        dpps    xmm1, xmm0, 11110001b

up_down_fin:
        call    save
        ret


;; handle left neighbour, M1: rdi, M2: rsi, position: r8
remainder:
        movss   xmm2, [rdi + r8*4]

        mov     r9, r8          ; calculate left neighbour's position in r9
        sub     r9, 1           ; it's one column to the left

        movss   xmm1, [rdi + r9*4]

        subps   xmm1, xmm2      ; neighbour - me
        mulps   xmm1, xmm0      ; c*(neighbour - me)

        call    save
        ret


;; delta: xmm1, pos: r8
save:
        movss   xmm2, [rsi + r8*4]
        addps   xmm2, xmm1      ; add delta
        movss   [rsi + r8*4], xmm2

        ret


move_T:
        mov     rsi, [M2]       ; M2 base address
        mov     rdi, [T]

        xor     rdx, rdx        ; x is const 0
        xor     rcx, rcx        ; loop counter (y)
m_l1:
        call    getpos
        movss   xmm1, [rdi + rcx*4]
        movss   [rsi + rax*4], xmm1

        inc     ecx             ; loop over height
        cmp     ecx, [h]
        jl      m_l1

        ret


;; copy all values from M2 to M1 - to be used after a step
copy:
        mov     rdi, [M1]       ; M1 base address
        mov     rsi, [M2]       ; M2 base address

        xor     rcx, rcx        ; loop counter (y)
c_l1:
        xor     rdx, rdx        ; loop counter (x)
c_l2:
        call    getpos

        mov     r8d, [w]
        sub     r8, rdx
        cmp     r8, 4
        jl      c_man

        movaps  xmm1, [rsi + rax*4]
        movaps  [rdi + rax*4], xmm1

        add     edx, 4          ; loop 2, by four
        cmp     edx, [w]
        jl      c_l2

        jmp     c_l2_inc

c_man:
        movss   xmm1, [rsi + rax*4]
        movss   [rdi + rax*4], xmm1

        inc     edx             ; loop 2, by one
        cmp     edx, [w]
        jl      c_l2

c_l2_inc:
        inc     ecx             ; loop 1
        cmp     ecx, [h]
        jl      c_l1

        ret

;; y in ecx, x in edx, result in eax
getpos:
        push    rdx

        xor     rax, rax
        mov     eax, [w]        ; eax : w
        mul     ecx             ; eax : w * y

        pop     rdx
        add     eax, edx        ; eax : w*y + x

        ret
