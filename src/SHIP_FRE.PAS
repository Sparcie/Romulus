{ freighter unit for romulus }
{A Danson 2010}

unit ship_fre;


interface
uses shiputil,planets,shipstat,hull,map,vector,RST,empire;


   procedure freighterC(sid : word; s:stateptr);
   procedure moneyTransport(sid : word; s:stateptr);
   procedure colonyFreighter(sid : word; s:stateptr);
   procedure migrationFreighter(sid : word; s:stateptr);
   procedure supplyFreighter(sid : word; s:stateptr);
   procedure resetFreighters;
   procedure tanker(sid	: word; s:stateptr);
   procedure RescueShip(sid : word; s :stateptr);
	 
implementation

   var
      rescue   : array[1..6] of word;
      rcount   : word;
      colcount : integer; {counts of different types of ships in units (100 cargo units min of 1)}
      supcount : integer;
      migcount : integer;
      totcount : integer; {total freight units}

	 procedure resetFreighters;
	 begin
	    colcount:=0;
	    supcount:=0;
	    migcount:=0;
	    totcount:=0;
	    rcount:=0;
	 end;

   procedure moneyTransport(sid : word; s:stateptr);
   var
      i,l   : integer;
   begin
      with vessels[sid]^ do
      begin
	 {$ifdef d_ships}
	 write('MT');
	 {$endif}
	 inc(stasks[6]);
	 s^.ctask:=9;
	 if (money=0) then
	 begin
	    if not((s^.action=3) or (s^.action=1)) then
	    begin
	       s^.action:=1;
	       s^.target:= moneySupply;
	       if s^.target=0 then
		  s^.ctask:=0;
	       exit;
	    end;
	    if (s^.action=3) then
	    begin
	       shiputil.load(sid,s^.target);
	       s^.action:=1;
	       s^.target:=moneyDemand;
	       {$ifdef d_ships}
	       write('^');
	       {$endif}
	       if s^.target=0 then
		  s^.ctask:=0;
	       exit;
	    end;
	 end;
	 if money>0 then
	 begin
	    if not((s^.action=3) or (s^.action=1)) then
	    begin
	       s^.action:=1;
	       s^.target:= moneyDemand;
	       if s^.target=0 then
		  s^.ctask:=0;
	       exit;
	    end;
	    if (s^.action=3) then
	    begin
	       unload(sid,s^.target);
	       s^.action:=1;
	       s^.target:=moneySupply;
	       {$ifdef d_ships}
	       write('$');
	       {$endif}
	       if s^.target=0 then
		  s^.ctask:=0;
	       exit;
	    end;
	 end;
      end;
   end; { moneyTransport }
   
   {freighter for colonising worlds}
   procedure colonyFreighter(sid : word; s:stateptr);
   var
      cs,us : integer;
      i,l   : integer;
      uc,ns : integer; {how many supplies/colonists to unload}
   begin 
      with vessels[sid]^ do
      begin
	 cs := hulls[hull].cargo - fish;
	 if cs=0 then exit;
	 us := colonists + supplies + tritanium + duranium + molybdenum;
	 {$ifdef d_ships}
	 write('FC');
	 {$endif}
	 if (player=6) then
	 begin {we are borg! we must check if we are at a planet with a base!}
	    {$ifdef d_ships}
	    write('b');
	    {$endif}
	    i:= nearestOwnedWorld(x,y);
	    l:= nearestBase(x,y);
	    if (not(i=l) and atPlanet(x,y,i)) then
	    begin {we are at a world without a starbase that we own!!}
	       {is it humanoid?!}
	       i:=findPlanet(i);
	       if ((worlds[i]^.nrace=1) and (worlds[i]^.colonists>1)) then
	       begin {this is a humanoid without a starbase!}
		  l:= worlds[i]^.colonists - 1;
		  l:= min(l,cs-us);
		  {ok now beam up some colonists!}
		  worlds[i]^.colonists:=worlds[i]^.colonists-l;
		  colonists:=colonists+l;
		  s^.action:=0;
		  speed:=0;
		  exit;
	       end
	       else
		  if ((colonists=0) or (supplies=0)) then
		  begin
		     s^.action:=0;
		     s^.owner:=0;
		     s^.target:=0;
		  end;
	    end;
	 end;	       
	 if ((s^.action=0)) then
	 begin {find and go to a supply world}
	    s^.owner:=1;
	    s^.target := nearestColonySupply(x,y);
	    if not(atPlanet(x,y,s^.target)) then
	       s^.action:=1;
	    if atPlanet(x,y,s^.target) then
	       s^.action:=3;
	    exit;
	 end;
	 if ((s^.action=3) and (us=0) and atPlanet(x,y,s^.target)) then
	 begin {load up ship}
	    {calculate the number of items to load}
	    unload(sid,s^.target);
	    if not(player=6) then loadColonists(sid,s^.target,(cs div 2 ));
	    if (player=6) then loadColonists(sid,s^.target,(cs div 15));
	    s^.action := 1; {make sure we are at a colony supply world}
	    s^.target := nearestColonySupply(x,y);
	    if ((colonists>0) and (supplies>4)) then
	    begin
	       s^.target := nearestUnownedWorld(x,y); {set colonise target}
	       s^.action := 1;
	       s^.owner := 1;
	       if s^.target>0 then
		  chart[s^.target].owner := 2; {mark as going to colonise}
	    end;
	    exit;
	 end;	       
	 if ((s^.action=3) and (us>0) and atPlanet(x,y,s^.target)) then
	 begin {at new world! check that and beam down colonists.}
	    {decide on the amount to beam down}
	    ns:=50;
	    uc:=50;
	    i:= findplanet(s^.target);
            if i>0 then
	      i:= planetUtility(worlds[i]);
	    if i=0 then
	    begin
	       ns:=25;
	       uc:=25;
	    end;
	    if i=1 then
	    begin
	       ns:=50;
	       uc:=50;
	    end;
	    if i=2 then
	    begin
	       ns:=100;
	       uc:=100;
	    end;
	    if i=3 then
	    begin
	       ns := supplies;
	       uc := colonists;
	    end;
	    if player =6 then
	    begin
	       ns:=14;
	       uc:=1;
	    end;
	    ns:= min(ns,supplies);
	    uc:= min(uc,colonists);
	    {unload!}
	    unloadtoP[7] := s^.target;
	    unloadtoP[6] := ns;
	    unloadtoP[5] := uc;
	    {chart[s^.target].owner := 0; mark as not doing anything!}
	    supplies:= supplies-ns;
	    colonists:= colonists-uc;
	    {if we have cargo left}
	    if ((colonists>0) and (supplies>4)) then
	    begin
	       s^.target := nearestUnownedWorld(x,y); {set colonise target}
	       s^.action := 1;
	       if s^.target>0 then
		  chart[s^.target].owner := 2; {mark as going to colonise}
	       exit;
	    end;
	    if not(player=6) then
	    begin
	       s^.action :=0;
	       s^.owner:=0;
	       s^.target:=0;
	    end
	    else
	    begin
	       s^.action:=0;
	    end;
	    exit;
	 end;
	 if (s^.action=7) then
	 begin {catch a cannot do or not doing anything}
	    s^.action:=1;
	    if s^.target>0 then
	       if not(chart[s^.target].owner=1) then
		  chart[s^.target].owner := 0;
	    s^.target := nearestColonySupply(x,y);
	 end;	 	 
      end;
   end; { colonyFreighter }
   

   {freighter for moving around colonists and supplies}
   procedure migrationFreighter(sid : word; s:stateptr);
   var
      cs,us : integer;
      i,l   : integer;
      cd    : integer;
   begin 
      with vessels[sid]^ do
      begin
	 cd:=colonydemand;
	 if cd=0 then supplyFreighter(sid,s);
	 cs := hulls[hull].cargo - fish;
	 if cs=0 then exit;
	 us := colonists + supplies + tritanium + duranium + molybdenum;
	 {deal with loading/unloading colonists demand first!}
	 if ((colonists=0) or (supplies=0))  then
	 begin {find and go to a supply world}
	    s^.target := nearestColonySupply(x,y);
	    s^.owner:=3;
	    if not(atPlanet(x,y,s^.target)) then
	       s^.action:=1;
	    if ((s^.action=3) or atPlanet(x,y,s^.target)) then
	    begin {load up ship}
	       cs := (cs - us) div 2; {calculate the number of items to load}
	       s^.action:=0;
	       unload(sid,s^.target);
	       loadColonists(sid,s^.target,cs);
	       s^.target := cd;
	       s^.action := 1;
	    end;
	 end;
	 if  ((s^.action=3) and (us>0))  then
	 begin {at world! check that and beam down colonists.}
	    unload(sid,s^.target);
	    s^.target:=0;
	    s^.owner:=0;
	    s^.action:=0;
	 end;
      end;
   end; { migrationFreighter }

   procedure supplyFreighter(sid : word; s:stateptr);
   var
      cs,us : integer;
      i,l   : integer;
   begin
      with vessels[sid]^ do
      begin
	 cs := hulls[hull].cargo - fish;
	 if cs=0 then exit;
	 us := colonists + supplies + tritanium + duranium + molybdenum;
	 if ((us=0) and
	     (not(atPlanet(x,y,s^.target)) or (s^.action=0)))
	    then
	 begin {go to a supply world}
	    s^.action:=1;
	    s^.target:=bestSupply;
	    s^.owner := 2;
	 end;
	 if (((us>supplies) or (us=cs)) and not(s^.action=3)) then
	 begin
	    s^.action:=1;
	    s^.target:=bestDelivery(x,y,tritanium,duranium,molybdenum,supplies);
	 end;
	 if ((us=0) and ((s^.action=3) or atPlanet(x,y,s^.target)))
	    then
	 begin {we have arrived at a supply}
	    shiputil.load(sid,s^.target);
	    us := colonists + supplies + tritanium + duranium + molybdenum;
	    s^.action:=1;
	    s^.target:=biggestDemand;
	 end;
	 if ((us>0) and atPlanet(x,y,s^.target) and (s^.action=3) ) then
	 begin {we have a full load and have arrived}
	    unload(sid,s^.target);
	    s^.action:=0;
	    us:=0;
	    s^.owner:=0;
	    s^.target:=0;
	 end;
      end;
   end; { supplyFreighter }

   {procedure which decides which type of freighter a ship should be}
   { and sets task words etc}
   procedure freighterC(sid: word; s:stateptr);
   var
      i,l     : word;
      cs      : word; {cargo space and used space}
      cu      : integer; {cargo units }
      targcol : integer; {target colonists units}
      targsup : integer; {target supply units}
      targmig : integer; {target migration units}

   begin
      {ships that are freighters can't do anything else so we don't
      check for other tasks}
      if ((s^.ctask=$4002) or (vessels[sid]^.hull=shipclas.tanker(6))) then exit; {its a tanker}
      s^.ctask:=9;
      with vessels[sid]^ do
      begin
	 mission:=5;
         if ((hull=shipclas.tanker(6)) and (stasks[4]>4)) then mission:=6; {it's a tanker not doing fuel transport}
	 cs := hulls[hull].cargo - fish;
	 if cs=0 then exit;
	 cu := cs div 100;
	 if cu = 0 then cu:=1;
	 totcount:=totcount + cu;
	 if bcount>0 then {Scout ship! transport money!}
	 begin
	    moneyTransport(sid,s);
	    exit;
	 end;
	 {LDSF always do supplies}
	 if (cs>600) then
	 begin
	    {$ifdef d_ships}
	    write('FS');
	    {$endif}
	    supplyFreighter(sid,s);
	    supcount:= supcount+cu;
	    exit;
	 end;
	 if s^.owner = 1 then
	 begin
	    colonyFreighter(sid,s);
	    colcount:=colcount+cu;
	    exit;
	 end;
	 if s^.owner = 2 then
	 begin
	    {$ifdef d_ships}
	    write('FS');
	    {$endif}
	    supplyFreighter(sid,s);
	    supcount:= supcount+cu;
	    exit;
	 end;
	 if s^.owner = 3 then
	 begin
	    {$ifdef d_ships}
	    write('FM');
	    {$endif}
	    migrationFreighter(sid,s);
	    migcount:=migcount+cu;
	    exit;
	 end;
	 {work out the target colonisist ships}
	 if (colplan<61) then
	 begin
	    targcol := (4*colplan) div 6;
	    targcol := 100 - targcol;
	    targcol := max( (targcol*totcount) div 100 ,1);
	 end
	 else
	 begin
	    targcol := ((colplan-60) * 6) div 4;
	    targcol := 60 - targcol;
	    targcol := max( (targcol*totcount) div 100,1);
	 end;
	 {old formula}
	 {targcol := max( ((100-colplan) * totcount) div 100 , 1);}
	 {work out the target supply ships}
	 targsup := max( ((100-baseReady) * totcount) div 100 , 1);
	 {work out the migration percentage}
	 targmig := max( totcount div 5 , 1);

	 {$ifdef d_ships}
	 write('*');
	 {$endif}
	 {ok now decide which type of ship we will be}
	 if targcol>colcount then
	 begin
	    colonyFreighter(sid,s);
	    colcount:=colcount+cu;
	    exit;
	 end;
	 if targsup>supcount then
	 begin
	    {$ifdef d_ships}
	    write('FS');
	    {$endif}
	    supplyFreighter(sid,s);
	    supcount:= supcount+cu;
	    exit;
	 end;
	 {if all else fails do nothing! the freighter should migrate people!}
	 {$ifdef d_ships}
	 write('FM');
	 {$endif}
	 migrationFreighter(sid,s);
	 migcount:=migcount+cu;
      end;
   end;

   function canRescue(id : word):boolean;
   var i : word;
   begin
      canRescue:=true;
      for i:= 1 to rcount do
	 if rescue[i]=id then canRescue:=false;
   end;
   
   procedure RescueShip(sid : word; s :stateptr);
   var
      i		    : word;
      bd,d	    : word;
      sh,ls	    : word;
      sx,sy,wf,hd,o : integer;
   begin
      {ok now we rescue ships if we can}
      {only tankers do this, and they just supply the ship with fuel}
      
      bd:=9000;
      sh:=0;
      with vessels[sid]^ do
      begin
	 {$ifdef d_ships}
	    write('RS');
	 {$endif}
	 for i:=1 to nvessel do
	 begin
	    d:=round(distance(x,y,vessels[i]^.x,vessels[i]^.y));
	    if ((d<bd) and (vessels[i]^.speed<3) and canRescue(vessels[i]^.id)) then
	    begin
	       sh:=vessels[i]^.id;
	       ls:=i;	
	       vessels[i]^.mission:=2;
	       bd:=d;
	    end;
	 end;

	 if ((sh=0) and (s^.ctask=$4002)) then exit; {didn't find anyone to rescue}
	 
	 if ((sh>0) and (s^.ctask=$4002)) then
	 begin
	    {ok set waypoint to be the target ship}
	    s^.action:=2;
	    s^.target:=sh;
	    s^.ctask := $4001;
	    if rcount<6 then
	       begin
		  inc(rcount);
		  rescue[rcount] := sh;
	       end;
	    exit;
	 end;
	 
	 if s^.action=2 then
	 begin
	    s^.ctask := $4001;
            if ((sh>0) and (sh<> s^.target)) then
               s^.target:=sh; {retarget a new ship to recue - maybe the other got fuel}
	    if rcount<6 then
	    begin
	       inc(rcount);
	       rescue[rcount] := s^.target;
	    end;
	    exit; {ship is on-route}
	 end;
	 if ((s^.action=3) or (atship(x,y,s^.target))) then
	 begin {ship should have arrived with ship in need}
	    sh := s^.target;
	    i:=nearestOwnedWorld(x,y);
	    d:=trunc(distance(x,y,chart[i].x,chart[i].y));
	    bd:= fuelUsage(sid,d,eng)+20;
	    begin {we are at the ship... give it whatever fuel we can spare}
	       for i:= 1 to nvessel do
	       begin
		  if ((vessels[i]^.id = sh) and atShip(x,y,vessels[i]^.id)) then
		  begin
		     d:=0;
		     if fuel>bd then d:= fuel - bd;
		     d:= min(d, hulls[vessels[i]^.hull].fueltank - vessels[i]^.fuel);
		     fuel:=fuel-d;
		     vessels[i]^.fuel:= vessels[i]^.fuel+d;
		  end;
	       end;
	       {head back!}
	       s^.action:=1;
	       s^.target:=nearestOwnedWorld(x,y);
	    end;
	    s^.ctask:=$4002;
	 end;
	   
      end;
   end; { RescueShip }

   procedure tanker(sid	: word; s:stateptr);
   var
      i, fill : word;
      l       : integer;
   begin
      with vessels[sid]^ do
      begin
         i:=10;
	 if not(hull=shipclas.tanker(6)) then exit;
	 if not(shipready(s^.ctask,$4001) or shipready(s^.ctask, $4002)) then exit;
	 if stasks[4]>4 then
	 begin
	    if ((s^.ctask=$4001) or (s^.ctask=$4002)) then s^.ctask:=0;
	    exit;
	 end;
	 inc(stasks[4]);
	 {$ifdef d_ships}
	 write('FT');
	 {$endif}

	 mission:=5;
	 
	 if ((S^.ctask <> $4001) and (s^.ctask <> $4002)) then
	    s^.ctask := $4002;
	 
	 if s^.ctask = $4001 then
	 begin
	    rescueShip(sid,s);
	    exit;
	 end;
        
	 if (s^.action = 3) then
	 begin
	    if atPlanet(x,y,s^.target) then	       
	    begin
	       i := findPlanet(s^.target);
	       {decide if we are filling or depositing}
	       if (worlds[i]^.nmined<50) then
	       begin { deposit }
		  fill := max(0, fuel - 50);
		  fuel := fuel - fill;
		  worlds[i]^.Nmined := worlds[i]^.Nmined + fill;
	       end
	       else
	       begin {fill }		  
		  fill := hulls[hull].fueltank - fuel;
		  fill := min( fill, worlds[i]^.Nmined);
		  fuel := fuel + fill;
		  worlds[i]^.Nmined := worlds[i]^.Nmined - fill;
	       end;
	    end;
	    s^.target := bestFuelSupply(x,y);
	    s^.action := 1;
	 end
         else
	    if not(s^.action = 1) then
	    begin
	       s^.target := bestFuelSupply(x,y);
	       s^.action := 1;
	    end;
	    
	 if (fuel >= (hulls[hull].fueltank) div 2) then
	 begin
	    rescueShip(sid,s);
	    s^.target := fueldemand;
	    s^.action := 1;
	 end;
      end;
   end; { tanker }

begin
   migcount:=0;
   rcount:=0;
end.
