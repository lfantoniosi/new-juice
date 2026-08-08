#include<stdio.h>
#include<string.h>
#include "types.h"


#define BDOS                5
#define BDOS_C_WRITE		2
#define BDOS_C_RAWIO		6

#define TYPE_MSCC 0x00
#define TYPE_DDX 0x01
#define TYPE_LINEAR 0x02
#define TYPE_K4  0x04
#define TYPE_K5  0x05
#define TYPE_A16 0x16
#define TYPE_A8  0x08
#define TYPE_UNK 0xFF
#define STEP_DEBUG_BREAKPOINT_CODE 0xFE

#define FHANDLE     uchar
#define DOS2_OPEN	0x43
#define DOS2_CLOSE	0x45
#define DOS2_READ	0x48


#define RDSLT               0x000C
#define CALSLT				0x001C
#define EXPTBL				0xFCC1
#define BASICSLT            0xFCC2
#define ENASLT              0x0024
#define HTIMI               0xFD9A
#define HKEYI               0xFD9F
#define CHGCPU	            0x0180

#define Z80_ROM   0x00
#define R800_ROM  0x81
#define R800_DRAM 0x82

#define RAMAD0	0xF341
#define RAMAD1	0xF342
#define RAMAD2	0xF343
#define RAMAD3	0xF344


void bdos() __naked
{
	__asm
	push	ix
	push	iy
	call	BDOS
	pop		iy
	pop		ix
	ret
	__endasm;
}

void bdos_c_write(uchar c) __naked
{
	c;
	__asm

	ld 		e,a
	ld		c,#BDOS_C_WRITE
	call	_bdos

	ret
	__endasm;
}

uchar bdos_c_rawio() __naked
{
	__asm

	ld		e,#0xFF;
	ld		c,#BDOS_C_RAWIO
	call	_bdos

	ret
	__endasm;
}

int putchar(int c) 
{
	if (c >= 0)
		bdos_c_write((char)c);
	return c;
}

int getchar()
{
	uchar c;
	do {
		c = bdos_c_rawio();
	} while(c == 0);
	return (int)c;
}

void fputs(const char *s)
{
	while(*s != NULL)
		putchar(*s++);
}

char to_upper(char c)
{
    if (c >= 'a' && c <= 'z')
        c = c - ('a'-'A');
    return c;
}

void enaslt(uchar slotid, uint addr) __naked
{
    slotid; addr;
    __asm
    push    af
    push    bc
    push    de
    push    hl
    push    ix
    push    iy

    ex      de,hl
    call    #ENASLT

    pop     iy
    pop     ix
    pop     hl
    pop     de
    pop     bc
    pop     af

    ret
    __endasm;
}

uchar rdslt(uchar slotid, uint addr) __naked
{
    slotid; addr;
    __asm
    push    bc
    push    de
 
    ex      de,hl
    call    #RDSLT
    ex      de,hl
 
    pop     de
    pop     bc

    ret
    __endasm;
}

void chgcpu(uchar mode) __naked
{
    mode;
    __asm
    push    bc
    push    de
    push    af

    ld      a,(EXPTBL)
    ld      hl,#CHGCPU
    call    #RDSLT

    cp      #0xC3
    jr      nz,__no_turbo
    ld      a,b

    pop     af

    ld      iy,(EXPTBL-1)
    ld      ix,#CHGCPU
    call    #CALSLT

    push    af

__no_turbo:

    pop     af
    pop     de
    pop     bc
    ret
    __endasm;
}

__sfr __at (0x8E) MEGA_PORT0;
__sfr __at (0x8F) MEGA_PORT1;
__sfr __at (0xA8) PPIA;

#define ENABLE_INT   \
         __asm       \
            ei       \
        __endasm

#define DISABLE_INT  \
         __asm       \
            di       \
        __endasm


FHANDLE dos2_open(uchar mode, const char* filepath) __naked
{
	 filepath; mode;
	__asm
		push	bc
		push	de
		push	hl
		ld 		c,#DOS2_OPEN
		call	BDOS
        or      a
        jr      z,__open_no_err    
        ld      b,#0
__open_no_err:
		ld		a,b
        pop     hl
		pop 	de
		pop     bc
		ret
	__endasm;
}

void dos2_close(FHANDLE hnd) __naked
{
	hnd;
	__asm
		push	bc
		ld   	a,b
		ld 		c,#DOS2_CLOSE
		call	BDOS
		pop     bc
		ret
	__endasm;
}

uint dos2_read(FHANDLE hnd, void *dst, uint size) __naked
{
	hnd; dst; size;
	__asm
		push	ix
		ld		ix,#0
		add		ix,sp
		push	bc

		ld 		b,a
		ld		l, 4 (ix)
		ld		h, 5 (ix)

		ld		c,#DOS2_READ
		call	BDOS

		pop		bc
		pop		ix
		ex 		de,hl
		ret
	__endasm;	
}

uchar dos2_getenv(char *var, char *buf) __naked
{
    var; buf;
	__asm
        ld      b,#255
		ld		c,#0x6B
		call	BDOS
		ret
	__endasm;	
}

char hexToNum(char h)
{
    //if (h >= 'A' && h <= 'F')
    //    return h-'A' + 10;
    if (h >= '0' && h <='9')
        return h-'0';    
    return 0;
}

void jump(uint addr) __naked
{
    addr;
    __asm

    ld      sp,(0x0006)
    jp      (hl)

    __endasm;
}

void runROM_page1() __naked
{
	__asm
    ei
    halt
    di
    ld      sp,#0xCFFF
    ld      a,(_stepDebug)
    or      a
    jr      z,__page1_breakpoint_programmed
    ld      a,#STEP_DEBUG_BREAKPOINT_CODE
    out     (#0x8F),a
    ld      a,(_breakpointAddress)
    out     (#0x8F),a
    ld      a,(_breakpointAddress+1)
    out     (#0x8F),a
__page1_breakpoint_programmed:
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    ld      a,(_sslt)
    ld      h,a
    ld      l,#0
    push    hl
    pop     iy
    ld      ix,(_romstart)
    push    iy
    push    ix

    ld      a,(EXPTBL)
    ld      hl,#0
    call    #ENASLT

    pop     ix
    pop     iy
    call    #CALSLT
    call    #CALSLT
    __endasm;
}
void runROM_page1_end() __naked {}

void runROM_page0() __naked
{
	__asm
    ei
    halt
    di
    ld      sp,#0xCFFF
    ld      a,(_stepDebug)
    or      a
    jr      z,__page0_breakpoint_programmed
    ld      a,#STEP_DEBUG_BREAKPOINT_CODE
    out     (#0x8F),a
    ld      a,(_breakpointAddress)
    out     (#0x8F),a
    ld      a,(_breakpointAddress+1)
    out     (#0x8F),a
__page0_breakpoint_programmed:
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    // Keep the BIOS mapped in page 0: CALSLT performs the inter-slot call
    // without ENASLT changing the page beneath the BIOS routine itself.
    ld      a,(_sslt)
    ld      h,a
    ld      l,#0
    push    hl
    pop     iy
    ld      ix,(_romstart)
    call    #CALSLT
    call    #CALSLT
	__endasm;
}
void runROM_page0_end() __naked {}

void runROM_page2() __naked
{
	__asm
    ei
    halt
    di
    ld      sp,#0xCFFF
    ld      a,(_stepDebug)
    or      a
    jr      z,__page2_breakpoint_programmed
    ld      a,#STEP_DEBUG_BREAKPOINT_CODE
    out     (#0x8F),a
    ld      a,(_breakpointAddress)
    out     (#0x8F),a
    ld      a,(_breakpointAddress+1)
    out     (#0x8F),a
__page2_breakpoint_programmed:
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    ld      a,(_sslt)
    ld      h,a
    ld      l,#0
    push    hl
    pop     iy
    ld      ix,(_romstart)
    push    iy
    push    ix

    ld      a,(EXPTBL)
    ld      hl,#0
    call    #ENASLT

    pop     ix
    pop     iy
    call    #CALSLT
    call    #CALSLT
	__endasm;
}
void runROM_page2_end() __naked {}

void runROM_page3() __naked
{
	__asm
    ei
    halt
    di
    ld      sp,#0xBFFF

    ld      a,(_stepDebug)
    or      a
    jr      z,__page3_breakpoint_programmed
    ld      a,#STEP_DEBUG_BREAKPOINT_CODE
    out     (#0x8F),a
    ld      a,(_breakpointAddress)
    out     (#0x8F),a
    ld      a,(_breakpointAddress+1)
    out     (#0x8F),a
__page3_breakpoint_programmed:

    ld      a,(_sslt)
    ld      h,a
    ld      l,#0
    push    hl
    pop     iy
    ld      ix,(_romstart)
    push    iy
    push    ix

    ld      a,(EXPTBL)
    ld      hl,#0
    call    #ENASLT

    pop     ix
    pop     iy
    call    #CALSLT
    call    #CALSLT
	__endasm;
}
void runROM_page3_end() __naked {}

void runROM_Reset() __naked
{
    __asm
    ei
    halt
    di
    ld      sp,#0xCFFF
    ld      a,(_stepDebug)
    or      a
    jr      z,__reset_breakpoint_programmed
    ld      a,#STEP_DEBUG_BREAKPOINT_CODE
    out     (#0x8F),a
    ld      a,(_breakpointAddress)
    out     (#0x8F),a
    ld      a,(_breakpointAddress+1)
    out     (#0x8F),a
__reset_breakpoint_programmed:
    ld      hl,#HTIMI
    ld      a,#0xC9
    ld      (hl),a
    ld      hl,#HKEYI
    ld      (hl),a

    ld      iy,(EXPTBL-1)
    ld      ix,#0
    call    #CALSLT
    call    #CALSLT
    __endasm;
}

void runROM_Reset_end() __naked {}

bool found = FALSE;
char* filename = NULL;
int megaram_type = TYPE_MSCC;
uchar curslt, cursslt, sslt, b;
const uchar *s;
uchar *t;
char* params;
char paramlen = 0;
FHANDLE handle;
uint bytes_read;
int i;
uint addr;
uchar page;
ulong romsize;
uchar slotid;
bool presAB = FALSE;
bool softReset = FALSE;
bool mapperSpecified = FALSE;
bool headerValid = FALSE;
bool linearHeaderValid = FALSE;
bool exitAfterLoad = FALSE;
bool stepDebug = FALSE;
bool breakpointAddressSpecified = FALSE;
char path[256];
char cpumode = 1; // defaults to Z80_ROM
uint romstart;
uint breakpointAddress;
uint linearRomstart;
uchar startpage = 1;
uchar loadpage = 0;
bool help = FALSE;
char scc_vol = 9;
char psg_vol = 9;
char opll_vol = 9;
char c;

void print_mapper_type(void)
{
    printf("\r\nMapper Type: ");
    switch(megaram_type)
    {
        case TYPE_MSCC:
            printf("MegaRAM SCC (default)\n\r");
            break;
        case TYPE_LINEAR:
            printf("LINEAR (/L)\n\r");
            break;
        case TYPE_K4:
            printf("Konami (/R6 or /K4)\n\r");
            break;
        case TYPE_K5:
            printf("Konami SCC (/R5 or /K5)\n\r");
            break;
        case TYPE_A16:
            printf("ASCII16 (/R1 or /A16)\n\r");
            break;
        case TYPE_A8:
            printf("ASCII8 (/R3 or /A8)\n\r");
            break;
        case TYPE_DDX:
            printf("MegaRAM DDX (/D)\n\r");
            break;
    }
}

int main(void)
{
    curslt = (PPIA & 0x0C) >> 2;
    cursslt = (~(*((uchar*)0xFFFF)) & 0x0C) | *((uchar*)EXPTBL+curslt);

    for(i = 1; i < 4; i++)
    {
        slotid = *((uchar*)EXPTBL+i);

        if (slotid & 0x80) {    // expanded ?

            enaslt(i | 0x80, 0x4000); // looking for BIOS, sslot 0
            
            b = *(uchar*)(0x6000); // it might be RAM
            *((uchar*)0x6000) = 7;
            s = "WonderTANG! uSD Driver";
            t = (uchar*)0x4110;
            for(int j=0; j<22; j++)
            {
                if (*s++ != *t++) break;

                if (j == 21) 
                {
                    found = TRUE;
                    break;
                }
            }

            *((uchar*)0x6000) = b; // return whatever was there

            enaslt(curslt | cursslt, 0x4000);
            
            if (found) break;
        }
    }
    //found = TRUE;
    sslt = 0;

    if (found)
    {
        printf("WonderTANG! Super MegaRAM SCC\n\r");
        printf("v3.01 (new-juice)\n\r");

        sslt = 0x80 | (2 << 2) | i;
        paramlen = *((char*)0x80);
        for(params = (char*)0x81; *params != 0 || paramlen == 0; ++params, paramlen--)
        {
            if (*params != ' ')
            {
                if (*params == '/')
                {
                    params++;
                    if (to_upper(*params) == 'R') 
                    {
                        mapperSpecified = TRUE;
                        params++;
                        if (*params == '0')
                            megaram_type = TYPE_MSCC;
                        else
                        if (*params == '2')
                            megaram_type = TYPE_LINEAR;
                        else
                        if (*params == '6')
                            megaram_type = TYPE_K4;
                        else
                        if (*params == '5')
                            megaram_type = TYPE_K5;
                        else
                        if (*params == '1')
                            megaram_type = TYPE_A16;
                        else
                        if (*params == '3')
                            megaram_type = TYPE_A8;
                        else 
                            megaram_type = TYPE_UNK;                    
                    } 
                    else if (to_upper(*params) == 'K')
                    {
                        mapperSpecified = TRUE;
                        params++;
                        if (*params == '5')
                            megaram_type = TYPE_K5;
                        else
                        if (*params == '4')
                            megaram_type = TYPE_K4;
                        else
                            megaram_type = TYPE_UNK;
                    } 
                    else if (to_upper(*params) == 'D')
                    {
                        mapperSpecified = TRUE;
                        megaram_type = TYPE_DDX;
                    }
                    else if (to_upper(*params) == 'L')
                    {
                        mapperSpecified = TRUE;
                        megaram_type = TYPE_LINEAR;
                    }
                    else if (to_upper(*params) == 'S')
                    {
                        softReset = TRUE;
                        presAB = TRUE;
                    }
                    else if (to_upper(*params) == 'A')
                    {
                        mapperSpecified = TRUE;
                        params++;
                        if (*params == '8')
                            megaram_type = TYPE_A8;
                        else 
                        if (*params == '1')
                        {
                            params++;
                            if (*params == '6')
                                megaram_type = TYPE_A16;
                            else
                                megaram_type = TYPE_UNK;
                        }
                        else
                            megaram_type = TYPE_UNK;
                    }
                    else if (to_upper(*params) == 'Y')
                    {
                        presAB = TRUE;
                    }
                    else if (to_upper(*params) == 'X')
                    {
                        exitAfterLoad = TRUE;
                    }
                    else if (to_upper(*params) == 'W')
                    {
                        uchar digits = 0;
                        uint parsedAddress = 0;

                        stepDebug = TRUE;
                        while (digits < 4) {
                            char digit = to_upper(*(params + 1));
                            uchar value;

                            if (digit >= '0' && digit <= '9')
                                value = digit - '0';
                            else if (digit >= 'A' && digit <= 'F')
                                value = digit - 'A' + 10;
                            else
                                break;

                            parsedAddress = (parsedAddress << 4) | value;
                            params++;
                            digits++;
                        }

                        // /W by itself uses the ROM entry point. An explicit
                        // breakpoint address is exactly four hexadecimal
                        // digits, accepted in either case.
                        if (digits == 4) {
                            breakpointAddress = parsedAddress;
                            breakpointAddressSpecified = TRUE;
                        }
                    }
               
                    else if (to_upper(*params) == 'Z')
                    {
                        params++;
                        if (*params >= '0' && *params <= '3')
                            cpumode = *params - '0';
                    }
                    else if (to_upper(*params) == '?')
                    {
                        help = TRUE;
                    }
                    else
                    {
                        // ignore option
                        while(*params++ != 0 && *params != ' ');
                    }
                } 
                else {
                    // should be filename
                    filename = params;
                    while(*params != 0 && *params != ' ') {
                            *params = to_upper(*params);
                            params++;
                    }

                     break;
                }
            }
        }

    } else megaram_type = TYPE_UNK;

    if (!found) 
    {
        printf("ERROR: WonderTANG! not found...\n\r");
        return 0;
    }
    else
    if (help == TRUE || megaram_type == TYPE_UNK)
    {
        printf("\n\rUSAGE: SMRAM [/Rx /L /W /X /Zx /Y] [romfile]\n\r\n\r"
                " /Rx: Set MegaROM type\n\r"
                "   0: Megaram SCC (default)\n\r"
                "   1: ASCII16     (/A16)\n\r"
                "   2: LINEAR      (/L)\n\r"
                "   3: ASCII8      (/A8)\n\r"
                "   5: Konami SCC  (/K5)\n\r"
                "   6: Konami      (/K4)\n\r\n\r"
                " /D: Set MegaRAM DDX type\n\r"
                " /L: Set LINEAR type (automatic for ROMs <=64KB)\n\r"
                " /S: Soft reset\n\r"
                " /Wxxxx: Break on M1 at hex address xxxx\n\r"
                "          (/W defaults to ROM start)\n\r"
                " /X: Load ROM, set mapper, and return to DOS\n\r"
                " /Zx: Set cpu mode\n\r"
                "   0: current\n\r"
                "   1: Z80\n\r"
                "   2: R800 ROM\n\r"
                "   3: R800 DRAM\n\r\n\r"
                " /Y:  Preserve AB header\n\r\n\r"
        );
        return 0;
    }

    if (filename == 0) {        
        print_mapper_type();
        if (megaram_type != TYPE_UNK)
            MEGA_PORT1 = megaram_type;    
        return 0;
    } 

    for(t = filename; *t != ' ' && *t != 0; t++);
    *t = 0;
    handle = dos2_open(0, filename);

    MEGA_PORT1 = TYPE_K4;

    if (handle)
    {
            printf("Loading ROM file: %s - ", filename);
            
            enaslt(sslt, 0x4000);
            page = 0;
            loadpage = 0;
            romsize = 0;
            printf("%04dKB", 0);

            do {
                bytes_read = dos2_read(handle, (void*)0x8000, 0x2000);
                // A linear image may begin at address 0 while its cartridge
                // header lives at a later 16 KiB boundary.  Remember the
                // first such header for launching, but only a header at file
                // offset zero is allowed to shift the image's load base.
                if ((romsize & 0x3FFFUL) == 0 && bytes_read >= 4 &&
                    *((uchar*)0x8000) == 'A' &&
                    *((uchar*)0x8001) == 'B')
                {
                    if (!presAB)
                        *((uchar*)0x8000) = 0; // remove AB header from image

                        if (!linearHeaderValid)
                    {
                        linearHeaderValid = TRUE;
                        linearRomstart = *((uint*)0x8002);
                    }

                    if (romsize == 0)
                    {
                        headerValid = TRUE;
                        romstart = *((uint*)0x8002);

                        if (megaram_type == TYPE_LINEAR)
                            loadpage = (uchar)((romstart >> 13) & 0xFE);
                    }
                }

                if (bytes_read > 0)
                {
                    MEGA_PORT0 = 0; // enable paging
                    *((uchar *)0x4000) = loadpage + page;
                    b = MEGA_PORT0; (b); // enable ram
                    memcpy((void*)0x4000, (void*)0x8000, bytes_read);
                    romsize += bytes_read;
                    page++;
                }
                MEGA_PORT0 = 0; // enable paging
                printf("\b\b\b\b\b\b%04dKB", (uint)(romsize >> 10));

            } while (bytes_read > 0);

             *((uchar *)0x4000) = 0;
            
            dos2_close(handle);
    } 
    else 
    {
        enaslt(*((uchar*)RAMAD1), 0x4000);
        enaslt(*((uchar*)RAMAD2), 0x8000);
        printf("ERROR: Failed loading %s\n\r", filename);
        __asm jp 0x0000 __endasm;
    }
    *t = ' '; // restore space

    if (!mapperSpecified && romsize <= 0x10000UL)
    {
        megaram_type = TYPE_LINEAR;
        if (headerValid)
            loadpage = (uchar)((romstart >> 13) & 0xFE);
    }

    if (megaram_type == TYPE_LINEAR)
    {
        if (!linearHeaderValid)
        {
            enaslt(*((uchar*)RAMAD1), 0x4000);
            enaslt(*((uchar*)RAMAD2), 0x8000);

            printf("ERROR: LINEAR ROM has no AB header\n\r");
            
            __asm jp 0x0000 __endasm;
        }

        // Launch through the first AB header found on a 16 KiB boundary.
        // This need not be the first bank (for example, a 48 KiB image can
        // load at 0x0000 and carry its header at 0x4000).
        romstart = linearRomstart;
        if (romsize + ((ulong)loadpage << 13) > 0x10000UL)
        {
            enaslt(*((uchar*)RAMAD1), 0x4000);
            enaslt(*((uchar*)RAMAD2), 0x8000);

            printf("ERROR: LINEAR ROM does not fit at 0x%04x\n\r",
                   (uint)((uint)loadpage << 13));

            __asm jp 0x0000 __endasm;
        }

        // With no mapper parameter the size was not known up front, so an
        // image whose first bank has AB was loaded at bank zero. Move it into
        // the 16 KiB page selected by that header without overwriting source
        // banks that have not been copied yet.
        if (!mapperSpecified && loadpage != 0)
        {
            page = (uchar)((romsize + 0x1FFFUL) >> 13);
            while (page > 0)
            {
                page--;
                MEGA_PORT0 = 0;
                *((uchar*)0x4000) = page;
                b = MEGA_PORT0; (b);
                memcpy((void*)0x8000, (void*)0x4000, 0x2000);

                MEGA_PORT0 = 0;
                *((uchar*)0x4000) = loadpage + page;
                b = MEGA_PORT0; (b);
                memcpy((void*)0x4000, (void*)0x8000, 0x2000);
            }
            MEGA_PORT0 = 0;
        }
    }

    print_mapper_type();
    MEGA_PORT1 = megaram_type;

    if (exitAfterLoad)
    {
        // Loading temporarily maps MegaRAM in page 1 and uses page 2 as its
        // DOS transfer buffer. Restore both BIOS-designated RAM slots;
        // the PPI-derived current slot is not necessarily the DOS RAM slot.
        enaslt(*((uchar*)RAMAD1), 0x4000);
        enaslt(*((uchar*)RAMAD2), 0x8000);
        printf("\n\rROM loaded; returning to DOS.\n\r");
        __asm jp 0x0000 __endasm;
        //return 0;
    }

    startpage = (uchar)(romstart >> 14);
    if (stepDebug && !breakpointAddressSpecified)
        breakpointAddress = romstart;
    if (megaram_type == TYPE_LINEAR)
    {
        // Establish the normal cartridge environment first: system BIOS in
        // page 0 (the copied launcher does this) and BASIC in page 1. Then
        // replace only the page containing the ROM entry point with MegaRAM.
        enaslt(*((uchar*)BASICSLT), 0x4000);
        if (startpage == 1)
            enaslt(sslt, 0x4000);
        else if (startpage == 2)
            enaslt(sslt, 0x8000);
    }
    else
    {
        enaslt(sslt, 0x4000);
        if (startpage >= 2)
            enaslt(sslt, 0x8000);
    }
    printf("\n\r\n\rStart address: 0x%04x (page %d)\n\r", romstart, (int)startpage);

    switch(megaram_type)
    {
        case TYPE_K4:
        case TYPE_K5:
            *((uchar *)0x4000) = 0;
            *((uchar *)0x6000) = 1;
            if (startpage >= 2)
            {
                *((uchar *)0x8000) = 0;
                *((uchar *)0xA000) = 1;
            }
            break;
        case TYPE_A16:
            *((uchar *)0x6000) = 0;
            if (startpage >= 2)
                *((uchar *)0x8000) = 0;
            break;
        case TYPE_A8:
            *((uchar *)0x6000) = 0;
            *((uchar *)0x6800) = 1;
            if (startpage >= 2)
            {
                *((uchar *)0x7000) = 0;
                *((uchar *)0x7800) = 1;
            }
            break;
        default:
            break;
    }
    
    if (cpumode != 0)
        chgcpu(cpumode == 1 ? Z80_ROM : cpumode == 2 ? R800_ROM : R800_DRAM);

    if (softReset == FALSE)
    {
        if (megaram_type == TYPE_LINEAR && startpage == 0)
            memcpy((void*)0xC000, &runROM_page0, ((uint)&runROM_page0_end - (uint)&runROM_page0));
        else if (megaram_type == TYPE_LINEAR && startpage == 3)
        {
            memcpy((void*)0x8000, &runROM_page3, ((uint)&runROM_page3_end - (uint)&runROM_page3));
            jump(0x8000);
        }
        else if (startpage >= 2)
            memcpy((void*)0xC000, &runROM_page2, ((uint)&runROM_page2_end - (uint)&runROM_page2));
        else
            memcpy((void*)0xC000, &runROM_page1, ((uint)&runROM_page1_end - (uint)&runROM_page1));
                
        jump(0xC000);
    }

    memcpy((void*)0xC000, &runROM_Reset, ((uint)&runROM_Reset_end - (uint)&runROM_Reset));
    jump(0xC000);

    return 1; // make sdcc happy
}
