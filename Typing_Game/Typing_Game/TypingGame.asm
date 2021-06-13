INCLUDE irvine32.inc
INCLUDE macros.inc
INCLUDELIB winmm.lib

;�ŧi�Ƶ{���쫬
PlaySound PROTO, pszSound:PTR BYTE, hmod:DWORD, fdwSound:DWORD

;�w�q�`��
BUFFER_SIZE = 1000	;buffer���j�p

.data
;Ū�ɥ��ܼ�
EASY_FILE_NAME BYTE "easy.txt", 0				;²�����ת��ɦW
NORMAL_FILE_NAME BYTE "normal.txt", 0			;���q���ת��ɦW
HARD_FILE_NAME BYTE "hard.txt", 0				;�x�����ת��ɦW
fileName BYTE 100 DUP(0)						;�ɦW
fileHandle Handle ?								;Ū��/�g�J�ɮץ�
buffer BYTE 100 DUP(0)							;�x�s�ɮפ��e
temp BYTE ?										;�x�sŪ�X���r��					
MENU_BGM_FILE_NAME BYTE "menu_bgm.wav", 0		;���I�����֪��ɦW
GAME_BGM_FILE_NAME BYTE "game_bgm.wav", 0		;�C���L�{�I�����֪��ɦW
END_BGM_FILE_NAME BYTE "end_bgm.wav", 0			;����I�����֪��ɦW

;�C�����ܼ�
input BYTE BUFFER_SIZE DUP(0)					;�ϥΪ̿�J		
SECOND_FACTOR WORD 1000							;�ΨӱN�@������
PENALTY_TIME WORD 10							;�����g�@�ɶ�
startTime DWORD ?								;�}�l�ɶ�
lastTime DWORD ?								;�W�����D�ɶ�
counter DWORD 0									;�O���q�L�����d��
health DWORD 5h									;���a��q
lostHealth DWORD 0								;���h����q
wordLength	DWORD 0								;��r����
again BYTE 2 DUP(0)								;�ˬd�O�_�n���s�}�l
errorCounter WORD 0								;�O����������
totalTime DWORD 0								;�O���q���`�ɶ�
difficulty BYTE ?								;�O���o���諸����
easyBestTime DWORD 9999							;²�����ת��̨γq���ɶ�
normalBestTime DWORD 9999						;���q���ת��̨γq���ɶ�
hardBestTime DWORD 9999							;�x�����ת��̨γq���ɶ�

.code
main PROC
	;���
	menu:
		;�M�e��
		call Clrscr

		;������I������
		INVOKE PlaySound, NULL, NULL, 20001H						;�Ȱ��W�@������
		INVOKE PlaySound, OFFSET MENU_BGM_FILE_NAME, NULL, 20009H	;���񭵼�

		;�e�X���
		call DrawMenu

		;��J�ﶵ
		call ReadInt

		;�ˬd�O�_�b���T�d�򤺡A���ŦX�N���s��J
		cmp eax, 1
		jb menu
		cmp eax, 5
		ja menu

		cmp eax, 1
		je get_file1
		cmp eax, 2
		je get_file2
		cmp eax, 3
		je get_file3
		cmp eax, 4
		je show_rules
		cmp eax, 5
		je quit
		
		;�ƻs�ɦW��
		mov esi, 0
		mov edi, 0

		;�ھڿ�ܪ����׿�ܭn�}���ɮ�
		get_file1:
			;��������
			mov difficulty, 1

			;�ƻs�ɦW��fileName
			INVOKE Str_copy,
				   ADDR EASY_FILE_NAME,
				   ADDR fileName
			jmp open_file
		get_file2:
			mov difficulty, 2

			INVOKE Str_copy,
				   ADDR NORMAL_FILE_NAME,
				   ADDR fileName
			jmp open_file
		get_file3:
			mov difficulty, 3

			INVOKE Str_copy,
				   ADDR HARD_FILE_NAME,
				   ADDR fileName
			jmp open_file
		show_rules:
			call ShowRules
			call ReadInt				;Ū����J
			cmp eax, 1
			je menu						;��J��1�N���^menu
			jmp show_rules				;��J��L���N���^show_rules

	;�}���ɮ�(�D��)
	open_file:
		mov edx, OFFSET fileName
		call OpenInputFile
		mov fileHandle, eax				;�Neax����Handle�ǵ�fileHandle

		;�ˬd�}�ɬO�_���X��
		cmp eax, INVALID_HANDLE_VALUE	;�ˬd�ثe��Handle�O�_����
		jne file_ok						;���ĴN����file_ok
		mWrite <"�L�k�}���ɮ�",0dh,0ah> ;���~�T��
		jmp quit						;�L�ĴN����quit

	;�}�ɦ��\
	file_ok:
		;�q�L�ˬd
		buf_size_ok:
			mov eax, fileHandle		;�N�ثe��fileHandle�s�^eax
	
		;�����}�l�ɶ�
		call GetMseconds
		mov startTime, eax
		mov lastTime, eax

		;����C���L�{�I������
		INVOKE PlaySound, NULL, NULL, 20001H						;�Ȱ��W�@������
		INVOKE PlaySound, OFFSET GAME_BGM_FILE_NAME, NULL, 20009H	;���񭵼� 

		;�C���}�l
		game_start:
			cmp counter, 25
			je game_end				;�p�G�q�������N����game_end

			;��l��esi�Ψ��^fileHandle
			init:
				mov esi, 0				;�Nindex�k0
				mov eax, fileHandle		;���^fileHandle

			;�@��Ū�@�Ӧr���A����Ū��Ů�(Ū�����G���@�ӳ�r)
			read_word:
				mov edx, OFFSET temp	;�s��buffer��
				mov ecx, 1				;�]�w�j�p
				call ReadFromFile		;Ū�����e
				cmp temp, ' '			
				je finish_reading		;Ū��Ů�N�N��Ū���F
				mov bl, temp			;�NŪ�쪺�r���s��bl
 				mov buffer[esi], bl		;�Nbl���ȶǵ�buffer[esi]
				;call Dumpregs			;debug��
				inc esi					;index�[1
				mov eax, fileHandle		;���^fileHandle(�]������ReadFromFile��Aeax���ȷ|��)
				jmp read_word			

			;Ū������
			finish_reading:
				mov wordLength, esi		;�x�s��r����
				inc counter
				;mov eax, counter		;debug��
				;call WriteDec

			;�M�e��
			call Clrscr

			;����D��
			display_problem:
				call SetTitleColor
				mWrite <"<�D��>",0dh,0ah>
				call SetDefaultTextColor
				mov edx, OFFSET buffer
				call WriteString

			;��ܤW�����D�ɶ�
			show_last_time:
				push ebx			;�Ȧs�쥻ebx����
				mGotoxy 30, 1		;�N��в���(��30�� �Ĥ@�C)
				mWrite "�W�@�D��F"
				call GetMseconds	;���o�ثe�ɶ�
				mov ebx, eax		;�Ȧs�ثe�ɶ�
				sub eax, lastTime	;��X�Z�����D�W���L�F�h�[

				;�ഫ����(���H1000)
				mov edx, 0
				movzx ecx, SECOND_FACTOR
				div ecx
				call WriteDec

				;��X���
				mWrite "��"

				mov lastTime, ebx	;��s�W�����D�ɶ�
				pop ebx				;���X�쥻ebx����

			;��ܥثe�D��
			show_counter:
	       		mov eax,counter	;�ǰѼ�
				call ShowCounter

			;�e�X��q�ΤH��
			draw_player:
				push ebx			;�Ȧs�쥻ebx����
				mov eax, lostHealth	;�ǰѼ�
				mov ebx, health		;�ǰѼ�
				call DrawPlayer
				pop ebx				;���X�쥻ebx����

			;Ū����J
			read_input:
				call SetTitleColor
				mWrite <"��J��:",0dh,0ah>
				call SetDefaultTextColor
				mov edx, OFFSET input
				mov ecx, BUFFER_SIZE
				mov esi, 0
				call ReadString

			;����r��
			compare_string:
				INVOKE Str_compare, ADDR buffer, ADDR input
				je equal
				ja wrong
				jb wrong

			;��J���T
			equal:
				call Crlf
				;mWrite <"��J���T",0dh,0ah>
				call Crlf
				jmp clear_buffer		;����clear_buffer

			;��J���~
			wrong:
				call Crlf
				;mWrite <"��J���~",0dh,0ah>
				call Crlf
				inc errorCounter		;���~���ƥ[1
				inc lostHealth
				dec health

			;�M��buffer�A�קK�P�U���x�s����r�Ĭ�
			clear_buffer:
				mov ecx, wordLength		;�]�w�j�馸��
				mov edi, 0
				L1:
					mov buffer[edi], 0
					inc edi
				loop L1
				cmp health, 0	
				je dead					;�p�G��q��0�N����dead
				jmp game_start
				
		;�C������(�٦��Ѿl��q)
		game_end:	
			;�M�e��
			call Clrscr

			;������I������
			INVOKE PlaySound, NULL, NULL, 20001H						;�Ȱ��W�@������
			INVOKE PlaySound, OFFSET END_BGM_FILE_NAME, NULL, 20009H	;���񭵼�

			;��ܹC�����G
			show_result:
				;�ھ����׿�ܤ��P����X
				mWrite "�C������:"
				cmp difficulty, 1
				je print_easy
				cmp difficulty, 2
				je print_normal
				cmp difficulty, 3
				je print_hard

				;²������
				print_easy:
					mWrite <"²��",0dh,0ah,0dh,0ah>
					mov ebx, easyBestTime	;�N�̨ήɶ��s�bebx
					jmp show_finish_time	;����show_finish_time


				;��������
				print_normal:
					mWrite <"����",0dh,0ah,0dh,0ah>
					mov ebx, normalBestTime
					jmp show_finish_time

				;�x������
				print_hard:
					mWrite <"�x��",0dh,0ah,0dh,0ah>
					mov ebx, hardBestTime

				;��ܧ����ɶ�
				show_finish_time:
					;���o�}�l�쵲�����ɶ�
					mWrite "�`�@��O "
					call GetMseconds

					;�ഫ����(���H1000)
					mov edx, 0
					sub eax, startTime
					movzx ecx, SECOND_FACTOR
					div ecx
					call WriteDec
					mov totalTime, eax				;�x�s�`�ɶ����Ĥ@����

					mWrite " + "

					;��X�����g�@�ɶ�
					mov ax, errorCounter
					mul PENALTY_TIME
					movzx eax, ax					
					call WriteDec

					;��X���
					mWrite <" ��",0dh,0ah,0dh,0ah>

					add totalTime, eax				;�[�W�`�ɶ����ĤG����(�g�@�ɶ�)
					mov ecx, totalTime				;�NtotalTime�s��ecx(�����)

				;�ھ����׿�ܭn������̨γq���ɶ�
				cmp difficulty, 1
				je compare_easy_best_time
				cmp difficulty, 2
				je compare_normal_best_time
				cmp difficulty, 3
				je compare_hard_best_time

				;����̨ήɶ�
				compare_easy_best_time:
					cmp ecx, easyBestTime
					jae show_best_time
					mov easyBestTime, ecx			;�p�G�Ҫ�ɶ���̨ήɶ��٤֡A�N��s�̨ήɶ�
					mov ebx, easyBestTime			;�N�̨ήɶ��s�bebx
					jmp show_best_time				;����show_best_time

				compare_normal_best_time:
					cmp ecx, normalBestTime
					jae	show_best_time
					mov normalBestTime, ecx
					mov ebx, normalBestTime
					jmp show_best_time

				compare_hard_best_time:
					cmp ecx, hardBestTime
					jae	show_best_time
					mov hardBestTime, ecx
					mov ebx, hardBestTime

				;��X�̨ήɶ�
				show_best_time:	
					mov eax, ebx				;�N�s�bebx�����̨ήɶ����X
					mWrite "�̨γq���ɶ��� "
					call WriteDec

					;��X���
					mWrite	<" ��",0dh,0ah,0dh,0ah>

					jmp restart		;����restart

		dead:
			;�M�e��
			call Clrscr

			;������I������
			INVOKE PlaySound, NULL, NULL, 20001H						;�Ȱ��W�@������
			INVOKE PlaySound, OFFSET END_BGM_FILE_NAME, NULL, 20009H	;���񭵼�

			mWrite <"����",0dh,0ah,0dh,0ah>


		;�߰ݬO�_�n���s�}�l
		restart:
			mov eax, fileHandle				;���^fileHandle
			call CloseFile					;����(�_�h�n���s�ɵL�k�A�}��)
			jmp restart_input				;����restart_input

			;��JY�MN�H�~���r��
			restart_input_fail:
				;�M�e��
				call Clrscr
				mWrite <"��J���~�A�п�JY(Yes)�Ϊ�N(No)",0dh,0ah>
				
			;��J�O�_�n���s�}�l
			restart_input:
				mWrite <"���s�}�l(Y/N)?",0dh,0ah>	
				mov edx, OFFSET again
				mov ecx, SIZEOF again
				call ReadString				;��J�O�_�n���s�}�l
				cmp again[0], 'N'
				je quit
				cmp again[0], 'Y'
				jne restart_input_fail		;��J���~�N����restart_input_fail
			
			;��l��
			mov counter, 0
			mov errorCounter, 0
			mov health, 5h
			mov lostHealth, 0
			jmp menu						;���^���

	;Ū�ɥ��ѩε{�����浲��
	quit:
		exit				;�����{��

	;procedures

	;-------------------------------------------------------------
	; DrawMenu PROC
	;
	; �e�X���
	; Receives: �S��
	; Returns: ���^��
	;-------------------------------------------------------------

	DrawMenu PROC
		mWrite <"Typing Game",0dh,0ah,0dh,0ah>
		mWrite <"1:²��",0dh,0ah,0dh,0ah>
		mWrite <"2:����",0dh,0ah,0dh,0ah>
		mWrite <"3:�x��",0dh,0ah,0dh,0ah>
		mWrite <"4:�C������",0dh,0ah,0dh,0ah>
		mWrite <"5:�h�X�C��",0dh,0ah,0dh,0ah>
		mWrite "�п�J�ﶵ:"
		ret
	DrawMenu ENDP

	;-------------------------------------------------------------
	; ShowRules PROC
	;
	; ��ܳW�h
	; Receives: �S��
	; Returns: ���^��
	;-------------------------------------------------------------

	ShowRules PROC
		;�M�e��
		call Clrscr	
		mWrite <"1. ���a��5���A�C����1�D�|��1��",0dh,0ah,0dh,0ah>
		mWrite <"2. �C�����@���A�q���ɶ��W�[10��",0dh,0ah,0dh,0ah>
		mWrite <"3. �b�^����25�D�e��q�k0���ܡA�N�⥢��",0dh,0ah,0dh,0ah>
		mWrite <"��J1�H��^���",0dh,0ah>
		mWrite ">"
		ret
	ShowRules ENDP

	;-------------------------------------------------------------
	; SetTitleColor PROC
	;
	; �]�w���D��r�έI���C��
	; Receives: �S��
	; Returns: ���^��
	;-------------------------------------------------------------

	SetTitleColor PROC
		push eax					;�Ȧs�쥻eax����
		mov eax, red+(lightCyan*16)
		call SetTextColor	
		pop eax						;���X�쥻eax����
		ret
	SetTitleColor ENDP

	;-------------------------------------------------------------
	; SetHealthColor PROC
	;
	; �]�w��q��r�έI���C��
	; Receives: �S��
	; Returns: ���^��
	;-------------------------------------------------------------

	SetHealthColor PROC
		push eax				;�Ȧs�쥻eax����
		mov eax, red+(black*16)
		call SetTextColor
		pop eax					;���X�쥻eax����
		ret
	SetHealthColor ENDP

	;-------------------------------------------------------------
	; SetDefaultTextColor PROC
	;
	; �N��r�C��զ^�쥻���զr�©�
	; Receives:	�S��
	; Returns: ���^��
	;-------------------------------------------------------------

	SetDefaultTextColor PROC
		push eax					;�Ȧs�쥻eax����
		mov eax, white+(black*16)
		call SetTextColor
		pop eax						;���X�쥻eax����
		ret
	SetDefaultTextColor ENDP

	;-------------------------------------------------------------
	; ShowCounter PROC
	;
	; ��ܥثe�D��
	; Receives: eax = �ثe�D��
	; Returns: ���^��
	;-------------------------------------------------------------

	ShowCounter PROC
		mGotoxy 50,1		;�N��в���(��50�� �Ĥ@�C)
		mWrite "�ثe�D��:"		
	    call WriteDec
		mWrite "/25"
		ret
	ShowCounter ENDP

	;-------------------------------------------------------------
	; DrawPlayer PROC
	;
	; �e�X���a��q
	; Receives: eax = �l������q , ebx = �Ѿl����q
	; Returns: ���^��
	;-------------------------------------------------------------
		
	DrawPlayer PROC
		push ecx					;�Ȧs�쥻ecx����
		mGotoxy 70, 1				;�N��в���(��70�� ��1�C)
		mWrite "���a��q:"
		cmp eax, 0	
		je draw_remaining_health	;�p�G�S�����h��q�A�N�����e�Ѿl��q
		mov ecx, eax				;�]�w�j�馸��

		;�e�X�l������q
		draw_lost_health:
			L1:
				mWrite "��"
			loop L1

		;�e�X�Ѿl��q
		draw_remaining_health:
			call SetHealthColor
			mov ecx, ebx	;�]�w�j�馸��

			L2:
				mWrite "��"
			loop L2
				
			call SetDefaultTextColor

		end_draw:
			call Crlf			
			call Crlf
			pop ecx				;���X�쥻ecx����
			ret
	DrawPlayer ENDP

main ENDP
END main