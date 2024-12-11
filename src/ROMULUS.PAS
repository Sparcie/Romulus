program Romulus;

uses RST,map,parts,hull,planets,ships,shipstat,turn,bsystem,bases,messages,diplo,targdb, Empire;

{$ifdef d_stateout}
procedure stateout;
var i :word ;
begin
   for i:=1 to 500 do
      if chart[i].owner>0 then
      begin
	 write('p: ');
	 write(i);
	 write(' xy: ');
	 write(chart[i].x);
	 write(',');
	 write(chart[i].y);
	 write(' o:');
	 writeln(chart[i].owner);
      end;
end;
{$endif}

procedure processRST(rst : string);
begin
   writeln;
   loadRST(rst);
   resetmsgs;
   resetDip;
   load;
   parseMessages;
   processVCR;
   mapworlds;
   targetdb;
   
   empireState;
   doDiplomacy;
   doworlds;
   doships;
   dobases;
   
   maketurn;
{$ifdef D_stateout}
   stateout;
{$endif}
   save;
   resetdb;
   resetMap;
   resetships;
   resetbases;
   clearworlds;
   resetRST;
end;

begin
   randomize;
   {$ifdef Debug}
   writeln('Memory Available ->', memAvail);
   {$endif}
   {for the moment we process any RST files we find}
   if checkfile('player1.rst') then processRST('player1.rst');
   if checkfile('player2.rst') then processRST('player2.rst');
   if checkfile('player3.rst') then processRST('player3.rst');
   if checkfile('player4.rst') then processRST('player4.rst');
   if checkfile('player5.rst') then processRST('player5.rst');
   if checkfile('player6.rst') then processRST('player6.rst');
   if checkfile('player7.rst') then processRST('player7.rst');
   if checkfile('player8.rst') then processRST('player8.rst');
   if checkfile('player9.rst') then processRST('player9.rst');
   if checkfile('player10.rst') then processRST('player10.rst');
   if checkfile('player11.rst') then processRST('player11.rst');
   {$ifdef Debug}
   writeln('Memory Available ->', memAvail);
   {$endif}
end.