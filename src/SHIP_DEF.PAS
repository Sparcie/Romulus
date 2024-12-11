{AI for defensive type ships and minelayers}

unit ship_def;

interface
uses shiputil,map,RST,vector,shipstat,diplo,messages,planets,targdb;

   procedure MineLayer(sid : word; s:stateptr);
   procedure Defence(sid : word; s:stateptr);
   procedure DefReset;
   
implementation

   type
      zone    = record
		   pid	  : word; {planet at it's centre}
		   ships  : word; {ships that are in this area defending or minelaying}
		   radius : word; {radius of the minefield here (if there is one)}
		end;	  
      defense = record {struture that contains all the pertinent defense info}
		   zones  : array[1..100] of zone;
		   zcount : word;
		end;	  
      
      defptr  = ^defense;
   
   var   
      inited : boolean;
      data   : defptr;

  procedure addZone(z : zone);
  var i	: word;
     d	: integer;
  begin
     with data^ do
     begin
	if zcount=100 then exit;
	{check to see if this zone is too close or already exists}
	for i:= 1 to zcount do
	begin
	   if z.pid = zones[i].pid then exit;
	   d:= trunc(distance(chart[z.pid].x,chart[z.pid].y,chart[zones[i].pid].x,chart[zones[i].pid].y));
	   if d<min(70,max(zones[i].radius,36)) then exit;
	end;
	inc(zcount);
	zones[zcount]:=z;
	{$ifdef d_defence}
	 writeln(' Defence ',zcount, ' Pid ', z.pid, ' ships ',
		   z.ships, ' radius ', z.radius);
	{$endif}
     end;
  end; { addZone }

  function pickDefZone(x,y :integer) :word; {returns the planet id!}
  var
     i	  : word;
     bz	  : word;
     bsc  : word;
     d,bd : integer;
  begin
     with data^ do
     begin
	pickDefZone:=0;
	if zcount=0 then exit;
	{are we in a zone already?}
	bz:=0;
	bsc:=0;
	for i:=1 to zcount do
	begin
	   d:= trunc(distance(x,y,chart[zones[i].pid].x,chart[zones[i].pid].y));
	   if d<70 then
	   begin
	      bz := i;
	   end;
	   if zones[i].ships<bsc then
	      bsc := zones[i].ships;
	end;
	if (bz>0) then
	   if bsc>zones[bz].ships then
	   begin
	      inc(zones[i].ships);
	      pickDefZone:= zones[i].pid;
	      exit;
	   end;
	{find the best zone to go to (where the need is)}
	bz:=0;
	bsc:=100;
	bd:=9000;
	for i:= 1 to zcount do
	begin
	   d:= trunc(distance(x,y,chart[zones[i].pid].x,chart[zones[i].pid].y));
	   if zones[i].ships<bsc then
	   begin
	      bd:=d;
	      bz:=zones[i].pid;
	      bsc:=zones[i].ships;
	   end;
	   if ((d<bd) and (zones[i].ships<=bsc)) then
	   begin
	      bd:=d;
	      bz:=zones[i].pid;
	      bsc:=zones[i].ships;
	   end;	      
	end;
	pickDefZone:=bz;
	for i:= 1 to zcount do
	   if zones[i].pid=bz then inc(zones[i].ships);
     end;
  end;  

  function pickMineZone(x,y: integer) :word; {returns the planet id!}
  var
     i	 : word;
     bz	 : word;
     bsc : word;
     d,p : word;
  begin
     with data^ do
     begin
	pickMineZone:=0;
	if zcount=0 then exit;
	bz:=0;
	bsc:= 150;
	for i:= 1 to zcount do
	begin
	   p:= zones[i].pid;
	   d:= trunc(distance(x,y,chart[p].x,chart[p].y));
	   d:= (d div 16) + zones[i].radius;
	   if d<bsc then
	   begin
	      bz:=p;
	      bsc:=d;
	   end;
	end;
	pickMineZone:=bz;
	for i:= 1 to zcount do
	   if zones[i].pid=bz then zones[i].radius:=150;
     end;
  end; { pickMineZone }

  function continueMineZone(z : word):boolean;
  var i	: word;
  begin
     continueMineZone:=false;
     with data^ do
	for i:= 1 to zcount do
	   if ((zones[i].pid=z) and (zones[i].radius<65)) then
	      continueMineZone:=true;
  end; { flagMineZone }
   
  procedure flagMineZone(z : word);
  var i	: word;
  begin
     with data^ do
	for i:= 1 to zcount do
	   if zones[i].pid=z then zones[i].radius:=zones[i].radius+150;
  end; { flagMineZone }
   
  procedure init;
  var i	: word;
     z	: zone;
  begin
     if inited then exit;
     new(data);
     inited:=true;
     data^.zcount :=0;
     {add previous minefields ...}
     for i:= 1 to mcount do
	if not(mines[i].enemy) then
	begin
	   z.pid := nearestOwnedWorld(mines[i].x,mines[i].y);
	   z.ships:=0;
	   z.radius:= mines[i].radius;
	   addZone(z);
	end;
     {creating initial zones (enemies first)}
     for i:= 1 to dbCount do
	if isEnemy(dbTarg[i]^.owner) then
	begin
	   z.pid:= nearestOwnedWorld(dbtarg[i]^.x,dbtarg[i]^.y);
	   z.ships:=0;
	   z.radius:=0;
	   addZone(z);
	end;
     {creating initial zones (intended for war)}
     for i:= 1 to dbCount do
	if (not(isEnemy(dbTarg[i]^.owner)) and intendWar(dbTarg[i]^.owner)) then
	begin
	   z.pid:= nearestOwnedWorld(dbtarg[i]^.x,dbtarg[i]^.y);
	   z.ships:=0;
	   z.radius:=0;
	   addZone(z);
	end;
     {creating initial zones (everyone else)}
     for i:= 1 to dbCount do
	if (not(isEnemy(dbtarg[i]^.owner)) and not(intendWar(dbTarg[i]^.owner))) then
	begin
	   z.pid:= nearestOwnedWorld(dbTarg[i]^.x,dbTarg[i]^.y);
	   z.ships:=0;
	   z.radius:=0;
	   addZone(z);
	end;
     {important planets (humanoids)}
     for i:= 1 to nworlds do
     begin
	if worlds[i]^.nrace = 1 then
	begin
	   z.pid:= worlds[i]^.id;
	   z.ships:=0;
	   z.radius:=0;
	   addZone(z);
	end;
     end;
  end; { init }

  procedure DefReset;
  {$ifdef d_defence}
  var i	: integer;
  {$endif}
  begin
     if not(inited) then exit;
     {$ifdef d_defence}
     with data^ do
	for i:= 1 to zcount do
	   writeln(' Defence ',i, ' Pid ', zones[i].pid, ' ships ',
		   zones[i].ships, ' radius ', zones[i].radius);	     
     {$endif}
     dispose(data);
     inited:=false;
  end;
      
  procedure Defence(sid : word; s:stateptr);
   var
      i, c  : word;
      bd, d : word;
      bt, t : word;
   begin
      init;
      with vessels[sid]^ do
      begin
	 if not(shipReady(s^.ctask,$4000)) then exit;
	 if groupFull(id) then
	 begin
	    if s^.ctask = $4000 then s^.ctask:=0;
	    exit; {battle group leaders with a full group do not defend!}
	 end;
	 inc(stasks[3]);
	 if (stasks[3] > sLimits[3])then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 s^.ctask := $4000;
	 if (s^.task and $8>0) then s^.ctask:=0; {battleships will not stay in defence!}
	 {$ifdef d_ships}
	 write('DF');
	 {$endif}
	 {ok now we can perform our defence task!}
	 mission:=2; {mine sweep if we can}
	 bt:=pickDefZone(x,y);
	 
	 if ((bt=0) or (bt>500)) then  bt:=nearestBase(x,y);
	 s^.action:=1;
	 s^.target:=bt;
	 {ok now we need to check if there are any targets that need attacking!}
	 {anyone within 3 turns range!}
	 bd := (sqr(eng) * 3)+1;
	 for i:= 1 to targetCount do
	 begin
	    d:=trunc(distance(x,y,getTarget(i)^.x,getTarget(i)^.y));
	    if ((d<bd) and isEnemy(getTarget(i)^.owner))  then
	    begin
	       bd:=d;
	       s^.action := 4;
	       s^.target := getTarget(i)^.id;
	    end;
	 end;
      end;
   end;

   procedure MineLayer(sid : word; s:stateptr);
   var
      i,bd,c : word;
      d,t,bt  : word;
   begin
      init;
      with vessels[sid]^ do
      begin
	 if not(shipReady(s^.ctask,$100)) then exit;
	 if stasks[1]>sLimits[1] then
	    begin
	       s^.ctask:=0;
	       exit; {limit number of minelayers}
	    end;
	 if groupFull(id) then
	 begin
	    if s^.ctask = $100 then s^.ctask:=0;
	    exit; {battle group leaders with a full group do not minelay!}
	 end;
	 {$ifdef d_ships}
	 write('ML');
	 {$endif}
	 stasks[1]:=stasks[1]+1;
	 {ok find a target to lay mines at)}
	 if checkTaskWord(s^.task,$40) then {cloak if we can}
	 begin
	    mission:=10; {cloak!}
	    beamUpFuel(sid);
	 end;
	 if not(continueMineZone(s^.target)) then
	 begin
	    s^.action:=0;
	    s^.target:=0;
	    s^.ctask:=0;
	 end;
	 if ((fish=0) and (mission=3)) then mission:=1;
	 if (atplanet(x,y,s^.target)) then
	 begin	    
	    flagMineZone(s^.target);
	    s^.ctask:=$100;
	    mission:=3;
	    if player=7 then mission:= 9;
	    s^.target:=0;
	    s^.action:=0;
	    {$ifdef d_defence}
	    write('%');
	    {$endif}
	    exit;
	 end;
	 if ( not(s^.action=1) or not(s^.ctask=$100)) then
	 begin
	    {$ifdef d_defence}
	    write('#');
	    {$endif}
	    bt:=pickMineZone(x,y);
	    if bt=0 then
	    begin
	       s^.target :=nearestBase(x,y);
	       s^.action :=1;
	       s^.ctask:=0;
	       mission := 2;
	       {$ifdef d_defence}
	       write('*');
	       {$endif}
	       exit;
	    end;
	    s^.ctask:=$100;
	    s^.action:=1;
	    s^.target:=bt;
	    if mission=3 then mission:=1;	    
	 end;
	 if ((s^.ctask=$100) and (s^.action=1)) then
	    flagMineZone(s^.target);
      end;      
   end;

   begin
      inited:=false;
      
   end.