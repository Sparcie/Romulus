{ AI for ships that perform attacks upon the enemy }

unit ship_att;

interface

uses shiputil,planets,map,RST,shipstat,shipclas,diplo,hull,vector,messages,targdb;

procedure Transport(sid : word; s: stateptr);
procedure BattleShip(sid : word; s: stateptr);
procedure BattleCruiser(sid : word;s :stateptr);
procedure smallWarship(sid : word; s :stateptr);
procedure medWarship(sid : word; s :stateptr);

function findTargetPlanet(sid : word;s: stateptr):boolean;
function findTargetShip(sid : word; s:stateptr; maxf:word):boolean;
function nastyShip(sid : word; s: stateptr):boolean;
function shortIntercept(sid : word):boolean;

   procedure resetAttack;

implementation

   type
      data    = record
		   attack : array[1..30] of word;
		   ac	  : word;
		   {response data (ships we need to hunt down!)}
		   dloc	  : array[1..70] of word;{location of nearest world}
		   dmag	  : array[1..70] of byte;{0 none 1 minimal 2 moderate 3 major }
		   dsc	  : array[1..70] of byte;{number of enemy ships} 
		   dcount : word;
		   {Attack data (list of ships being attacked!)}
		   acount  :word;
		   targship: array[1..100] of word; {target}
		   targfp  : array[1..100] of word; {its firepower}
		   targatfp: array[1..100] of word; {attacking firepower}
		end;	  
      dataptr =  ^data;

   var
      inited	 : boolean;
      attackdata : dataptr;
   

   function canTargetShip(id	: word):boolean;
   var i : integer;
   begin
      canTargetShip:=true;
      with attackData^ do
	 for i:= 1 to acount do
	    if ((id=targship[i]) and (targatfp[i]>targfp[i])) then canTargetShip:=false;
   end; { canTargetShip }

   procedure addTargetShip(id, tfp, afp: word);
   var i : integer;
   begin 
      with attackData^ do
      begin
	 for i:= 1 to acount do
	    if id=targship[i] then
	    begin
	       targatfp[i]:=targatfp[i]+afp;
	       exit;
	    end;
	 if acount>99 then exit;
	 inc(acount);
	 targship[acount]:=id;
	 targfp[acount]:=tfp;
	 targatfp[acount]:=afp;
      end;
   end;
   
   procedure resetAttack;
   {$ifdef d_attack}
   var i : integer;
   {$endif}
   begin
      if not(inited) then exit;
      {$ifdef d_attack}
      with attackdata^ do
      begin
	 for i:=1 to dcount do
	    writeln('Respond ',i,' location ',dloc[i],' mag ',dmag[i],' ship count ',dsc[i]);
	 for i:= 1 to acount do
	    writeln('targetship ',i,' id ',targship[i],' fp ',targfp[i],' att fp ',targatfp[i]);
	 for i:= 1 to ac do
	    writeln(i,' attack planet ',attack[i]);
      end;
      {$endif}
      inited:=false;
      dispose(attackdata);
   end; { resetAttack }

   procedure addAttack(a : word);
   var i : word;
   begin
      with attackdata^ do
      begin
	 if ac>29 then exit;
	 for i:= 1 to ac do
	    if attack[i] = a then exit;
	 inc(ac);
	 attack[ac]:=a;
      end;
   end; { addAttack }

   function canAttack(a : word):boolean;
   var i :  word;
   begin
      with attackdata^ do
      begin
	 canAttack:=false;
	 for i:= 1 to ac do
	    if attack[i] = a then exit;
	 canAttack:=true;
      end;
   end;
   
   procedure init;
   var
      i,c  : word;
      t	   : targetptr;
      w,fp : word;
      tl   : word;
      wm   : word;
      pd   : boolean;
   begin
      if inited then exit;
      new(attackdata);
      inited:=true;
      attackdata^.ac:=0;
      attackdata^.dcount:=0;
      attackdata^.acount:=0;
      with attackdata^ do
      begin {find out which planets are potentially under attack by a hostile vessel }
	 for i:= 1 to dbCount do
	 begin
	    t:= dbtarg[i];
	    w:= nearestOwnedWorld(t^.x,t^.y);
	    fp:= getFirePower(t^.hull);
	    tl:=0;
	    if fp>4 then tl:=1;
	    if fp>14 then tl:=2;
	    if fp>21 then tl:=3;
	    if (isEnemy(t^.owner) or intendWar(t^.owner)) then
	    begin
	       {found a potential distress!}
	       {check to see if we need to upgrade a previous distress}
	       pd:=false;
	       for c:= 1 to dcount do
	       begin
		  if ((dloc[c] = w) and (tl=dmag[c])) then
		  begin
		     inc(dsc[c]);
		     pd:=true;
		  end;
	       end;
	       if not(pd) then
	       begin
		  {simply add the extra distress}
		  if dcount<70 then
		  begin
		     inc(dcount);
		     dloc[dcount]:=w;
		     dmag[dcount]:=tl;
		     dsc[dcount]:=1;
		  end;
	       end;
	    end;
	 end;
	 {check to see if the potential distresses already have ships present}
	 for i:= 1 to nvessel do
	    with vessels[i]^ do
	    begin
	       fp:=getFirePower(hull);
	       tl:=0;
	       if fp>4 then tl:=1;
	       if fp>14 then tl:=2;
	       if fp>21 then tl:=3;
	       wm:=0;
	       fp:=0;
	       for c:= 1 to dcount do
	       begin
		  if ((dsc[c]>0) and (dmag[c]<=tl)) then
		  begin
		     w:= trunc(distance(x,y,chart[dloc[c]].x,chart[dloc[c]].y));
		     if ((w<150) and (wm<dmag[c])) then
		     begin
			wm:=dmag[c];
			fp:=c;
		     end;
		  end;
	       end;
	       if fp>0 then dsc[fp]:=dsc[fp]-1;
	    end;	 
      end;
   end; { init }

   function respond(sid,rl : word; s: stateptr):boolean;
   var
      i	       : word;
      bl,br,bi : word;
   begin {Repsond to a distress listed... }
      init;
      respond:=false;
      with attackData^ do
      begin
         {check if we are already with in 150ly of a response}
	 for i:= 1 to dcount do
	 begin
	    bl:= dloc[i];
	    br:=trunc(distance(vessels[i]^.x,vessels[i]^.y, chart[bl].x,chart[bl].y));
	    if br<150 then exit;
	 end;
	 {are we already responding?}
	 if s^.action=1 then
	 begin
	    respond:=true;
	    for i := 1 to dcount do
	       if dloc[i]=s^.target then
	       begin
		  if dsc[i]>0 then
		     dsc[i]:=dsc[i]-1;
	       end;
	    exit;
	 end;
	 {$ifdef d_attack}
 	 write('rp');
	 {$endif}
	 {find a target location to respond to.}
	 bl:=0;
	 br:=0;
	 for i:= 1 to dcount do
	 begin {check for a threat up to equal with the specified level}
	    if ((dmag[i]>br) and (dmag[i]<=rl) and (dsc[i]>0) ) then
	    begin
	       bi:=i;
	       bl:=dloc[i];
	       br:=dmag[i];
	    end;
	 end;
	 if br>0 then
	 begin
	    respond:=true;
	    dec(dsc[bi]);
	    if dsc[bi]=0 then dmag[bi] := 5;
	    s^.action:=1;
	    s^.target:=bl;
	 end;
      end;
   end;
      
   function findTargetPlanet(sid : word;s: stateptr):boolean;
   var
      i,c,z : word;
      sd,d  : word;
      t	    : word;
   begin
      with vessels[sid]^ do
      begin
	 init;
	 {ok look for a world to conquer that is marked}
	 {$ifdef d_attack}
 	 write('tp');
	 {$endif}
	 findTargetPlanet:=false;
	 sd:=9000;
	 t:=0;
	 {find the nearest enemy world to the ship}
	 for i:= 1 to 500 do
	    if ((chart[i].owner=3) or (isEnemy(chart[i].owner-10))) then
	    begin
	       d:= trunc(distance(x,y,chart[i].x,chart[i].y));
	       if ((d<sd) and canAttack(i)) then
	       begin
		  sd:=d;		  
		  t:=i;
	       end;
	    end;
	 if (t>0) then i:= nearestOwnedWorld(chart[t].x,chart[t].y);
	 if ((t>0) and (i>0)) then
	    sd := trunc(distance(chart[t].x,chart[t].y,chart[i].x,chart[i].y))
	 else
	    sd:=9000;
	 {check clusters we own for closer planets}
	 for i:= 1 to nclusters do
	    if ((clusters[i].owned>0) and (clusters[i].ecount>0)
		and isEnemy(clusters[i].bigEnemy)) then
	       for c:= 1 to clusters[i].size do
		  if (canAttack(clusters[i].planets[c])
		      and isEnemy(chart[clusters[i].planets[c]].owner -10)) then
		     with clusters[i] do
		     begin
			z:=nearestOwnedWorld(chart[planets[c]].x,chart[planets[c]].y);
			d:= trunc(distance(chart[z].x,chart[z].y,chart[planets[c]].x,chart[planets[c]].y ));
			if (d<sd) then
			begin
			   sd:=d;
			   t:=planets[c];
			end;
		     end;

	 {if we found one}
	 if t>0 then
	 begin
	    findTargetPlanet:=true;
	    s^.action:=5;
	    s^.target:=t;
	    addAttack(t);
	 end;	 
      end;
   end; { findTargetPlanet }

   function findTargetShip(sid : word; s:stateptr; maxf:word):boolean;
   var
      i	       : word;
      ff,bf,fp : word;{firepower}
      td,bd    : word;{distance}
      npt,npd  : word;{nearest planet}
      targ     : targetptr;
      m,em     : word;{mass}
      tid      : word; {target id}
   begin
      with vessels[sid]^ do
      begin
	 init;
	 {$ifdef d_attack}
 	 write('ts');
	 {$endif}
	 findTargetShip:=false;
	 mission := 5;
	 bf:=0;
	 bd:=500;
	 tid:=0;
	 fp:=getFirepower(hull);
	 m := hulls[hull].mass;
	 for i:= 1 to targetCount do
	 begin
	    targ:=getTarget(i);
	    ff := getfirepower(targ^.hull);
	    em := hulls[targ^.hull].mass;
	    td := trunc(distance(x,y,targ^.x,targ^.y));
	    npt:=nearestOwnedWorld(targ^.x,targ^.y);
	    npd:= trunc(distance(targ^.x,targ^.y,chart[npt].x,chart[npt].y));
	    if ( ((ff<=maxf) or (em<m)) 
		and isEnemy(targ^.owner) and canTargetShip(targ^.id) )  then
	    begin
	       if ((ff=bf) and (td<bd)) then
	       begin
		  s^.target:= targ^.id;
		  tid:=targ^.id;
		  s^.action:= 4;
		  bf:=ff;
		  bd:=td;
		  findTargetShip:=true;
		  if (npd<td) then
		  begin
		     s^.target:=npt;
		     s^.action:=1;
		  end;
	       end;
	       if (ff>bf) then
	       begin {ok found a target}
		  s^.target:= targ^.id;
		  tid:=targ^.id;
		  s^.action:= 4;
		  bf:=ff;
		  bd:=td;
		  findTargetShip:=true;
		  if (npd<td) then
		  begin
		     s^.target:=npt;
		     s^.action:=1;
		  end;
	       end;
	    end;	 
	 end;
	 if (tid>0) then addTargetShip(tid,bf,fp);
      end;
   end; { findTargetShip }

   {find a nasty ship and attack it, or lay a minefield near it!}
   function nastyShip(sid : word; s: stateptr):boolean;
   var 
      gt	   : boolean;
      tx,ty,wf,h,o : integer; {for locating the vessel}
      targ	   : targetptr;
   begin
      with vessels[sid]^ do
      begin
	 nastyShip:=false;
	 gt:=false;
	 gt:= findTargetShip(sid,s,41); {find the nastiest ship out there}
	 if not(gt) then exit; {no need to chase the nasty ship}
	 for tx := 1 to targetCount do
	 begin
	    targ:=getTarget(tx);
	    if targ^.id = s^.target then
	       if maxfp>=getFirePower(targ^.hull) then exit; {ship isn't better than our own}
	 end;
	 nastyShip:=true;
	 if checkTaskWord(s^.task,$40) then {cloak if we can}
	 begin
	    mission:=10; {cloak!}
	    beamUpFuel(sid);
	 end;
	 if getFirePower(hull)<8 then
	 begin
	    findship(tx,ty,wf,h,o,s^.target);
	    s^.action:=1; {travel to the nearest world to the enemy}
	    s^.target := nearestOwnedWorld(tx,ty);
	    if (atPlanet(x,y,s^.target)) then
	       mission:=3;
	    if ((player=7) and (atplanet(x,y,s^.target))) then
	       mission:=9;
	 end;
      end;
   end; { nastyShip }

   {check for ships that we should be able to intercept in one turn}
   function shortIntercept(sid : word):boolean;
   var
      fp	   : word;
      i		   : word;
      edx,edy	   : real; {destination of enemy ship}
      warpd	   : real; {warp distance this ship will travel}
      t		   : targetptr;
      thead,tspeed : real;
   begin
      shortIntercept := false;
      with vessels[sid]^ do
      begin
	 warpd := speed * speed;
	 for i:=1 to targetCount do
	    if (isenemy(getTarget(i)^.owner)) then
	    begin
	       t:= getTarget(i);
	       thead := t^.heading;
	       tspeed := sqr(t^.speed);
	       calcvector(thead, tspeed, edx, edy);
	       edx := edx + t^.x;
	       edy := edy + t^.y;
	       if ((distance(edx,edy,x,y) < warpd) and
		   (getFirePower(hull) > getFirePower(t^.hull) )) then
	       begin {we should be able to catch it!}
		  enemy := t^.owner;
		  mission := 8;
		  intercept := t^.id;
		  shortIntercept := true;
		  exit;
	       end;
	    end;
      end;
   end;
   
   procedure medWarship(sid : word; s :stateptr);
   var
      gt : boolean;
      fp : word;
   begin
      init;
      {check that we can do this}
      if not(shipReady(s^.ctask,$2)) then exit;
      {$ifdef d_ships}
      write('WM');
      {$endif}
      {ok look for a ship to target}
      with vessels[sid]^ do
      begin
	 if (shipReady(s^.ctask,$2) and (s^.action=7)) then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 if (shortIntercept(sid)) then
	 begin
	    s^.action := 0;
	    s^.ctask := $2;
	    exit;
	 end;
	 {if we already have a target keep going}
	 if (s^.action = 4) then addTargetShip(s^.target,0,getfirepower(hull));
	 if (s^.action = 5) then addAttack(s^.target);
	 if ((s^.action = 4) or (s^.action=5)) then exit;
	 gt:=false;
	 fp:= getFirePower(hull);
	 gt:= nastyShip(sid,s);
	 if not(gt) then gt:= findTargetShip(sid,s,fp);
	 {if the enemy is poorly defended (ie less than 70% starbases) attack worlds}
	 if (aggressive and not(gt) and (fp>8)) then gt:=findTargetPlanet(sid,s);
	 if not(gt) then gt:=respond(sid,1,s);
	 if gt then s^.ctask := $2;
	 if not(gt)  then
	 begin
	    s^.ctask:=0;
	    s^.action:=1;
	    s^.target := nearestOwnedWorld(x+dx,y+dy);
	 end;
      end;
   end; { medWarship }

   procedure smallWarship(sid : word; s :stateptr);
   var
      gt : boolean;
      fp : word;
   begin
      init;
      {check that we can do this}
      if not(shipReady(s^.ctask,$1)) then exit;
      {$ifdef d_ships}
      write('WS');
      {$endif}
      with vessels[sid]^ do
      begin
	 if (shipReady(s^.ctask,$1) and (s^.action=7)) then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 if (shortIntercept(sid)) then
	 begin
	    s^.action := 0;
	    s^.ctask := $1;
	    exit;
	 end;
	 {if we already have a target keep going}
	 if (s^.action = 4) then addTargetShip(s^.target,0,getfirepower(hull));
	 if ((s^.action = 4) or (s^.action=5)) then exit;
	 gt:=false;
	 fp:= getFirePower(hull);
	 gt:= nastyShip(sid,s);
	 if not(gt) then gt:=findTargetShip(sid,s,0);
	 if not(gt) then gt:=findTargetShip(sid,s,4);
	 if not(gt) then gt:=findTargetShip(sid,s,fp);
	 if not(gt) then gt:=respond(sid,0,s);
	 if gt then s^.ctask := $1;
	 if not(gt)  then
	 begin
	    s^.ctask:=0;
	    s^.action:=1;
	    s^.target := nearestOwnedWorld(x+dx,y+dy);
	 end;
      end;
   end; { smallWarship }

   procedure BattleCruiser(sid : word;s :stateptr);
   var
      gt : boolean;
      fp : word;
   begin
      init;
      {check that we can do this}
      with vessels[sid]^ do
      begin
	 if not(shipReady(s^.ctask,$4)) then exit;
	 if (shipReady(s^.ctask,$4) and (s^.action=7)) then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 {$ifdef d_ships}
 	 write('BC');
	 {$endif}
	 {allow 2 ships to group with this one! if it is a carrier}
	 if isCarrier(hull) then makeGroup(id,2);
	 if not(s^.action = 5) then
	    if shortIntercept(sid) then
	    begin
	       s^.action := 0;
	       s^.ctask := $4;
	       exit;
	    end;
	 {if we already have a target keep going}
	 if (s^.action = 4) then addTargetShip(s^.target,0,getfirepower(hull));
	 if (s^.action = 5) then addAttack(s^.target);
	 if ((s^.action = 4) or (s^.action=5)) then exit;
	 gt:=false;
	 fp:= getFirePower(hull);
	 {a complete battlegroup should attack planets!}
	 if (groupfull(id) and not(gt)) then gt:=findTargetPlanet(sid,s);
	 {if the enemy is poorly defended (ie less than 70% starbases) attack worlds}
	 if (aggressive and not(gt)) then gt:=findTargetPlanet(sid,s);
	 {otherwise normal behaviour is attack a ship.}
	 if not(gt) then gt:= findTargetShip(sid,s,fp);
	 if not(gt) then gt:= findTargetShip(sid,s,20);
	 if not(gt) then gt:=respond(sid,2,s);
	 if (gt) then
	    s^.ctask:=$4
	 else
	    s^.ctask:=0;
      end;
   end; { BattleCruiser }

   procedure BattleShip(sid : word; s: stateptr);
   var
       gt : boolean;
       fp : word;
   begin
      init;
      {check that we can do this}
      with vessels[sid]^ do
      begin
	 if not(shipReady(s^.ctask,$8)) then exit;
	 if (shipReady(s^.ctask,$8) and (s^.action=7)) then
	 begin
	    s^.ctask:=0;
	    exit;
	 end;
	 {$ifdef d_ships}
	 write('BS');
	 {$endif}
	 {make a battle group for this size ship}
	 if isCarrier(hull) then
	    makeGroup(id,6)
	 else
	    makeGroup(id,4);
	 if not(s^.action = 5) then
	    if shortIntercept(sid) then
	    begin
	       s^.action := 0;
	       s^.ctask := $4;
	       exit;
	    end;
	 {if we already have a target keep going}
	 if (s^.action = 4) then addTargetShip(s^.target,0,getfirepower(hull));
	 if (s^.action = 5) then addAttack(s^.target);
	 if ((s^.action = 4) or (s^.action=5)) then exit;
	 gt:=false;
	 fp:= getFirePower(hull);
	 if (isCarrier(hull) and (fp>35)) then gt:=findTargetPlanet(sid,s);
	 {if the enemy is poorly defended (ie less than 70% starbases) attack worlds}
	 if (aggressive and not(gt)) then gt:=findTargetPlanet(sid,s);
	 {battleships (or carriers) with a complete battle group can also attack a planet}
	 if (not(gt) and groupFull(id)) then gt:=findTargetPlanet(sid,s);
	 if not(gt) then gt:= findTargetShip(sid,s,fp);
	 if not(gt) then gt:= findTargetShip(sid,s,30);
	 if not(gt) then gt:= respond(sid,3,s);
	 if (gt) then
	    s^.ctask:=$8
	 else
	    s^.ctask:=0;
      end;	 
   end; { BattleShip }

   procedure Transport(sid : word; s: stateptr);
   var
      cs,us    : integer;
      i,z,sd,d : word;
   begin
      if not(shipReady(s^.ctask,$20)) then exit;
      if ((player>1) and (player<6)) then
	  if not(checkTaskWord(s^.task,$40)) then exit;
      if ((stasks[0]>slimits[0])) then
      begin
	 s^.ctask:=0;
	 exit; 
      end;

      {$ifdef d_ships}
      write('TT');
      {$endif}
      stasks[0]:=stasks[0]+1;
      s^.ctask:=$20; {ships continue this task forever (until death or interuption by maintenance)}
      with vessels[sid]^ do
      begin
	 cs := hulls[hull].cargo - fish;
	 us := colonists + supplies + tritanium + duranium + molybdenum;

	 if (us=0) then
	 begin
	    s^.target := nearestColonySupply(x,y);
	    if not(atPlanet(x,y,s^.target)) then
	       s^.action:=1;
	    if atPlanet(x,y,s^.target) then
	       s^.action:=3;
	 end;
	 if ((us=0) and (s^.action=3)) then
	 begin
	    unload(sid,s^.target); {make sure we are empty}
	    {find and load the colonists from the planet}
	    i:=findPlanet(s^.target);
	    if worlds[i]^.id = s^.target then
	    begin
	       us:=cs;
	       if worlds[i]^.colonists< 6000 then
		  us:=min(cs, worlds[i]^.colonists-1000);
	       if us>0 then
	       begin
		  worlds[i]^.colonists:=worlds[i]^.colonists-us;
		  colonists:=colonists+us;
		  {ok look for a world to conquer that is marked}
		  if colonists=cs then
		     if (findTargetPlanet(sid,s)) then
		     begin			     
			s^.action:=1;
			if checkTaskWord(s^.task,$40) then
			begin
			   mission:=10; {cloak!}
			   beamUpFuel(sid);
			end;
		     end;			   
	       end;
	    end;
	 end;{endif (us<cs) and s^.action=3)}
	 if ((us=cs) and atplanet(x,y,s^.target) and (s^.action=3)) then
	 begin
	    unloadtoP[7] := s^.target;
	    unloadtoP[5] := colonists;
	    colonists:=0;
	    s^.action :=1;
	    s^.target := nearestColonySupply(x,y);
	 end;
      end;
   end;



end.
