include 'emu8086.inc'
org 100h

jmp start

playerName db 20 dup(0)
scores db 10 dup(0)
names  db 200 dup(0)

count  db 0
score  db 0
target db 0
rounds db 5
grade  db 0
rank   db 0
streak db 0

menuMsg  db 13,10,'===========================',13,10
         db '     SHOOTING GAME v1.0',13,10
         db '===========================',13,10
         db '1. Play Game',13,10
         db '2. Leaderboard',13,10
         db '3. Exit',13,10
         db 'Choice: $'

nameMsg db 13,10,'Enter Your Name: $'
shotMsg db 13,10,'Your Shot (1-9): $'
saveMsg db 13,10,'Score Saved!$'
boardMsg db 13,10,'===== LEADERBOARD =====',13,10,'$'
emptyMsg db 13,10,'No Records Yet!$'

gradeA db 'Grade : A - Excellent!$'
gradeB db 'Grade : B - Good Job!$'
gradeC db 'Grade : C - Decent!$'
gradeF db 'Grade : F - Keep Practicing!$'

streakMsg db 13,10,'*** STREAK BONUS! ***$'
perfectMsg db 13,10,'=== PERFECT SCORE! ===$'

NEWLINE MACRO
    mov ah, 2
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
ENDM

BEEP MACRO
    mov ah, 2
    mov dl, 7
    int 21h
ENDM

cls_blue proc
    mov ah, 00h
    mov al, 03h
    int 10h
    mov ah, 06h
    mov al, 0
    mov bh, 17h
    mov ch, 0
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 10h
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h
    ret
cls_blue endp

draw_bar proc
    push ax
    push cx

    mov ah, 2
    mov dl, '['
    int 21h

    mov cl, score
    mov ch, 0
    cmp cx, 0
    je  db_empty

db_fill:
    mov ah, 2
    mov dl, '#'
    int 21h
    dec cl
    jnz db_fill

db_empty:
    mov al, 5
    sub al, score
    mov cl, al
    cmp cl, 0
    je  db_done

db_dots:
    mov ah, 2
    mov dl, '.'
    int 21h
    dec cl
    jnz db_dots

db_done:
    mov ah, 2
    mov dl, ']'
    int 21h

    pop cx
    pop ax
    ret
draw_bar endp

draw_gun proc
    PRINTN "   +-----+"
    PRINTN "   | GUN |======---->"
    PRINTN "   +-----+"
    ret
draw_gun endp

draw_target proc
    push ax
    PRINTN "       +-------+"
    PRINTN "       | (---) |"
    PRINT  "       | ( "
    mov al, target
    add al, 48
    mov dl, al
    mov ah, 2
    int 21h
    PRINTN " ) |"
    PRINTN "       | (---) |"
    PRINTN "       +-------+"
    pop ax
    ret
draw_target endp

anim_hit proc
    NEWLINE
    BEEP
    BEEP
    PRINTN "  ====================="
    PRINTN "  *** HIT! Great Shot!"
    PRINTN "  ====================="
    ret
anim_hit endp

anim_miss proc
    NEWLINE
    PRINTN "  ~~~~~~~~~~~~~~~~~~~~~"
    PRINTN "  --- MISS! Try again!"
    PRINTN "  ~~~~~~~~~~~~~~~~~~~~~"
    ret
anim_miss endp

show_countdown proc
    NEWLINE
    PRINTN "  Get Ready..."
    PRINT  "  3... 2... 1... GO!"
    NEWLINE
    BEEP
    ret
show_countdown endp

draw_scoreboard proc
    push ax
    PRINT "Score  : "
    call draw_bar
    mov al, streak
    cmp al, 0
    je  dsb_done
    PRINT "  Streak: "
    mov ah, 0
    call PRINT_NUM_UNS
    PUTC 'x'
dsb_done:
    NEWLINE
    pop ax
    ret
draw_scoreboard endp

print_grade proc
    push ax
    push bx

    mov al, score
    mov bl, 20
    imul bl

    cmp ax, 100
    jge pg_A
    cmp ax, 60
    jge pg_B
    cmp ax, 40
    jge pg_C
    jmp pg_F
pg_A:
    mov grade, 'A'
    jmp pg_acc
pg_B:
    mov grade, 'B'
    jmp pg_acc
pg_C:
    mov grade, 'C'
    jmp pg_acc
pg_F:
    mov grade, 'F'
pg_acc:
    PRINT "Accuracy : "
    call PRINT_NUM_UNS
    PUTC '%'
    NEWLINE
    NEWLINE
    mov al, grade
    cmp al, 'A'
    jne pg_chkB
    BEEP
    BEEP
    mov dx, offset gradeA
    mov ah, 9
    int 21h
    jmp pg_done
pg_chkB:
    cmp al, 'B'
    jne pg_chkC
    mov dx, offset gradeB
    mov ah, 9
    int 21h
    jmp pg_done
pg_chkC:
    cmp al, 'C'
    jne pg_chkF
    mov dx, offset gradeC
    mov ah, 9
    int 21h
    jmp pg_done
pg_chkF:
    mov dx, offset gradeF
    mov ah, 9
    int 21h
pg_done:
    pop bx
    pop ax
    ret
print_grade endp

sort_scores proc
    push bp
    mov bp, sp
    sub sp, 2

    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, count
    cmp al, 2
    jb  sort_exit

    mov cl, al
    mov ch, 0
    dec cx

sort_out:
    push cx
    mov si, 0
    mov word ptr [bp-2], 0

    mov al, count
    dec al
    mov cl, al
    mov ch, 0

sort_in:
    mov al, scores[si]
    mov bl, scores[si+1]
    cmp al, bl
    jge sort_skip

    mov scores[si], bl
    mov scores[si+1], al

    push cx
    push si

    mov ax, si
    mov bx, 20
    mul bx
    mov di, ax

    mov ax, si
    inc ax
    mov bx, 20
    mul bx
    mov bx, ax

    mov cx, 20
swap_nm:
    mov al, names[di]
    mov dl, names[bx]
    mov names[di], dl
    mov names[bx], al
    inc di
    inc bx
    loop swap_nm

    pop si
    pop cx
    mov word ptr [bp-2], 1

sort_skip:
    inc si
    loop sort_in

    pop cx
    loop sort_out

sort_exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    mov sp, bp
    pop bp
    ret
sort_scores endp

start:
    call cls_blue
    NEWLINE
    NEWLINE
    PRINTN "    ========================="
    PRINTN "       SHOOTING  GAME"
    PRINTN "    ========================="
    NEWLINE
    call draw_gun
    NEWLINE
    PRINTN "    - Match the target number"
    PRINTN "    - 5 rounds per game"
    PRINTN "    - Build streaks for bonus!"
    NEWLINE
    PRINTN "    ========================="
    NEWLINE
    PRINT  "    Press any key to start..."
    mov ah, 1
    int 21h

menu:
    call cls_blue
    mov dx, offset menuMsg
    mov ah, 9
    int 21h
    mov ah, 1
    int 21h
    cmp al, '1'
    je play_game
    cmp al, '2'
    je leaderboard
    cmp al, '3'
    je exit_prog
    jmp menu

play_game:
    call cls_blue
    mov score, 0
    mov rounds, 5
    mov streak, 0

    ; clear name buffer
    lea si, playerName
    mov cx, 20
clear_name:
    mov byte ptr [si], 0
    inc si
    loop clear_name

    mov dx, offset nameMsg
    mov ah, 9
    int 21h

    lea di, playerName
    mov dx, 19
    call GET_STRING

game_loop:
    cmp rounds, 0
    je game_over

    call cls_blue

    ; random target 1-9
    mov ah, 00h
    int 1Ah
    mov al, dl
    xor ah, ah
    mov bl, 9
    div bl
    inc ah
    mov target, ah

    PRINTN "========================="
    PRINTN "      SHOOTING GAME"
    PRINTN "========================="
    NEWLINE

    PRINT "Round  : "
    mov al, 6
    sub al, rounds
    mov ah, 0
    call PRINT_NUM_UNS
    PRINT " of 5"
    NEWLINE

    call draw_scoreboard
    NEWLINE
    call draw_gun
    NEWLINE
    call draw_target
    NEWLINE
    call show_countdown
    NEWLINE

    PRINTN "  Fire : ---===---> [TARGET]"
    NEWLINE

    mov dx, offset shotMsg
    mov ah, 9
    int 21h

    call SCAN_NUM

    mov al, target
    mov ah, 0
    cmp cx, ax
    je hit_label
    jmp miss_label

hit_label:
    call anim_hit
    mov al, score
    add al, 1
    mov score, al
    mov al, streak
    add al, 1
    mov streak, al
    cmp al, 3
    jl next_round
    mov dx, offset streakMsg
    mov ah, 9
    int 21h
    BEEP
    jmp next_round

miss_label:
    call anim_miss
    mov streak, 0

next_round:
    NEWLINE
    PRINT "Press any key..."
    mov ah, 1
    int 21h
    dec rounds
    jmp game_loop

game_over:
    call cls_blue

    mov al, score
    cmp al, 5
    jne go_normal
    BEEP
    BEEP
    BEEP
    mov dx, offset perfectMsg
    mov ah, 9
    int 21h
    NEWLINE

go_normal:
    PRINTN "========================="
    PRINTN "       GAME OVER!"
    PRINTN "========================="
    NEWLINE

    PRINT "Score    : "
    call draw_bar
    NEWLINE

    PRINT "Rating   : "
    mov cl, score
    mov ch, 0
    cmp cx, 0
    je go_grade
go_stars:
    PUTC '*'
    dec cl
    jnz go_stars

go_grade:
    NEWLINE
    call print_grade
    NEWLINE

    ; save to arrays - use count as index
    mov al, count
    xor ah, ah
    mov si, ax
    mov al, score
    mov scores[si], al

    mov al, count
    xor ah, ah
    mov bx, 20
    mul bx
    mov di, ax

    lea si, playerName
    mov cx, 20
copy_nm:
    mov al, [si]
    mov names[di], al
    inc si
    inc di
    loop copy_nm

    inc count

    mov dx, offset saveMsg
    mov ah, 9
    int 21h
    NEWLINE
    PRINT "Press any key..."
    mov ah, 1
    int 21h
    jmp menu

; =========================================
; LEADERBOARD - fixed loop
; =========================================
leaderboard:
    call cls_blue
    call sort_scores

    mov dx, offset boardMsg
    mov ah, 9
    int 21h

    ; check if anyone played
    mov al, count
    cmp al, 0
    je no_records

    ; FIX: use bl as rank, cl as counter
    ; keep them separate so mul cant corrupt
    mov bl, 1           ; rank starts at 1
    mov al, count
    mov ah, 0
    mov cl, al          ; cl = how many players
    mov ch, 0
    mov si, 0           ; si = current player index

disp_loop:
    ; safety check - stop if cl is 0
    cmp cl, 0
    je board_done

    NEWLINE

    ; print rank from bl (not affected by mul)
    PUTC '['
    mov al, bl
    mov ah, 0
    call PRINT_NUM_UNS
    PUTC ']'
    PUTC ' '

    ; save everything before mul corrupts bx
    push bx
    push cx
    push si

    ; get name start offset = si * 20
    mov ax, si
    mov bx, 20
    mul bx              ; ax = offset, bx destroyed here
    mov di, ax          ; di = name position in names[]

    pop si
    pop cx
    pop bx

    ; print name char by char until 0
    push bx
    push cx
    push si
    mov cx, 20
print_nm:
    mov al, names[di]
    cmp al, 0
    je nm_done
    mov dl, al
    mov ah, 2
    int 21h
    inc di
    loop print_nm
nm_done:
    pop si
    pop cx
    pop bx

    ; print score number
    PRINT "  "
    mov al, scores[si]
    mov ah, 0
    call PRINT_NUM_UNS
    PRINT "/5 "

    ; print stars
    push cx
    mov cl, scores[si]
    mov ch, 0
    cmp cx, 0
    je lb_nostar
lb_stars:
    PUTC '*'
    dec cl
    jnz lb_stars
lb_nostar:
    pop cx

    PRINT " "

    ; draw bar - uses score variable
    ; temporarily put this player score into score
    push ax
    mov al, scores[si]
    mov score, al
    call draw_bar
    pop ax

    ; grade letter
    mov al, scores[si]
    mov bh, 20          ; use bh not bl to avoid corruption
    mul bh              ; ax = percentage
    PRINT " ("
    cmp ax, 100
    jge show_A
    cmp ax, 60
    jge show_B
    cmp ax, 40
    jge show_C
    PUTC 'F'
    jmp show_end
show_A:
    PUTC 'A'
    jmp show_end
show_B:
    PUTC 'B'
    jmp show_end
show_C:
    PUTC 'C'
show_end:
    PUTC ')'
    NEWLINE
    PRINTN "-------------------------"

    inc bl              ; next rank
    inc si              ; next player
    dec cl              ; one less to show
    jnz disp_loop
    jmp board_done

no_records:
    mov dx, offset emptyMsg
    mov ah, 9
    int 21h

board_done:
    NEWLINE
    PRINT "Press any key..."
    mov ah, 1
    int 21h
    jmp menu

exit_prog:
    call cls_blue
    NEWLINE
    PRINTN "  Thanks for playing!"
    PRINTN "  Goodbye!"
    mov ah, 4Ch
    int 21h

DEFINE_SCAN_NUM
DEFINE_PRINT_NUM_UNS
DEFINE_GET_STRING
DEFINE_PRINT_STRING
DEFINE_CLEAR_SCREEN

end start