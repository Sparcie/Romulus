{ship AI ... this will be a large unit}
unit ships;

interface
uses RST,map,vector,shipstat,shipclas,hull,parts,planets,messages,diplo,shiputil,ship_def,ship_att,ship_fre,ship_swp;

   
procedure doShips;
procedure resetShips;

implementation

var
   fcount   : integer; {count of freighters currently}
   pdemands : word;
   colcount : integer; {count of colonist supply ships so far}
   
   procedure resetShips;
   var
      i	: word;
   begin
      for i:= 1 to nvessel do
	 dispose(vessels[i]);
      nvessel:=0;
      for i:=0 to 9 do
         hullsupply[i]:=0;
      DefReset;
      resetAttack;
      resetFreighters;
   end; { resetShips }


   procedure initState(sid : word; s:stateptr);
   var
      cl,tk : word;
   begin
      getShipClass(vessels[sid]^.hull,cl,tk);
      if ((s^.task = $FFFF) or not(s^.task=tk)) then
      begin
	 s^.task:=tk;
	 s^.ctask:=0;
	 s^.action:=0;
	 s^.owner:=0;
	 s^.age:=0;
      end;
   end;


   procedure FighterFactory(sid	: word; s :stateptr);
   var
      us,cs : Integer;
   begin     
      if not( player >8) then exit;
      if (s^.ctask = $4002 ) then exit;
      if ((vessels[sid]^.hull = shipclas.tanker(6)) and (stasks[4]<4)) then exit;
      {$ifdef d_ships}
      write('FF');
      {$endif}
      s^.ctask:=$10;
      with vessels[sid]^ do
      begin
	 cs:=hulls[hull].cargo;
	 us:= fish + colonists + tritanium + duranium + molybdenum +supplies;
	 if (cs-us)>9 then
	 begin	    
	    if not(player=10) then
	    begin
	       mission:=9;
	       tow:=11;
	    end;
	    fcode[1]:='l';
	    fcode[2]:='f';
	    fcode[3]:='m';
	    s^.action:=1;
	    s^.target:=nearestOwnedWorld(x,y);
	 end
	 else
	 begin
	    s^.action:=1;
	    cs:=fighterDemand;
	    if not(cs=0) then
	       s^.target:=cs;
	 end;
      end;
   end;

   procedure shipMaintenance(sid : word; s:stateptr);
   var
      cs,us : word;
      bb,nb : word;
   begin
      with vessels[sid]^ do
      begin
	 {ok we check if we have damage}
	 {is we are a freighter we leave}
	 cs := hulls[hull].cargo;
	 us := colonists + supplies + tritanium + duranium + molybdenum;
	 cs:=cs-us;
	 if s^.task=0 then exit;
	 if (damage>0) then
	 begin
	    nb:= nearestBase(x,y);
	    s^.ctask := $1000;
	    s^.action :=1;
	    s^.target:=nb;
	    if damage>50 then
	    begin
	       mission:=15;
	       unload(sid,nearestOwnedWorld(x,y));
	    end
	    else
	    begin
	       mission:=5;
	    end;
	 end;
	 {if we are repaired unload extra supplies and move on}
	 if ((damage=0) and (s^.ctask = $1000)) then
	 begin
	    unload(sid,nearestOwnedWorld(x,y));
	    mission:=5;
	    s^.ctask:=0; {allow to begin new activity}
	 end;
	 if s^.ctask=$1000 then
	 begin
	    {$ifdef d_ships}
	    write('Rp');
	    {$endif}
	    {Borg repair ship race advantage!}
	    if ((player=6) and (damage>0)) then
	    begin
	       speed:=0;
	       mission:=9;
	       if tow>0 then tow:=0;
	       if intercept>0 then intercept:=0;
	    end;

	    exit;
	 end;
	 {do not load ordinance on tankers!}
	 if (hull=shipclas.tanker(6)) then exit;
	 {factory ships already build ordinance}
	 if checkTaskWord(s^.task,$10) then exit;
	 if ((fish=0) and (mission=3)) then mission:=1;
	 if ((s^.ctask=$2000) and (fish>= min(loadout(hull),cs))) then
	    s^.ctask:=0;
	 if (isCarrier(hull) and (fish<min(loadout(hull) - (fbays*3),cs) ) )
	    then
	 begin
	    unload(sid,nearestOwnedWorld(x,y));
	    bb:= bestBase(x,y,1);
	    nb:= nearestBase(x,y);
	    s^.ctask := $2000;
	    s^.action :=1;
	    s^.target:=bb;
	    if s^.target=0 then
	       s^.target:= nb;
	    if ((player>8) and (cs>9)) then
	    begin
	       if not(player=10) then
		  mission:=9;
	       fcode[1]:='l';
	       fcode[2]:='f';
	       fcode[3]:='m';
	       {go to the best place to build fighters}
	       
	       if fish=0 then
		  begin
		     s^.target:=bb;
		     if s^.target=0 then
			s^.target:= nb;
		  end;
	    end;
	 end;
	 if (not(iscarrier(hull))
	     and (fish<min(loadout(hull) div 2 ,cs)) and (torp>0)) then
	 begin
	    unload(sid,nearestOwnedWorld(x,y));
	    bb:= bestBase(x,y,torps[torp].tech);
	    nb:= nearestBase(x,y);
	    mission:=2;
	    s^.ctask := $2000;
	    s^.action :=1;
	    s^.target:=bb;
	    if s^.target=0 then
	       s^.target:= nb;
	 end;
	 {$ifdef d_ships}
	 if (((s^.ctask and $3000)>0) and not(s^.ctask=$2001))
	    then write('LO');
	 {$endif}
      end;
   end;

   procedure AlchemyShip(sid : word; s:stateptr);
   begin
      if s^.ctask=$4004 then exit;
      s^.ctask:=$200;{alchemy ships only do this}
      {$ifdef d_ships}
      write('AL');
      {$endif}
      with vessels[sid]^ do
      begin
	 mission:=15;
	 if ((s^.action=0) or not(atPlanet(x,y,nearestOwnedWorld(x,y)))) then
	    begin
	       s^.action:=1;
	       s^.target:=nearestBase(x,y);
	    end;
	 if (atPlanet(x,y,s^.target)) then unload(sid,s^.target);
      end;
   end; { AlchemyShip }

   procedure RefineryShip(sid : word; s:stateptr);
   var
      i : integer ;
      l : integer;
   begin
      if s^.ctask=$4004 then exit;
      s^.ctask:=$400;
      {$ifdef d_ships}
      write('RF');
      {$endif}
      with vessels[sid]^ do
      begin
	 mission:=2;
	 if ((s^.action=0) or not(atPlanet(x,y,nearestOwnedWorld(x,y)))
	     or not(atPlanet(x,y,s^.target))) then
	    begin
	       s^.action:=1;
	       s^.target:=nearestBase(x,y);
	    end;
	 {find planet with the same id as our target and load the ship}
	 i:= findPlanet(s^.target);
         if i=0 then
         begin
            s^.action:=1;
            s^.target:=nearestBase(x,y);
         end;
	 if ((worlds[i]^.id=s^.target) and (worlds[i]^.owner=player) and
	     atplanet(x,y,s^.target)) then
	 begin
	    unload(sid,s^.target);
	    l:=60;
	    if (worlds[i]^.supplies-100)<maxint then
	       l:=min(worlds[i]^.supplies-100,60);
	    if ((worlds[i]^.tmined>2000) and (worlds[i]^.Dmined>2000) and (worlds[i]^.Mmined>2000) and (l>10)) then
	    begin
	       if worlds[i]^.supplies<maxint then
		  l:=worlds[i]^.supplies-10
	       else
		  l:=10000;
	       l:=min(l,300);
	    end;
	    if l<0 then l:=0;
	    worlds[i]^.supplies:=worlds[i]^.supplies -l;
	    supplies:=supplies+l;
	    l:=l div 3;
	    if (worlds[i]^.Tmined>1500) then
	    begin
	       worlds[i]^.Tmined:=worlds[i]^.Tmined -l;
	       tritanium:=tritanium+l;
	    end;
	    if (worlds[i]^.Dmined >1500) then
	    begin
	       worlds[i]^.Dmined:=worlds[i]^.Dmined -l;
	       duranium:=duranium+l;
	    end;
	    if (worlds[i]^.Mmined >1200) then
	    begin
	       worlds[i]^.Mmined:=worlds[i]^.Mmined -l;
	       molybdenum:=molybdenum+l;
	    end;
	    l:= fuel-1;
	    if l>0 then
	    begin
	       worlds[i]^.NMined:=worlds[i]^.NMined+l;
	       fuel:=fuel-l;
	    end;
	 end;
      end;
   end; { RefineryShip }

   procedure dohullSupply(task,hull : word);
   var sc : word;
   begin
      sc:= getSupplyCode(hull);
      if not(sc=10) then inc(hullsupply[sc]);
   end; { dohullSupply }    


   {check to see if we are in a minefield and are not deliberately trying to
     sweep it}
   procedure mines(sid : word; s:stateptr);
   var
      field : word;
      m	    : MineField;
   begin
      with vessels[sid]^ do
      begin
	 if s^.ctask = $4003 then exit; {if we are using the standard minesweep then we don't need this!}
	 field := inMines(x,y);
         if field<101 then
	    if ((mission = 10) and not(messages.mines[field].web) and (damage=0)) then exit;
         if ((mission=10) and (field=101)) then exit;
	 {cloaking ships do not minesweep except in webmines!}
	 if field = 101 then
	 begin
	    field:= inMines(x+dx,y+dy);
	 end;
	 if (s^.ctask = $400) then exit;
	 if (s^.ctask = $200) then exit;
	 if field = 101 then exit;
	 {ok we have a field and now we need to find where to go!}
	 m := messages.mines[field];
	 mission := 2; {mine sweep mission}
	 if m.web=false then
	 begin {not a web minefield! slow down - and keep going!}
	    speed:=4; {slow down!}
	 end
	 else
	 begin {web minefield! - we may make some better code to sweep}
	    s^.action:=1;
	    s^.target:=nearestOwnedWorld(x,y);
	    speed:=2;
	    beamUpFuel(sid);
	 end;	 
	 {$ifdef d_ships}
	 write('ms');
	 {$endif}
      end;
   end;

   procedure IonStorm(sid : word; s:stateptr);
   var
      storm  : word;
      is     : messages.IonStorm;
      d	     : integer; {distance from centre}
      ed,nd  : integer; {distance from edge -ve it outside the storm}
      hed,sp : real; {variables for calculating headings}
      nx,ny  : real;
   begin
      with vessels[sid]^ do
      begin
	 storm := inStorm(x,y);
	 if ((storm=21) and not(s^.ctask=$4004)) then exit;
	 if ((storm=21) and (s^.action=3)) then
	 begin
	    if s^.ctask=$4004 then s^.ctask:=0;
	    exit;
	 end;
	 {$ifdef d_ships}
	 write('IS');
	 {$endif}
	 ed:=0;
	 if storm<21 then
	 begin
	    is := storms[storm];	       
	    s^.ctask := $4004;
	    s^.action:=8;
	    mission:= 11; {beam up fuel}
	    {ok we are in the radius of a storm move out!}
	    d := trunc(distance(x,y,is.x,is.y));
	    ed := is.radius - d;
	 end;
	 if ed>0 then {we are in the storm}
	 begin
	    speed:=eng;
	    if  (ed<(3*sqr(speed)))  then
	    begin {we are close to the edge}
	       hed:=is.heading+90;
	       sp:=sqr(speed);
	       if hed>360 then hed:=hed-360;
	       if hed<0 then hed:=hed+360;
	       {ok work out if we would be closer or further!}
	       calcvector(hed,sp,nx,ny);
	       ny:=ny*-1; {invert the y because tim made it upside down compared to me}
	       nd := trunc(distance(x+nx,x+ny,is.x,is.y));
	       if nd<d then
	       begin {the other direction is further away}
		  hed:=hed-90;
		  if hed>360 then hed:=hed-360;
		  if hed<0 then hed:=hed+360;
	       end;
	       {ok now we can work out a waypoint and get there}
               sp:=sp+6;
	       calcvector(hed,sp,nx,ny);
	       dx := trunc(nx);
	       dy := trunc(ny*-1);
	    end
	    else
	    begin
	       {we are deep in it! it must be a big one! go against the storm as hard as we can!}
	       speed:=eng;
	       sp:=sqr(speed);
	       hed:=is.heading+180;
	       if hed>360 then hed:=hed-360;
	       if hed<0 then hed:=hed+360;
               sp:=sp+6;
	       calcvector(hed,sp,nx,ny);
	       dx := trunc(nx);
	       dy := trunc(ny*-1);
	    end;
	    {$ifdef d_ships}
	    write('d(',dx,',',dy,')');
	    {$endif}
	 end;
	 if ((ed<=0) and (s^.action=7)) then
	 begin {we are out of the storm but we can't reach a home!}
	    {get as close as we can to it!}
	    if (fuelUsage(sid,eng*eng,eng)<fuel) then
	       speed:=eng
	    else
	       speed:=0;
	    if ((dx=0) and (dy=0)) then s^.action:=0;
	 end;
	 if ((ed<=0) and not(s^.action=7)) then
	 begin {we are on the edge or out of the storm! head to a world for fuel}
	    s^.action:=1; {lets hope we don't end up back in the storm!}
	    s^.target:=nearestOwnedWorld(x,y);
	    speed:=eng;
	 end;
	 {beam up fuel if we can!}
	 emergBeamUpFuel(sid);
      end;
   end; { IonStorm }

   procedure teraformer(sid : word; s:stateptr);
   var
      tt,i   : integer;
      td,wtd : integer;
      p	     : word;
   begin
      with vessels[sid]^ do
	 begin
	    if not(shipready(s^.ctask,$80)) then exit;
	    if not(isTeraformer(hull)) then exit;
	    if stasks[2]>6 then exit;
	    {$ifdef d_ships}
	    write('TF');
	    {$endif}
	    stasks[2] := stasks[2]+1;
	    s^.ctask:=$80;
	    tt:=50;
	    if player=7 then tt:=100;
	    wtd:=0;
	    {Are we at a world that needs changing and if so wait until it's
	    done}
	    wtd:= nearestOwnedWorld(x,y);
	    if atPlanet(x,y,wtd) then
	    begin
	       for i:= 1 to nworlds do
		  if worlds[i]^.id = wtd then
		  begin
		     td := tt - (100-worlds[i]^.temp);
		     if hull = 8 then td :=(100-worlds[i]^.temp) - tt;
		     if td > 10 then
			begin
			   s^.action:=1;
			   s^.target:=wtd;
			   exit;
			end;
		  end;
	    end;
	    
	    {find a new world to go to!}
	    wtd:=0;
            for i:= 1 to nworlds do
	    begin
	       p:=worlds[i]^.id;
	       td := tt - (100-worlds[i]^.temp);
	       if hull = 8 then td :=(100-worlds[i]^.temp) - tt;
	       if td>wtd then
	       begin
		  wtd:=td;
		  s^.action:=1;
		  s^.target:=p;
	       end;	       
	    end;
	    if wtd=0 then s^.ctask:=0;
	 end;
   end; { teraformer }

   procedure warFreighter(sid : word; s:stateptr);
   var
      us : word;
   begin
      if targetCount=0 then
      begin {no targets! act like a colony freighter!}
	 {$ifdef d_ships}
	 write('WF');
	 {$endif}
	 colonyFreighter(sid,s);
	 s^.ctask:=9;
	 exit;
      end;
      {we have targets! we need to ditch any load we are carrying and go back
      on duty!}
      with vessels[sid]^ do
      begin
	 us := colonists + supplies + tritanium + duranium + molybdenum;
	 if us>0 then
	 begin
	    s^.action:=1;
	    s^.target:=nearestOwnedWorld(x,y);
	    if atPlanet(x,y,s^.target) then unload(sid,s^.target);
	 end;
	 if (us=0) then
	    s^.ctask:=0;
      end;
   end; { warFreighter }

   procedure BattleGroup(sid : word; s:stateptr);
   var
      g	: groupptr;
   begin
      if not(shipready(s^.ctask,$2001)) then exit;
      {$ifdef d_ships}
      write('BG');
      {$endif}
      {disband groups this ship may be leading (only if they are empty!)}
      if not(getGroup(vessels[sid]^.id)=nil) then
      begin
	 g:= getGroup(vessels[sid]^.id);
	 if g^.size>0 then exit;
	 g^.target:=0;
      end;
      if not( (s^.action=6) and not(getGroup(s^.target)=nil)) then
      begin {assign a ship to a battle group}
	 g:= getRallyGroup;
	 if g=nil then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 g^.size:=g^.size+1;
	 g^.ships[g^.size]:= vessels[sid]^.id;
	 s^.action:=6;
	 s^.target:=g^.target;
	 s^.ctask:=$2001;
      end;
      {the actual copying of the ship commands occurs after all other ships
      have moved!}
   end; { BattleGroup }

   function syncShip(g	: groupptr; ts:word; cs:word):boolean;
   var
      si : word; {current ship index into vessel array}
      ss : stateptr; {current ship state ptr}
      i	 : word; {loop counter}
   begin
      syncShip:=false;
      si:=0;
      for i:= 1 to nvessel do
	 if vessels[i]^.id=cs then si:=i;
      ss:= getState(cs);
      if ((si=0) or not(ss^.ctask=$2001)) then exit;
      if not(ss^.target= vessels[ts]^.id) then
      begin
	 ss^.ctask:=0;
	 exit;
      end;
      syncShip:=true;
      {ok we are ready to send the ship off!}
      with vessels[si]^ do
      begin
	 setWaypointS(x,y,dx,dy,ss^.target);
	 speed:= eng;
	 if ( atShip(x,y,ss^.target)) then
	 begin {we are at the ship!}
	    {copy the target ships waypoint and mission! }
	    inc(g^.ships[10]);
	    g^.ships[9] := g^.ships[9] + getFirepower(hull);
	    if (isCarrier(hull) or ((ss^.task and $8)>0)) then inc(g^.ships[9]);
	    dx := vessels[ts]^.dx;
	    dy := vessels[ts]^.dy;
	    enemy:= vessels[ts]^.enemy;
	    mission:= vessels[ts]^.mission;
	    intercept:= vessels[ts]^.intercept;
	    speed:= vessels[ts]^.speed;
	    if ((mission=10) and not(isCloaker(hull))) then
		mission:=2;
	 end;
         {$ifdef d_ships}
         write('(d ',dx,',',dy,')');
         {$endif}
      end;
      BeamUpFuel(si);
      fuelCheck(si,ss);
   end;

   procedure runBattleGroups;
   var
      i,c : word; {loop counters}
      ts  : word; {target ship}
      g	  : groupptr; {current group}
   begin
      Writeln('Running Battle groups...');
      for i:= 1 to gcount do
      begin
	 write('.');
	 g:= @(battlegroups^[i]);
	 if g^.target>0 then
	 begin {ok now we can run a group!}
	    {$ifdef d_ships}
	    write('(',g^.size,')');
	    {$endif}
	    g^.ships[10]:=0;
	    g^.ships[9]:=0;
	    ts:=0;
	    for c:= 1 to nvessel do
	       if vessels[c]^.id=g^.target then ts:=c;
	    if ts>0 then
	    begin {ok we have found our target ship}
	       g^.ships[9]:= getFirepower(vessels[ts]^.hull);
               c:=1;
	       while ( (c<(g^.size+1)) and (c>0)) do
               begin
		  if not(syncShip(g,ts,g^.ships[c])) then
		  begin {ship is not in the battle group!}
		     g^.ships[c]:= g^.ships[g^.size];
		     g^.size:=g^.size-1;
		     c:=c-1;
		  end;
                  c:=c+1;
               end;
	    end
	    else {ship not found!}
	       g^.target:=0;
	 end;
      end;
      writeln;
   end; { runBattleGroups }

   procedure stopped(sid : word; s:stateptr);
   begin
      with vessels[sid]^ do
      begin
	 if s^.ctask=0 then defence(sid,s);
	 if s^.ctask=0 then mineSweep(sid,s);
	 if s^.ctask=0 then
	 begin
	    {$ifdef d_ships} write('rd'); {$endif}
	    s^.target:=nearestOwnedWorld(x,y);
	    s^.action:=1;
	 end;        
      end;
   end;

   procedure doShips;
   var
      i,c : word;
      ss  : stateptr;
      t	  : target;
      rfc : boolean; {reset fcodes}
      nfc : string[3]; {new fcode}
   begin
      rfc:=false;
      if random(100)>60 then rfc:=true;
      pdemands:=nworlds div 10;
      colcount:=0;
      fcount:=0;
      writeln('checking target ships...');
      for i:= 1 to targetCount do
      begin
	 t:= getTarget(i)^;
	 if t.owner<12 then
	    for c:= 1 to 500 do
	       if ((distance(t.x,t.y,chart[c].x,chart[c].y) < int(sqr(t.speed)+1)) and
		   not(chart[c].owner=1)) then chart[c].owner:=t.owner+10;
      end;
      writeln('operating ships...');
      c:= shipCount;
      maxfp:=0;
      {make copy of ships}
      for i:=1 to c do
      begin
	 new(vessels[i]);
	 vessels[i]^ := getShip(i)^;
	 if getFirePower(vessels[i]^.hull) > maxfp then maxfp:=getFirePower(vessels[i]^.hull);
      end;
      nvessel := c;
      {init supply,mines and special tasks}
      for i:=0 to 9 do
	 hullsupply[i]:=0;
      for i:=0 to 6 do
	 stasks[i]:=0;
      
      {ok now we have copied the ships over now we process them}
      for i:= 1 to nvessel do
	 with vessels[i]^ do
	 begin
	    write('.');
	    ss := getState(id);
	    initstate(i,ss);
	    checkActions(i,ss);
	    doHullSupply(ss^.task,hull);	    
	    {check the Fcode }
	    nfc := getCombatFcode(hull);
	    if (not(nfc[1] = fcode[1]) or rfc) then
	    begin
	       fcode[1] := nfc[1];
	       fcode[2] := nfc[2];
	       fcode[3] := nfc[3];
	    end;

	    {Basic check for enemies - set primary enemy if we are a warship and there is someone very
	    close. do not do this if we are cloaked!}
	    enemy:=0;
	    if (not(mission = 10) and (bcount>0)) then
	    begin
	       for c:= 1 to targetCount do
	       begin
		  t:= getTarget(c)^;
		  if ((trunc(distance(x,y,t.x,t.y)) < (sqr(speed)*2)+1)
		      and (isEnemy(t.owner))) then enemy := t.owner;
	       end;
	    end;
        
	    {**** state stuff for the brains of the ship}
	    {need to put in race modifiers somehow for now all the same order}
	    {non warships and general tasks}
	    shipMaintenance(i,ss);
	    tanker(i,ss); {for ships that are tankers}
	    if checkTaskWord(ss^.task,$80) then teraformer(i,ss);
	    if ss^.task = 0 then freighterC(i,ss);
	    if checkTaskWord(ss^.task,$10) then fighterFactory(i,ss);
	    if checkTaskWord(ss^.task,$200) then alchemyShip(i,ss);
	    if checkTaskWord(ss^.task,$400) then refineryShip(i,ss);

	    {small ships transport money if no ships are doing it}
	    if stasks[6]<2 then
	    begin
	       if (checkTaskWord(ss^.task,$1) and shipReady(ss^.ctask,$9))
		  then moneyTransport(i,ss);
	    end;
	    
	    {special war operations (transports, minelayers, other special ships)}
	    if (checkTaskWord(ss^.task,$20) and (player=2)) then
	       transport(i,ss);
	    if (checkTaskWord(ss^.task,$100)) then minelayer(i,ss);
	    if (checkTaskWord(ss^.task,$20) and not(player=2)) then
	       transport(i,ss);
	    
	    {warships}
	    battleGroup(i,ss);
	    if checkTaskWord(ss^.task,$8) then BattleShip(i,ss);
	    if checkTaskWord(ss^.task,$4) then BattleCruiser(i,ss);
	    if checkTaskWord(ss^.task,$2) then medWarship(i,ss);
	    if checkTaskWord(ss^.task,$1) then smallWarship(i,ss);
	    Defence(i,ss); {set ships for defence!, there is a limit!}
	    mineSweep(i,ss); {minesweep (deliberate sweeping and web sweeping)}
		
	    {check for storms and minefields}
	    mines(i,ss);
	    IonStorm(i,ss);

	    {if after all this we still have nothing to do, and no enemies
	    we participate in freight}
	    if (shipReady(ss^.ctask,$9) and (ss^.task>0)) then
	    begin
	       warFreighter(i,ss);
	    end;
	    
	    {final action check}
	    checkActions(i,ss);
	    
	    if ss^.action = 7 then
	    begin {if for some reason we can't get there become defence!}
	       {$ifdef d_ships}
	       write('X');
	       {$endif}
	       stopped(i,ss);
	       checkActions(i,ss);
	    end;
	    {turn off the borg repair if we are fixed!}
	    if ((player=6) and (mission=9) and (damage=0)) then mission:=1;

	    {check if the ship has been doing nothing (going nowhere) for 5 turns}
	    {only if it isn't defending, ionstorm, alchemy or a factory ship}
	    if ( ( ((dx=0) and (dy=0)) or (speed=0) )
		and not(ss^.ctask=$4004) and not(ss^.ctask=$4003)
		and not(ss^.ctask=$200) and not(ss^.ctask=$400)
		and not(ss^.ctask=$10) and not(ss^.ctask=$2001)
		and not(ss^.ctask=$4002) and not(ss^.ctask=9)) then
	    begin
	       ss^.owner:=ss^.owner+1;
	       if ss^.owner=5 then
	       begin
		  ss^.ctask:=0;
		  {$ifdef d_ships}
		  write('@');
		  {$endif}
	       end;
	    end
	    else
	       if not(ss^.ctask=9) then
		  ss^.owner:=0;
	    
	    {$ifdef d_ships}
	    write('(',ss^.task,',',ss^.ctask,',',ss^.action,',',ss^.target,')');
	    {$endif}
	 end;
         writeln;

      {run battle groups!}
      runBattleGroups;
       
      {check freighter colonising markers}
      c:=0;
      for i:= 1 to 500 do
	 if chart[i].owner = 2 then inc(c);

      if c>(hullsupply[0] div 2) then
      begin
	 for i:= 1 to 500 do
	    if chart[i].owner = 2 then chart[i].owner:=0;

	 for i:= 1 to nvessel do
	    with vessels[i]^ do
	    begin
	       ss := getState(id);
               if ((ss^.target>0) and (ss^.target<501)) then
		  if ((ss^.ctask=$9) and (chart[ss^.target].owner=0)) then
		   chart[ss^.target].owner:=2;
	    end;
      end;

{$ifdef d_ships}
      {write out our hull supply (debug)}
      write('hs');
      for i:=0 to 9 do
      begin
	 write(',');
	 write(hullsupply[i]);
      end;
      writeln;
{$endif}
   end; { doShips }

begin
   nvessel:=0;
end.