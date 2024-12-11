{ mine sweeper unit for romulus }
{ A Danson 2011}

unit ship_swp;

interface

uses shiputil,planets,shipstat,hull,map,vector,RST,messages,diplo;

{ deliberate minesweeping, ships seek out mines and attmept to sweep them }
procedure minesweep(sid : word; s: stateptr);


implementation

function nearestMines(x,y : integer):word;
var i : word; {loop counter}
   bd : integer; { best distance}
   ew : word; {enemy world}
   en : boolean; {current minefield belongs to a enemy (based on dipstate)}
   fe : boolean; {found a minefield that belongs to a dipstate enemy}
begin
   bd:=1000;
   nearestMines:=101;
   if mcount=0 then exit;
   fe:=false;
   for i:=0 to (mcount-1) do
   begin
      if (mines[i].enemy and not(mines[i].web)) then
      begin
	 ew := nearestEnemyWorld(mines[i].x,mines[i].y);
	 en:=false;
	 if (ew>0) then
	    if isEnemy(chart[ew].owner-10) then en:=true;
	 if ((round(distance(x,y,mines[i].x,mines[i].y) - mines[i].radius ) <= bd) and (en or not(fe))) then
	 begin
	    if en then fe:=true;
	    nearestMines:=i;
	    bd:=round(distance(x,y,mines[i].x,mines[i].y)) - mines[i].radius;
	 end;
      end;
   end;
end; { nearestMines }

function nearestWebMines(x,y : integer):word;
var i : word; {loop counter}
   bd : integer; { best distance}
   ew : word; {enemy world}
   en : boolean; {current minefield belongs to a enemy (based on dipstate)}
   fe : boolean; {found a minefield that belongs to a dipstate enemy}
begin
   bd:=1000;
   nearestWebMines:=101;
   if mcount=0 then exit;
   fe:=false;
   for i:=0 to (mcount-1) do
   begin
      if (mines[i].enemy and (mines[i].web)) then
      begin
	 ew := nearestEnemyWorld(mines[i].x,mines[i].y);
	 en:=false;
	 if (ew>0) then
	    if isEnemy(chart[ew].owner-10) then en:=true;
	 if ((round(distance(x,y,mines[i].x,mines[i].y) - mines[i].radius ) <= bd) and (en or not(fe))) then
	 begin
	    if en then fe:=true;
	    nearestWebMines:=i;
	    bd:=round(distance(x,y,mines[i].x,mines[i].y)) - mines[i].radius;
	 end;
      end;
   end;
end; { nearestWebMines }

procedure minesweep(sid : word; s: stateptr);
var
   field,w    : integer; {minefield we have found and world }
   wd,sd      : integer; {distance from planet or ship}
   bearing,sp : real;    {minefield direction finding}
   nx,ny      : real;    {target finding}
   m	      : Minefield; {current minefield}
begin
   with vessels[sid]^ do
   begin
      if not(shipready(s^.ctask,$4003)) then exit;
      if bcount<4 then exit;
      if (s^.task and $7)=0 then exit;
      if sTasks[5]>=sLimits[5] then exit;
      inc(sTasks[5]);
      {$ifdef d_ships}
      write('MS');
      {$endif}
      
      {find minefield}
      field := nearestMines(x,y);
      {if we have one sweep it}
      if field<101 then
      begin
	 speed:=eng;
	 if inMines(x,y)<101 then speed:=4;
	 mission:=2;
	 m := messages.mines[field];
	 bearing := calcBearing(m.x,m.y,x,y);
	 sp:= m.radius-1;
	 calcvector(bearing,sp,nx,ny);
	 nx := m.x + nx;
	 ny := m.y + ny;
	 {ok whick is closer to the location nx,ny the ship or a nearby planet}
	 w:= nearestOwnedWorld(round(nx),round(ny));
	 if w>0 then
	    wd := round(distance(nx,ny,chart[w].x,chart[w].y));
	 sd:=round(distance(x,y,nx,ny));
	 if sd>wd then
	 begin
	    s^.action := 1;
	    s^.target := w;
	 end
	 else
	 begin
	    dx := round(nx-x);
	    dy := round(ny-y);
	    s^.action:=0;
	 end;	 
	 s^.ctask:=$4003;
      end
      else
	 s^.ctask:=0;
      {check to see if we can get home!}
      w := nearestOwnedWorld(x,y);
      field := trunc(distance(x,y,chart[w].x,chart[w].y));
      field := fuelUsage(sid,field+(eng*eng),eng);
      if field+10>=fuel then
      begin
	 s^.action :=1;
	 s^.target:=w;
      end;
   end;
end;

end.