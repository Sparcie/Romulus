{hull data for planets}

unit hull;

interface

type
  shiphull  = record
		 name	  : array[1..30] of char;
		 pic	  : word;
		 dpic	  : word;
		 tcost	  : word;
		 dcost	  : word;
		 mcost	  : word;
		 fueltank : word;
		 crew	  : word;
		 engines  : word;
		 mass	  : word;
		 tech	  : word;
		 cargo	  : word;
		 bays	  : word;
		 tubes	  : word;
		 beams	  : word;
		 cost	  : word;
	      end;	  
   shiplist =  record
		  hull : array[1..20] of word;
	       end;
   


var
   hulls : array[1..105] of shiphull;
   race	 : array[1..11] of shiplist;

function isFreighter(s	: word):boolean;
function guessHull(o,m : integer):word;

implementation

var
   hullspec : file;
   i,b	    : word;

function guessHull(o,m : integer):word;
var
   i,hl : word;
   md	  : integer;
   bmd	  : integer;
begin
   guesshull:=1; {default ship}
   for i:= 1 to 20 do
      if race[o].hull[i]>0 then
	 with hulls[race[o].hull[i]] do
	 begin
	    md := abs(m - (mass + (fueltank div 2) + (cargo div 2) + (beams*7) + (tubes*4)  ) );
	    if md < bmd then
	    begin
	       hl:=race[o].hull[i];
	       bmd:=md;
	    end;
	 end;
end;

   function isFreighter(s : word):boolean;
   begin
      isFreighter:=true;
      if (hulls[s].beams>0) then isFreighter:=false;
      if hulls[s].tubes>0 then isFreighter:=false;
   end;

begin
   writeln('reading hulls');
   assign(hullspec,'hullspec.dat');
   reset(hullspec,1);
   for i:=1 to 105 do
   begin
      blockread(hullspec,hulls[i],sizeof(shiphull),b);
      if not(b=sizeof(shiphull)) then
      begin
	 writeln('error reading hulls');
	 halt(1);
      end;
   end;
   close(hullspec);
   assign(hullspec,'truehull.dat');
   reset(hullspec,1);
   for i:=1 to 11 do
   begin
      blockread(hullspec,race[i].hull,sizeof(word)*20,b);
      if not(b=sizeof(shiplist)) then
      begin
	 writeln('error reading ship list');
	 halt(1);
      end;
   end;
   close(hullspec);
end.