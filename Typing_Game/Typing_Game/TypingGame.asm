INCLUDE irvine32.inc
INCLUDE macros.inc

;下次目標
;調整游標位置(https://stackoverflow.com/questions/40940029/assembly-8086-cursor-placement)


;定義常數
BUFFER_SIZE = 1000 ;buffer的大小

.data
;讀檔用變數
EASY_FILE_NAME BYTE "easy.txt", 0		;簡單難度的檔名
NORMAL_FILE_NAME BYTE "normal.txt", 0	;普通難度的檔名
HARD_FILE_NAME BYTE "hard.txt", 0		;困難難度的檔名
fileName BYTE 100 DUP(0)				;檔名
fileHandle Handle ?						;讀取檔案用
buffer BYTE 100 DUP(0)					;儲存檔案內容
temp BYTE 0								;儲存讀出的字元					

;遊戲用變數
input BYTE BUFFER_SIZE DUP(0)			;使用者輸入		
SECOND_FACTOR WORD 1000					;用來換成秒
startTime DWORD ?						;開始時間
counter DWORD 0							;記錄通過的關卡數
health DWORD 5h							;玩家血量
lostHealth DWORD 0						;失去的血量
wordLength	DWORD 0						;單字長度
again BYTE 2 DUP(0)						;檢查是否要重新開始

.code
main PROC
	;選單
	menu:
		;清畫面
		call Clrscr

		;畫出選單
		call DrawMenu

		;輸入選項
		call ReadInt

		;檢查是否在正確範圍內，不符合就重新輸入
		cmp eax, 1
		jb menu
		cmp eax, 3
		ja menu

		cmp eax, 1
		je open_file1
		cmp eax, 2
		je open_file2
		cmp eax, 3
		je open_file3
		
		;複製檔名用
		mov esi, 0
		mov edi, 0

		;根據選擇的難度選擇要開的檔案
		open_file1:
			;複製檔名給fileName
			INVOKE Str_copy,
				   ADDR EASY_FILE_NAME,
				   ADDR fileName
			jmp read_file
		open_file2:
			INVOKE Str_copy,
				   ADDR NORMAL_FILE_NAME,
				   ADDR fileName
			jmp read_file
		open_file3:
			INVOKE Str_copy,
				   ADDR HARD_FILE_NAME,
				   ADDR fileName
			jmp read_file

	;讀取檔案(題目)
	read_file:
		mov edx, OFFSET fileName
		call OpenInputFile
		mov fileHandle, eax				;將eax內的Handle傳給fileHandle

		;檢查開檔是否有出錯
		cmp eax, INVALID_HANDLE_VALUE	;檢查目前的Handle是否有效
		jne file_ok						;有效就跳到file_ok
		mWrite <"無法開啟檔案",0dh,0ah> ;錯誤訊息
		jmp quit						;無效就跳到quit

	;讀檔成功
	file_ok:
		;通過檢查
		buf_size_ok:
			mov eax, fileHandle		;將目前的fileHandle存回eax
	
		;紀錄開始時間
		call GetMseconds
		mov startTime, eax

		;遊戲開始
		game_start:
			cmp counter, 25
			jae game_end				;如果通關完成就跳到game_end

			;初始化esi及取回fileHandle
			init:
				mov esi, 0				;將index歸0
				mov eax, fileHandle		;取回fileHandle

			;一次讀一個字元，直到讀到空格(讀完結果為一個單字)
			read_word:
				mov edx, OFFSET temp	;存到buffer內
				mov ecx, 1				;設定大小
				call ReadFromFile		;讀取內容
				cmp temp, ' '			
				je finish_reading		;讀到空格就代表讀完了
				mov bl, temp			;將讀到的字元存到bl
 				mov buffer[esi], bl		;將bl的值傳給buffer[esi]
				;call Dumpregs			;debug用
				inc esi					;index加1
				mov eax, fileHandle		;取回fileHandle(因為做完ReadFromFile後，eax的值會變)
				jmp read_word			

			;讀取結束
			finish_reading:
				mov wordLength, esi		;儲存單字長度
				inc counter
				;mov eax, counter		;debug用
				;call WriteDec

			;清畫面
			call Clrscr

			;顯示題目
			display_problem:
				call SetTitleColor
				mWrite <"<題目>",0dh,0ah>
				call SetNormalTextColor
				mov edx, OFFSET buffer
				call WriteString

			;畫出血量及人物
			draw_player:
				push eax			;暫存原本eax的值
				push ebx			;暫存原本ebx的值
				mov eax, lostHealth	;傳參數
				mov ebx, health		;傳參數
				call DrawPlayer
				pop ebx				;取出原本ebx的值
				pop eax				;取出原本eax的值

			;讀取輸入
			read_input:
				call SetTitleColor
				mWrite <"輸入區:",0dh,0ah>
				call SetNormalTextColor
				mov edx, OFFSET input
				mov ecx, BUFFER_SIZE
				mov esi, 0
				call ReadString

			;比較字串
			compare_string:
				INVOKE Str_compare, ADDR buffer, ADDR input
				je equal
				ja wrong
				jb wrong

			;輸入正確
			equal:
				call Crlf
				;mWrite <"輸入正確",0dh,0ah>
				call Crlf
				jmp clear_buffer	;跳到clear_buffer

			;輸入錯誤
			wrong:
				call Crlf
				;mWrite <"輸入錯誤",0dh,0ah>
				call Crlf
				inc lostHealth
				dec health

			;清空buffer，避免與下次儲存的單字衝突
			clear_buffer:
				mov ecx, wordLength		;設定迴圈次數
				mov edi, 0
				L1:
					mov buffer[edi], 0
					inc edi
				loop L1
				cmp health, 0	
				je dead					;如果血量為0就跳到dead
				jmp game_start
				
		;遊戲結束(還有剩餘血量)
		game_end:	
			;清畫面
			call Clrscr

			;取得開始到結束的時間
			mWrite "總共花費"
			call GetMseconds

			;轉換成秒(除以1000)
			mov edx, 0
			sub eax, startTime
			movzx ecx, SECOND_FACTOR
			div ecx
			call WriteDec

			;輸出單位
			mWrite <"秒",0dh,0ah,0dh,0ah>

			jmp restart		;跳到restart

		dead:
			;清畫面
			call Clrscr

			mWrite <"失敗",0dh,0ah,0dh,0ah>


		;詢問是否要重新開始
		restart:
			mWrite <"重新開始(Y/N)?",0dh,0ah>	
			mov edx, OFFSET again
			mov ecx, SIZEOF again
			call ReadString				;輸入是否要重新開始
			mov eax, fileHandle			;取回fileHandle
			call CloseFile				;關檔(否則要重新時無法再開檔)
			cmp again[0], 'Y'
			jne quit
			
			;初始化
			mov counter, 0
			mov health, 5h
			mov lostHealth, 0
			jmp menu				;跳回選單

	;讀檔失敗或程式執行結束
	quit:
		exit				;結束程式

	;procedures
	;-------------------------------------------------------------
	; DrawMenu PROC
	;
	; 畫出選單
	; Receives: 沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	DrawMenu PROC
		mWrite <"Typing Game",0dh,0ah,0dh,0ah>
		mWrite <"1:簡單",0dh,0ah,0dh,0ah>
		mWrite <"2:中等",0dh,0ah,0dh,0ah>
		mWrite <"3:困難",0dh,0ah,0dh,0ah>
		mWrite "請輸入選項:"
		ret
	DrawMenu ENDP

	;-------------------------------------------------------------
	; SetTitleColor PROC
	;
	; 設定標題文字及背景顏色
	; Receives: 沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	SetTitleColor PROC
		push eax			;暫存原本eax的值
		mov eax, red+(lightCyan*16)
		call SetTextColor	
		pop eax		;取出原本eax的值
		ret
	SetTitleColor ENDP

	;-------------------------------------------------------------
	; SetHealthColor PROC
	;
	; 設定血量文字及背景顏色
	; Receives: 沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	SetHealthColor PROC
		push eax			;暫存原本eax的值
		mov eax, red+(black*16)
		call SetTextColor
		pop eax				;取出原本eax的值
		ret
	SetHealthColor ENDP

	;-------------------------------------------------------------
	; SetNormalTextColor PROC
	;
	; 將文字顏色調回原本的白字黑底
	; Receives:	沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	SetNormalTextColor PROC
		push eax			;暫存原本eax的值
		mov eax, white+(black*16)
		call SetTextColor
		pop eax				;取出原本eax的值
		ret
	SetNormalTextColor ENDP

	;-------------------------------------------------------------
	; DrawPlayer PROC
	;
	; 畫出玩家血量
	; Receives: eax = 損失的血量 , ebx = 剩餘的血量
	; Returns: 不回傳
	;-------------------------------------------------------------
		
	DrawPlayer PROC
		push ecx			;暫存原本ecx的值
		mGotoxy 70, 1		;將游標移到(第70行 第1列)
		mWrite "玩家血量:"
		cmp eax, 0	
		je draw_remaining_health ;如果沒有失去血量，就直接畫剩餘血量
		mov ecx, eax		;設定迴圈次數

		;畫出損失的血量
		draw_lost_health:
			L1:
				mWrite "□"
			loop L1

		;畫出剩餘血量
		draw_remaining_health:
			call SetHealthColor
			mov ecx, ebx	;設定迴圈次數

			L2:
				mWrite "■"
			loop L2
				
			call SetNormalTextColor

		end_draw:
			call Crlf			
			call Crlf
			pop ecx				;取出原本ecx的值
			ret
	DrawPlayer ENDP

main ENDP
END main