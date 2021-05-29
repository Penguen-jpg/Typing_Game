INCLUDE irvine32.inc
INCLUDE macros.inc

;�U���ؼ�
;�վ��Ц�m(https://stackoverflow.com/questions/40940029/assembly-8086-cursor-placement)


;�w�q�`��
BUFFER_SIZE = 1000 ;buffer���j�p

.data
;Ū�ɥ��ܼ�
EASY_FILE_NAME BYTE "data1.txt", 0		;²�����ת��ɦW
MEDIUM_FILE_NAME BYTE "data2.txt", 0	;�������ת��ɦW
HARD_FILE_NAME BYTE "data3.txt", 0		;�x�����ת��ɦW
fileName BYTE 100 DUP(0)				;�ɦW
fileHandle Handle ?						;Ū���ɮץ�
buffer BYTE 100 DUP(0)					;�x�s�ɮפ��e
temp BYTE 0								;�x�sŪ�X���r��

;�C�����ܼ�
input BYTE BUFFER_SIZE DUP(0)			;�ϥΪ̿�J		
SECOND_FACTOR WORD 1000					;�ΨӴ�����
startTime DWORD ?						;�}�l�ɶ�
counter DWORD 0							;�O���q�L�����d��
health DWORD 5h							;���a��q
lostHealth DWORD 0						;���h����q
wordLength	DWORD 0						;��r����

.code
main PROC
	;�������
	choose_difficulty:
		;�M�e��
		call Clrscr

		;�e�X���
		call DrawMenu

		;��J�ﶵ
		call ReadInt

		;�ˬd�O�_�b���T�d�򤺡A���ŦX�N���s��J
		cmp eax, 1
		jb choose_difficulty
		cmp eax, 3
		ja choose_difficulty

		cmp eax, 1
		je open_file1
		cmp eax, 2
		je open_file2
		cmp eax, 3
		je open_file3
		
		;�ƻs�ɦW��
		mov esi, 0
		mov edi, 0

		;�ھڿ�ܪ����׿�ܭn�}���ɮ�
		open_file1:
			;�ƻs�ɦW��fileName
			INVOKE Str_copy,
				   ADDR EASY_FILE_NAME,
				   ADDR fileName
			jmp read_file
		open_file2:
			INVOKE Str_copy,
				   ADDR MEDIUM_FILE_NAME,
				   ADDR fileName
			jmp read_file
		open_file3:
			INVOKE Str_copy,
				   ADDR HARD_FILE_NAME,
				   ADDR fileName
			jmp read_file

	;Ū���ɮ�(�D��)
	read_file:
		mov edx, OFFSET fileName
		call OpenInputFile
		mov fileHandle, eax				;�Neax����Handle�ǵ�fileHandle

		;�ˬd�}�ɬO�_���X��
		cmp eax, INVALID_HANDLE_VALUE	;�ˬd�ثe��Handle�O�_����
		jne file_ok						;���ĴN����file_ok
		mWrite <"�L�k�}���ɮ�",0dh,0ah> ;���~�T��
		jmp quit						;�L�ĴN����quit

	;Ū�ɦ��\
	file_ok:
		;�q�L�ˬd
		buf_size_ok:
			mov eax, fileHandle		;�N�ثe��fileHandle�s�^eax
	
		;�����}�l�ɶ�
		call GetMseconds
		mov startTime, eax

		;�C���}�l
		game_start:
			cmp counter, 10
			jae game_end				;�p�G�q�������N����game_end

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
				call SetNormalTextColor
				mov edx, OFFSET buffer
				call WriteString

			;�e�X��q�ΤH��
			draw_player:
				push eax			;�Ȧs�쥻eax����
				push ebx			;�Ȧs�쥻ebx����
				mov eax, lostHealth	;�ǰѼ�
				mov ebx, health		;�ǰѼ�
				call DrawPlayer
				pop ebx				;���X�쥻ebx����
				pop eax				;���X�쥻eax����
				cmp health, 0		;�p�G��q��0�A����game_end
				je game_end

			;Ū����J
			read_input:
				call SetTitleColor
				mWrite <"��J��:",0dh,0ah>
				call SetNormalTextColor
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
				jmp clear_buffer	;����clear_buffer

			;��J���~
			wrong:
				call Crlf
				;mWrite <"��J���~",0dh,0ah>
				call Crlf
				;inc lostHealth
				;dec health
				cmp health, 0	
				je draw_player	;�p�G��q��0�A�N����draw_player�e�X�̫�@����q

			;�M��buffer�A�קK�P�U���x�s����r�Ĭ�
			clear_buffer:
				mov ecx, wordLength		;�]�w�j�馸��
				mov edi, 0
				L1:
					mov buffer[edi], 0
					inc edi
				loop L1
				jmp game_start
				
		;�C������
		game_end:
			;���o�}�l�쵲�����ɶ�
			mWrite "�`�@��O"
			call GetMseconds

			;�ഫ����(���H1000)
			mov edx, 0
			sub eax, startTime
			movzx ecx, SECOND_FACTOR
			div ecx
			call WriteDec

			;��X���
			mWrite <"��",0dh,0ah>

	;Ū�ɥ��ѩε{�����浲��
	quit:
		mov eax, fileHandle	;���^fileHandle
		call CloseFile		;����
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
		mWrite "�п�J�ﶵ:"
		ret
	DrawMenu ENDP

	;-------------------------------------------------------------
	; SetTitleColor PROC
	;
	; �]�w���D��r�έI���C��
	; Receives: �S��
	; Returns: ���^��
	;-------------------------------------------------------------

	SetTitleColor PROC
		push eax			;�Ȧs�쥻eax����
		mov eax, red+(lightCyan*16)
		call SetTextColor	
		pop eax		;���X�쥻eax����
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
		push eax			;�Ȧs�쥻eax����
		mov eax, red+(black*16)
		call SetTextColor
		pop eax				;���X�쥻eax����
		ret
	SetHealthColor ENDP

	;-------------------------------------------------------------
	; SetNormalTextColor PROC
	;
	; �N��r�C��զ^�쥻���զr�©�
	; Receives:	�S��
	; Returns: ���^��
	;-------------------------------------------------------------
	SetNormalTextColor PROC
		push eax			;�Ȧs�쥻eax����
		mov eax, white+(black*16)
		call SetTextColor
		pop eax				;���X�쥻eax����
		ret
	SetNormalTextColor ENDP

	;-------------------------------------------------------------
	; DrawPlayer PROC
	;
	; �e�X���a��q
	; Receives: eax = �l������q , ebx = �Ѿl����q
	; Returns: ���^��
	;-------------------------------------------------------------
		
	DrawPlayer PROC
		push ecx			;�Ȧs�쥻ecx����
		mGotoxy 70, 1		;�N��в���(��70�� ��1�C)
		mWrite "���a��q:"
		cmp eax, 0	
		je draw_remaining_health ;�p�G�S�����h��q�A�N�����e�Ѿl��q
		mov ecx, eax		;�]�w�j�馸��

		;�e�X�l������q
		draw_lost_health:
			L1:
				mWrite "��"
			loop L1

		cmp ebx, 0			;�p�G�Ѿl��q��0�A�N����end_draw
		je end_draw

		;�e�X�Ѿl��q
		draw_remaining_health:
			call SetHealthColor
			mov ecx, ebx	;�]�w�j�馸��

			L2:
				mWrite "��"
			loop L2
				
			call SetNormalTextColor

		end_draw:
			call Crlf			
			call Crlf
			pop ecx				;���X�쥻ecx����
			ret
	DrawPlayer ENDP

main ENDP
END main