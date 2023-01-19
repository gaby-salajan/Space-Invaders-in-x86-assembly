.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Space Invaders",0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

ship_x DD 290
ship_y DD 400
;ship_offset_x DD 0

bullet_x DD 0
bullet_y DD 0

aliens_1  EQU 50
aliens_2  EQU 106
aliens_3  EQU 162
aliens_4  EQU 218
aliens_5  EQU 274
aliens_6  EQU 330
aliens_7  EQU 386
aliens_8  EQU 442
aliens_9  EQU 498
aliens_10 EQU 554

alien1_y EQU 144
alien2_y EQU 104
alien3_y EQU  64
alien4_y EQU  20

state11 DD 0
state12 DD 0
state13 DD 0
state14 DD 0
state15 DD 0
state16 DD 0
state17 DD 0
state18 DD 0
state19 DD 0
state110 DD 0

state21 DD 0
state22 DD 0
state23 DD 0
state24 DD 0
state25 DD 0
state26 DD 0
state27 DD 0
state28 DD 0
state29 DD 0
state210 DD 0

state31 DD 0
state32 DD 0
state33 DD 0
state34 DD 0
state35 DD 0
state36 DD 0
state37 DD 0
state38 DD 0
state39 DD 0
state310 DD 0

state41 DD 0
state42 DD 0
state43 DD 0
state44 DD 0
state45 DD 0
state46 DD 0
state47 DD 0
state48 DD 0
state49 DD 0
state410 DD 0

did_shoot DD 0

win DD 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


;-----------------------------------------------------------------------------------
calculate_pos macro x,y		;macro care calculeaza pozitia din pixel in vector
	mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax,area
endm

make_shape macro x, y, lungime, latime, color ; macro care creeaza o forma in functie 
local shape_start							  ; de parametri
local shape_loop
	calculate_pos x,y
	mov esi, eax
	
	mov edx, latime
	shape_start:
		mov eax,esi
		mov ecx, lungime
	shape_loop:
		mov dword ptr[eax], color
		add eax, 4
		loop shape_loop
	dec edx
	add esi, area_width*4
	cmp edx, 0
	jg shape_start
endm

make_alien1_macro macro x, y, state   ; color = 0FF00h
local destroyed
local end_draw
	mov edx, state
	cmp state, 1
	je destroyed
	
	make_shape x+4, y, 4, 4, 0FF00h
	make_shape x+28, y, 4, 4, 0FF00h
	
	make_shape x+8, y+4, 4, 4, 0FF00h
	make_shape x+24, y+4, 4, 4, 0FF00h
	
	make_shape x+4, y+8, 28, 4, 0FF00h
	
	make_shape x, y+12, 8, 4, 0FF00h
	make_shape x+12, y+12, 12, 4, 0FF00h
	make_shape x+28, y+12, 8, 4, 0FF00h
	
	make_shape x, y+16, 36, 4, 0FF00h
	
	make_shape x+4, y+20, 28, 4, 0FF00h
	
	make_shape x+4, y+24, 4, 4, 0FF00h
	make_shape x+28, y+24, 4, 4, 0FF00h
	
	make_shape x+8, y+28, 8, 4, 0FF00h
	make_shape x+20, y+28, 8, 4, 0FF00h	
	jmp end_draw
	
	destroyed:
		make_shape x+4, y, 4, 4, 0h
		make_shape x+28, y, 4, 4, 0h
		
		make_shape x+8, y+4, 4, 4, 0h
		make_shape x+24, y+4, 4, 4, 0h
		
		make_shape x+4, y+8, 28, 4, 0h
		
		make_shape x, y+12, 8, 4, 0h
		make_shape x+12, y+12, 12, 4, 0h
		make_shape x+28, y+12, 8, 4, 0h
		
		make_shape x, y+16, 36, 4, 0h
		
		make_shape x+4, y+20, 28, 4, 0h
		
		make_shape x+4, y+24, 4, 4, 0h
		make_shape x+28, y+24, 4, 4, 0h
		
		make_shape x+8, y+28, 8, 4, 0h
		make_shape x+20, y+28, 8, 4, 0h	
	
	end_draw:
endm 

make_alien2_macro macro x, y, state   ; color = 0FFh
local destroyed
local end_draw
	mov edx, state
	cmp state, 1
	je destroyed

	make_shape x+12, y, 12, 4, 0FFh
	
	make_shape x+4, y+4, 28, 4, 0FFh
	
	make_shape x, y+8, 36, 4, 0FFh
	
	make_shape x, y+12, 4, 4, 0FFh
	make_shape x+12, y+12, 12, 4, 0FFh
	make_shape x+32, y+12, 4, 4, 0FFh
	
	make_shape x, y+16, 36, 4, 0FFh
	
	make_shape x+8, y+20, 4, 4, 0FFh
	make_shape x+24, y+20, 4, 4, 0FFh
	
	make_shape x+4, y+24, 4, 4, 0FFh
	make_shape x+12, y+24, 12, 4, 0FFh
	make_shape x+28, y+24, 4, 4, 0FFh
	
	make_shape x, y+28, 4, 4, 0FFh
	make_shape x+32, y+28, 4, 4, 0FFh
	jmp end_draw
	
	destroyed:
		make_shape x+12, y, 12, 4, 0h
	
		make_shape x+4, y+4, 28, 4, 0h
		
		make_shape x, y+8, 36, 4, 0h
		
		make_shape x, y+12, 4, 4, 0h
		make_shape x+12, y+12, 12, 4, 0h
		make_shape x+32, y+12, 4, 4, 0h
		
		make_shape x, y+16, 36, 4, 0h
		
		make_shape x+8, y+20, 4, 4, 0h
		make_shape x+24, y+20, 4, 4, 0h
		
		make_shape x+4, y+24, 4, 4, 0h
		make_shape x+12, y+24, 12, 4, 0h
		make_shape x+28, y+24, 4, 4, 0h
		
		make_shape x, y+28, 4, 4, 0h
		make_shape x+32, y+28, 4, 4, 0h
		
	end_draw:
endm 

make_alien3_macro macro x, y, state   ; color = 7F00FFh
local destroyed
local end_draw
	mov edx, state
	cmp state, 1
	je destroyed
	
	make_shape x+8, y, 4, 4, 7F00FFh
	make_shape x+24, y, 4, 4, 7F00FFh
	
	make_shape x+4, y+4, 28, 4, 7F00FFh
	
	make_shape x, y+8, 36, 4, 7F00FFh
	
	make_shape x, y+12, 8, 4, 7F00FFh
	make_shape x+12, y+12, 12, 4, 7F00FFh
	make_shape x+28, y+12, 8, 4, 7F00FFh
	
	make_shape x+4, y+16, 28, 8, 7F00FFh
	
	make_shape x+8, y+24, 4, 8, 7F00FFh
	make_shape x+24, y+24, 4, 8, 7F00FFh
	make_shape x+4, y+28, 4, 4, 7F00FFh
	make_shape x+28, y+28, 4, 4, 7F00FFh
	jmp end_draw
	
	destroyed:
		make_shape x+8, y, 4, 4, 0h
		make_shape x+24, y, 4, 4, 0h
		
		make_shape x+4, y+4, 28, 4, 0h
		
		make_shape x, y+8, 36, 4, 0h
		
		make_shape x, y+12, 8, 4, 0h
		make_shape x+12, y+12, 12, 4, 0h
		make_shape x+28, y+12, 8, 4, 0h
		
		make_shape x+4, y+16, 28, 8, 0h
		
		make_shape x+8, y+24, 4, 8, 0h
		make_shape x+24, y+24, 4, 8, 0h
		make_shape x+4, y+28, 4, 4, 0h
		make_shape x+28, y+28, 4, 4, 0h
	end_draw:
endm 

make_alien4_macro macro x, y, state   ; color = 0FFFF00h
local destroyed
local end_draw
	mov edx, state
	cmp state, 1
	je destroyed
	make_shape x+12, y, 12, 4, 0FFFF00h
	
	make_shape x+4, y+4, 28, 4, 0FFFF00h
	
	make_shape x, y+8, 8, 4, 0FFFF00h
	make_shape x+12, y+8, 12, 4, 0FFFF00h
	make_shape x+28, y+8, 8, 4, 0FFFF00h
	
	make_shape x, y+12, 36, 4, 0FFFF00h
	
	make_shape x+4, y+16, 8, 4, 0FFFF00h
	make_shape x+24, y+16, 8, 4, 0FFFF00h
	
	make_shape x+8, y+20, 20, 4, 0FFFF00h
	
	make_shape x+4, y+24, 4, 4, 0FFFF00h
	make_shape x+28, y+24, 4, 4, 0FFFF00h
	
	make_shape x+8, y+28, 8, 4, 0FFFF00h
	make_shape x+20, y+28, 8, 4, 0FFFF00h
	jmp end_draw
	
	destroyed:
		make_shape x+12, y, 12, 4, 0h
	
		make_shape x+4, y+4, 28, 4, 0h
		
		make_shape x, y+8, 8, 4, 0h
		make_shape x+12, y+8, 12, 4, 0h
		make_shape x+28, y+8, 8, 4, 0h
		
		make_shape x, y+12, 36, 4, 0h
		
		make_shape x+4, y+16, 8, 4, 0h
		make_shape x+24, y+16, 8, 4, 0h
		
		make_shape x+8, y+20, 20, 4, 0h
		
		make_shape x+4, y+24, 4, 4, 0h
		make_shape x+28, y+24, 4, 4, 0h
		
		make_shape x+8, y+28, 8, 4, 0h
		make_shape x+20, y+28, 8, 4, 0h
	end_draw:
endm

make_ship_macro macro x, y   ; color = 7F00FFh
	make_shape x, y+32, 4, 8, 0FF0000h
	make_shape x, y+40, 4, 8, 0FFFFFFh
	make_shape x, y+48, 20, 4, 0FFFFFFh
	make_shape x, y+52, 12, 4, 0FFFFFFh
	make_shape x, y+56, 8, 4, 0FFFFFFh
	make_shape x, y+60, 4, 4, 0FFFFFFh
	add x, 8
	make_shape x, y+44,  44, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+24,  4,  4, 0FF0000h
	make_shape x, y+28,  4, 4, 0FFFFFFh
	make_shape x, y+32,  4, 4, 0FFFFFFh
	make_shape x, y+36,  4, 4, 0000FFh
	make_shape x, y+40, 12, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+32,  4, 4, 0000FFh
	make_shape x, y+36,  8, 4, 0FFFFFFh
	make_shape x, y+52, 8, 4, 0FF0000h
	make_shape x, y+56, 8, 4, 0FF0000h
	add x, 4
	make_shape x, y+28, 20, 4, 0FFFFFFh
	make_shape x, y+32,  8, 4, 0FFFFFFh
	make_shape x, y+48, 4, 4, 0FF0000h
	add x, 4
	make_shape x, y+12, 12, 16, 0FFFFFFh
	make_shape x, y+36, 12, 4, 0FF0000h
	make_shape x, y+40,  4, 4, 0FF0000h
	make_shape x, y+48, 12, 4, 0FFFFFFh
	make_shape x, y+52, 12, 4, 0FFFFFFh
	add x, 2
	make_shape x,    y,  8, 12, 0FFFFFFh
	add x, 2
	make_shape x, y+32,  4, 4, 0FF0000h
	make_shape x, y+40,  4, 4, 0FFFFFFh
	make_shape x, y+56, 4, 4, 0FFFFFFh
	make_shape x, y+60, 4, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+32,  8, 4, 0FFFFFFh
	make_shape x, y+40,  4, 4, 0FF0000h
	add x, 4
	make_shape x, y+36,  8, 4, 0FFFFFFh
	make_shape x, y+40, 12, 4, 0FFFFFFh
	make_shape x, y+48, 4, 4, 0FF0000h
	make_shape x, y+52, 8, 4, 0FF0000h
	make_shape x, y+56, 8, 4, 0FF0000h
	add x, 4
	make_shape x, y+32,  4, 4, 0000FFh
	make_shape x, y+48, 20, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+24,  4, 4, 0FF0000h
	make_shape x, y+28,  4, 4, 0FFFFFFh
	make_shape x, y+32,  4, 4, 0FFFFFFh
	make_shape x, y+36,  4, 4, 0000FFh
	add x, 4
	make_shape x, y+52, 12, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+56, 8, 4, 0FFFFFFh
	add x, 4
	make_shape x, y+60, 4, 4, 0FFFFFFh
	make_shape x, y+32, 4, 8, 0FF0000h
	make_shape x, y+40, 4, 8, 0FFFFFFh
	sub x, 56
endm

make_bullet_macro macro x, y		;macro care creeaza proiectilul
	make_shape x, y, 8, 12, 0ff8000h
endm

erase_alien_macro macro x,y			;macro care sterge extraterestrul
	make_shape x, y, 36, 32, 0
endm
erase_bullet_macro macro x,y		;macro care sterge proiectilul
	make_shape x, y, 8, 12, 0
endm
erase_ship_macro macro x,y			;macro care sterge nava
	make_shape x, y, 60, 64, 0
endm

destroy_alien_macro macro bulletX, bulletY, alien_Y , state1, state2, state3, state4, state5, state6, state7, state8, state9, state10
local destroy1
local destroy2
local destroy3
local destroy4
local destroy5
local destroy6
local destroy7
local destroy8
local destroy9
local destroy10 
local end_destroy
local empty
	
	erase_bullet_macro bulletX, bulletY
	
	cmp bullet_x,  43
	jl empty
	cmp bullet_x,  85 
	jle destroy1
	
	cmp bullet_x, 99
	jl empty
	cmp bullet_x, 141
	jle destroy2
	
	cmp bullet_x, 155
	jl empty
	cmp bullet_x, 197
	jle destroy3
	
	
	cmp bullet_x, 211
	jl empty
	cmp bullet_x, 253
	jle destroy4
	
	cmp bullet_x, 267
	jl empty
	cmp bullet_x, 309
	jle destroy5
	
	cmp bullet_x, 323
	jl empty
	cmp bullet_x, 365
	jle destroy6
	
	cmp bullet_x, 379
	jl empty
	cmp bullet_x, 421
	jle destroy7
	
	cmp bullet_x, 435
	jl empty
	cmp bullet_x, 477
	jle destroy8
	
	cmp bullet_x, 491
	jl empty
	cmp bullet_x, 533
	jle destroy9
	
	cmp bullet_x, 547
	jl empty
	cmp bullet_x, 589
	jle destroy10
	
	destroy1:
		mov edx, state1
		cmp edx, 1
		je empty
		
		make_shape aliens_1, alien_Y, 36, 32, 0h
		mov state1, 1
		jmp end_destroy
	destroy2:
		mov edx, state2
		cmp edx, 1
		je empty
		
		make_shape aliens_2, alien_Y, 36, 32, 0h
		mov state2, 1
		jmp end_destroy
	destroy3:
		mov edx, state3
		cmp edx, 1
		je empty
		
		make_shape aliens_3, alien_Y, 36, 32, 0h
		mov state3, 1
		jmp end_destroy
	destroy4:
		mov edx, state4
		cmp edx, 1
		je empty
		
		make_shape aliens_4, alien_Y, 36, 32, 0h
		mov state4, 1
		jmp end_destroy
	destroy5:
		mov edx, state5
		cmp edx, 1
		je empty
		
		make_shape aliens_5, alien_Y, 36, 32, 0h
		mov state5, 1
		jmp end_destroy
	destroy6:
		mov edx, state6
		cmp edx, 1
		je empty
		
		make_shape aliens_6, alien_Y, 36, 32, 0h
		mov state6, 1
		jmp end_destroy
	destroy7:
		mov edx, state7
		cmp edx, 1
		je empty
		
		make_shape aliens_7, alien_Y, 36, 32, 0h
		mov state7, 1
		jmp end_destroy
	destroy8:
		mov edx, state8
		cmp edx, 1
		je empty
		
		make_shape aliens_8, alien_Y, 36, 32, 0h
		mov state8, 1
		jmp end_destroy
	destroy9:
		mov edx, state9
		cmp edx, 1
		je empty
		
		make_shape aliens_9, alien_Y, 36, 32, 0h
		mov state9, 1
		jmp end_destroy
	destroy10:
		mov edx, state10
		cmp edx, 1
		je empty
		
		make_shape aliens_10, alien_Y, 36, 32, 0h
		mov state10, 1
		jmp end_destroy
		
	end_destroy:
		erase_bullet_macro bulletX, bulletY
		mov did_shoot, 0
		jmp final_draw
	empty:
		jmp continue_shoot
endm		

check_win_macro macro x, y, win
local check_start					
local check_loop
local no_win
	calculate_pos x,y
	mov esi, eax
	
	mov edx, 155
	check_start:
		mov eax,esi
		mov ecx, 539
	check_loop:
		cmp dword ptr[eax], 0h
		jne no_win
		add eax, 4
		loop check_loop
	dec edx
	add esi, area_width*4
	cmp edx, 0
	jg check_start
	mov win, 1
	
	no_win:
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov eax, [ebp+arg1] ;verifica eveniment
	cmp eax, 1			
	jz evt_click		;s-a apasat click
	cmp eax, 2
	jz evt_timer 		; nu s-a efectuat click pe nimic
	cmp eax, 3
	jz evt_keypress		;s-a apasat tasta
	
	;mai jos e codul care intializeaza fereastra cu pixeli NEGRI
	mov eax, area_width
	mov ebx, area_height
	mul ebx 
	shl eax, 2
	push eax
	push 0
	push area
	call memset
	add esp, 12
	
	jmp afisare_litere
	
evt_click:
	cmp win, 1
	je winner
	
	
	jmp afisare_litere
	
evt_keypress:					;daca s-a apasat tasta verifica daca e SPACE, LEFT/RIGHT ARROW
	cmp win, 1
	je winner
	
	mov eax, [ebp+arg2]
	cmp eax, 37
	je left_pressed
	cmp eax, 39
	je right_pressed
	cmp eax, 32
	je space_pressed

	
evt_timer:
	inc counter
	check_win_macro 50, 20, win 
	cmp win, 1
	je winner
	
afisare_litere:
	
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	make_alien1_macro aliens_1,  alien1_y, state11
	make_alien1_macro aliens_2,  alien1_y, state12
	make_alien1_macro aliens_3,  alien1_y, state13
	make_alien1_macro aliens_4,  alien1_y, state14
	make_alien1_macro aliens_5,  alien1_y, state15
	make_alien1_macro aliens_6,  alien1_y, state16
	make_alien1_macro aliens_7,  alien1_y, state17
	make_alien1_macro aliens_8,  alien1_y, state18
	make_alien1_macro aliens_9,  alien1_y, state19
	make_alien1_macro aliens_10, alien1_y, state110
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien2_macro aliens_1,  alien2_y, state21
	make_alien2_macro aliens_2,  alien2_y, state22
	make_alien2_macro aliens_3,  alien2_y, state23
	make_alien2_macro aliens_4,  alien2_y, state24
	make_alien2_macro aliens_5,  alien2_y, state25
	make_alien2_macro aliens_6,  alien2_y, state26
	make_alien2_macro aliens_7,  alien2_y, state27
	make_alien2_macro aliens_8,  alien2_y, state28
	make_alien2_macro aliens_9,  alien2_y, state29
	make_alien2_macro aliens_10, alien2_y, state210
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien3_macro aliens_1,  alien3_y, state31
	make_alien3_macro aliens_2,  alien3_y, state32
	make_alien3_macro aliens_3,  alien3_y, state33
	make_alien3_macro aliens_4,  alien3_y, state34
	make_alien3_macro aliens_5,  alien3_y, state35
	make_alien3_macro aliens_6,  alien3_y, state36
	make_alien3_macro aliens_7,  alien3_y, state37
	make_alien3_macro aliens_8,  alien3_y, state38
	make_alien3_macro aliens_9,  alien3_y, state39
	make_alien3_macro aliens_10, alien3_y, state310
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien4_macro aliens_1,  alien4_y, state41
	make_alien4_macro aliens_2,  alien4_y, state42
	make_alien4_macro aliens_3,  alien4_y, state43
	make_alien4_macro aliens_4,  alien4_y, state44
	make_alien4_macro aliens_5,  alien4_y, state45
	make_alien4_macro aliens_6,  alien4_y, state46
	make_alien4_macro aliens_7,  alien4_y, state47
	make_alien4_macro aliens_8,  alien4_y, state48
	make_alien4_macro aliens_9,  alien4_y, state49
	make_alien4_macro aliens_10, alien4_y, state410
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	make_ship_macro ship_x, 400
	
	shoot:							;eticheta care creeaza proiectilul si il misca
		cmp did_shoot, 0
		je final_draw
		
		cmp bullet_y, 30
		jle out_of_bounds
		
		cmp bullet_y, alien4_y
		jle continue_shoot
		cmp bullet_y, alien4_y+31
		jle row4
		
		cmp bullet_y, alien3_y
		jle continue_shoot
		cmp bullet_y, alien3_y+31
		jle row3
		
		
		cmp bullet_y, alien2_y
		jle continue_shoot
		cmp bullet_y, alien2_y+31
		jle row2
		
		cmp bullet_y, alien1_y
		jle continue_shoot
		cmp bullet_y, alien1_y+31
		jle row1
		
		continue_shoot:
			erase_bullet_macro bullet_x, bullet_y
			sub bullet_y, 20
			make_bullet_macro bullet_x, bullet_y
		
	jmp final_draw
	
	left_pressed:				;muta nava spre stanga | boundary la 10px
		cmp ship_x, 10
		jle after_press
		
		erase_ship_macro ship_x, ship_y
		sub ship_x, 8
		make_ship_macro ship_x, 400
		jmp after_press
		
	right_pressed:				;muta nava spre dreapta | boundary la 10px de margine
		cmp ship_x, 570    		;dar compara cu marginea din stanga asa ca trebuie sa fie 640-60-10px
		jge after_press
		
		erase_ship_macro ship_x, ship_y
		add ship_x, 8
		make_ship_macro ship_x, 400
		jmp after_press
		
	space_pressed:				;lanseaza proiectilul
		cmp did_shoot, 1
		je after_press
		
		mov eax, ship_x
		mov bullet_x, eax
		add bullet_x, 26
		
		mov eax, ship_y
		mov bullet_y, eax
		sub bullet_y, 12
		
		mov did_shoot, 1
		jmp shoot
	
	row1:
		destroy_alien_macro bullet_x, bullet_y, alien1_y, state11, state12, state13, state14, state15, state16, state17, state18, state19, state110
	
	row2:
		destroy_alien_macro bullet_x, bullet_y, alien2_y, state21, state22, state23, state24, state25, state26, state27, state28, state29, state210
	
	row3:
		destroy_alien_macro bullet_x, bullet_y, alien3_y, state31, state32, state33, state34, state35, state36, state37, state38, state39, state310
		
	row4:
		destroy_alien_macro bullet_x, bullet_y, alien4_y, state41, state42, state43, state44, state45, state46, state47, state48, state49, state410
	
	out_of_bounds:				;eticheta pentru cand se iese de pe ecran
		erase_bullet_macro bullet_x, bullet_y
		mov did_shoot, 0
	
	after_press:
		jmp final_draw
	winner:
		make_shape 0, 0, 640, 480, 0h
		make_text_macro 'Y', area, 280, 230
		make_text_macro 'O', area, 290, 230
		make_text_macro 'U', area, 300, 230
		
		make_text_macro 'W', area, 320, 230
		make_text_macro 'O', area, 330, 230
		make_text_macro 'N', area, 340, 230
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp
;########################################################################################
start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
