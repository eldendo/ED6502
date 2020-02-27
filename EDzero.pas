(* EDzero - EL DENDO's very simple computer emulation using a 6502
(c) copyright 2010-2020 by ir. Marc Dendooven
this is a VERY SIMPLE 6502 based computer emulation demo for my ED6502
emulator *)

program EDzero;

uses ED6502;

var mem: array[0..$FFFF] of byte;

function peek(address: word): byte; 	// define read access functionality for memory
begin									// if memory mapped input is used include this here
	peek := mem[address]
end;

procedure poke(address: word; value: byte); // define write access functionality for memory
begin										// if memory mapped output is used include this here
	mem[address] := value
end;

begin
	writeln('welcome to EDzero');
	writeln('testing ED6502');
	writeln('-----------------');
	
//	      LDX #$05    A205
//LOOP    DEX         CA
//        BNE LOOP    D0FD
//        (EXIT)      FF
	
	poke ($C000,$A2); poke($C001,$05);
    poke ($C002,$CA);
    poke ($C003,$D0); poke($C004,$FD);
    poke ($C005,$FF);

//    poke ($FFFC,00); poke($FFFD,$C0);

	run6502($C000, @peek, @poke)
end. 
