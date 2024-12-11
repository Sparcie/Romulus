{ship AI utility unit
  important bits used by all of the ship components}
unit shiputil;

interface
uses RST,map,vector,shipstat,shipclas,hull,parts,planets,messages,diplo;

var
   vessels    : array[1..500] of starshipptr;
   nvessel    : word;
   hullsupply : array[0..9] of integer; {see hulldemand in bases}
   stasks     : array[0..6] of integer; { 0 - transport vessels, 1 - mine layer,
					2 - special (glory etc), 3 defenders,
					4 tanker, 5 minesweepers 6 money transports}
   maxfp    : integer; { max fp of the current race ships}

function factoryShipCount(id	: word):word;
function shipCountAt(x,y : integer):word;
function BestBase(x,y,tt :integer) :word;
procedure setWaypointP(var x,y,dx,dy	:integer; target :word);
procedure findShip(var x,y,wf,head,owner:integer;id : word);
function fuelUsage(sid : word; dist:real;sp :integer):word;
procedure emergBeamUpFuel(sid :word );
procedure beamUpFuel(sid :word );
procedure fuelCheck(sid : word; s:stateptr);
function atShip(x,y,target : integer):boolean;
procedure setWaypointS(var x,y,dx,dy	: integer; target:word);
function checkTaskWord(t,f : word):boolean;
function distanceToIntercept(x,y,sp,tx,ty,px,py : real; var ix,iy:real):word;
procedure attackShip(sid : word; s:stateptr);
procedure checkActions(sid : word; s:stateptr);
procedure loadColonists(sid,from,amount: word);
procedure unload(sid,dest: word);
procedure load(sid,dest: word);
function shipReady(ctask,doing : word):boolean;
function atAnyWorld(id : word):boolean;
function hullCount(hull : word):word;

implementation


   function hullCount(hull : word):word;
   var i    : integer;
      count : word;
   begin
      count:=0;
      for i:= 1 to nvessel do
	 if vessels[i]^.hull=hull then inc(count);
      hullCount:=count;      
   end;

   function atAnyWorld(id : word):boolean;
   var
      i	: word;
   begin
      atAnyWorld:=false;
      with vessels[id]^ do
      for i := 1 to 500 do
	 if (atPlanet(x,y,i) and (chart[i].owner=1)) then atAnyWorld:=true;
   end; { atAnyWorld }

   function factoryShipCount(id	: word):word;
   var
      s	  : stateptr;
      i	  : word;
      fig : word;
   begin
      fig:=0;
      for i:= 1 to nvessel do
      begin
	 s := getState(vessels[i]^.id);
	 if ((s^.ctask = $10) and atPlanet(vessels[i]^.x,vessels[i]^.y,id)) then
	 begin
	    fig:=fig+vessels[i]^.fish;
	 end;
      end;
      factoryShipCount:=fig;
   end;

   function shipCountAt(x,y : integer):word;
   var
      i,count	: word;
   begin
      count:=0;
      for i:= 1 to nvessel do
	 if ((vessels[i]^.x=x) and (vessels[i]^.y=y)) then inc(count);
      shipCountAt:=count;
   end;

   function BestBase(x,y,tt :integer) :word;
   var
      fig,bfig : word; {fighter count including factory ships}
      mon,bmon : longint; {money count}
      mat,bmat : longint; {material count}
      sb       : starbaseptr;
      i,c,id,d : word;
   begin
      bfig:=0;
      bmon:=0;
      bmat:=0;
      BestBase:=0;
      for i:= 1 to baseCount do
      begin
	 sb := getBase(i);
	 id:= sb^.baseid;
	 fig := sb^.fighters;
	 fig := fig + factoryShipCount(id);
	 c:= shipCountAt(chart[id].x,chart[id].y)+1;
	 mat:=planetMaterial(id) - (c*50); {count planet materials}
	 mon:=planetMoney(id) - (c*150); {count planet money}
	 d := round(distance(x,y,chart[id].x,chart[id].y)) div 81;
	 mat:= mat div (d+1);
	 mon := mon div (d+1);
	 if ((fig>bfig) and (mon>bmon) and (mat>bmat) and ( sb^.Ttech+1 > tt)) then
	 begin
	    bfig:=fig;
	    bmon:=mon;
	    bmat:=mat;
	    bestBase:=id;
	 end;
      end;
   end; { BestBase }


   procedure setWaypointP(var x,y,dx,dy	:integer; target :word);
   var
      i	      : word;
      h,nh    : integer;
      tx,ty   : word;
      dist,sd : word;
   begin
      dx:=0; dy:=0;
      {get the target xy}
      if (target=0) then exit;
      tx:= chart[target].x;
      ty:= chart[target].y;
      dist := trunc(distance(x,y,int(tx),int(ty)));
      {ok so we have a problem where we are too far away so lets find a closer
      planet}
      h := trunc(calcbearing(x,y,int(tx),int(ty))); {heading to target}
      sd := dist;
      dx:= tx-x;
      dy:= ty-y;
      for i:= 1 to 500 do
      begin
	 if ((chart[i].owner = 1) or (i=target)) then {only travel on owned worlds }
	 begin {or to the target}
	    dist := trunc(distance(x,y,chart[i].x,chart[i].y));
	    nh := trunc(calcbearing(x,y,chart[i].x,chart[i].y));
	    nh := abs(nh-h);
	    if nh>180 then nh := 360 - nh;
	    if ((dist<sd) and (nh<45) and (dist>0)) then
	    begin
	       sd := dist;
	       dx := chart[i].x - x;
	       dy := chart[i].y - y;
	    end;
	 end;
      end;
   end; { setWaypointP }

   procedure findShip(var x,y,wf,head,owner:integer;id : word);
   var
      i	: word;
      t	: targetptr;
   begin
      x:=9000;
      y:=9000;
      head:=$FF;
      wf:=$FF;
      for i:= 1 to nvessel do
	 if vessels[i]^.id = id then
	 begin
	    x:= vessels[i]^.x;
	    y:= vessels[i]^.y;
	    wf:= vessels[i]^.speed;
	    owner:=player;
	 end;
      for i:= 1 to targetcount do
	 if id = getTarget(i)^.id then
	 begin
	    t:=getTarget(i);
	    x:= t^.x;
	    y:= t^.y;
	    wf:= t^.speed;
	    head:=t^.heading;
	    owner:=t^.owner;
	 end;
   end; { findShip }

   function fuelUsage(sid : word; dist:real;sp :integer):word;
   var
      mass,eff,t : real;
   begin
      fuelUsage:=0;
      with vessels[sid]^ do
	 if ((sp>0) and (dist>0)) then
	 begin
	    mass:= hulls[hull].mass;
	    if ((bcount>0) and (beam>0) and (beam<11)) then
	       mass:= mass + (bcount * parts.weapons[beam].mass);
	    if ((tcount>0) and (torp>0) and (torp<11)) then
	       mass:= mass + (tcount * parts.torps[torp].mass);
	    mass:= mass + fish;
	    mass:= mass + fuel;
	    mass:= mass + colonists + supplies + tritanium + duranium + molybdenum;
	    eff := parts.engines[eng].fconsumption[sp];
	    t := (dist * mass * eff ) / (sqr(sp) * 100000);
	    if hull = 46 then fuelUsage:=round(t/2);

	    if mission=10 then
	    begin
	       eff :=trunc(dist / sqr(sp)) + 1; {number of turns travelling}
	       if ((hull=31) or (hull=29)) then eff:=0;
	       if ((eff>0) and (round(t + (5*(hulls[hull].mass / 100))*eff) < maxint)) then
		  t:=round(t + (5*(hulls[hull].mass / 100))*eff);
	    end;
	    fuelUsage:=round(t);
	 end;
   end;

   procedure emergBeamUpFuel(sid :word );
   var
      avail : word;
      ships : word;
      i,p   : word;
      w	    : word;
   begin
      with vessels[sid]^ do
      begin
         w:=0;
	 avail:=20000;
	 for p:= 1 to nworlds do
	    if (atplanet(x,y,worlds[p]^.id) and (worlds[p]^.owner=player) ) then
	    begin
	       if worlds[p]^.Nmined<maxint then avail:=worlds[p]^.Nmined;
	       w:=p;
	    end;
         if w=0 then exit;
	 ships:=0;
	 for i:= 1 to nvessel do
	    if atplanet(vessels[i]^.x,vessels[i]^.y,worlds[w]^.id) then
	       inc(ships);
         if ships>0 then
	    avail:=avail div ships;
	 {ok load vessel!}      
	 avail:= min(avail,hulls[hull].fueltank-fuel);
	 worlds[w]^.Nmined:=worlds[w]^.Nmined-avail;
	 fuel:=fuel+avail;	     	    
      end;
   end; { emergBeamUpFuel}

   procedure beamUpFuel(sid :word );
   var
      dist : real;
      use  : word;
      i,p  : word;
      z	   : word;
   begin
      with vessels[sid]^ do
      	 begin
	    dist:= distance(0,0,dx,dy)+(speed*speed);
	    z:=fuelUsage(sid,dist,speed);
	    if z < 2000 then
	       z:= (z * 2)+10;
	    {set like this for the return trip and possible detour}
	    use := min(hulls[hull].fueltank,z);
	    if fuel<use then
	    begin
	       {beam up some fuel}
	       for i:=1 to 500 do
		  if atPlanet(x,y,i) then
		  begin
		     for p:= 1 to nworlds do
			if ((worlds[p]^.id = i) and (worlds[p]^.owner=player)) then
			   while ((fuel<use) and (worlds[p]^.Nmined>0)) do
			   begin
			      fuel:=fuel+1;
			      worlds[p]^.Nmined:=worlds[p]^.Nmined-1;
			      {recalculate the usage}
			      z:=fuelUsage(sid,dist,speed);
			      if z < 2000 then
				 z:= (z * 2)+10;
			      {set like this for the return trip and possible detour}
			      use := min(hulls[hull].fueltank,z);
			   end;		     
		  end;
	    end;	    
	 end;
   end; { beamUpFuel}

   procedure fuelCheck(sid : word; s:stateptr);
   var
      used : word;
      dist : word;
      temp : word;
      g	   : groupptr;
   begin
      with vessels[sid]^ do
      begin
	 if speed>0 then
	 begin
	    dist:= round(distance(0,0,dx,dy));
	    used := fuelUsage(sid,dist,speed);
	    if ((fuel<used) and (mission=10)) then
	    begin
	       mission:=5;
	       used := fuelUsage(sid,dist,speed);
	    end;
	    if (fuel<used) then
	    begin {ok now seek out a fuel source if possible, and set mission
		  to kill so people don't try to steal us}
	       {$ifdef d_ships}
	       write('!');
	       {$endif}
	       dist := nearestOwnedWorld(x,y);
	       mission := 4 ;
	       if player=5 then mission:=9;
	       if dist>0 then
		  if not(atPlanet(x,y,dist)) then
		  begin
		     setWaypointP(x,y,dx,dy,dist);
		     dist:= round(distance(0,0,dx,dy));
		     used := fuelUsage(sid,dist,speed);
		     if (fuel<used) then speed:=0; {can't get there stop!}
		  end
		  else
		     speed:=0;
	    end;{now final check ... if the tank is full and we can't get there or we need more than can be carried}
	    if ( ((fuel=hulls[hull].fueltank) and (speed=0)) or (hulls[hull].fueltank<used) ) then
	    begin
	       s^.action:=7;
	       if not(getGroup(id)=nil) then {if it's leading a battlegroup disband it!}
	       begin
		  g:= getGroup(id);
		  g^.target:=0;
	       end;
	    end;
	 end;
      end;
   end;

   function atShip(x,y,target : integer):boolean;
   var tx,ty,wf,h,o : integer;
   begin
      atShip:=false;
      findship(tx,ty,wf,h,o,target);
      if ((x=tx) and (y=ty)) then atShip:=true;
   end;

   procedure setWaypointS(var x,y,dx,dy	: integer; target:word);
   var
      tx,ty   : integer;
      dp,dt,o : integer;
      pid     : word;
   begin
      dx:=0;
      dy:=0;
      findShip(tx,ty,dp,dt,o,target);
      if ((tx=9000) and (ty=9000)) then exit;
      pid := nearestOwnedWorld(tx,ty);
      dp:=1000;
      if pid>0 then
	 dp := trunc(distance(tx,ty,chart[pid].x,chart[pid].y));
      dt := trunc(distance(tx,ty,x,y));
      if ((dp<dt) and (pid>0)) then
	 setWaypointP(x,y,dx,dy,pid)
      else
      begin
	 dx:= tx-x;
	 dy:= ty-y;
      end;
   end; { setWaypointS }

   function checkTaskWord(t,f : word):boolean;
   begin
      checkTaskWord:=false;
      if (t and f)>0 then checkTaskWord:=true;      
   end;

   { returns the distance it will take to intercept a ship }
   { x,y,sp : friendly ship location and speed}
   { tx,ty  : target ship x y}
   { px,py  : target ship delta per turn}
   { ix,iy  : location intercept occurs at}
   function distanceToIntercept(x,y,sp,tx,ty,px,py : real; var ix,iy:real):word;
   var
      t	    : word; {turns}
      rd    : word; {relative distance}
      td    : word; {traveled distance}
      hd    : real; {heading}
      dx,dy : real; {delta for interceptor}
      tr    : real; {distance needed for a turn}
   begin    
      distanceToIntercept:=4000;
      t:=0;
      rd:=1000;
      td:=0;
      while ((rd>1) and (t<19)) do
      begin
	 tx:= tx+px;{move enemy}
	 ty:= ty+py;
	 hd := calcbearing(x,y,tx,ty);{calc heading}
	 tr := distance(x,y,tx,ty);
	 if (tr>sp) then tr:=sp;{calc distance to travel}
	 calcVector(hd,tr,dx,dy); {calc delta}
	 x:=x + dx; {move ship}
	 y:=y + dy;
	 rd:= round(distance(x,y,tx,ty)); {distance at eot}
	 td:=td+round(tr);
	 t:=t+1;
      end;
      ix:=x;
      iy:=y;
      if t=19 then exit; {ship too far!}
      {ok gotta go home}
      rd:= nearestOwnedWorld(round(x),round(y));
      if rd>0 then
         td:= td + round(distance(x,y,chart[rd].x,chart[rd].y));
      distanceToIntercept:=td;
   end; { distanceToIntercept }
   
   procedure attackShip(sid : word; s:stateptr);
   var
      tx,ty    : integer; {target x,y}
      wf,hd,en : integer; {target warp, heading and owner}
      ix,iy    : real; {intercept location}
      edx,edy  : real; {target delta (predicted by heading}
      b,sp     : real; {bearing and speed temp vars}
      rtd      : integer; {roundtrip distance}
      nrtd     : integer; {new roundtrip distance (after cutting off the curve)}
   begin
      with vessels[sid]^ do
      begin

	 mission:=2;
	 intercept:=0;
	 findShip(tx,ty,wf,hd,en,s^.target);
	 if ((tx=9000) and (ty=9000)) then
	 begin {ship may be behind a planet}
	    tx:= x+dx; {where we think the ship is (from last intercept)}
	    ty:= y+dy;
	    wf:= nearestEnemyWorld(tx,ty);
	    {ship is likely to be at the planet so lets go there}
	    setWaypointP(x,y,dx,dy,wf);
	    if checkTaskWord(s^.task,$40) then mission:=10; {cloak!}
            if wf=0 then exit;
	    hd := round(distance(x,y,chart[wf].x,chart[wf].y));
	    if hd<trunc(sqr(speed)) then mission:=4;
	    exit; {don't attempt intercept code}
	 end;
	 {get the targets delta x,y}
	 b:=hd;
	 sp:=sqr(wf);
	 edx:=0;
	 edy:=0;
	 if (not(b=-1) and (sp>0)) then calcvector(b,sp,edx,edy);
	 {our current speed in ly}
         sp:=sqr(speed);
	 if hull=46 then sp:=sp*2; {for the meteor}
	 
	 {work out the intercept x,y and distance for the round trip}
	 rtd := distanceToIntercept(x,y,sp,tx,ty,edx,0-edy,ix,iy);
	 {set the dx,dy for the ship to the intercept point!}
	 dx := x-trunc(ix);
	 dy := y-trunc(iy);
	 {update the predicted round trip distance...}
	 nrtd := round(distance(x,y,ix,iy)); {trip out to the vessel}
	 hd:=nearestOwnedWorld(round(ix),round(iy));
	 if hd>0 then {return trip if one can be made!}
	    nrtd := nrtd + round(distance(ix,iy,chart[hd].x,chart[hd].y));
	 		       
	 b:=distance(x,y,tx,ty);
	 if checkTaskWord(s^.task,$40) then mission:=10; {cloak!}
	 if b<sp then {intercept if close enough}
	 begin
	    mission:=8;
	    intercept:=s^.target;
	    enemy := en;
	 end;
	 
	 {check we can get home}
	 emergBeamUpFuel(sid);{fill our tank if possible}
	 hd := fuelUsage(sid,rtd,speed);
	 if hd>fuel then
	 begin {too far!}
	    setWaypointP(x,y,dx,dy,wf);
	    s^.action:=7;
	 end;
      end;
   end; { attackShip }


   procedure checkActions(sid : word; s:stateptr);
   var tx,ty,wf,hd,o : integer;
   begin
      with vessels[sid]^ do
      begin
	 if s^.action = 1 then
	 begin
	    setWaypointP(x,y,dx,dy,s^.target);
	    if ((dx = 0) and (dy=0) and atPlanet(x,y,s^.target)) then
	       s^.action:=3;
	    if ((dx = 0) and (dy=0) and not(atPlanet(x,y,s^.target) )) then
	       s^.action:=7;
	    speed:=eng;
	 end;
	 if s^.action = 2 then
	 begin
	    setWaypointS(x,y,dx,dy,s^.target);
	    if ((dx = 0) and (dy=0) and atShip(x,y,s^.target)) then
	       s^.action:=3;
	    if ((dx = 0) and (dy=0) and not(atShip(x,y,s^.target) )) then
	       s^.action:=7;
	    speed:=eng;
	 end;
	 if s^.action = 4 then
	 begin
	    findShip(tx,ty,wf,hd,o,s^.target);
	    if not(isEnemy(o)) then
	    begin
	       s^.action:=7;
	       speed:=0;
	       exit;
	    end;
	    attackShip(sid,s);
	    if ((dx=0) and (dy=0) and not((tx=x) and (ty=y))) then
	    begin
	       s^.action:=3;
	    end;
	    if ((dx=0) and (dy=0) and (tx=x) and (ty=y) and (wf=0)) then
	    begin {tow ship to a base}
	       setWaypointP(x,y,dx,dy,nearestBase(x,y));
	       mission:=7; 
	       tow:=s^.target;
	       if (atPlanet(x,y,nearestBase(x,y))) then
	       begin
		  s^.action:=3;
		  mission:=2;
		  tow:=0;
	       end;
	    end;
	    if ((dx=0) and (dy=0) and (tx=x) and (ty=y)
		and (player=5) and (fbays=0) and (wf>0)) then
	    begin
	       mission:=9;
	       tow:=0;
	    end;
	    
	    if s^.action=3 then mission:=2;
	    speed:=eng;
	 end;
	 if s^.action = 5 then
	 begin
	    if not(isEnemy(chart[s^.target].owner-10)) then
	    begin
	       s^.action:=7;
	       speed:=0;
	       exit;
	    end;
	    speed:=eng;
	    setWaypointP(x,y,dx,dy,s^.target);
	    if ((dx = 0) and (dy=0) and atPlanet(x,y,s^.target)) then
	    begin
	       s^.action:=0;
	       chart[s^.target].owner:=0;
	    end;
	    if ((dx = 0) and (dy=0) and not(atPlanet(x,y,s^.target) )) then
	       s^.action:=7;
	    if checkTaskWord(s^.task,$40) then
	       begin
		  mission:=10; {cloak!}
		  if fuelUsage(sid,trunc(distance(0,0,dx,dy)),speed) > fuel then
		     mission:=4;
	       end;
	    if trunc(distance(0,0,dx,dy)) <= sqr(speed) then  mission:=4;
	 end;
	 if s^.action = 6 then
	 begin
	    
	 end;
	 {turn off cloak if at a world we own}
	 wf := nearestOwnedWorld(x,y);
	 if ((atPlanet(x,y,wf)) and (mission=10) and (speed=0)) then
	    mission:=5;
	 {ok now check we have enough fuel to travel where we are going}
	 if not(s^.ctask = $400 ) then beamUpFuel(sid);
	 if not((s^.action=7) and (s^.ctask=$4004)) then fuelCheck(sid,s);
      end;
   end; { checkActions }

   procedure loadColonists(sid,from,amount: word);
   var
      i,l   : integer ;
      us,cs : integer;
   begin
      if amount=0 then exit;
      with vessels[sid]^ do
      begin
	 {find planet with the same id as our target and load the ship}
	 i:=findPlanet(from);
         if i=0 then exit;
	 if ((worlds[i]^.id=from) and (worlds[i]^.owner=player)
	     and atplanet(x,y,from)) then
	 begin
	    cs := hulls[hull].cargo;
	    us := colonists + supplies + tritanium + duranium + molybdenum +fish;
	    l:= cs - us - amount;
	    if l<0 then l:=0;
	    if not(worlds[i]^.supplies>maxint) then
	       l := min(l,worlds[i]^.supplies);
	    
	    worlds[i]^.supplies:=worlds[i]^.supplies-l;
	    supplies:=supplies+l;
	    l:=amount;
	    if not(worlds[i]^.colonists>maxint) then
	       l := min(l,worlds[i]^.colonists-100);
	    if l<0 then l:=0;
	    worlds[i]^.colonists:=worlds[i]^.colonists-l;
	    colonists:=colonists+l;
	 end;
      end;
   end;

   procedure unload(sid,dest: word);
   var
      i,l   : word ;
      cs,us : word;
   begin
      with vessels[sid]^ do
      begin
	 {find planet with the same id as our target and unload the ship}
	 i:=findPlanet(dest);
         if i=0 then exit;
	 if ((worlds[i]^.id=dest) and (worlds[i]^.owner=player)
	     and atplanet(x,y,dest)) then
	 begin
	    l := supplies;
	    worlds[i]^.supplies:= worlds[i]^.supplies+l;
	    supplies:=0;
	    l := colonists;
	    worlds[i]^.colonists:=worlds[i]^.colonists+l;
	    colonists:=0;
	    l := tritanium;
	    worlds[i]^.Tmined :=worlds[i]^.Tmined +l;
	    tritanium:=0;
	    l := duranium;
	    worlds[i]^.Dmined:=worlds[i]^.Dmined +l;
	    duranium:=0;
	    l := molybdenum;
	    worlds[i]^.Mmined :=worlds[i]^.Mmined +l;
	    molybdenum:=0;
	    l := money;
	    worlds[i]^.credits:=worlds[i]^.credits +l;
	    money:=0;
	 end;
      end;
   end;

   procedure load(sid,dest: word);
   var
      i,l      : word ;
      cs,us,rs : word;
      sp,ors   : word;
   begin
      with vessels[sid]^ do
      begin
	 {find planet with the same id as our target and load the ship}
	 i:=findPlanet(dest);
         if i=0 then exit;
	 if ((worlds[i]^.id=dest) and (worlds[i]^.owner=player)
	     and atPlanet(x,y,dest)) then
	 begin
	    cs := hulls[hull].cargo;
	    us := colonists + supplies + tritanium + duranium + molybdenum +fish;
	    rs:= cs-us;
	    ors:=0;
	    sp := findSupply(worlds[i]^.id);
	    if sp=0 then exit;
	    {load the most demanded mineral.}
	    l:= mineralDemand;
	    if l=0 then
	    begin
	       l:=rs;
	       if not(supply[sp].supplies>maxint) then
		  l := min(supply[sp].supplies,rs);
	       if not(worlds[i]^.supplies>maxint) then
		  l := min(l,worlds[i]^.supplies);
	       worlds[i]^.supplies:=worlds[i]^.supplies -l;
	       supply[sp].supplies := supply[sp].supplies-l;
	       supplies:=supplies+l;
	       rs:=rs-l;
	       l:=0;
	    end;
	    if l=1 then
	    begin
	       l:=rs;
	       if not(supply[sp].duranium>maxint) then
		  l := min(supply[sp].duranium,rs);
	       if not(worlds[i]^.Dmined>maxint) then
		  l := min(l,worlds[i]^.Dmined);
	       worlds[i]^.Dmined:=worlds[i]^.Dmined -l;
	       supply[sp].duranium := supply[sp].duranium-l;
	       duranium:=duranium+l;
	       rs:=rs-l;
	       l:=0;
	    end;
	    if l=2 then
	    begin
	       l:=rs;
	       if not(supply[sp].Tritanium>maxint) then
		  l := min(supply[sp].tritanium,rs);
	       if not(worlds[i]^.Tmined>maxint) then
		  l := min(l,worlds[i]^.Tmined);
	       worlds[i]^.Tmined:=worlds[i]^.Tmined -l;
	       supply[sp].tritanium := supply[sp].tritanium-l;
	       tritanium:=tritanium+l;
	       rs:=rs-l;
	       l:=0;
	    end;
	    if l=3 then
	    begin
	       l:=rs;
	       if not(supply[sp].molybdenum>maxint) then
		  l := min(supply[sp].molybdenum,rs);
	       if not(worlds[i]^.Mmined>maxint) then
		  l := min(l,worlds[i]^.Mmined);
	       l:=min(400,l);
		  worlds[i]^.Mmined:=worlds[i]^.Mmined -l;
	       supply[sp].molybdenum := supply[sp].molybdenum-l;
	       molybdenum:=molybdenum+l;
	       rs:=rs-l;
	       l:=0;
	    end;
	    {load minerals!}
	    while (not(sp=0) and (rs>0) and not(ors=rs)) do
	    begin
	       ors:=rs;
	       l:=rs;
	       if not(supply[sp].molybdenum>maxint) then
		  l := min(supply[sp].molybdenum,rs);
	       if not(worlds[i]^.Mmined>maxint) then
		  l := min(l,worlds[i]^.Mmined);
	       l:=min(400,l);
		  worlds[i]^.Mmined:=worlds[i]^.Mmined -l;
	       supply[sp].molybdenum := supply[sp].molybdenum-l;
	       molybdenum:=molybdenum+l;
	       rs:=rs-l;
	       l:=rs;
	       if not(supply[sp].duranium>maxint) then
		  l := min(supply[sp].duranium,rs);
	       if not(worlds[i]^.Dmined>maxint) then
		  l := min(l,worlds[i]^.Dmined);
	       l:=min(400,l);
	       worlds[i]^.Dmined:=worlds[i]^.Dmined -l;
	       supply[sp].duranium := supply[sp].duranium-l;
	       duranium:=duranium+l;
	       rs:=rs-l;
	       l:=rs;
	       if not(supply[sp].tritanium>maxint) then
		  l := min(supply[sp].tritanium,rs);
	       if not(worlds[i]^.Tmined>maxint) then
		  l := min(l,worlds[i]^.Tmined);
	       l:=min(400,l);
	       worlds[i]^.Tmined:=worlds[i]^.Tmined -l;
	       supply[sp].tritanium := supply[sp].tritanium-l;
	       tritanium:=tritanium+l;
	       rs:=rs-l;
	       l:=rs;	       
	       if not(supply[sp].supplies>maxint) then
		  l := min(supply[sp].supplies,rs);
	       if not(worlds[i]^.supplies>maxint) then
		  l := min(l,worlds[i]^.supplies);
	       l:=min(400,l);
	       worlds[i]^.supplies:=worlds[i]^.supplies -l;
	       supply[sp].supplies := supply[sp].supplies-l;
	       supplies:=supplies+l;
	       rs:=rs-l;
	       sp:=findsupply(worlds[i]^.id);
	    end;
	    {load money}
	    l:=10000-money;
	    if not(worlds[i]^.credits>10000) then
	       l := min(10000-money,worlds[i]^.credits);
	    worlds[i]^.credits:=worlds[i]^.credits -l;
	    money:=money+l;
	    {convert supplies to money and load on the ship}
	    if not(sp=0) then
	    begin
	       l:=10000-money;
	       if not(worlds[i]^.supplies>10000) then
		  l := min(10000-money,supply[sp].supplies);
	       worlds[i]^.supplies:=worlds[i]^.supplies -l;
	       money:=money+l;
	    end;
	 end;
      end;
   end; { load }

   function shipReady(ctask,doing : word):boolean;
   begin
      shipReady:=false;;
      if ctask = 0 then shipReady:=true;
      if ctask = doing then shipReady:=true;
   end; { shipReady }

begin
   nvessel:=0;
end.
