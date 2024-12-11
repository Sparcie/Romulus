{parts loaded from planets data files}

unit parts;

interface

type
   weapon  = record
		name   : array[1..20] of char;
		cost   : word;
		tcost  : word;
		dcost  : word;
		mcost  : word;
		mass   : word;
		tech   : word;
		kill   : word;
		damage : word;
	     end;      
   engine  = record
		name	     : array[1..20] of char;
		cost	     : word;
		tcost	     : word;
		dcost	     : word;
		mcost	     : word;
		tech	     : word;
		fconsumption : array[1..9] of longint;
	     end;
   
   torpedo =  record
		 name	  : array[1..20] of char;
		 costtorp : word;
		 costtube : word;
		 tcost	  : word;
		 dcost	  : word;
		 mcost	  : word;
		 mass	  : word;
		 tech	  : word;
		 kill	  : word;
		 damage	  : word;
	      end;
		 

var
   weapons : array[1..10] of weapon;
   torps   : array[1..10]of torpedo;
   engines : array[1..9] of engine;

function getBestEng(tech : word):word;
function getBestBeam(cost,count,tech : word):word;
function getKillBeam(cost,count,tech : word):word;
function getBestTube(cost,count,tech : word):word;

implementation

var
   beamspec : file;
   i,b	    : word;

function getBestEng(tech : word):word;
var i : word;
begin
   getBestEng:=1;
   for i:= 1 to 9 do
      if engines[i].tech <= tech then getBestEng:=i;
end; { getBestEng }

function getBestBeam(cost,count,tech: word):word;
var
   p,cc	: word;
   bp	: word;
begin
   bp:=0;
   getBestBeam:=0;
   for i:= 1 to 10 do
   begin
      p:= weapons[i].damage;
      cc := weapons[i].cost * count;
      if ((weapons[i].tech<=tech) and (cc<cost) and (p>bp)) then
      begin
	 getBestBeam:=i;
	 bp:=p;
      end;
   end; 
end; { getBestBeam }

function getKillBeam(cost,count,tech: word):word;
var
   p,cc	: word;
   bp	: word;
begin
   bp:=0;
   getKillBeam:=0;
   for i:= 1 to 10 do
   begin
      p:= weapons[i].kill;
      cc := weapons[i].cost * count;
      if ((weapons[i].tech<=tech) and (cc<cost) and (p>bp)) then
      begin
	 getKillBeam:=i;
	 bp:=p;
      end;
   end; 
end; { getKillBeam }

function getBestTube(cost,count,tech : word):word;
var
   boc,oc : real;
begin
   boc:=0;
   getBestTube:=0;
   for i:= 1 to 10 do
   begin
      oc:= int(torps[i].damage);
      if ((torps[i].tech<=tech) and (oc>boc)) then
      begin
	 getBestTube:=i;
	 boc:=oc;
      end;
   end; 
end; { getBestTube }

begin
   writeln('Loading weapons');
   assign(beamspec,'beamspec.dat');
   reset(beamspec,1);
   for i:= 1 to 10 do
   begin
      blockread(beamspec,weapons[i],sizeof(weapon),b);
      if not(b=sizeof(weapon)) then
      begin
	 writeln('could not read beams');
      end;
   end;
   close(beamspec);
   writeln('Loading engines');
   assign(beamspec,'engspec.dat');
   reset(beamspec,1);
   for i:= 1 to 9 do
   begin
      blockread(beamspec,engines[i],sizeof(engine),b);
      if not(b=sizeof(engine)) then
      begin
	 writeln('could not read engines');
      end;
   end;
   close(beamspec);
   writeln('Loading torpedoes');
   assign(beamspec,'torpspec.dat');
   reset(beamspec,1);
   for i:= 1 to 10 do
   begin
      blockread(beamspec,torps[i],sizeof(torpedo),b);
      if not(b=sizeof(torpedo)) then
      begin
	 writeln('could not read torpedoes');
      end;
   end;
   close(beamspec);
end.
