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
ship_offset_x DD 0

bullet_x DD 0
bullet_y DD 0

aliens_x DD 50, 106, 162, 218, 274, 330, 386, 442, 498, 554

alien1_y DD 144
alien2_y DD 104
alien3_y DD  64
alien4_y DD  20

did_shoot DD 0

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

make_alien1_macro macro x, y   ; color = 0FF00h
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
endm 

make_alien2_macro macro x, y   ; color = 0FFh
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
endm 

make_alien3_macro macro x, y   ; color = 7F00FFh
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
endm 

make_alien4_macro macro x, y   ; color = 0FFFF00h
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
	make_shape [ebp+arg2], [ebp+arg3], 64, 64, 0FF91F8h
	jmp afisare_litere
	
evt_keypress:					;daca s-a apasat tasta verifica daca e SPACE, LEFT/RIGHT ARROW
	mov eax, [ebp+arg2]
	cmp eax, 37
	je left_pressed
	cmp eax, 39
	je right_pressed
	cmp eax, 32
	je space_pressed

	
evt_timer:
	inc counter

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
	
	
	make_alien1_macro 50, 144
	make_alien1_macro 106, 144
	make_alien1_macro 162,  144
	make_alien1_macro 218, 144
	make_alien1_macro 274, 144
	
	make_alien1_macro 330, 144
	make_alien1_macro 386, 144
	make_alien1_macro 442, 144
	make_alien1_macro 498, 144
	make_alien1_macro 554, 144
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien2_macro  50, 104
	make_alien2_macro 106, 104
	make_alien2_macro 162, 104
	make_alien2_macro 218, 104
	make_alien2_macro 274, 104
	
	make_alien2_macro 330, 104
	make_alien2_macro 386, 104
	make_alien2_macro 442, 104
	make_alien2_macro 498, 104
	make_alien2_macro 554, 104
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien3_macro  50, 64
	make_alien3_macro 106, 64
	make_alien3_macro 162, 64
	make_alien3_macro 218, 64
	make_alien3_macro 274, 64
	
	make_alien3_macro 330, 64
	make_alien3_macro 386, 64
	make_alien3_macro 442, 64
	make_alien3_macro 498, 64
	make_alien3_macro 554, 64
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	make_alien4_macro  50, 20
	make_alien4_macro 106, 20
	make_alien4_macro 162, 20
	make_alien4_macro 218, 20
	make_alien4_macro 274, 20
	
	make_alien4_macro 330, 20
	make_alien4_macro 386, 20
	make_alien4_macro 442, 20
	make_alien4_macro 498, 20
	make_alien4_macro 554, 20
	;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	make_ship_macro ship_x, 400
	
	shoot:							;eticheta care creeaza proiectilul si il misca
		cmp did_shoot, 0
		je final_draw
		
		cmp bullet_y, 30
		jle out_of_bounds
		
		erase_bullet_macro bullet_x, bullet_y
		sub bullet_y, 30 
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
	
	out_of_bounds:				;eticheta pentru cand se iese de pe ecran
	erase_bullet_macro bullet_x, bullet_y
	mov did_shoot, 0
	
	after_press:
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
