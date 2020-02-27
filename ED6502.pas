(*****************************************************************
* ED6502 : EL DENDO's 6502 Emulator  V0.1 DEV                    *
* Copyright (c) 2006 - 2020 by ir. Marc Dendooven                *
* This is the 6502 (6510) emulation used in my c64 emulator ED64 *
* rebuild as a unit                                              *
*****************************************************************)
unit ED6502;

interface

type  	readCallBack = function(address: word): byte;
		writeCallBack = procedure(address: word; value: byte);
		
procedure run6502(PC:word; peek:readCallBack; poke:writeCallBack);

implementation

// uses memio, SysUtils, strUtils;
uses strUtils;

//const debugMax = 100000000;

procedure run6502(PC:word; peek:readCallBack; poke:writeCallBack);

(*****************************************************************
* 6510 registers                                                 *
*****************************************************************)
var
        A,X,Y,S,P,IR : byte;
//       PC : word;
        cnt: cardinal = 0;
        nodbug: boolean = true;


(******************************************************************
* Emulator help procedures and functions                                                  *
******************************************************************)
procedure error (s: string);
begin
    writeln;
    writeln('--------------------------------------');
    writeln('emulator error: ',s);
    writeln('PC=',hexstr(PC,4),' IR=',hexstr(IR,2));
    writeln;
    writeln('Execution has been ended');
    writeln('push return to exit');
    writeln('--------------------------------------');
    readln;
    halt
end;

function peek2(address : word) : word;
begin
        peek2 := peek(address) + peek(address + 1) * 256
end;

const inst_names: array[0..255] of string = ('BRK imp','ORA indX','ERR imm','ERR ERR','ERR ERR','ORA zp','ASL zp','ERR ERR','PHP imp','ORA imm','ASL acc','ERR ERR','ERR ERR','ORA abs','ASL abs','ERR ERR','BPL rel','ORA indY','ERR ERR','ERR ERR','ERR ERR','ORA zpX','ASL zpX','ERR ERR','CLC imp','ORA absY','ERR ERR','ERR ERR','ERR ERR','ORA absX','ASL absX','ERR ERR','JSR abs','AND indX','ERR imm','ERR ERR','BIT zp','AND zp','ROL zp','ERR ERR','PLP imp','AND imm','ROL acc','ERR ERR','BIT abs','AND abs','ROL abs','ERR ERR','BMI rel','AND indY','ERR ERR','ERR ERR','ERR zpX','AND zpX','ROL zpX','ERR ERR','SEC imp','AND absY','ERR ERR','ERR ERR','ERR absX','AND absX','ROL absX','ERR ERR','RTI imp','EOR indX','ERR imm','ERR ERR','ERR zp','EOR zp','LSR zp','ERR ERR','PHA imp','EOR imm','LSR acc','ERR ERR','JMP abs','EOR abs','LSR abs','ERR ERR','BVC rel','EOR indY','ERR ERR','ERR ERR','ERR zpX','EOR zpX','LSR zpX','ERR ERR','CLI imp','EOR absY','ERR ERR','ERR ERR','ERR absX','EOR absX','LSR absX','ERR ERR','RTS imp','ADC indX','ERR imm','ERR ERR','ERR zp','ADC zp','ROR zp','ERR ERR','PLA imp','ADC imm','ROR acc','ERR ERR','JMP ind','ADC abs','ROR abs','ERR ERR','BVS rel','ADC indY','ERR ERR','ERR ERR','ERR zpX','ADC zpX','ROR zpX','ERR ERR','SEI imp','ADC absY','ERR ERR','ERR ERR','ERR absX','ADC absX','ROR absX','ERR ERR','ERR imm','STA indX','ERR imm','ERR ERR','STY zp','STA zp','STX zp','ERR ERR','DEY imp','ERR imm','TXA imp','ERR ERR','STY abs','STA abs','STX abs','ERR ERR','BCC rel','STA indY','ERR ERR','ERR ERR','STY zpX','STA zpX','STX zpY','ERR ERR','TYA imp','STA absY','TXS imp','ERR ERR','ERR absX','STA absX','ERR absY','ERR ERR','LDY imm','LDA indX','LDX imm','ERR ERR','LDY zp','LDA zp','LDX zp','ERR ERR','TAY imp','LDA imm','TAX imp','ERR ERR','LDY abs','LDA abs','LDX abs','ERR ERR','BCS rel','LDA indY','ERR ERR','ERR ERR','LDY zpX','LDA zpX','LDX zpY','ERR ERR','CLV imp','LDA absY','TSX imp','ERR ERR','LDY absX','LDA absX','LDX absY','ERR ERR','CPY imm','CMP indX','ERR imm','ERR ERR','CPY zp','CMP zp','DEC zp','ERR ERR','INY imp','CMP imm','DEX imp','ERR ERR','CPY abs','CMP abs','DEC abs','ERR ERR','BNE rel','CMP indY','ERR ERR','ERR ERR','ERR zpX','CMP zpX','DEC zpX','ERR ERR','CLD imp','CMP absY','ERR ERR','ERR ERR','ERR absX','CMP absX','DEC absX','ERR ERR','CPX imm','SBC indX','ERR imm','ERR ERR','CPX zp','SBC zp','INC zp','ERR ERR','INX imp','SBC imm','NOP imp','ERR ERR','CPX abs','SBC abs','INC abs','ERR ERR','BEQ rel','SBC indY','ERR ERR','ERR ERR','ERR zpX','SBC zpX','INC zpX','ERR ERR','SED imp','SBC absY','ERR ERR','ERR ERR','ERR absX','SBC absX','INC absX','ERR ERR');

procedure dump;
begin
//	inc(cnt); 	if cnt > debugMax then error('more than '+intToStr(debugMax)+' cycles... probably looping');
//	if PC=hex2Dec('3368') then nodbug := false;
//	if nodbug then exit;

    write(' PC=',hexstr(PC,4),' IR=',hexstr(IR,2));
    write(' A=',hexstr(A,2),' X=',hexstr(X,2),
            ' Y=',hexstr(Y,2),' S=',hexstr(S,2),
            ' P=',binstr(P,8));
    write('     ',hexStr(PC,4),' ',inst_names[IR]);
    writeln
end;

(******************************************************************
* Addressing modes: functions which return the address for        *
* instructions to work upon                                       *
******************************************************************)
function imm : word;
begin
        imm := PC;
        inc(PC)
end;

function zp : byte;
begin
        zp := peek(PC);
        inc(PC)
end;

function zpx : byte;
begin
        zpx := peek(PC)+X;
        inc(PC)
end;

function zpy : byte;
begin
        zpy := peek(PC)+Y;
        inc(PC)
end;

function abs : word;
begin
        abs := peek2(PC);
        inc(PC,2)
end;

function absx : word;
begin
        absx := peek2(PC) + X;
        inc(PC,2)
end;

function absy : word;
begin
        absy := peek2(PC) + Y;
        inc(PC,2)
end;

function ind : word;
begin
        ind := peek2(peek2(PC));
        inc(PC,2)
end;

function indx : word;
begin
        indx := peek2(byte(peek(PC)+X));
        inc(PC)
end;

function indy : word;
begin
        indy := peek2(peek(PC)) + Y;
        inc(PC)
end;

(********************************************************************
* Actions on Status Register (P)    NV.BDIZC                        *
********************************************************************)

const
        C = $01;
        Z = $02;
        I = $04;
        D = $08;
        B = $10;
        V = $40;
        N = $80;

procedure setflag (flag : byte; status : boolean);
begin
        if status       then P := P or flag
                        else P := P and not flag
end;

function flagset (flag : byte) : boolean;
begin
        flagset := boolean(P and flag)
end;

(********************************************************************
* Stack operations                                                  *
********************************************************************)

procedure push (b : byte);
begin
        poke ($100+S,b);
        dec(S)
end;

function pull : byte;
begin
        inc(S);
        pull := peek($100+S)
end;

(******************************************************************
* generic branching instructions                                  *
******************************************************************)
procedure bfs (flag : byte);
begin
        if flagset(flag)   then PC := PC + shortint(peek(PC)) + 1
                           else inc(PC)
end;

procedure bfc (flag : byte);
begin
        if flagset(flag)   then inc(PC)
                           else PC := PC + shortint(peek(PC)) + 1
end;

(********************************************************************
* Instructions                                                                              *
********************************************************************)

procedure adc (address : word);
var     
		AL,AH : byte;
		HC: boolean;
        val : byte;
begin
        val := peek(address);
        AL := A and $0F + val and $0F;
        if flagset(C) then inc(AL);
        if flagSet(D) then HC := AL > 9 else HC := AL > $F; 
        AH := (A and $F0)>>4 + (val and $F0)>>4;
        if HC then inc(AH); 
        if flagSet(D) then setFlag(C,AH > 9) else setFlag(C,AH > $F); 
        setFlag(V,boolean((not (A xor val) and $80) and ((A xor AH*16) and  $80)));
        A := AH*16+(AL and $0F);
        if flagset(D) then
			begin
//				error('halted in ADC with D set');
				if HC then AL := (AL+6) and $0F;
				if flagSet(C) then AH := (AH+6) and $0F;
				A := AH*16+(AL and $0F)
			end;
		setflag(Z,A = 0);
        setflag(N,A >= $80);
       
end; 

procedure sbc (address : word);
var     
		AL,AH : byte;
		HC: boolean;
        val : byte;
begin
		val := peek(address) xor $FF;
	    AL := A and $0F + val and $0F;
        if flagset(C) then inc(AL);
//        if flagSet(D) then HC := AL > 9 else HC := AL > $F; 
		HC := AL > $F;
        AH := (A and $F0)>>4 + (val and $F0)>>4;
        if HC then inc(AH); 
//        if flagSet(D) then setFlag(C,AH > 9) else setFlag(C,AH > $F); 
		setFlag(C,AH > $F);
        setFlag(V,boolean((not (A xor val) and $80) and ((A xor AH*16) and  $80)));
        A := AH*16+(AL and $0F);
        if flagset(D) then
			begin
//				error('halted in SBC with D set');
				if not HC then AL := (AL+10) and $0F;
				if not FlagSet(C) then AH := (AH+10) and $0F;
				A := AH*16+(AL and $0F);
//				writeln(AH,' ',AL,' ',A);
			end;
		setflag(Z,A = 0);
        setflag(N,A >= $80);
end;

(*
procedure sbc (address : word);
var     H : word;
        val : byte;
		DHC: boolean;
        AL: Byte;
begin
        val := peek(address);
        H := A - val;
        if not flagset(C) then H := H - 1;
        if H and $0F > 9 then DHC := true else DHC := False;
        if flagSet(D) and not DHC then H := H + $10;
        setFlag(V,boolean(((A xor val) and $80) and ((A xor H) and  $80)));
        if flagSet(D) then setflag(C,H<=99) else setflag(C,H<=$FF);    
        A:=H;   
        if flagset(D) then
			begin
				setflag(C,H <= 99);
				AL := A and $0F;
				if AL > 9 then AL:=AL+$A;
				if not flagset(C) then A:=A+$A0;
				A := (A and $F0) + AL
			end;
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;
*)
procedure and_ (address : word);
begin
        A := A and peek(address);
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure ora (address : word);
begin
        A := A or peek(address);
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure asl_A;
begin
        setflag(C,boolean(A and $80));
        A := A shl 1;
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure asl (address : word);
var B : byte;
begin
        B := peek(address);
        setflag(C,boolean(B and $80));
        B := B shl 1;
        poke(address,B);
        setflag(Z,B=0);
        setflag(N,B>=$80)
end;

procedure rol_A;
var bit : boolean;
begin
        bit := flagset(C);
        setflag(C,boolean(A and $80));
        A := A shl 1;
        if bit then A := A or $01;
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure rol (address : word);
var B : byte;
    bit : boolean;
begin
        B := peek(address);
        bit := flagset(C);
        setflag(C,boolean(B and $80));
        B := B shl 1;
        if bit then B := B or $01;
        poke(address,B);
        setflag(Z,B=0);
        setflag(N,B>=$80)
end;

procedure ror_A;
var bit : boolean;
begin
        bit := flagset(C);
        setflag(C,boolean(A and $01));
        A := A shr 1;
        if bit then A := A or $80;
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure ror (address : word);
var B : byte;
    bit : boolean;
begin
        B := peek(address);
        bit := flagset(C);
        setflag(C,boolean(B and $01));
        B := B shr 1;
        if bit then B := B or $80;
        poke(address,B);
        setflag(Z,B=0);
        setflag(N,B>=$80)
end;

procedure lsr_A;
begin
        setflag(C,boolean(A and $01));
        A := A shr 1;
        setflag(Z,A=0);
        setflag(N,false);
end;

procedure lsr (address : word);
var B : byte;
begin
        B := peek(address);
        setflag(C,boolean(B and $01));
        B := B shr 1;
        poke(address,B);
        setflag(Z,B=0);
        setflag(N,false);
end;

procedure bit (address : word);
var H : byte;
begin
        H := peek(address);
        setflag(N,boolean(H and $80));
        setflag(V,boolean(H and $40));
        setflag(Z,(H and A)=0)
end;



procedure brk;
begin
        setflag(B,true);
        inc(PC);
        push(hi(PC));
        push(lo(PC));
        push(P or %00110000);
        setflag(I,true);
        PC := peek2($FFFE)
end;

procedure cmp (address : word);
var H : word;
begin
        H := A - peek(address);
        setflag(C,H<=$FF);
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure cpx (address : word);
var H : word;
begin
        H := X - peek(address);
        setflag(C,H<=$FF);
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure cpy (address : word);
var H : word;
begin
        H := Y - peek(address);
        setflag(C,H<=$FF);
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure dec_ (address : word);
var H : word;
begin
        H := peek(address) - 1;
        poke (address,H);
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure dex;
var H : word;
begin
        H := X - 1;
        X := H;
        setflag(Z,X=0);
        setflag(N,X>=$80)
end;

procedure dey;
var H : word;
begin
        H := Y - 1;
        Y := H;
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure eor (address : word);
begin
        A := A xor peek(address);
        setflag(Z,A=0);
        setflag(N,A>=$80);
end;

procedure inc_ (address : word);
var H : word;
begin
        H := peek(address) + 1;
        poke (address,H);
        setflag(Z,lo(H)=0);
        setflag(N,lo(H)>=$80)
end;

procedure inx;
var H : word;
begin
        H := X + 1;
        X := H;
        setflag(Z,X=0);
        setflag(N,X>=$80)
end;

procedure iny;
var H : word;
begin
        H := Y + 1;
        Y := H;
        setflag(Z,Y=0);
        setflag(N,Y>=$80)
end;

procedure jmp (address : word);
begin
        PC := address;
end;

procedure jsr (address : word);
begin
        dec(PC);
        push(hi(PC));
        push(lo(PC));
        PC := address
end;

procedure rts;
begin
        PC := pull;
        PC := PC + pull*256 + 1
end;

procedure rti;
begin
        P := pull;
        PC := pull;
        PC := PC + pull*256
end;




procedure lda (address : word);
begin
        A := peek (address);
        setflag(Z,A=0);
        setflag(N,A>=$80)
end;

procedure ldx (address : word);
begin
        X := peek (address);
        setflag(Z,X=0);
        setflag(N,X>=$80)
end;

procedure ldy (address : word);
begin
        Y := peek (address);
        setflag(Z,Y=0);
        setflag(N,Y>=$80)
end;

procedure pla;
begin
        A := pull;
        setflag(Z,A=0);
        setflag(N,A>=$80)
end;

procedure sta (address : word);
begin
        poke (address, A)
end;

procedure stx(address : word);
begin
        poke (address, X)
end;

procedure sty (address : word);
begin
        poke (address, Y)
end;

procedure tax;
begin
        X := A;
        setflag(Z,X=0);
        setflag(N,X>=$80)
end;

procedure tay;
begin
        Y := A;
        setflag(Z,Y=0);
        setflag(N,Y>=$80)
end;

procedure tsx;
begin
        X := S;
        setflag(Z,X=0);
        setflag(N,X>=$80)
end;

procedure txa;
begin
        A := X;
        setflag(Z,A=0);
        setflag(N,A>=$80)
end;

procedure txs;
begin
        S := X;
end;

procedure tya;
begin
        A := Y;
        setflag(Z,A=0);
        setflag(N,A>=$80)
end;

(******************************************************************
* interrupts and reset                                            *
******************************************************************)
procedure irq;
begin
    if not flagset(I) then
    begin
        setflag(B,false);
        push(hi(PC));
        push(lo(PC));
        push(P);
        setflag(I,true);
        PC := peek2($FFFE);
    end
end;

procedure nmi;
begin
    setflag(B,false);
    push(hi(PC));
    push(lo(PC));
    push(P);
    setflag(I,true);
    PC := peek2($FFFA)
end;

procedure reset;
begin
    PC := peek2($FFFC);
    setflag(I,true)
end;

(******************************************************************
* processor main loop                                             *
******************************************************************)
begin
    writeln('--------------------------------------');
    writeln('Welcome to EL DENDO''s c64 emulator');
    writeln('(c) 2006 ir. Marc Dendooven');
    writeln('--------------------------------------');

//    PC := peek2($FFFC);
//	PC := $400;
    while true do
        begin
            IR := peek(PC);
            dump;
            inc(PC);
            case IR of
                $69 : adc(imm);
                $65 : adc(zp);
                $75 : adc(zpx);
                $6D : adc(abs);
                $7D : adc(absx);
                $79 : adc(absy);
                $61 : adc(indx);
                $71 : adc(indy);

                $29 : and_(imm);
                $25 : and_(zp);
                $35 : and_(zpx);
                $2D : and_(abs);
                $3D : and_(absx);
                $39 : and_(absy);
                $21 : and_(indx);
                $31 : and_(indy);

                $0A : asl_A;
                $06 : asl(zp);
                $16 : asl(zpx);
                $0E : asl(abs);
                $1E : asl(absx);

                $90 : bfc(C); //bcc

                $B0 : bfs(C); //bcs

                $F0 : bfs(Z); //beq

                $24 : bit(zp);
                $2C : bit(abs);

                $30 : bfs(N); //bmi

                $D0 : bfc(Z); //bne

                $10 : bfc(N); //bpl

                $00 : brk;

                $50 : bfc(V); //bvc

                $70 : bfs(V); //bvs

                $18 : setflag(C,false); //clc

                $D8 : setflag(D,false); //cld

                $58 : setflag(I,false); //cli

                $B8 : setflag(V,false); //clv

                $C9 : cmp(imm);
                $C5 : cmp(zp);
                $D5 : cmp(zpx);
                $CD : cmp(abs);
                $DD : cmp(absx);
                $D9 : cmp(absy);
                $C1 : cmp(indx);
                $D1 : cmp(indy);

                $E0 : cpx(imm);
                $E4 : cpx(zp);
                $EC : cpx(abs);

                $C0 : cpy(imm);
                $C4 : cpy(zp);
                $CC : cpy(abs);

                $C6 : dec_(zp);
                $D6 : dec_(zpx);
                $CE : dec_(abs);
                $DE : dec_(absx);

                $CA : dex;

                $88 : dey;

                $49 : eor(imm);
                $45 : eor(zp);
                $55 : eor(zpx);
                $4D : eor(abs);
                $5D : eor(absx);
                $59 : eor(absy);
                $41 : eor(indx);
                $51 : eor(indy);

                $E6 : inc_(zp);
                $F6 : inc_(zpx);
                $EE : inc_(abs);
                $FE : inc_(absx);

                $E8 : inx;

                $C8 : iny;

                $4C : jmp(abs);
                $6C : jmp(ind);

                $20 : jsr(abs);

                $A9 : lda(imm);
                $A5 : lda(zp);
                $B5 : lda(zpx);
                $AD : lda(abs);
                $BD : lda(absx);
                $B9 : lda(absy);
                $A1 : lda(indx);
                $B1 : lda(indy);

                $A2 : ldx(imm);
                $A6 : ldx(zp);
                $B6 : ldx(zpy);
                $AE : ldx(abs);
                $BE : ldx(absy);

                $A0 : ldy(imm);
                $A4 : ldy(zp);
                $B4 : ldy(zpx);
                $AC : ldy(abs);
                $BC : ldy(absx);

                $4A : lsr_A;
                $46 : lsr(zp);
                $56 : lsr(zpx);
                $4E : lsr(abs);
                $5E : lsr(absx);

                $EA : ; // nop

                $09 : ora(imm);
                $05 : ora(zp);
                $15 : ora(zpx);
                $0D : ora(abs);
                $1D : ora(absx);
                $19 : ora(absy);
                $01 : ora(indx);
                $11 : ora(indy);

                $48 : push(A); //pha

                $08 : push(P or %00110000); //php

                $68 : pla;

                $28 : P := pull; //plp

                $2A : rol_A;
                $26 : rol(zp);
                $36 : rol(zpx);
                $2E : rol(abs);
                $3E : rol(absx);

                $6A : ror_A;
                $66 : ror(zp);
                $76 : ror(zpx);
                $6E : ror(abs);
                $7E : ror(absx);

                $40 : rti;

                $60 : rts;

                $E9 : sbc(imm);
                $E5 : sbc(zp);
                $F5 : sbc(zpx);
                $ED : sbc(abs);
                $FD : sbc(absx);
                $F9 : sbc(absy);
                $E1 : sbc(indx);
                $F1 : sbc(indy);

                $38 : setflag(C,true);     //sec

                $F8 ://error('trying to set D flag but decimal mode not implemented'); 
                     setflag(D,true);     //sed

                $78 : setflag(I,true);     //sei

                $85 : sta(zp);
                $95 : sta(zpx);
                $8D : sta(abs);
                $9D : sta(absx);
                $99 : sta(absy);
                $81 : sta(indx);
                $91 : sta(indy);

                $86 : stx(zp);
                $96 : stx(zpy);
                $8E : stx(abs);

                $84 : sty(zp);
                $94 : sty(zpx);
                $8C : sty(abs);

                $AA : tax;

                $A8 : tay;

                $BA : tsx;

                $8A : txa;

                $9A : txs;

                $98 : tya;
            else
                error ('unknown instruction ')
            end
    end
end;

end.
