INCLUDE irvine32.inc
INCLUDE macros.inc
INCLUDELIB winmm.lib

;宣告副程式原型
PlaySound PROTO, pszSound:PTR BYTE, hmod:DWORD, fdwSound:DWORD

;定義常數
BUFFER_SIZE = 1000	;buffer的大小

.data
;讀檔用變數
EASY_FILE_NAME BYTE "easy.txt", 0				;簡單難度的檔名
NORMAL_FILE_NAME BYTE "normal.txt", 0			;普通難度的檔名
HARD_FILE_NAME BYTE "hard.txt", 0				;困難難度的檔名
fileName BYTE 100 DUP(0)						;檔名
fileHandle Handle ?								;讀取/寫入檔案用
buffer BYTE 100 DUP(0)							;儲存檔案內容
temp BYTE ?										;儲存讀出的字元					
MENU_BGM_FILE_NAME BYTE "menu_bgm.wav", 0		;選單背景音樂的檔名
GAME_BGM_FILE_NAME BYTE "game_bgm.wav", 0		;遊玩過程背景音樂的檔名
END_BGM_FILE_NAME BYTE "end_bgm.wav", 0			;結算背景音樂的檔名

;遊戲用變數
input BYTE BUFFER_SIZE DUP(0)					;使用者輸入		
SECOND_FACTOR WORD 1000							;用來將毫秒換成秒
PENALTY_TIME WORD 10							;答錯懲罰時間
startTime DWORD ?								;開始時間
lastTime DWORD ?								;上次答題時間
counter DWORD 0									;記錄通過的關卡數
health DWORD 5h									;玩家血量
lostHealth DWORD 0								;失去的血量
wordLength	DWORD 0								;單字長度
again BYTE 2 DUP(0)								;檢查是否要重新開始
errorCounter WORD 0								;記錄答錯次數
totalTime DWORD 0								;記錄通關總時間
difficulty BYTE ?								;記錄這次選的難度
easyBestTime DWORD 9999							;簡單難度的最佳通關時間
normalBestTime DWORD 9999						;普通難度的最佳通關時間
hardBestTime DWORD 9999							;困難難度的最佳通關時間

.code
main PROC
	;選單
	menu:
		;清畫面
		call Clrscr

		;播放選單背景音樂
		INVOKE PlaySound, NULL, NULL, 20001H						;暫停上一首音樂
		INVOKE PlaySound, OFFSET MENU_BGM_FILE_NAME, NULL, 20009H	;播放音樂

		;畫出選單
		call DrawMenu

		;輸入選項
		call ReadInt

		;檢查是否在正確範圍內，不符合就重新輸入
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
		
		;複製檔名用
		mov esi, 0
		mov edi, 0

		;根據選擇的難度選擇要開的檔案
		get_file1:
			;紀錄難度
			mov difficulty, 1

			;複製檔名給fileName
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
			call ReadInt				;讀取輸入
			cmp eax, 1
			je menu						;輸入為1就跳回menu
			jmp show_rules				;輸入其他的就跳回show_rules

	;開啟檔案(題目)
	open_file:
		mov edx, OFFSET fileName
		call OpenInputFile
		mov fileHandle, eax				;將eax內的Handle傳給fileHandle

		;檢查開檔是否有出錯
		cmp eax, INVALID_HANDLE_VALUE	;檢查目前的Handle是否有效
		jne file_ok						;有效就跳到file_ok
		mWrite <"無法開啟檔案",0dh,0ah> ;錯誤訊息
		jmp quit						;無效就跳到quit

	;開檔成功
	file_ok:
		;通過檢查
		buf_size_ok:
			mov eax, fileHandle		;將目前的fileHandle存回eax
	
		;紀錄開始時間
		call GetMseconds
		mov startTime, eax
		mov lastTime, eax

		;播放遊玩過程背景音樂
		INVOKE PlaySound, NULL, NULL, 20001H						;暫停上一首音樂
		INVOKE PlaySound, OFFSET GAME_BGM_FILE_NAME, NULL, 20009H	;播放音樂 

		;遊戲開始
		game_start:
			cmp counter, 25
			je game_end				;如果通關完成就跳到game_end

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
				call SetDefaultTextColor
				mov edx, OFFSET buffer
				call WriteString

			;顯示上次答題時間
			show_last_time:
				push ebx			;暫存原本ebx的值
				mGotoxy 30, 1		;將游標移到(第30行 第一列)
				mWrite "上一題花了"
				call GetMseconds	;取得目前時間
				mov ebx, eax		;暫存目前時間
				sub eax, lastTime	;算出距離答題上次過了多久

				;轉換成秒(除以1000)
				mov edx, 0
				movzx ecx, SECOND_FACTOR
				div ecx
				call WriteDec

				;輸出單位
				mWrite "秒"

				mov lastTime, ebx	;更新上次答題時間
				pop ebx				;取出原本ebx的值

			;顯示目前題號
			show_counter:
	       		mov eax,counter	;傳參數
				call ShowCounter

			;畫出血量及人物
			draw_player:
				push ebx			;暫存原本ebx的值
				mov eax, lostHealth	;傳參數
				mov ebx, health		;傳參數
				call DrawPlayer
				pop ebx				;取出原本ebx的值

			;讀取輸入
			read_input:
				call SetTitleColor
				mWrite <"輸入區:",0dh,0ah>
				call SetDefaultTextColor
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
				jmp clear_buffer		;跳到clear_buffer

			;輸入錯誤
			wrong:
				call Crlf
				;mWrite <"輸入錯誤",0dh,0ah>
				call Crlf
				inc errorCounter		;錯誤次數加1
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

			;播放選單背景音樂
			INVOKE PlaySound, NULL, NULL, 20001H						;暫停上一首音樂
			INVOKE PlaySound, OFFSET END_BGM_FILE_NAME, NULL, 20009H	;播放音樂

			;顯示遊玩結果
			show_result:
				;根據難度選擇不同的輸出
				mWrite "遊玩難度:"
				cmp difficulty, 1
				je print_easy
				cmp difficulty, 2
				je print_normal
				cmp difficulty, 3
				je print_hard

				;簡單難度
				print_easy:
					mWrite <"簡單",0dh,0ah,0dh,0ah>
					mov ebx, easyBestTime	;將最佳時間存在ebx
					jmp show_finish_time	;跳到show_finish_time


				;中等難度
				print_normal:
					mWrite <"中等",0dh,0ah,0dh,0ah>
					mov ebx, normalBestTime
					jmp show_finish_time

				;困難難度
				print_hard:
					mWrite <"困難",0dh,0ah,0dh,0ah>
					mov ebx, hardBestTime

				;顯示完成時間
				show_finish_time:
					;取得開始到結束的時間
					mWrite "總共花費 "
					call GetMseconds

					;轉換成秒(除以1000)
					mov edx, 0
					sub eax, startTime
					movzx ecx, SECOND_FACTOR
					div ecx
					call WriteDec
					mov totalTime, eax				;儲存總時間的第一部分

					mWrite " + "

					;算出答錯懲罰時間
					mov ax, errorCounter
					mul PENALTY_TIME
					movzx eax, ax					
					call WriteDec

					;輸出單位
					mWrite <" 秒",0dh,0ah,0dh,0ah>

					add totalTime, eax				;加上總時間的第二部分(懲罰時間)
					mov ecx, totalTime				;將totalTime存到ecx(比較用)

				;根據難度選擇要比較的最佳通關時間
				cmp difficulty, 1
				je compare_easy_best_time
				cmp difficulty, 2
				je compare_normal_best_time
				cmp difficulty, 3
				je compare_hard_best_time

				;比較最佳時間
				compare_easy_best_time:
					cmp ecx, easyBestTime
					jae show_best_time
					mov easyBestTime, ecx			;如果所花時間比最佳時間還少，就更新最佳時間
					mov ebx, easyBestTime			;將最佳時間存在ebx
					jmp show_best_time				;跳到show_best_time

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

				;輸出最佳時間
				show_best_time:	
					mov eax, ebx				;將存在ebx內的最佳時間取出
					mWrite "最佳通關時間為 "
					call WriteDec

					;輸出單位
					mWrite	<" 秒",0dh,0ah,0dh,0ah>

					jmp restart		;跳到restart

		dead:
			;清畫面
			call Clrscr

			;播放選單背景音樂
			INVOKE PlaySound, NULL, NULL, 20001H						;暫停上一首音樂
			INVOKE PlaySound, OFFSET END_BGM_FILE_NAME, NULL, 20009H	;播放音樂

			mWrite <"失敗",0dh,0ah,0dh,0ah>


		;詢問是否要重新開始
		restart:
			mov eax, fileHandle				;取回fileHandle
			call CloseFile					;關檔(否則要重新時無法再開檔)
			jmp restart_input				;跳到restart_input

			;輸入Y和N以外的字元
			restart_input_fail:
				;清畫面
				call Clrscr
				mWrite <"輸入錯誤，請輸入Y(Yes)或者N(No)",0dh,0ah>
				
			;輸入是否要重新開始
			restart_input:
				mWrite <"重新開始(Y/N)?",0dh,0ah>	
				mov edx, OFFSET again
				mov ecx, SIZEOF again
				call ReadString				;輸入是否要重新開始
				cmp again[0], 'N'
				je quit
				cmp again[0], 'Y'
				jne restart_input_fail		;輸入錯誤就跳到restart_input_fail
			
			;初始化
			mov counter, 0
			mov errorCounter, 0
			mov health, 5h
			mov lostHealth, 0
			jmp menu						;跳回選單

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
		mWrite <"4:遊戲說明",0dh,0ah,0dh,0ah>
		mWrite <"5:退出遊戲",0dh,0ah,0dh,0ah>
		mWrite "請輸入選項:"
		ret
	DrawMenu ENDP

	;-------------------------------------------------------------
	; ShowRules PROC
	;
	; 顯示規則
	; Receives: 沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	ShowRules PROC
		;清畫面
		call Clrscr	
		mWrite <"1. 玩家有5格血，每答錯1題會扣1格",0dh,0ah,0dh,0ah>
		mWrite <"2. 每答錯一次，通關時間增加10秒",0dh,0ah,0dh,0ah>
		mWrite <"3. 在回答完25題前血量歸0的話，就算失敗",0dh,0ah,0dh,0ah>
		mWrite <"輸入1以返回選單",0dh,0ah>
		mWrite ">"
		ret
	ShowRules ENDP

	;-------------------------------------------------------------
	; SetTitleColor PROC
	;
	; 設定標題文字及背景顏色
	; Receives: 沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	SetTitleColor PROC
		push eax					;暫存原本eax的值
		mov eax, red+(lightCyan*16)
		call SetTextColor	
		pop eax						;取出原本eax的值
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
		push eax				;暫存原本eax的值
		mov eax, red+(black*16)
		call SetTextColor
		pop eax					;取出原本eax的值
		ret
	SetHealthColor ENDP

	;-------------------------------------------------------------
	; SetDefaultTextColor PROC
	;
	; 將文字顏色調回原本的白字黑底
	; Receives:	沒有
	; Returns: 不回傳
	;-------------------------------------------------------------

	SetDefaultTextColor PROC
		push eax					;暫存原本eax的值
		mov eax, white+(black*16)
		call SetTextColor
		pop eax						;取出原本eax的值
		ret
	SetDefaultTextColor ENDP

	;-------------------------------------------------------------
	; ShowCounter PROC
	;
	; 顯示目前題數
	; Receives: eax = 目前題數
	; Returns: 不回傳
	;-------------------------------------------------------------

	ShowCounter PROC
		mGotoxy 50,1		;將游標移到(第50行 第一列)
		mWrite "目前題數:"		
	    call WriteDec
		mWrite "/25"
		ret
	ShowCounter ENDP

	;-------------------------------------------------------------
	; DrawPlayer PROC
	;
	; 畫出玩家血量
	; Receives: eax = 損失的血量 , ebx = 剩餘的血量
	; Returns: 不回傳
	;-------------------------------------------------------------
		
	DrawPlayer PROC
		push ecx					;暫存原本ecx的值
		mGotoxy 70, 1				;將游標移到(第70行 第1列)
		mWrite "玩家血量:"
		cmp eax, 0	
		je draw_remaining_health	;如果沒有失去血量，就直接畫剩餘血量
		mov ecx, eax				;設定迴圈次數

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
				
			call SetDefaultTextColor

		end_draw:
			call Crlf			
			call Crlf
			pop ecx				;取出原本ecx的值
			ret
	DrawPlayer ENDP

main ENDP
END main