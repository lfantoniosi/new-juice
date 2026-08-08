;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.6.0 #16555 (Mac OS X ppc)
;--------------------------------------------------------
	.module smram
	
	.optsdcc -mz80 sdcccall(1)
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _print_mapper_type
	.globl _runROM_Reset_end
	.globl _runROM_Reset
	.globl _runROM_page3_end
	.globl _runROM_page3
	.globl _runROM_page2_end
	.globl _runROM_page2
	.globl _runROM_page0_end
	.globl _runROM_page0
	.globl _runROM_page1_end
	.globl _runROM_page1
	.globl _jump
	.globl _hexToNum
	.globl _dos2_getenv
	.globl _dos2_read
	.globl _dos2_close
	.globl _dos2_open
	.globl _chgcpu
	.globl _rdslt
	.globl _enaslt
	.globl _to_upper
	.globl _fputs
	.globl _bdos_c_rawio
	.globl _bdos_c_write
	.globl _bdos
	.globl _printf
	.globl _opll_vol
	.globl _psg_vol
	.globl _scc_vol
	.globl _help
	.globl _loadpage
	.globl _startpage
	.globl _cpumode
	.globl _breakpointAddressSpecified
	.globl _stepDebug
	.globl _exitAfterLoad
	.globl _linearHeaderValid
	.globl _headerValid
	.globl _mapperSpecified
	.globl _softReset
	.globl _presAB
	.globl _paramlen
	.globl _megaram_type
	.globl _filename
	.globl _found
	.globl _c
	.globl _linearRomstart
	.globl _breakpointAddress
	.globl _romstart
	.globl _path
	.globl _slotid
	.globl _romsize
	.globl _page
	.globl _addr
	.globl _i
	.globl _bytes_read
	.globl _handle
	.globl _params
	.globl _t
	.globl _s
	.globl _b
	.globl _sslt
	.globl _cursslt
	.globl _curslt
	.globl _putchar
	.globl _getchar
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_MEGA_PORT0	=	0x008e
_MEGA_PORT1	=	0x008f
_PPIA	=	0x00a8
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_curslt::
	.ds 1
_cursslt::
	.ds 1
_sslt::
	.ds 1
_b::
	.ds 1
_s::
	.ds 2
_t::
	.ds 2
_params::
	.ds 2
_handle::
	.ds 1
_bytes_read::
	.ds 2
_i::
	.ds 2
_addr::
	.ds 2
_page::
	.ds 1
_romsize::
	.ds 4
_slotid::
	.ds 1
_path::
	.ds 256
_romstart::
	.ds 2
_breakpointAddress::
	.ds 2
_linearRomstart::
	.ds 2
_c::
	.ds 1
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
_found::
	.ds 1
_filename::
	.ds 2
_megaram_type::
	.ds 2
_paramlen::
	.ds 1
_presAB::
	.ds 1
_softReset::
	.ds 1
_mapperSpecified::
	.ds 1
_headerValid::
	.ds 1
_linearHeaderValid::
	.ds 1
_exitAfterLoad::
	.ds 1
_stepDebug::
	.ds 1
_breakpointAddressSpecified::
	.ds 1
_cpumode::
	.ds 1
_startpage::
	.ds 1
_loadpage::
	.ds 1
_help::
	.ds 1
_scc_vol::
	.ds 1
_psg_vol::
	.ds 1
_opll_vol::
	.ds 1
;--------------------------------------------------------
; absolute ram data
;--------------------------------------------------------
	.area _DABS (ABS)
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;smram.c:45: void bdos() __naked
;	---------------------------------
; Function bdos
; ---------------------------------
_bdos::
;smram.c:54: __endasm;
	push ix
	push iy
	call 5
	pop iy
	pop ix
	ret
;smram.c:55: }
;smram.c:57: void bdos_c_write(uchar c) __naked
;	---------------------------------
; Function bdos_c_write
; ---------------------------------
_bdos_c_write::
;smram.c:67: __endasm;
	ld e,a
	ld c,#2
	call _bdos
	ret
;smram.c:68: }
;smram.c:70: uchar bdos_c_rawio() __naked
;	---------------------------------
; Function bdos_c_rawio
; ---------------------------------
_bdos_c_rawio::
;smram.c:79: __endasm;
	ld e,#0xFF;
	ld c,#6
	call _bdos
	ret
;smram.c:80: }
;smram.c:82: int putchar(int c) 
;	---------------------------------
; Function putchar
; ---------------------------------
_putchar::
	ex	de, hl
;smram.c:84: if (c >= 0)
	bit	7, d
	ret	nz
;smram.c:85: bdos_c_write((char)c);
	ld	a, e
	push	de
	call	_bdos_c_write
	pop	de
;smram.c:86: return c;
;smram.c:87: }
	ret
;smram.c:89: int getchar()
;	---------------------------------
; Function getchar
; ---------------------------------
_getchar::
;smram.c:92: do {
00101$:
;smram.c:93: c = bdos_c_rawio();
	call	_bdos_c_rawio
	ld	e, a
;smram.c:94: } while(c == 0);
	or	a, a
	jr	z, 00101$
;smram.c:95: return (int)c;
	ld	d, #0x00
;smram.c:96: }
	ret
;smram.c:98: void fputs(const char *s)
;	---------------------------------
; Function fputs
; ---------------------------------
_fputs::
;smram.c:100: while(*s != NULL)
00101$:
	ld	a, (hl)
	or	a, a
	ret	z
;smram.c:101: putchar(*s++);
	inc	hl
	ld	c, #0x00
	push	hl
	ld	l, a
	ld	h, c
	call	_putchar
	pop	hl
;smram.c:102: }
	jr	00101$
;smram.c:104: char to_upper(char c)
;	---------------------------------
; Function to_upper
; ---------------------------------
_to_upper::
;smram.c:106: if (c >= 'a' && c <= 'z')
	cp	a, #0x61
	ret	c
	cp	a, #0x7b
	ret	nc
;smram.c:107: c = c - ('a'-'A');
	add	a, #0xe0
;smram.c:108: return c;
;smram.c:109: }
	ret
;smram.c:111: void enaslt(uchar slotid, uint addr) __naked
;	---------------------------------
; Function enaslt
; ---------------------------------
_enaslt::
;smram.c:133: __endasm;
	push af
	push bc
	push de
	push hl
	push ix
	push iy
	ex de,hl
	call #0x0024
	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ret
;smram.c:134: }
;smram.c:136: uchar rdslt(uchar slotid, uint addr) __naked
;	---------------------------------
; Function rdslt
; ---------------------------------
_rdslt::
;smram.c:151: __endasm;
	push bc
	push de
	ex de,hl
	call #0x000C
	ex de,hl
	pop de
	pop bc
	ret
;smram.c:152: }
;smram.c:154: void chgcpu(uchar mode) __naked
;	---------------------------------
; Function chgcpu
; ---------------------------------
_chgcpu::
;smram.c:184: __endasm;
	push bc
	push de
	push af
	ld a,(0xFCC1)
	ld hl,#0x0180
	call #0x000C
	cp #0xC3
	jr nz,__no_turbo
	ld a,b
	pop af
	ld iy,(0xFCC1 -1)
	ld ix,#0x0180
	call #0x001C
	push af
__no_turbo:
	pop af
	pop de
	pop bc
	ret
;smram.c:185: }
;smram.c:202: FHANDLE dos2_open(uchar mode, const char* filepath) __naked
;	---------------------------------
; Function dos2_open
; ---------------------------------
_dos2_open::
;smram.c:220: __endasm;
	push bc
	push de
	push hl
	ld c,#0x43
	call 5
	or a
	jr z,__open_no_err
	ld b,#0
__open_no_err:
	ld a,b
	pop hl
	pop de
	pop bc
	ret
;smram.c:221: }
;smram.c:223: void dos2_close(FHANDLE hnd) __naked
;	---------------------------------
; Function dos2_close
; ---------------------------------
_dos2_close::
;smram.c:233: __endasm;
	push bc
	ld a,b
	ld c,#0x45
	call 5
	pop bc
	ret
;smram.c:234: }
;smram.c:236: uint dos2_read(FHANDLE hnd, void *dst, uint size) __naked
;	---------------------------------
; Function dos2_read
; ---------------------------------
_dos2_read::
;smram.c:256: __endasm;	
	push ix
	ld ix,#0
	add ix,sp
	push bc
	ld b,a
	ld l, 4 (ix)
	ld h, 5 (ix)
	ld c,#0x48
	call 5
	pop bc
	pop ix
	ex de,hl
	ret
;smram.c:257: }
;smram.c:259: uchar dos2_getenv(char *var, char *buf) __naked
;	---------------------------------
; Function dos2_getenv
; ---------------------------------
_dos2_getenv::
;smram.c:267: __endasm;	
	ld b,#255
	ld c,#0x6B
	call 5
	ret
;smram.c:268: }
;smram.c:270: char hexToNum(char h)
;	---------------------------------
; Function hexToNum
; ---------------------------------
_hexToNum::
;smram.c:274: if (h >= '0' && h <='9')
	cp	a, #0x30
	jr	c, 00102$
	cp	a, #0x3a
	jr	nc, 00102$
;smram.c:275: return h-'0';    
	add	a, #0xd0
	ret
00102$:
;smram.c:276: return 0;
	xor	a, a
;smram.c:277: }
	ret
;smram.c:279: void jump(uint addr) __naked
;	---------------------------------
; Function jump
; ---------------------------------
_jump::
;smram.c:287: __endasm;
	ld sp,(0x0006)
	jp (hl)
;smram.c:288: }
;smram.c:290: void runROM_page1() __naked
;	---------------------------------
; Function runROM_page1
; ---------------------------------
_runROM_page1::
;smram.c:330: __endasm;
	ei
	halt
	di
	ld sp,#0xCFFF
	ld a,(_stepDebug)
	or a
	jr z,__page1_breakpoint_programmed
	ld a,#0xFE
	out (#0x8F),a
	ld a,(_breakpointAddress)
	out (#0x8F),a
	ld a,(_breakpointAddress+1)
	out (#0x8F),a
__page1_breakpoint_programmed:
	ld hl,#0xFD9A
	ld a,#0xC9
	ld (hl),a
	ld hl,#0xFD9F
	ld (hl),a
	ld a,(_sslt)
	ld h,a
	ld l,#0
	push hl
	pop iy
	ld ix,(_romstart)
	push iy
	push ix
	ld a,(0xFCC1)
	ld hl,#0
	call #0x0024
	pop ix
	pop iy
	call #0x001C
	call #0x001C
;smram.c:331: }
;smram.c:332: void runROM_page1_end() __naked {}
;	---------------------------------
; Function runROM_page1_end
; ---------------------------------
_runROM_page1_end::
;smram.c:334: void runROM_page0() __naked
;	---------------------------------
; Function runROM_page0
; ---------------------------------
_runROM_page0::
;smram.c:367: __endasm;
	ei
	halt
	di
	ld sp,#0xCFFF
	ld a,(_stepDebug)
	or a
	jr z,__page0_breakpoint_programmed
	ld a,#0xFE
	out (#0x8F),a
	ld a,(_breakpointAddress)
	out (#0x8F),a
	ld a,(_breakpointAddress+1)
	out (#0x8F),a
__page0_breakpoint_programmed:
	ld hl,#0xFD9A
	ld a,#0xC9
	ld (hl),a
	ld hl,#0xFD9F
	ld (hl),a
	ld a,(_sslt)
	ld h,a
	ld l,#0
	push hl
	pop iy
	ld ix,(_romstart)
	call #0x001C
	call #0x001C
;smram.c:368: }
;smram.c:369: void runROM_page0_end() __naked {}
;	---------------------------------
; Function runROM_page0_end
; ---------------------------------
_runROM_page0_end::
;smram.c:371: void runROM_page2() __naked
;	---------------------------------
; Function runROM_page2
; ---------------------------------
_runROM_page2::
;smram.c:411: __endasm;
	ei
	halt
	di
	ld sp,#0xCFFF
	ld a,(_stepDebug)
	or a
	jr z,__page2_breakpoint_programmed
	ld a,#0xFE
	out (#0x8F),a
	ld a,(_breakpointAddress)
	out (#0x8F),a
	ld a,(_breakpointAddress+1)
	out (#0x8F),a
__page2_breakpoint_programmed:
	ld hl,#0xFD9A
	ld a,#0xC9
	ld (hl),a
	ld hl,#0xFD9F
	ld (hl),a
	ld a,(_sslt)
	ld h,a
	ld l,#0
	push hl
	pop iy
	ld ix,(_romstart)
	push iy
	push ix
	ld a,(0xFCC1)
	ld hl,#0
	call #0x0024
	pop ix
	pop iy
	call #0x001C
	call #0x001C
;smram.c:412: }
;smram.c:413: void runROM_page2_end() __naked {}
;	---------------------------------
; Function runROM_page2_end
; ---------------------------------
_runROM_page2_end::
;smram.c:415: void runROM_page3() __naked
;	---------------------------------
; Function runROM_page3
; ---------------------------------
_runROM_page3::
;smram.c:451: __endasm;
	ei
	halt
	di
	ld sp,#0xBFFF
	ld a,(_stepDebug)
	or a
	jr z,__page3_breakpoint_programmed
	ld a,#0xFE
	out (#0x8F),a
	ld a,(_breakpointAddress)
	out (#0x8F),a
	ld a,(_breakpointAddress+1)
	out (#0x8F),a
__page3_breakpoint_programmed:
	ld a,(_sslt)
	ld h,a
	ld l,#0
	push hl
	pop iy
	ld ix,(_romstart)
	push iy
	push ix
	ld a,(0xFCC1)
	ld hl,#0
	call #0x0024
	pop ix
	pop iy
	call #0x001C
	call #0x001C
;smram.c:452: }
;smram.c:453: void runROM_page3_end() __naked {}
;	---------------------------------
; Function runROM_page3_end
; ---------------------------------
_runROM_page3_end::
;smram.c:455: void runROM_Reset() __naked
;	---------------------------------
; Function runROM_Reset
; ---------------------------------
_runROM_Reset::
;smram.c:482: __endasm;
	ei
	halt
	di
	ld sp,#0xCFFF
	ld a,(_stepDebug)
	or a
	jr z,__reset_breakpoint_programmed
	ld a,#0xFE
	out (#0x8F),a
	ld a,(_breakpointAddress)
	out (#0x8F),a
	ld a,(_breakpointAddress+1)
	out (#0x8F),a
__reset_breakpoint_programmed:
	ld hl,#0xFD9A
	ld a,#0xC9
	ld (hl),a
	ld hl,#0xFD9F
	ld (hl),a
	ld iy,(0xFCC1 -1)
	ld ix,#0
	call #0x001C
	call #0x001C
;smram.c:483: }
;smram.c:485: void runROM_Reset_end() __naked {}
;	---------------------------------
; Function runROM_Reset_end
; ---------------------------------
_runROM_Reset_end::
;smram.c:523: void print_mapper_type(void)
;	---------------------------------
; Function print_mapper_type
; ---------------------------------
_print_mapper_type::
;smram.c:525: printf("\r\nMapper Type: ");
	ld	hl, #___str_0
	push	hl
	call	_printf
	pop	af
;smram.c:526: switch(megaram_type)
	ld	a, (_megaram_type+1)
	ld	iy, #_megaram_type
	or	a, 0 (iy)
	jr	z, 00101$
	ld	a, (_megaram_type+0)
	dec	a
	or	a, 1 (iy)
	jr	z, 00107$
	ld	a, (_megaram_type+0)
	sub	a, #0x02
	or	a, 1 (iy)
	jr	z, 00102$
	ld	a, (_megaram_type+0)
	sub	a, #0x04
	or	a, 1 (iy)
	jr	z, 00103$
	ld	a, (_megaram_type+0)
	sub	a, #0x05
	or	a, 1 (iy)
	jr	z, 00104$
	ld	a, (_megaram_type+0)
	sub	a, #0x08
	or	a, 1 (iy)
	jr	z, 00106$
	ld	a, (_megaram_type+0)
	sub	a, #0x16
	or	a, 1 (iy)
	jr	z, 00105$
	ret
;smram.c:528: case TYPE_MSCC:
00101$:
;smram.c:529: printf("MegaRAM SCC (default)\n\r");
	ld	hl, #___str_1
	push	hl
	call	_printf
	pop	af
;smram.c:530: break;
	ret
;smram.c:531: case TYPE_LINEAR:
00102$:
;smram.c:532: printf("LINEAR (/L)\n\r");
	ld	hl, #___str_2
	push	hl
	call	_printf
	pop	af
;smram.c:533: break;
	ret
;smram.c:534: case TYPE_K4:
00103$:
;smram.c:535: printf("Konami (/R6 or /K4)\n\r");
	ld	hl, #___str_3
	push	hl
	call	_printf
	pop	af
;smram.c:536: break;
	ret
;smram.c:537: case TYPE_K5:
00104$:
;smram.c:538: printf("Konami SCC (/R5 or /K5)\n\r");
	ld	bc, #___str_4+0
	push	bc
	call	_printf
	pop	af
;smram.c:539: break;
	ret
;smram.c:540: case TYPE_A16:
00105$:
;smram.c:541: printf("ASCII16 (/R1 or /A16)\n\r");
	ld	hl, #___str_5
	push	hl
	call	_printf
	pop	af
;smram.c:542: break;
	ret
;smram.c:543: case TYPE_A8:
00106$:
;smram.c:544: printf("ASCII8 (/R3 or /A8)\n\r");
	ld	hl, #___str_6
	push	hl
	call	_printf
	pop	af
;smram.c:545: break;
	ret
;smram.c:546: case TYPE_DDX:
00107$:
;smram.c:547: printf("MegaRAM DDX (/D)\n\r");
	ld	hl, #___str_7
	push	hl
	call	_printf
	pop	af
;smram.c:549: }
;smram.c:550: }
	ret
___str_0:
	.db 0x0d
	.db 0x0a
	.ascii "Mapper Type: "
	.db 0x00
___str_1:
	.ascii "MegaRAM SCC (default)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_2:
	.ascii "LINEAR (/L)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_3:
	.ascii "Konami (/R6 or /K4)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_4:
	.ascii "Konami SCC (/R5 or /K5)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_5:
	.ascii "ASCII16 (/R1 or /A16)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_6:
	.ascii "ASCII8 (/R3 or /A8)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_7:
	.ascii "MegaRAM DDX (/D)"
	.db 0x0a
	.db 0x0d
	.db 0x00
;smram.c:552: int main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main::
;smram.c:554: curslt = (PPIA & 0x0C) >> 2;
	in	a, (_PPIA)
	and	a, #0x0c
	ld	l, #0x00
	sra	l
	rr	a
	sra	l
	rr	a
	ld	(_curslt), a
;smram.c:555: cursslt = (~(*((uchar*)0xFFFF)) & 0x0C) | *((uchar*)EXPTBL+curslt);
	ld	a, (#0xffff)
	cpl
	and	a, #0x0c
	ld	c, a
	ld	a, (_curslt)
	ld	l, a
	ld	h, #0x00
	ld	de, #0xfcc1
	add	hl, de
	ld	a, (hl)
	or	a, c
	ld	(#_cursslt), a
;smram.c:557: for(i = 1; i < 4; i++)
	ld	hl, #0x0001
	ld	(_i), hl
00304$:
;smram.c:559: slotid = *((uchar*)EXPTBL+i);
	ld	hl, (_i)
	ld	de, #0xfcc1
	add	hl, de
	ld	a, (hl)
	ld	(#_slotid), a
;smram.c:561: if (slotid & 0x80) {    // expanded ?
	ld	a, (_slotid)
	rlca
	jr	nc, 00305$
;smram.c:563: enaslt(i | 0x80, 0x4000); // looking for BIOS, sslot 0
	ld	a, (_i)
	set	7, a
	ld	de, #0x4000
	call	_enaslt
;smram.c:565: b = *(uchar*)(0x6000); // it might be RAM
	ld	a, (#0x6000)
	ld	(#_b), a
;smram.c:566: *((uchar*)0x6000) = 7;
	ld	hl, #0x6000
	ld	(hl), #0x07
;smram.c:567: s = "WonderTANG! uSD Driver";
	ld	hl, #___str_8
	ld	(_s), hl
;smram.c:568: t = (uchar*)0x4110;
	ld	hl, #0x4110
	ld	(_t), hl
;smram.c:569: for(int j=0; j<22; j++)
	ld	bc, #0x0000
00302$:
	ld	a, c
	sub	a, #0x16
	ld	a, b
	rla
	ccf
	rra
	sbc	a, #0x80
	jr	nc, 00105$
;smram.c:571: if (*s++ != *t++) break;
	ld	hl, (_s)
	ld	e, (hl)
	ld	hl, (_s)
	inc	hl
	ld	(_s), hl
	ld	hl, (_t)
	ld	d, (hl)
	ld	hl, (_t)
	inc	hl
	ld	(_t), hl
	ld	a, e
	sub	a, d
	jr	nz, 00105$
;smram.c:573: if (j == 21) 
	ld	a, c
	sub	a, #0x15
	or	a, b
	jr	nz, 00303$
;smram.c:575: found = TRUE;
	ld	hl, #_found
	ld	(hl), #0x01
;smram.c:576: break;
	jr	00105$
00303$:
;smram.c:569: for(int j=0; j<22; j++)
	inc	bc
	jr	00302$
00105$:
;smram.c:580: *((uchar*)0x6000) = b; // return whatever was there
	ld	hl, #0x6000
	ld	a, (_b)
	ld	(hl), a
;smram.c:582: enaslt(curslt | cursslt, 0x4000);
	ld	a, (_curslt)
	ld	hl, #_cursslt
	or	a, (hl)
	ld	de, #0x4000
	call	_enaslt
;smram.c:584: if (found) break;
	ld	a, (_found+0)
	or	a, a
	jr	nz, 00110$
00305$:
;smram.c:557: for(i = 1; i < 4; i++)
	ld	hl, (_i)
	inc	hl
	ld	(_i), hl
	ld	a, (_i+0)
	sub	a, #0x04
	ld	a, (_i+1)
	rla
	ccf
	rra
	sbc	a, #0x80
	jp	c, 00304$
00110$:
;smram.c:588: sslt = 0;
	xor	a, a
	ld	(#_sslt), a
;smram.c:590: if (found)
	ld	a, (_found+0)
	or	a, a
	jp	z, 00208$
;smram.c:592: printf("WonderTANG! Super MegaRAM SCC\n\r");
	ld	hl, #___str_9
	push	hl
	call	_printf
;smram.c:593: printf("v3.01 (new-juice)\n\r");
	ld	hl, #___str_10
	ex	(sp),hl
	call	_printf
	pop	af
;smram.c:595: sslt = 0x80 | (2 << 2) | i;
	ld	a, (_i)
	or	a, #0x88
	ld	(#_sslt), a
;smram.c:596: paramlen = *((char*)0x80);
	ld	a, (#0x0080)
	ld	(#_paramlen), a
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, #0x0081
	ld	(_params), hl
00308$:
	ld	bc, (_params)
	ld	a, (bc)
	ld	e, a
	or	a, a
	jr	nz, 00307$
	ld	a, (_paramlen+0)
	or	a, a
	jp	nz, 00209$
00307$:
;smram.c:599: if (*params != ' ')
;smram.c:601: if (*params == '/')
	ld	a, e
	cp	a, #0x20
	jp	z, 00309$
	sub	a, #0x2f
	jp	nz, 00202$
;smram.c:603: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	c, (hl)
;smram.c:604: if (to_upper(*params) == 'R') 
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
;smram.c:603: params++;
	ld	hl, (_params)
	inc	hl
;smram.c:604: if (to_upper(*params) == 'R') 
	cp	a, #0x52
	jr	nz, 00195$
;smram.c:606: mapperSpecified = TRUE;
	ld	a, #0x01
	ld	(_mapperSpecified+0), a
;smram.c:607: params++;
	ld	(_params), hl
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;smram.c:608: if (*params == '0')
	cp	a, #0x30
	jr	nz, 00127$
;smram.c:609: megaram_type = TYPE_MSCC;
	ld	hl, #0x0000
	ld	(_megaram_type), hl
	jp	00309$
00127$:
;smram.c:611: if (*params == '2')
	cp	a, #0x32
	jr	nz, 00124$
;smram.c:612: megaram_type = TYPE_LINEAR;
	ld	hl, #0x0002
	ld	(_megaram_type), hl
	jp	00309$
00124$:
;smram.c:614: if (*params == '6')
	cp	a, #0x36
	jr	nz, 00121$
;smram.c:615: megaram_type = TYPE_K4;
	ld	hl, #0x0004
	ld	(_megaram_type), hl
	jp	00309$
00121$:
;smram.c:617: if (*params == '5')
	cp	a, #0x35
	jr	nz, 00118$
;smram.c:618: megaram_type = TYPE_K5;
	ld	hl, #0x0005
	ld	(_megaram_type), hl
	jp	00309$
00118$:
;smram.c:620: if (*params == '1')
	cp	a, #0x31
	jr	nz, 00115$
;smram.c:621: megaram_type = TYPE_A16;
	ld	hl, #0x0016
	ld	(_megaram_type), hl
	jp	00309$
00115$:
;smram.c:623: if (*params == '3')
	cp	a, #0x33
	jr	nz, 00112$
;smram.c:624: megaram_type = TYPE_A8;
	ld	hl, #0x0008
	ld	(_megaram_type), hl
	jp	00309$
00112$:
;smram.c:626: megaram_type = TYPE_UNK;                    
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00309$
00195$:
;smram.c:628: else if (to_upper(*params) == 'K')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x4b
	jr	nz, 00192$
;smram.c:630: mapperSpecified = TRUE;
	ld	a, #0x01
	ld	(_mapperSpecified+0), a
;smram.c:631: params++;
	ld	(_params), hl
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;smram.c:632: if (*params == '5')
	cp	a, #0x35
	jr	nz, 00133$
;smram.c:633: megaram_type = TYPE_K5;
	ld	hl, #0x0005
	ld	(_megaram_type), hl
	jp	00309$
00133$:
;smram.c:635: if (*params == '4')
	cp	a, #0x34
	jr	nz, 00130$
;smram.c:636: megaram_type = TYPE_K4;
	ld	hl, #0x0004
	ld	(_megaram_type), hl
	jp	00309$
00130$:
;smram.c:638: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00309$
00192$:
;smram.c:640: else if (to_upper(*params) == 'D')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x44
	jr	nz, 00189$
;smram.c:642: mapperSpecified = TRUE;
	ld	hl, #_mapperSpecified
	ld	(hl), #0x01
;smram.c:643: megaram_type = TYPE_DDX;
	ld	hl, #0x0001
	ld	(_megaram_type), hl
	jp	00309$
00189$:
;smram.c:645: else if (to_upper(*params) == 'L')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x4c
	jr	nz, 00186$
;smram.c:647: mapperSpecified = TRUE;
	ld	hl, #_mapperSpecified
	ld	(hl), #0x01
;smram.c:648: megaram_type = TYPE_LINEAR;
	ld	hl, #0x0002
	ld	(_megaram_type), hl
	jp	00309$
00186$:
;smram.c:650: else if (to_upper(*params) == 'S')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x53
	jr	nz, 00183$
;smram.c:652: softReset = TRUE;
	ld	hl, #_softReset
	ld	(hl), #0x01
;smram.c:653: presAB = TRUE;
	ld	hl, #_presAB
	ld	(hl), #0x01
	jp	00309$
00183$:
;smram.c:655: else if (to_upper(*params) == 'A')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x41
	jr	nz, 00180$
;smram.c:657: mapperSpecified = TRUE;
	ld	a, #0x01
	ld	(_mapperSpecified+0), a
;smram.c:658: params++;
	ld	(_params), hl
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;smram.c:659: if (*params == '8')
	cp	a, #0x38
	jr	nz, 00142$
;smram.c:660: megaram_type = TYPE_A8;
	ld	hl, #0x0008
	ld	(_megaram_type), hl
	jp	00309$
00142$:
;smram.c:662: if (*params == '1')
	cp	a, #0x31
	jr	nz, 00139$
;smram.c:664: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
;smram.c:665: if (*params == '6')
	ld	hl, (_params)
	ld	a, (hl)
	cp	a, #0x36
	jr	nz, 00136$
;smram.c:666: megaram_type = TYPE_A16;
	ld	hl, #0x0016
	ld	(_megaram_type), hl
	jp	00309$
00136$:
;smram.c:668: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00309$
00139$:
;smram.c:671: megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
	jp	00309$
00180$:
;smram.c:673: else if (to_upper(*params) == 'Y')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x59
	jr	nz, 00177$
;smram.c:675: presAB = TRUE;
	ld	hl, #_presAB
	ld	(hl), #0x01
	jp	00309$
00177$:
;smram.c:677: else if (to_upper(*params) == 'X')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x58
	jr	nz, 00174$
;smram.c:679: exitAfterLoad = TRUE;
	ld	hl, #_exitAfterLoad
	ld	(hl), #0x01
	jp	00309$
00174$:
;smram.c:681: else if (to_upper(*params) == 'W')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x57
	jr	nz, 00171$
;smram.c:684: uint parsedAddress = 0;
	ld	bc, #0x0000
;smram.c:686: stepDebug = TRUE;
	ld	hl, #_stepDebug
	ld	(hl), #0x01
;smram.c:687: while (digits < 4) {
	ld	e, #0x00
00152$:
	ld	a, e
	sub	a, #0x04
	jr	nc, 00154$
;smram.c:603: params++;
	ld	hl, (_params)
	inc	hl
;smram.c:688: char digit = to_upper(*(params + 1));
	ld	a, (hl)
	push	hl
	push	bc
	push	de
	call	_to_upper
	pop	de
	pop	bc
	pop	hl
;smram.c:692: value = digit - '0';
	ld	d, a
;smram.c:691: if (digit >= '0' && digit <= '9')
	cp	a, #0x30
	jr	c, 00149$
	cp	a, #0x3a
	jr	nc, 00149$
;smram.c:692: value = digit - '0';
	ld	a, d
	add	a, #0xd0
	ld	d, a
	jr	00150$
00149$:
;smram.c:693: else if (digit >= 'A' && digit <= 'F')
	cp	a, #0x41
	jr	c, 00154$
	cp	a, #0x47
	jr	nc, 00154$
;smram.c:694: value = digit - 'A' + 10;
	ld	a, d
	add	a, #0xc9
	ld	d, a
;smram.c:696: break;
00150$:
;smram.c:698: parsedAddress = (parsedAddress << 4) | value;
	ld	a, c
	add	a, a
	rl	b
	add	a, a
	rl	b
	add	a, a
	rl	b
	add	a, a
	rl	b
	ld	c, d
	ld	d, #0x00
	or	a, c
	ld	c, a
;smram.c:699: params++;
	ld	(_params), hl
;smram.c:700: digits++;
	inc	e
	jr	00152$
00154$:
;smram.c:706: if (digits == 4) {
	ld	a, e
	sub	a, #0x04
	jr	nz, 00309$
;smram.c:707: breakpointAddress = parsedAddress;
	ld	(_breakpointAddress), bc
;smram.c:708: breakpointAddressSpecified = TRUE;
	ld	hl, #_breakpointAddressSpecified
	ld	(hl), #0x01
	jr	00309$
00171$:
;smram.c:712: else if (to_upper(*params) == 'Z')
	push	hl
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	pop	hl
	cp	a, #0x5a
	jr	nz, 00168$
;smram.c:714: params++;
	ld	(_params), hl
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;smram.c:715: if (*params >= '0' && *params <= '3')
	cp	a, #0x30
	jr	c, 00309$
	cp	a, #0x34
	jr	nc, 00309$
;smram.c:716: cpumode = *params - '0';
	add	a, #0xd0
	ld	(#_cpumode), a
	jr	00309$
00168$:
;smram.c:718: else if (to_upper(*params) == '?')
	push	bc
	ld	a, c
	call	_to_upper
	pop	bc
	cp	a, #0x3f
	jr	nz, 00161$
;smram.c:720: help = TRUE;
	ld	hl, #_help
	ld	(hl), #0x01
	jr	00309$
;smram.c:725: while(*params++ != 0 && *params != ' ');
00161$:
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	ld	a, c
	or	a, a
	jr	z, 00309$
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	c, (hl)
;smram.c:725: while(*params++ != 0 && *params != ' ');
	ld	a, c
	sub	a, #0x20
	jr	z, 00309$
	jr	00161$
00202$:
;smram.c:730: filename = params;
	ld	(_filename), bc
;smram.c:731: while(*params != 0 && *params != ' ') {
00198$:
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	ld	a, (hl)
;smram.c:731: while(*params != 0 && *params != ' ') {
	or	a, a
	jr	z, 00209$
	cp	a, #0x20
	jr	z, 00209$
;smram.c:732: *params = to_upper(*params);
	push	hl
	call	_to_upper
	pop	hl
	ld	(hl), a
;smram.c:733: params++;
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	jr	00198$
;smram.c:736: break;
00309$:
;smram.c:597: for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
	ld	hl, (_params)
	inc	hl
	ld	(_params), hl
	ld	hl, #_paramlen
	dec	(hl)
	jp	00308$
00208$:
;smram.c:741: } else megaram_type = TYPE_UNK;
	ld	hl, #0x00ff
	ld	(_megaram_type), hl
00209$:
;smram.c:743: if (!found) 
	ld	a, (_found+0)
	or	a, a
	jr	nz, 00214$
;smram.c:745: printf("ERROR: WonderTANG! not found...\n\r");
	ld	hl, #___str_11
	push	hl
	call	_printf
	pop	af
;smram.c:746: return 0;
	ld	de, #0x0000
	ret
00214$:
;smram.c:749: if (help == TRUE || megaram_type == TYPE_UNK)
	ld	a, (_help)
	dec	a
	jr	z, 00210$
	ld	a, (_megaram_type)
	inc	a
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	nz, 00215$
00210$:
;smram.c:771: );
	ld	hl, #___str_12
	push	hl
	call	_printf
	pop	af
;smram.c:772: return 0;
	ld	de, #0x0000
	ret
00215$:
;smram.c:775: if (filename == 0) {        
	ld	a, (_filename+1)
	ld	hl, #_filename
	or	a, (hl)
	jr	nz, 00219$
;smram.c:776: print_mapper_type();
	call	_print_mapper_type
;smram.c:777: if (megaram_type != TYPE_UNK)
	ld	a, (_megaram_type)
	inc	a
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	z, 00217$
;smram.c:778: MEGA_PORT1 = megaram_type;    
	ld	a, (_megaram_type+0)
	out	(_MEGA_PORT1), a
00217$:
;smram.c:779: return 0;
	ld	de, #0x0000
	ret
00219$:
;smram.c:782: for(t = filename; *t != ' ' && *t != 0; t++);
	ld	hl, (_filename)
	ld	(_t), hl
00312$:
;smram.c:571: if (*s++ != *t++) break;
	ld	hl, (_t)
;smram.c:782: for(t = filename; *t != ' ' && *t != 0; t++);
	ld	a, (hl)
	cp	a, #0x20
	jr	z, 00220$
	or	a, a
	jr	z, 00220$
	ld	hl, (_t)
	inc	hl
	ld	(_t), hl
	jr	00312$
00220$:
;smram.c:783: *t = 0;
	ld	(hl), #0x00
;smram.c:784: handle = dos2_open(0, filename);
	ld	de, (_filename)
	xor	a, a
	call	_dos2_open
	ld	(#_handle), a
;smram.c:786: MEGA_PORT1 = TYPE_K4;
	ld	a, #0x04
	out	(_MEGA_PORT1), a
;smram.c:788: if (handle)
	ld	a, (_handle+0)
	or	a, a
	jp	z, 00240$
;smram.c:790: printf("Loading ROM file: %s - ", filename);
	ld	bc, #___str_13+0
	ld	hl, (_filename)
	push	hl
	push	bc
	call	_printf
	pop	af
	pop	af
;smram.c:792: enaslt(sslt, 0x4000);
	ld	de, #0x4000
	ld	a, (_sslt)
	call	_enaslt
;smram.c:793: page = 0;
;smram.c:794: loadpage = 0;
	xor	a, a
	ld	(#_page), a
	ld	(#_loadpage), a
;smram.c:795: romsize = 0;
	xor	a, a
	ld	(_romsize+0), a
	ld	(_romsize+1), a
	ld	(_romsize+2), a
	ld	(_romsize+3), a
;smram.c:796: printf("%04dKB", 0);
	ld	hl, #0x0000
	push	hl
	ld	hl, #___str_14
	push	hl
	call	_printf
	pop	af
	pop	af
;smram.c:798: do {
00236$:
;smram.c:799: bytes_read = dos2_read(handle, (void*)0x8000, 0x2000);
	ld	hl, #0x2000
	push	hl
	ld	de, #0x8000
	ld	a, (_handle)
	call	_dos2_read
	ld	(_bytes_read), de
;smram.c:804: if ((romsize & 0x3FFFUL) == 0 && bytes_read >= 4 &&
	ld	a, (_romsize+0)
	or	a, a
	jr	nz, 00230$
	ld	a, (_romsize+1)
	and	a, #0x3f
	jr	nz, 00230$
	ld	de, #0x0004
	ld	hl, (_bytes_read)
	cp	a, a
	sbc	hl, de
	jr	c, 00230$
;smram.c:805: *((uchar*)0x8000) == 'A' &&
	ld	a, (#0x8000)
	cp	a, #0x41
	jr	nz, 00230$
;smram.c:806: *((uchar*)0x8001) == 'B')
	ld	a, (#0x8001)
	cp	a, #0x42
	jr	nz, 00230$
;smram.c:808: if (!presAB)
	ld	a, (_presAB+0)
	or	a, a
	jr	nz, 00222$
;smram.c:809: *((uchar*)0x8000) = 0; // remove AB header from image
	ld	hl, #0x8000
	ld	(hl), #0x00
00222$:
;smram.c:811: if (!linearHeaderValid)
	ld	a, (_linearHeaderValid+0)
	or	a, a
	jr	nz, 00224$
;smram.c:813: linearHeaderValid = TRUE;
	ld	hl, #_linearHeaderValid
	ld	(hl), #0x01
;smram.c:814: linearRomstart = *((uint*)0x8002);
	ld	hl, #0x8002
	ld	a, (hl)
	inc	hl
	ld	(_linearRomstart+0), a
	ld	a, (hl)
	ld	(_linearRomstart+1), a
00224$:
;smram.c:817: if (romsize == 0)
	ld	a, (_romsize+3)
	ld	iy, #_romsize
	or	a, 2 (iy)
	or	a, 1 (iy)
	or	a, 0 (iy)
	jr	nz, 00230$
;smram.c:819: headerValid = TRUE;
	ld	hl, #_headerValid
	ld	(hl), #0x01
;smram.c:820: romstart = *((uint*)0x8002);
	ld	hl, #0x8002
	ld	a, (hl)
	inc	hl
	ld	(_romstart+0), a
	ld	a, (hl)
	ld	(_romstart+1), a
;smram.c:822: if (megaram_type == TYPE_LINEAR)
	ld	a, (_megaram_type)
	sub	a, #0x02
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	nz, 00230$
;smram.c:823: loadpage = (uchar)((romstart >> 13) & 0xFE);
	ld	a, (_romstart+1)
	rlca
	rlca
	rlca
	and	a, #0x6
	ld	(#_loadpage), a
00230$:
;smram.c:827: if (bytes_read > 0)
	ld	a, (_bytes_read+1)
	ld	hl, #_bytes_read
	or	a, (hl)
	jr	z, 00235$
;smram.c:829: MEGA_PORT0 = 0; // enable paging
	xor	a, a
	out	(_MEGA_PORT0), a
;smram.c:830: *((uchar *)0x4000) = loadpage + page;
	ld	hl, #_page
	ld	a, (_loadpage+0)
	add	a, (hl)
	ld	(#0x4000), a
;smram.c:831: b = MEGA_PORT0; (b); // enable ram
	in	a, (_MEGA_PORT0)
	ld	(#_b), a
;smram.c:832: memcpy((void*)0x4000, (void*)0x8000, bytes_read);
	ld	de, #0x4000
	ld	hl, #0x8000
	ld	bc, (_bytes_read)
	ld	a, b
	or	a, c
	jr	z, 01292$
	ldir
01292$:
;smram.c:833: romsize += bytes_read;
	ld	bc, (_bytes_read)
	ld	de, #0x0000
	ld	a, c
	ld	hl, #_romsize
	add	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, b
	adc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, e
	adc	a, (hl)
	ld	(hl), a
	inc	hl
	ld	a, d
	adc	a, (hl)
	ld	(hl), a
;smram.c:834: page++;
	ld	hl, #_page
	inc	(hl)
00235$:
;smram.c:836: MEGA_PORT0 = 0; // enable paging
	xor	a, a
	out	(_MEGA_PORT0), a
;smram.c:837: printf("\b\b\b\b\b\b%04dKB", (uint)(romsize >> 10));
	ld	hl, (_romsize + 1)
	ld	a, (_romsize+3)
	ld	b, #0x02
01293$:
	srl	a
	rr	h
	rr	l
	djnz	01293$
	push	hl
	ld	hl, #___str_15
	push	hl
	call	_printf
	pop	af
	pop	af
;smram.c:839: } while (bytes_read > 0);
	ld	a, (_bytes_read+1)
	ld	hl, #_bytes_read
	or	a, (hl)
	jp	nz, 00236$
;smram.c:841: *((uchar *)0x4000) = 0;
	ld	hl, #0x4000
	ld	(hl), #0x00
;smram.c:843: dos2_close(handle);
	ld	a, (_handle)
	call	_dos2_close
	jr	00241$
00240$:
;smram.c:847: enaslt(*((uchar*)RAMAD1), 0x4000);
	ld	a, (#0xf342)
	ld	de, #0x4000
	call	_enaslt
;smram.c:848: enaslt(*((uchar*)RAMAD2), 0x8000);
	ld	a, (#0xf343)
	ld	de, #0x8000
	call	_enaslt
;smram.c:849: printf("ERROR: Failed loading %s\n\r", filename);
	ld	hl, (_filename)
	push	hl
	ld	hl, #___str_16
	push	hl
	call	_printf
	pop	af
	pop	af
;smram.c:850: __asm jp 0x0000 __endasm;
	jp	0x0000 
00241$:
;smram.c:852: *t = ' '; // restore space
	ld	hl, (_t)
	ld	(hl), #0x20
;smram.c:854: if (!mapperSpecified && romsize <= 0x10000UL)
	ld	a, (_mapperSpecified+0)
	or	a,a
	jr	nz, 00245$
	ld	iy, #_romsize
	cp	a, 0 (iy)
	sbc	a, 1 (iy)
	ld	de, (_romsize + 2)
	ld	hl, #0x0001
	sbc	hl, de
	jr	c, 00245$
;smram.c:856: megaram_type = TYPE_LINEAR;
	ld	hl, #0x0002
	ld	(_megaram_type), hl
;smram.c:857: if (headerValid)
	ld	a, (_headerValid+0)
	or	a, a
	jr	z, 00245$
;smram.c:858: loadpage = (uchar)((romstart >> 13) & 0xFE);
	ld	a, (_romstart+1)
	rlca
	rlca
	rlca
	and	a, #0x6
	ld	(#_loadpage), a
00245$:
;smram.c:861: if (megaram_type == TYPE_LINEAR)
	ld	a, (_megaram_type)
	sub	a, #0x02
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jp	nz, 00258$
;smram.c:863: if (!linearHeaderValid)
	ld	a, (_linearHeaderValid+0)
	or	a, a
	jr	nz, 00248$
;smram.c:865: enaslt(*((uchar*)RAMAD1), 0x4000);
	ld	a, (#0xf342)
	ld	de, #0x4000
	call	_enaslt
;smram.c:866: enaslt(*((uchar*)RAMAD2), 0x8000);
	ld	a, (#0xf343)
	ld	de, #0x8000
	call	_enaslt
;smram.c:868: printf("ERROR: LINEAR ROM has no AB header\n\r");
	ld	hl, #___str_17
	push	hl
	call	_printf
	pop	af
;smram.c:870: __asm jp 0x0000 __endasm;
	jp	0x0000 
00248$:
;smram.c:876: romstart = linearRomstart;
	ld	hl, (_linearRomstart)
	ld	(_romstart), hl
;smram.c:877: if (romsize + ((ulong)loadpage << 13) > 0x10000UL)
	ld	a, (_loadpage)
	ld	c, a
	ld	b, #0x00
	ld	de, #0x0000
	ld	d, e
	ld	e, b
	ld	b, c
	ld	a, #0x05
01297$:
	sla	b
	rl	e
	rl	d
	dec	a
	jr	nz, 01297$
	ld	a, (#_romsize + 0)
	ld	c, a
	ld	a, (_romsize+1)
	add	a, b
	ld	b, a
	ld	a, (_romsize+2)
	adc	a, e
	ld	e, a
	ld	a, (_romsize+3)
	adc	a, d
	ld	d, a
	xor	a, a
	cp	a, c
	sbc	a, b
	ld	hl, #0x0001
	sbc	hl, de
	jr	nc, 00250$
;smram.c:879: enaslt(*((uchar*)RAMAD1), 0x4000);
	ld	a, (#0xf342)
	ld	de, #0x4000
	call	_enaslt
;smram.c:880: enaslt(*((uchar*)RAMAD2), 0x8000);
	ld	a, (#0xf343)
	ld	de, #0x8000
	call	_enaslt
;smram.c:883: (uint)((uint)loadpage << 13));
	ld	a, (_loadpage)
	rrca
	rrca
	rrca
	and	a, #0xe0
	ld	d, a
	ld	e, #0x00
;smram.c:882: printf("ERROR: LINEAR ROM does not fit at 0x%04x\n\r",
	ld	bc, #___str_18+0
	push	de
	push	bc
	call	_printf
	pop	af
	pop	af
;smram.c:885: __asm jp 0x0000 __endasm;
	jp	0x0000 
00250$:
;smram.c:892: if (!mapperSpecified && loadpage != 0)
	ld	a, (_mapperSpecified+0)
	or	a, a
	jr	nz, 00258$
	ld	a, (_loadpage+0)
	or	a, a
	jr	z, 00258$
;smram.c:894: page = (uchar)((romsize + 0x1FFFUL) >> 13);
	ld	a, (_romsize+0)
	add	a, #0xff
	ld	a, (_romsize+1)
	adc	a, #0x1f
	ld	d, a
	ld	a, (_romsize+2)
	adc	a, #0x00
	ld	c, a
	ld	a, (_romsize+3)
	adc	a, #0x00
	ld	b, a
	ld	a, d
	ld	e, b
	ld	b, #0x05
01299$:
	srl	e
	rr	c
	rr	a
	djnz	01299$
	ld	(_page), a
;smram.c:895: while (page > 0)
00251$:
	ld	a, (_page+0)
	or	a, a
	jr	z, 00253$
;smram.c:897: page--;
	ld	hl, #_page
	dec	(hl)
;smram.c:898: MEGA_PORT0 = 0;
	xor	a, a
	out	(_MEGA_PORT0), a
;smram.c:899: *((uchar*)0x4000) = page;
	ld	hl, #0x4000
	ld	a, (_page)
	ld	(hl), a
;smram.c:900: b = MEGA_PORT0; (b);
	in	a, (_MEGA_PORT0)
	ld	(#_b), a
;smram.c:901: memcpy((void*)0x8000, (void*)0x4000, 0x2000);
	ld	de, #0x8000
	ld	hl, #0x4000
	ld	bc, #0x2000
	ldir
;smram.c:903: MEGA_PORT0 = 0;
	xor	a, a
	out	(_MEGA_PORT0), a
;smram.c:904: *((uchar*)0x4000) = loadpage + page;
	ld	hl, #_page
	ld	a, (_loadpage+0)
	add	a, (hl)
	ld	(#0x4000), a
;smram.c:905: b = MEGA_PORT0; (b);
	in	a, (_MEGA_PORT0)
	ld	(#_b), a
;smram.c:906: memcpy((void*)0x4000, (void*)0x8000, 0x2000);
	ld	de, #0x4000
	ld	hl, #0x8000
	ld	bc, #0x2000
	ldir
	jr	00251$
00253$:
;smram.c:908: MEGA_PORT0 = 0;
	xor	a, a
	out	(_MEGA_PORT0), a
00258$:
;smram.c:912: print_mapper_type();
	call	_print_mapper_type
;smram.c:913: MEGA_PORT1 = megaram_type;
	ld	a, (_megaram_type+0)
	out	(_MEGA_PORT1), a
;smram.c:915: if (exitAfterLoad)
	ld	a, (_exitAfterLoad+0)
	or	a, a
	jr	z, 00260$
;smram.c:920: enaslt(*((uchar*)RAMAD1), 0x4000);
	ld	a, (#0xf342)
	ld	de, #0x4000
	call	_enaslt
;smram.c:921: enaslt(*((uchar*)RAMAD2), 0x8000);
	ld	a, (#0xf343)
	ld	de, #0x8000
	call	_enaslt
;smram.c:922: printf("\n\rROM loaded; returning to DOS.\n\r");
	ld	hl, #___str_19
	push	hl
	call	_printf
	pop	af
;smram.c:923: __asm jp 0x0000 __endasm;
	jp	0x0000 
00260$:
;smram.c:927: startpage = (uchar)(romstart >> 14);
	ld	a, (_romstart+1)
	rlca
	rlca
	and	a, #0x03
	ld	(_startpage), a
;smram.c:928: if (stepDebug && !breakpointAddressSpecified)
	ld	a, (_stepDebug+0)
	or	a, a
	jr	z, 00262$
	ld	a, (_breakpointAddressSpecified+0)
	or	a, a
	jr	nz, 00262$
;smram.c:929: breakpointAddress = romstart;
	ld	hl, (_romstart)
	ld	(_breakpointAddress), hl
00262$:
;smram.c:930: if (megaram_type == TYPE_LINEAR)
	ld	a, (_megaram_type)
	sub	a, #0x02
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	jr	nz, 00272$
;smram.c:935: enaslt(*((uchar*)BASICSLT), 0x4000);
	ld	a, (#0xfcc2)
	ld	de, #0x4000
	call	_enaslt
;smram.c:936: if (startpage == 1)
	ld	a, (_startpage)
	dec	a
	jr	nz, 00267$
;smram.c:937: enaslt(sslt, 0x4000);
	ld	de, #0x4000
	ld	a, (_sslt)
	call	_enaslt
	jr	00273$
00267$:
;smram.c:938: else if (startpage == 2)
	ld	a, (_startpage)
	sub	a, #0x02
	jr	nz, 00273$
;smram.c:939: enaslt(sslt, 0x8000);
	ld	de, #0x8000
	ld	a, (_sslt)
	call	_enaslt
	jr	00273$
00272$:
;smram.c:943: enaslt(sslt, 0x4000);
	ld	de, #0x4000
	ld	a, (_sslt)
	call	_enaslt
;smram.c:944: if (startpage >= 2)
	ld	a, (_startpage+0)
	sub	a, #0x02
	jr	c, 00273$
;smram.c:945: enaslt(sslt, 0x8000);
	ld	de, #0x8000
	ld	a, (_sslt)
	call	_enaslt
00273$:
;smram.c:947: printf("\n\r\n\rStart address: 0x%04x (page %d)\n\r", romstart, (int)startpage);
	ld	a, (_startpage)
	ld	c, a
	ld	b, #0x00
	push	bc
	ld	hl, (_romstart)
	push	hl
	ld	hl, #___str_20
	push	hl
	call	_printf
	pop	af
	pop	af
	pop	af
;smram.c:949: switch(megaram_type)
	ld	a, (_megaram_type)
	sub	a, #0x04
	ld	iy, #_megaram_type
	or	a, 1 (iy)
	jr	z, 00275$
	ld	a, (_megaram_type+0)
	sub	a, #0x05
	or	a, 1 (iy)
	jr	z, 00275$
	ld	a, (_megaram_type+0)
	sub	a, #0x08
	or	a, 1 (iy)
	jr	z, 00281$
	ld	a, (_megaram_type+0)
	sub	a, #0x16
	or	a, 1 (iy)
	jr	z, 00278$
	jr	00285$
;smram.c:952: case TYPE_K5:
00275$:
;smram.c:953: *((uchar *)0x4000) = 0;
	ld	hl, #0x4000
	ld	(hl), #0x00
;smram.c:954: *((uchar *)0x6000) = 1;
	ld	h, #0x60
	ld	(hl), #0x01
;smram.c:955: if (startpage >= 2)
	ld	a, (_startpage+0)
	sub	a, #0x02
	jr	c, 00285$
;smram.c:957: *((uchar *)0x8000) = 0;
	ld	h, #0x80
	ld	(hl), #0x00
;smram.c:958: *((uchar *)0xA000) = 1;
	ld	h, #0xa0
	ld	(hl), #0x01
;smram.c:960: break;
	jr	00285$
;smram.c:961: case TYPE_A16:
00278$:
;smram.c:962: *((uchar *)0x6000) = 0;
	ld	hl, #0x6000
	ld	(hl), #0x00
;smram.c:963: if (startpage >= 2)
	ld	a, (_startpage+0)
	sub	a, #0x02
	jr	c, 00285$
;smram.c:964: *((uchar *)0x8000) = 0;
	ld	h, #0x80
	ld	(hl), #0x00
;smram.c:965: break;
	jr	00285$
;smram.c:966: case TYPE_A8:
00281$:
;smram.c:967: *((uchar *)0x6000) = 0;
	ld	hl, #0x6000
	ld	(hl), #0x00
;smram.c:968: *((uchar *)0x6800) = 1;
	ld	h, #0x68
	ld	(hl), #0x01
;smram.c:969: if (startpage >= 2)
	ld	a, (_startpage+0)
	sub	a, #0x02
	jr	c, 00285$
;smram.c:971: *((uchar *)0x7000) = 0;
	ld	h, #0x70
	ld	(hl), #0x00
;smram.c:972: *((uchar *)0x7800) = 1;
	ld	h, #0x78
	ld	(hl), #0x01
;smram.c:977: }
00285$:
;smram.c:979: if (cpumode != 0)
	ld	a, (_cpumode+0)
	or	a, a
	jr	z, 00287$
;smram.c:980: chgcpu(cpumode == 1 ? Z80_ROM : cpumode == 2 ? R800_ROM : R800_DRAM);
	ld	a, (_cpumode)
	dec	a
	jr	z, 00317$
	ld	a, (_cpumode)
	sub	a, #0x02
	ld	a, #0x81
	jr	z, 00319$
	ld	a, #0x82
00319$:
00317$:
	call	_chgcpu
00287$:
;smram.c:982: if (softReset == FALSE)
	ld	a, (_softReset+0)
	or	a, a
	jp	nz, 00300$
;smram.c:984: if (megaram_type == TYPE_LINEAR && startpage == 0)
	ld	a, (_megaram_type)
	sub	a, #0x02
	ld	hl, #_megaram_type + 1
	or	a, (hl)
	ld	a, #0x01
	jr	z, 01316$
	xor	a, a
01316$:
	ld	c, a
	or	a, a
	jr	z, 00296$
	ld	a, (_startpage+0)
	or	a, a
	jr	nz, 00296$
;smram.c:985: memcpy((void*)0xC000, &runROM_page0, ((uint)&runROM_page0_end - (uint)&runROM_page0));
	ld	hl, #_runROM_page0
	ld	bc, #_runROM_page0_end
	ld	de, #_runROM_page0
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	z, 00297$
	ldir
	jr	00297$
00296$:
;smram.c:986: else if (megaram_type == TYPE_LINEAR && startpage == 3)
	ld	a, c
	or	a, a
	jr	z, 00292$
	ld	a, (_startpage)
	sub	a, #0x03
	jr	nz, 00292$
;smram.c:988: memcpy((void*)0x8000, &runROM_page3, ((uint)&runROM_page3_end - (uint)&runROM_page3));
	ld	hl, #_runROM_page3
	ld	bc, #_runROM_page3_end
	ld	de, #_runROM_page3
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0x8000
	ld	a, b
	or	a, c
	jr	z, 01320$
	ldir
01320$:
;smram.c:989: jump(0x8000);
	ld	hl, #0x8000
	call	_jump
	jr	00297$
00292$:
;smram.c:991: else if (startpage >= 2)
	ld	a, (_startpage+0)
	sub	a, #0x02
	jr	c, 00289$
;smram.c:992: memcpy((void*)0xC000, &runROM_page2, ((uint)&runROM_page2_end - (uint)&runROM_page2));
	ld	hl, #_runROM_page2
	ld	bc, #_runROM_page2_end
	ld	de, #_runROM_page2
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	z, 00297$
	ldir
	jr	00297$
00289$:
;smram.c:994: memcpy((void*)0xC000, &runROM_page1, ((uint)&runROM_page1_end - (uint)&runROM_page1));
	ld	hl, #_runROM_page1
	ld	bc, #_runROM_page1_end
	ld	de, #_runROM_page1
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	z, 01322$
	ldir
01322$:
00297$:
;smram.c:996: jump(0xC000);
	ld	hl, #0xc000
	call	_jump
00300$:
;smram.c:999: memcpy((void*)0xC000, &runROM_Reset, ((uint)&runROM_Reset_end - (uint)&runROM_Reset));
	ld	hl, #_runROM_Reset
	ld	bc, #_runROM_Reset_end
	ld	de, #_runROM_Reset
	ld	a, c
	sub	a, e
	ld	c, a
	ld	a, b
	sbc	a, d
	ld	b, a
	ld	de, #0xc000
	ld	a, b
	or	a, c
	jr	z, 01323$
	ldir
01323$:
;smram.c:1000: jump(0xC000);
	ld	hl, #0xc000
	call	_jump
;smram.c:1002: return 1; // make sdcc happy
	ld	de, #0x0001
;smram.c:1003: }
	ret
___str_8:
	.ascii "WonderTANG! uSD Driver"
	.db 0x00
___str_9:
	.ascii "WonderTANG! Super MegaRAM SCC"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_10:
	.ascii "v3.01 (new-juice)"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_11:
	.ascii "ERROR: WonderTANG! not found..."
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_12:
	.db 0x0a
	.db 0x0d
	.ascii "USAGE: SMRAM [/Rx /L /W /X /Zx /Y] [romfile]"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /Rx: Set MegaROM type"
	.db 0x0a
	.db 0x0d
	.ascii "   0: Megaram SCC (default)"
	.db 0x0a
	.db 0x0d
	.ascii "   1: ASCII16     (/A16)"
	.db 0x0a
	.db 0x0d
	.ascii "   2: LINEAR      (/L)"
	.db 0x0a
	.db 0x0d
	.ascii "   3: ASCII8      (/A8)"
	.db 0x0a
	.db 0x0d
	.ascii "   5: Konami SCC  (/K5)"
	.db 0x0a
	.db 0x0d
	.ascii "   6: Konami      (/K4)"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /D: Set MegaRAM DDX type"
	.db 0x0a
	.db 0x0d
	.ascii " /L: Set LINEAR type (automatic for ROMs <=64KB)"
	.db 0x0a
	.db 0x0d
	.ascii " /S: Soft reset"
	.db 0x0a
	.db 0x0d
	.ascii " /Wxxxx: Break on M1 at hex address xxxx"
	.db 0x0a
	.db 0x0d
	.ascii "          (/W defaults to ROM start)"
	.db 0x0a
	.db 0x0d
	.ascii " /X: Load ROM, set mapper, and return to DOS"
	.db 0x0a
	.db 0x0d
	.ascii " /Zx: Set cpu mode"
	.db 0x0a
	.db 0x0d
	.ascii "   0: current"
	.db 0x0a
	.db 0x0d
	.ascii "   1: Z80"
	.db 0x0a
	.db 0x0d
	.ascii "   2: R800 ROM"
	.db 0x0a
	.db 0x0d
	.ascii "   3: R800 DRAM"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii " /Y:  Preserve AB header"
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_13:
	.ascii "Loading ROM file: %s - "
	.db 0x00
___str_14:
	.ascii "%04dKB"
	.db 0x00
___str_15:
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.db 0x08
	.ascii "%04dKB"
	.db 0x00
___str_16:
	.ascii "ERROR: Failed loading %s"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_17:
	.ascii "ERROR: LINEAR ROM has no AB header"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_18:
	.ascii "ERROR: LINEAR ROM does not fit at 0x%04x"
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_19:
	.db 0x0a
	.db 0x0d
	.ascii "ROM loaded; returning to DOS."
	.db 0x0a
	.db 0x0d
	.db 0x00
___str_20:
	.db 0x0a
	.db 0x0d
	.db 0x0a
	.db 0x0d
	.ascii "Start address: 0x%04x (page %d)"
	.db 0x0a
	.db 0x0d
	.db 0x00
	.area _CODE
	.area _INITIALIZER
__xinit__found:
	.db #0x00	; 0
__xinit__filename:
	.dw #0x0000
__xinit__megaram_type:
	.dw #0x0000
__xinit__paramlen:
	.db #0x00	; 0
__xinit__presAB:
	.db #0x00	; 0
__xinit__softReset:
	.db #0x00	; 0
__xinit__mapperSpecified:
	.db #0x00	; 0
__xinit__headerValid:
	.db #0x00	; 0
__xinit__linearHeaderValid:
	.db #0x00	; 0
__xinit__exitAfterLoad:
	.db #0x00	; 0
__xinit__stepDebug:
	.db #0x00	; 0
__xinit__breakpointAddressSpecified:
	.db #0x00	; 0
__xinit__cpumode:
	.db #0x01	; 1
__xinit__startpage:
	.db #0x01	; 1
__xinit__loadpage:
	.db #0x00	; 0
__xinit__help:
	.db #0x00	; 0
__xinit__scc_vol:
	.db #0x09	; 9
__xinit__psg_vol:
	.db #0x09	; 9
__xinit__opll_vol:
	.db #0x09	; 9
	.area _CABS (ABS)
