INCLUDE Irvine32.inc
INCLUDE macros.inc
BUFFER_SIZE = 5000

.data
searchmode DWORD ?
linestart DWORD 0
lineend DWORD 99
searchword byte "ali",0
wordsize DWORD ?
buffer BYTE BUFFER_SIZE DUP(?)
filename BYTE 80 DUP(0)
fileHandle HANDLE ?
accepted DWORD 0
filesize DWORD ?
fileend DWORD 0
alregtmp BYTE ?
linenumber SDWORD 1
.code
wholewordcase PROTO
matchcase PROTO
getword PROTO
getdata PROTO

main PROC

INVOKE getword
INVOKE getdata
call crlf
mWrite "Choose Search Mode: "
call crlf
mWrite "1 : Match Case"
call crlf
mWrite "2 : Match Whole Word"
call crlf
call readint 
mov searchmode,eax
call crlf
.IF searchmode==1
	INVOKE matchcase
.ELSE
	INVOKE wholewordcase
.ENDIF
exit
main ENDP

getword PROC USES ecx edx eax
	mWrite "Enter word : "
	mov edx,OFFSET searchword
	mov ecx,SIZEOF searchword
	call ReadString
	mov edx, OFFSET searchword
	mov eax,-1
	L:
		inc eax
		loop L
	mov wordsize,eax
	ret 
getword ENDP 

getdata PROC USES ecx edi edx eax
	
	; Let user input a filename.
	mWrite "Enter an input filename: "
	mov edx,OFFSET filename
	mov ecx,SIZEOF filename
	call ReadString 


	; Open the file for input.
	mov edx,OFFSET filename
	call OpenInputFile
	mov fileHandle,eax

	;Check for errors.
	cmp eax,INVALID_HANDLE_VALUE ; error opening file?
	jne file_ok ; no: skip
	mWrite <"Cannot open file",0dh,0ah>
	jmp quit ; and quit 

	file_ok:
	; Read the file into a buffer.
		mov edx,OFFSET buffer
		mov ecx,BUFFER_SIZE
		call ReadFromFile
		jnc check_buffer_size ; error reading?
		mWrite "Error reading file. " ; yes: show error message
		call WriteWindowsMsg
		jmp close_file

	check_buffer_size:
		cmp eax,BUFFER_SIZE ; buffer large enough?
		jb buf_size_ok ; yes
		mWrite <"Error: Buffer too small for the file",0dh,0ah>
		jmp quit ; and quit

	buf_size_ok:
		mov buffer[eax],0 ; insert null terminator
		mov filesize,eax
		mWrite "File size: "
		call WriteDec ; display file size
		call Crlf


	;Display the buffer.
		mWrite <"Buffer:",0dh,0ah,0dh,0ah>
		mov edx,OFFSET buffer ; display the buffer
		call WriteString
		call Crlf

	close_file:
		mov eax,fileHandle
		call CloseFile

	quit:
		ret
getdata ENDP

matchcase PROC USES edi esi edx ecx ebx eax
	mov esi,offset searchword
	mov edi,offset buffer	 
	mov ecx,lengthof searchword-1
	mov ebx,filesize

	.WHILE fileend!=ebx
		mov accepted,0
		mov al,[esi]
		mov dl,[edi]
		.IF al==dl
			inc accepted
			push ecx
			mov ecx,1
			.WHILE ecx<wordsize
				inc fileend
				inc edi
				inc esi
				mov al,[esi]
				mov dl,[edi]
				.IF al==dl
					inc accepted
				.ENDIF
				inc ecx
			.ENDW
			pop ecx
			mov eax,wordsize
				.IF accepted!=eax
					mov esi,offset searchword
					dec edi
					sub edi,accepted
					push eax
						mov eax,accepted
						sub fileend,eax
					pop eax
				.ELSE
					push ebx 
					push esi
						mov esi,offset buffer
						mov ebx,linestart
						add esi,ebx
						mWrite "Found at line number : "
						push eax
						mov eax,linenumber
						call writeint
						pop eax 
						call crlf
						.WHILE ebx<=lineend 
							mov al,[esi]
							call writechar
							inc ebx
							inc esi
						.ENDW
					pop esi
					pop ebx
					call crlf	
				.ENDIF
			.ELSE
				inc edi
				inc fileend
				push ebx
					mov ebx,lineend
					.IF fileend>ebx
						add linestart,100
						add lineend,100
					.ENDIF
				pop ebx
		.ENDIF
		
		mov esi,offset searchword
	.ENDW 
	ret
matchcase ENDP

wholewordcase PROC USES edi esi edx ecx ebx eax
	mov esi,offset searchword
	mov edi,offset buffer	 
	mov ecx,lengthof searchword-1
	mov ebx,filesize

	.WHILE fileend!=ebx
		mov accepted,0
		mov al,[esi]
		mov dl,[edi]
		mov alregtmp,al
		.IF al>=41h && al<=5Ah
			add al,32
			mov bl,al
		.ELSEIF al>=61h && al<=7Ah
			sub al,32
			mov bl,al
		.ENDIF 
		mov al,alregtmp
		.IF al==dl ||bl==dl
			inc accepted
			push ecx
			mov ecx,1
			.WHILE ecx<wordsize
				inc fileend
				inc edi
				inc esi
				mov al,[esi]
				mov dl,[edi]
				mov alregtmp,al
				.IF al>=41h && al<=5Ah
					add al,32
					mov bl,al
				.ELSEIF al>=61h && al<=7Ah
					sub al,32
					mov bl,al
				.ENDIF 
				mov al,alregtmp
				.IF al==dl
					inc accepted
				.ENDIF
				inc ecx
			.ENDW
			pop ecx
			mov eax,wordsize
				.IF accepted!=eax
					mov esi,offset searchword
					dec edi
					sub edi,accepted
					push eax
						mov eax,accepted
						sub fileend,eax
					pop eax
				.ELSE
					push ebx 
					push esi
						mov esi,offset buffer
						mov ebx,linestart
						add esi,ebx
						mWrite "Found at line number : "
						push eax
						mov eax,linenumber
						call writeint
						pop eax 
						call crlf
						.WHILE ebx<=lineend 
							mov al,[esi]
							call writechar
							inc ebx
							inc esi
						.ENDW
					pop esi
					pop ebx
					call crlf	
				.ENDIF
			.ELSE
				inc edi
				inc fileend
				push ebx
					mov ebx,lineend
					.IF fileend>=ebx
						add linestart,100
						add lineend,100
					.ENDIF
				pop ebx
		.ENDIF
		
		mov esi,offset searchword
	.ENDW 
	ret
wholewordcase ENDP
END main
