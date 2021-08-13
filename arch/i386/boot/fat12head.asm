org  07c00h
BaseOfStack		equ	07c00h	; The base address of the stack in the Boot state (bottom of the stack, from which it grows to a lower address)
BaseOfLoader		equ	09000h	; Segment address
OffsetOfLoader		equ	0100h	; Offset address
RootDirSectors		equ	14
SectorNoOfRootDirectory	equ	19
SectorNoOfFAT1		equ	1
DeltaSectorNo		equ	17
					

	jmp short LABEL_START		; Start to boot.
	nop

	; the head of fat12
	BS_OEMName	DB 'MCM-i386'
	BPB_BytsPerSec	DW 512
	BPB_SecPerClus	DB 1
	BPB_RsvdSecCnt	DW 1
	BPB_NumFATs	DB 2
	BPB_RootEntCnt	DW 224
	BPB_TotSec16	DW 2880	
	BPB_Media	DB 0xF0
	BPB_FATSz16	DW 9
	BPB_SecPerTrk	DW 18
	BPB_NumHeads	DW 2
	BPB_HiddSec	DD 0
	BPB_TotSec32	DD 0
	BS_DrvNum	DB 0
	BS_Reserved1	DB 0
	BS_BootSig	DB 29h
	BS_VolID	DD 0
	BS_VolLab	DB 'Minicosmos '
	BS_FileSysType	DB 'FAT12   '

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

; clear screen
	mov	ax, 0600h
	mov	bx, 0700h
	mov	cx, 0			; (0, 0)
	mov	dx, 0184fh		; (80, 50)
	int	10h

; Reset floppy device
	xor	ah, ah
	xor	dl, dl
	int	13h
	
; find RUN.BIN
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
; Determine if the root directory area is finished.
; If had read it, no run.bin will be found.
	cmp	word [wRootDirSizeForLoop], 0
	jz	LABEL_NO_LOADERBIN 
	dec	word [wRootDirSizeForLoop]	
	mov	ax, BaseOfLoader
	mov	es, ax			; es <- BaseOfLoader
	mov	bx, OffsetOfLoader	; bx <- OffsetOfLoader	于是, es:bx = BaseOfLoader:OffsetOfLoader
	mov	ax, [wSectorNo]	; ax <- Root Directory 中的某 Sector 号
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName	; ds:si -> "LOADER  BIN"
	mov	di, OffsetOfLoader	; es:di -> BaseOfLoader:0100 = BaseOfLoader*10h+100
	cld
	mov	dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
	dec	dx
	mov	cx, 11
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND
dec	cx
	lodsb				; ds:si -> al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT

LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME

LABEL_DIFFERENT:
	and	di, 0FFE0h
	add	di, 20h
	mov	si, LoaderFileName
	jmp	LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 0			; "run.bin not found."
	call	DispStr
	jmp	$

LABEL_FILENAME_FOUND:			; continue
	mov	ax, RootDirSectors
	and	di, 0FFE0h		; di -> The start of the current entry
	add	di, 01Ah		; di -> the first Sector
	mov	cx, word [es:di]
	push	cx			; Save the number of the Sector in the FAT
	add	cx, ax
	add	cx, DeltaSectorNo
	mov	ax, BaseOfLoader
	mov	es, ax
	mov	bx, OffsetOfLoader
	mov	ax, cx

LABEL_GOON_LOADING_FILE:
	mov	cl, 1
	call	ReadSector
	pop	ax
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:
	jmp	BaseOfLoader:OffsetOfLoader



wRootDirSizeForLoop	dw	RootDirSectors
wSectorNo		dw	0		; The sector number to read
bOdd			db	0		; Odd or even


; String
LoaderFileName		db	"RUN     BIN", 0
MessageLength		equ	18
BootMessage:		db	"run.bin not found."


; function: DispStr
; Displays a string. The dh function should start with the string ordinal (0-based).
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax		
	mov	ax, ds		
	mov	es, ax			
	mov	cx, MessageLength
	mov	ax, 01301h	
	mov	bx, 0007h	
	mov	dl, 0
	int	10h		
	ret


; function: ReadSector
; Read cl Sector into es:bx, starting with the ax Sector

ReadSector:
	push	bp
	mov	bp, sp
	sub	esp, 2			; A stack area of two bytes is allocated to hold the number of sectors to be read: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx
	mov	bl, [BPB_SecPerTrk]
	div	bl
	inc	ah
	mov	cl, ah		
	mov	dh, al		
	shr	al, 1		
	mov	ch, al			
	and	dh, 1		
	pop	bx			
	; At this point, "cylinder number, start sector, head number" are all obtained
	mov	dl, [BS_DrvNum]		; device number
.GoOnReading:
	mov	ah, 2			; read
	mov	al, byte [bp-2]
	int	13h
	jc	.GoOnReading

	add	esp, 2
	pop	bp

	ret

; function: GetFATEntry
; Find the FAT entry for a Sector ax, and place the result in AX
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfLoader
	sub	ax, 0100h
	mov	es, ax
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx		
	mov	bx, 2
	div	bx		
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:
	xor	dx, dx			
	mov	bx, [BPB_BytsPerSec]
	div	bx ; dx:ax / BPB_BytsPerSec
	push	dx
	mov	bx, 0 ; bx <- 0 于是, es:bx = (BaseOfLoader - 100):00
	add	ax, SectorNoOfFAT1
	mov	cl, 2
	call	ReadSector 

	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret

times 	510-($-$$)	db	0
dw 	0xaa55
