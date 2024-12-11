{unit implementing AI for starbases}

unit Bases;

interface
uses RST,planets,shiputil,shipclas,parts,hull,map,shipstat,diplo;

var
   sbases     : array[1..400] of starbaseptr;
   nbase      : word;
   hullDemand : array[0..9] of integer;
   shipLimit  : boolean;
   { demand for
   0 colony freighter
   1 large freighter
   2 small warship
   3 med warship
   4 Battle cruiser
   5 Battle Ship
   6 factory ship (fighters)
   7 light carrier (anti warship)
   8 heavy carrier (anti planet)
   9 alchemy/refinery ships
   }

procedure doBases;
procedure resetBases;


implementation

   function resourceState(p :  planetptr): byte;
   var r : byte;
   begin
      resourceState := 0; {ok to build fighters and torpedoes at max capacity}
      r:= 0;
      with p^ do
      begin
	 {build some fighters and torpedoes just not as many}
	 if ((tmined<500) or (dmined<500) or (mmined<500)) then r := 1;
	 {don't make many fighters and torpedoes, keep materials for building ships.}
	 if ((tmined<300) or (dmined<300) or (mmined<300)) then r := 2;
	 {don't make any torps/fighters}
	 if ((tmined<100) or (dmined<100) or (mmined<100)) then r := 3;
	 {if we've hit the shiplimit we should always do _some_ building of resources}
	 if shipLimit then r:= min(r,2);
      end;
      resourceState:=r;
   end;

   function upgradeTech(var tech : word; p:planetptr):boolean;     
   begin
      upgradeTech:=false;
      if tech>5 then exit; {will need to be changed for registered users}
      with p^ do
      begin
	 if (credits>(tech*100)) then
	 begin
	    upgradeTech:=true;
	    credits:= credits-tech*100;
	    tech:=tech+1;
	 end;
      end;
   end; { upgradeTech }

   function buildFighter(var fighters : word; p:planetptr):boolean;
   var
      s	: byte;
      c	: byte;
   begin
      buildFighter:=false;
      s:= resourceState(p);
      c:= 60; {number of fighters to build}
      if s = 1 then c:=5;
      if s = 2 then c:=2;
      if s = 3 then exit;
      with p^ do
      begin
	 if ((credits>100) and (tmined>3) and (mmined>2) and (fighters<60) and (c>0)) then
	 begin
	    fighters:=fighters+1;
	    credits:= credits-100;
	    tmined:=tmined-3;
	    mmined:=mmined-2;
	    c:=c-1;
	    buildFighter:=true;
	 end;
      end;
   end; { buildFighter }

   function AlchemyNeeded(bid : word):word;
   var
      i,c : word;
      a,r : boolean ;
      loc : word;
      w	  : planetptr;
   begin
      a:=false;
      r:=false;
      w:=nil;
      loc := sbases[bid]^.baseid;
      for i:= 1 to nvessel do
	 with vessels[i]^ do
	 begin
	    if ((x = chart[loc].x) and (y = chart[loc].y)) then
	    begin
	       if hull = 105 then a:=true;
	       if hull = 104 then r:=true;
	       {if hull = 97 then r:=true; shareware users don't get this one}
	    end;
	 end;
      for c:= 1 to nworlds do
	 if worlds[c]^.id=loc then  w := worlds[c];
      if (w^.Nmined>2000) then r:=true;
      if (w^.Tmined >2000) then
	 if (w^.Dmined >2000) then
	    if (w^.Mmined>2000) then a:=true;
      i:=2;
      if (a and not(r)) then i:=1;
      if (r and not(a)) then i:=0;
      if (not(r) and not(a)) then i:=0;
      AlchemyNeeded:=i;
   end;

   function checkSpecialShips(tech,money :word):word;
   var
      z	      : word;
      cr      : word; {best cruiser (for working out if we need to build different hulls for sweeping/laying)}
      crt,crc : word; {task and class for the best cruiser}
      ms      : word; {minesweeper}
   begin
      {this function returns the index for a special ship that needs to be built}
      checkSpecialShips:=0;
      { we require at least one supply freighter!}
      if ((hullCount(17)=0) and (tech=6) and (hulldemand[1]>0) ) then
      begin
	 checkSpecialShips:=supplyFreighter(tech);
	 exit;
      end; { checkSpecialShips }
      if (stasks[6]<2) then
      begin
	 checkSpecialShips:=bestFhunter(tech,money);
	 inc(stasks[6]);
	 exit;
      end;
      {do not build these special ships before turn 30}
      if turnNumber<20 then exit;
      {tankers}    
      z:=tanker(tech);
      if ((stasks[4] < 4) and (z>0) and (hullCount(z)<4)) then
      begin 
	 checkSpecialShips:=findhull(z,tech);
	 inc(stasks[4]);
	 exit;
      end; { doBases }
      cr := getHullId(bestCruiser(tech,money)); {find the best cruiser available.}
      if player=5 then {the mbr is a small ship and better than the cruiser class}
	 cr:=getHullId(bestFhunter(tech,money));
      crc:=0; crt:=0;
      if cr>0 then 
	 getShipClass(cr,crc,crt); {get the task and class for the hull}
      
      {if the best cruiser can't lay mines build minelayers}
      if ((crt and $100>0) and (stasks[1] < slimits[1])) then
      begin
	 checkSpecialShips := findhull(layer(tech),tech);
	 inc(stasks[1]);
	 exit;
      end;

      {build the minesweeper ships if they have more beams than the standard cruiser}
      if stasks[5] < slimits[5] then
      begin
	 ms := sweeper(tech);
	 if ((cr>0) and (ms>0)) then
	    if (hulls[cr].beams < hulls[ms].beams) then
	    begin
	       checkSpecialShips:=findhull(ms,tech);
	       inc(stasks[5]);
	       exit;
	    end
	    else
	       inc(hulldemand[3]);
      end;
      
      {in future check for the teraformers, dwarfstar, SSD, lady royal, loki,
      and glory devices (plus any other race special ships there are)}

      {teraformers}
      {eros    cooler (fed and lizard)}
      z:= findhull(8,tech) ;
      if ((z>0) and (hullCount(8)<3) and (stasks[2]<6) and (player=1)) then
      begin
	 checkSpecialShips:=z;
	 inc(stasks[2]);
	 exit;
      end;
      if ((z>0) and (player=2) and (stasks[2]<3) ) then
      begin
	 checkSpecialShips:=z;
	 inc(stasks[2]);
	 exit;
      end;
      {bohemian   heater (fed only)}
      z:= findhull(3,tech);
      if ((z>0) and (hullCount(3)<7) and (stasks[2]<6)) then
      begin
	 checkSpecialShips:=z;
	 inc(stasks[2]);
	 exit;
      end;
      {Onyx    heater}
      z:= findhull(64,tech);
      if ((z>0) and (stasks[2]<3) and (hullCount(64)<3)) then
      begin
	 checkSpecialShips:=z;
	 inc(stasks[2]);
	 exit;
      end;
      {privateers do not usually build transport vessels }
      if player=5 then
      begin
	 {look for dwarfstars}
	 if ((stasks[0] < slimits[0]) and (hullcount(43)<sLimits[0])) then
	 begin
	    checkSpecialShips:=findhull(43,tech);
	    inc(stasks[0]);
	    exit;
	 end;
	 {look for the torpedo boat, it's small fast and cheap}
	 if ((hulldemand[2] > 0) and (hullcount(45)<6)) then
	 begin
	    checkSpecialShips:=findhull(45,tech);
	    dec(hulldemand[2]);
	    exit;
	 end;
      end;
      {Fed building (higher tech ships)
      thor (11)  and missouri (13)}
      if ((player=1) and (tech>6)) then
      begin
	 if ((hullCount(11) < 10) and (hulldemand[3]>0)) then
	 begin
	    checkSpecialShips:=findhull(11,tech);
	    dec(hulldemand[3]);
	 end;
	 if ((hullCount(13) < 6) and (hulldemand[5]>0))  then
	 begin
	    dec(hulldemand[5]);
	    checkSpecialShips:=findhull(13,tech);
	 end;
	 exit;
      end;
      {(42) lady royal (privateers and colonials)}
      if ((findhull(42,tech)>0) and (hullcount(42) < 3)) then
      begin
	 checkSpecialShips:=findhull(42,tech);
	 exit;
      end;
      { (96) cobol cruiser }
      if ((findHull(96,tech)>0) and (hullcount(96) < 5))  then
      begin
	 checkSpecialShips:=findhull(96,tech);
	 exit;
      end;
      { (69) super Star destroyer }
      if ((findHull(69,tech)>0) and (hullcount(69)<6)) then
      begin
	 checkSpecialShips:=findhull(69,tech);
	 exit;
      end;

      {choose hulls if we have reached the ship limit
        this should choose general purpose craft that each race needs lots of
        and only should be applied to standard non-tech 10 worlds}
      if ((tech >6) or not(shipLimit)) then exit;
      
      if ((player=3) or (player=4) or (player=1) or (player=2) or (player=6)) then
	 checkSpecialShips := bestCruiser(tech,money);
      if ((player=5)) then
	 checkSpecialShips := bestFHunter(tech,money);
      if (player=7) then
	 checkSpecialShips := BattleCruiser(tech,money);
      if (player=8) then
	 checkSpecialShips := findhull(69,tech);
      if ((player=10) or (player=11) or (player=9)) then
	 checkSpecialShips := lightCarrier(tech,money);      
   end;

   function chooseHull(tech,money,bid : word; var class:word):word;
   var
      i,c,d : word;
      t	 : targetptr;
   begin
      chooseHull:=0;
      {first turn we attempt to build a large deep space freighter}
      if turnNumber=1 then
      begin
	 chooseHull:= supplyFreighter(tech);
	 class:=1;
	 exit;
      end;
      c:=10; {use to mark the one with most demand}
      d:=0; {use to measure demand}
      for i:=0 to 9 do
	 if hulldemand[i]>d then
	 begin
	    c:=i;
	    d:=hulldemand[i];
	 end;
      d:=0;
      if c=0 then d:= colonyFreighter(tech);
      if c=1 then d:= supplyFreighter(tech);
      if c=2 then d:= bestFhunter(tech,money);
      if c=3 then d:= bestCruiser(tech,money);
      if c=4 then d:= BattleCruiser(tech,money);
      if c=5 then d:= BattleShip(tech,money);
      if c=6 then d:= factory(tech,money);
      if c=7 then d:= lightCarrier(tech,money);
      if c=8 then d:= heavyCarrier(tech,money);
      if c=10 then d:= checkSpecialShips(tech,money);
      if ((hulldemand[9]>0) and (tech=10)) then
      begin
	 i := alchemyNeeded(bid);
	 if i=0 then d:= findhull(105,tech);
	 if i=1 then d:= findhull(104,tech);
      end;

      if d>0 then
	 if ((tech>6) and (hulls[getHullid(d)].tech<7)) then d:=0;
      {$ifdef d_base}
      write('(c');
      write(c,')');
      {$endif}
      if ((d=0) and not(c=10)) then
      begin
	 i:= hulldemand[c];
	 hulldemand[c]:=0;
	 d:=chooseHull(tech,money,bid,class);
	 hulldemand[c]:=i;
	 c:=class;
      end;
      class:=c;
      chooseHull:=d;
   end;

   procedure buildShip(bid : word; p:planetptr);
   var
      dcost,tcost,mcost,ccost : longint; {cost}
      hl,ee,bm,tb	      : integer; {hullid,engines,beams,tubes}
      et,bt,tt	              : integer; {engine type,beam type, tube type}
      temp		      : integer; {temporary}
      cl                      : word;
   begin
      with sbases[bid]^ do
      begin
	 temp:=10000;
	 if (p^.credits<maxint) then
	    temp:=(p^.credits) - 150;
	 if temp<0 then exit;
	 setSupply(p^.tmined,p^.dmined,p^.mmined);
	 {check what we are building already should be built}
	 if buildhull>0 then
	 begin
	    {we know the ship limit must be reached!}
	    shipLimit:= true;
	    cl := getSupplyCode(getHullid(buildhull));
	    temp:= getHullid(buildhull);
	    {reasons to build a ship that we don't really need (in terms of demand anyway)}
	    if (isTeraformer(temp) and (stasks[2]<6)) then exit;
	    if isSpecial(temp) then exit;
	    if ((tanker(Htech) = temp) and (stasks[4] < 3)) then exit;
	    {ok check if we should continue to build it!}
	    if not(cl=10) then
	       if hulldemand[cl]>0 then
	       begin
		  hulldemand[cl]:=hulldemand[cl]-1;
		  exit;
	       end;
	    buildhull:=0;
	    Etype:=0;
	    Btype:=0;
	    Bcount:=0;
	    Ttype:=0;
	    Tcount:=0;
	 end
	 else
	 begin
	    Etype:=0;
	    Btype:=0;
	    Bcount:=0;
	    Ttype:=0;
	    Tcount:=0;
	 end;
         hl := chooseHull(Htech,temp,bid,cl);
	 if hl = 0 then
	 begin {we couldn't pick one! construct one out of stock!}
	    for cl:= 1 to 20 do
	       if Hstore[cl]>0 then hl:=cl;
	    cl:= getSupplyCode(getHullid(hl)); {we don't know which supply this applies to!}
	    if cl=10 then
	    begin {check against special types}
	       temp:= getHullid(hl);
	       {reasons to not build a ship out of stock}
	       if (isTeraformer(temp) and (stasks[2]>5))  then exit;
	       if ((tanker(Htech) = temp) and (stasks[4] >3)) then exit;
	    end;
	 end;
	 if ((cl=6) and (fighters>40)) then exit;
	 if ((cl<10) and not(shipLimit)) then
	    if hulldemand[cl]<1 then exit;
	 {$ifdef d_base}
	 write('(s',hl,'sc',cl,')');
	 {$endif}
	 if hl<=0 then exit;
	 if hl>20 then exit;
	 temp:= getHullid(hl);
	 dcost:=0;
	 tcost:=0;
	 mcost:=0;
	 ccost:=0;
	 if HStore[hl]=0 then
	 begin
	    dcost := hulls[temp].dcost;
	    tcost := hulls[temp].tcost;
	    mcost := hulls[temp].mcost;
	    ccost := hulls[temp].cost;
	 end;
	 ee := hulls[temp].engines;
	 bm := hulls[temp].beams;
	 tb := hulls[temp].tubes;

	 et := getBestEng(Etech);
	 ee := ee - EStore[et];
	 if ee<0 then ee:=0;
	 dcost := dcost + (engines[et].dcost*ee);
	 tcost:= tcost + (engines[et].tcost*ee);
	 mcost:= mcost + (engines[et].mcost*ee);
	 ccost:= ccost + (engines[et].cost*ee);
	 
	 if bm>0 then
	    begin
	       temp:=10000;
	       if (p^.credits<maxint) then
		  temp:=(p^.credits) - ccost;
	       if temp<0 then exit;
	       bt := getBestBeam(temp,bm,Wtech);
	       if ((player = 5) and isCloaker(gethullid(hl))) then bt:= getKillBeam(temp,bm,Wtech);
               if bt = 0 then exit;
	       bm:= bm - BStore[bt];
	       if bm<0 then bm:=0;
	       dcost := dcost + (weapons[bt].dcost*bm);
	       tcost := tcost + (weapons[bt].tcost*bm);
	       mcost := mcost + (weapons[bt].mcost*bm);
	       ccost := ccost + (weapons[bt].cost*bm);
	    end;

	 if tb>0 then
	    begin
	       temp:=10000;
	       if (p^.credits<maxint) then
		  temp:=(p^.credits) - ccost;
	       if temp<0 then exit;
	       tt:= getBestTube(temp,tb,Ttech);
               if tt=0 then exit;
	       tb:=tb - TStore[tt];
	       if tb<0 then tb :=0;
	       dcost := dcost + (parts.torps[tt].dcost *tb);
	       tcost := tcost + (parts.torps[tt].tcost *tb);
	       mcost := mcost + (parts.torps[tt].mcost *tb);
	       ccost := ccost + (parts.torps[tt].costtube*tb);
	    end;

	 {ok check the costs against what is there and build}
	 if ( (dcost<p^.dmined) and (tcost<p^.tmined) and
	     (mcost<p^.mmined) and (ccost<p^.credits) ) then
	 begin
	    {okay build}
	    {$ifdef d_base}
	    write('B');
	    {$endif}
	    if not(cl=10) then
	       hulldemand[cl]:=hulldemand[cl]-1;
	    if Hstore[hl] = 0 then
	       Hstore[hl]:=1;
	    EStore[et]:=EStore[et]+ee;
	    if (bm>0) then BStore[bt]:=Bstore[bt]+bm;
	    if (tb>0) then TStore[tt]:=TStore[tt]+tb;
	    buildhull:=hl;
	    Etype:=et;
	    temp:= getHullid(hl);
	    if hulls[temp].Beams>0 then Btype:=bt;
	    Bcount:=hulls[temp].Beams;
	    if hulls[temp].tubes>0 then Ttype:=tt;
	    Tcount:=hulls[temp].tubes;
	    {deduct cost!}
	    p^.dmined:= p^.dmined-dcost;
	    p^.tmined:= p^.tmined-tcost;
	    p^.mmined:= p^.mmined-mcost;
	    p^.credits:= p^.credits-ccost;		
	 end; 
	 
      end;
   end;

   procedure loadSupplies(bid : word; p:planetptr);
      var
	 i,l   : word;
	 us,sl : integer;
   begin
      with sbases[bid]^ do 
	 for i:=1 to nvessel do
	 begin
	    if ((vessels[i]^.y = chart[baseid].y) and (vessels[i]^.x = chart[baseid].x)
		and ((vessels[i]^.tcount>0) or (vessels[i]^.damage>0)) ) then
	    begin
	       with vessels[i]^ do
	       begin
		  us := supplies + colonists + molybdenum + tritanium + duranium + fish;
		  us:=hulls[hull].cargo - us;
		  l:= loadout(hull);
		  if fish<l then
		  begin
		     us:= us - (l-fish);
		  end;
	       end;
	       if ((us>0) and (vessels[i]^.supplies<50)) then
	       begin
		  sl := min(50,(p^.supplies)-100 );
		  sl := min(sl,us);
		  if sl<0 then sl:=0;     
		  if sl>0 then
		  begin
		     vessels[i]^.supplies := vessels[i]^.supplies + sl;
		     p^.supplies := p^.supplies - sl;
		  end;
	       end;
	    end;
	 end;
   end;

   procedure loadTorps(bid : word; p:planetptr);
   var
	 i,l   : word;
	 us,tt : integer;
          s    : byte;
   begin
      with sbases[bid]^ do 
	 for i:=1 to nvessel do
	 begin
	    if ((vessels[i]^.y = chart[baseid].y) and (vessels[i]^.x = chart[baseid].x)
		and (vessels[i]^.tcount>0)) then
	    begin
	       with vessels[i]^ do
		  us := supplies + colonists + molybdenum + tritanium + duranium;
	       tt := loadout(vessels[i]^.hull) + 10;
	       us:= min(tt, (hulls[vessels[i]^.hull].cargo) - us);
	       if getState(vessels[i]^.id)^.ctask=$100 then
	       begin
		  with vessels[i]^ do
		     us := supplies + colonists + molybdenum + tritanium + duranium;
		  tt:= min(100,tt*4);
		  us:=min(tt,(hulls[vessels[i]^.hull].cargo) - us);
	       end;
	       tt := vessels[i]^.torp;
	       if (not(isCarrier(vessels[i]^.hull)) and (tt>0) and (us>0)) then
	       begin
		  if vessels[i]^.fish>us then
		  begin
		     l:= vessels[i]^.fish-us;
		     l:= min(vessels[i]^.fish,l);
		     vessels[i]^.fish:=vessels[i]^.fish-l;
		     torps[tt]:=torps[tt]+l;
		  end;
		  if ((torps[tt]>0) and (vessels[i]^.fish<us)) then
		  begin
		     l:= min(us,torps[tt]);
		     vessels[i]^.fish:=vessels[i]^.fish+l;
		     torps[tt]:=torps[tt]-l;
		  end;
		  {check the resource state and adjust the amount to load}
		  s:= resourceState(p);
		  if s = 3 then exit; {don't load torps!}
		  if s = 2 then
		     us := min(us,vessels[i]^.fish+5);
		  if s = 1 then
		     us := min(us,vessels[i]^.fish+20);
		     		  
		  if ((torps[tt]=0) and (vessels[i]^.fish<us) and (Ttech>=parts.torps[tt].tech)) then
		     while ((vessels[i]^.fish <  us) and
			    (p^.credits>parts.torps[tt].costtorp)
			    and (p^.tmined>0) and (p^.dmined>0) and (p^.mmined>0))
			do
		     begin
			vessels[i]^.fish := vessels[i]^.fish+1;
			p^.credits := p^.credits-parts.torps[tt].costtorp;
			p^.tmined:=p^.tmined-1;
			p^.dmined:=p^.dmined-1;
			p^.mmined:=p^.mmined-1;
		     end;
	       end;
	    end;
	 end;
   end;

   procedure fixShips(bid : word);
   var
      i	: word;
   begin
      with sbases[bid]^ do 
	 for i:=1 to nvessel do
	 begin
	    if ( ( vessels[i]^.x = chart[baseid].x) and (vessels[i]^.y = chart[baseid].y) and
		(vessels[i]^.damage>0) ) then
	    begin
	       opid:= vessels[i]^.id;
	       op := 1;
	    end	    
	 end;
   end;

   procedure engineRefit(bid : word; p:planetptr);
   var
      i	: word;
   begin 
      {check for and build engines if we need some}
      with sbases[bid]^ do
      begin
	 while ((Estore[9] < 6) and (p^.tmined>engines[9].tcost) and (p^.dmined>engines[9].dcost)
		and (p^.mmined>engines[9].mcost) and (p^.credits > engines[9].cost)) do
	 begin
	    Estore[9] := Estore[9] + 1;
	    p^.tmined:=p^.tmined - engines[9].tcost;
	    p^.dmined:=p^.dmined - engines[9].dcost;
	    p^.mmined:=p^.mmined - engines[9].mcost;
	    p^.credits :=p^.credits - engines[9].cost;
	 end;

	  for i:=1 to nvessel do
	       if ( (vessels[i]^.x = chart[baseid].x)
		   and (vessels[i]^.y = chart[baseid].y)
		   and (vessels[i]^.eng<9) and (Estore[9] > 3)) then
	       begin
		  {$IFDEF d_base}
		  write('E');
		  {$ENDIF}
		  vessels[i]^.speed:=0;
		  vessels[i]^.mission:=9;
	       end;
      end;      
   end; { engineRefit }

   procedure weaponRefit(bid : word; p:planetptr);
   var
      i	: word;
   begin 
      {check for and build engines if we need some}
      with sbases[bid]^ do
      begin
	 while ((Bstore[10] < 10) and (p^.tmined>weapons[10].tcost) and (p^.dmined>weapons[10].dcost)
		and (p^.mmined>weapons[10].mcost) and (p^.credits > weapons[10].cost)) do
	 begin
	    Bstore[10] := Bstore[10] + 1;
	    p^.tmined:=p^.tmined - weapons[10].tcost;
	    p^.dmined:=p^.dmined - weapons[10].dcost;
	    p^.mmined:=p^.mmined - weapons[10].mcost;
	    p^.credits :=p^.credits - weapons[10].cost;
	 end;

	  for i:=1 to nvessel do
	       if ( (vessels[i]^.x = chart[baseid].x)
		   and (vessels[i]^.y = chart[baseid].y) and (vessels[i]^.beam<10)
		   and (vessels[i]^.bcount>0) and (Bstore[10]>vessels[i]^.bcount) ) then
	       begin
		  {$IFDEF d_base}
		  write('W');
		  {$ENDIF}
		  vessels[i]^.speed:=0;
		  vessels[i]^.mission:=9;
	       end;
      end;      
   end; { weaponRefit }

   procedure loadFighters(bid :word) ;
   var
      i	    : word;
      c	    : boolean ;
      ftl   : integer;
      cl,tk : word;
      us    : word;
   begin
      with sbases[bid]^ do
      begin
	 if fighters=0 then exit;
	 c:=true;
	 while c do
	 begin
	    c:=false;
	    {load some ships}
	    for i:=1 to nvessel do
	       if (isCarrier(vessels[i]^.hull)
		   and (vessels[i]^.x = chart[baseid].x)
		   and (vessels[i]^.y = chart[baseid].y) ) then
	       begin
		  getShipClass(vessels[i]^.hull,cl,tk);
		  with vessels[i]^ do
		  begin
		     us := supplies + colonists + molybdenum + tritanium + duranium;
		     ftl := loadout(hull) + 15;
		     ftl := min(ftl , (hulls[hull].cargo - us));
		  end;
		  if (not(tk and $10=$10) ) then
		     while ((vessels[i]^.fish < ftl) and (fighters>0))
			do
		     begin
			c:=true;
			fighters:=fighters-1;
			vessels[i]^.fish := vessels[i]^.fish+1;
		     end;
	    end;
	    {unload some ships}
	    for i:=1 to nvessel do
	    begin
	       getShipClass(vessels[i]^.hull,cl,tk);
	       if (isCarrier(vessels[i]^.hull) and (tk and $10=$10)
		   and (vessels[i]^.x = chart[baseid].x) and (vessels[i]^.y = chart[baseid].y)) then
		  while ((vessels[i]^.fish > 0) and (fighters<60))
		     do
		  begin
		     c:=true;
		     fighters:=fighters+1;
		     vessels[i]^.fish := vessels[i]^.fish-1;
		  end;
	    end;
	 end;
      end; 
   end; { loadFighters }

   procedure fleetModifier;
   var
      ew : integer;
   begin
      if ((turnNumber>15) or (targetCount>0)) then
      begin
	 ew:= (nworlds div 25) +1;
	 hulldemand[2]:=hulldemand[2]+(2*ew); {light}
	 hulldemand[3]:=hulldemand[3]+(7*ew); {cruiser}
	 hulldemand[4]:=hulldemand[4]+(6*ew); {bc}
	 hulldemand[5]:=hulldemand[5]+(3*ew); {bs}
	 hulldemand[7]:=hulldemand[7]+(5*ew); {light carrier}
	 hulldemand[8]:=hulldemand[8]+(3*ew); {heavy carrier}
      end;
      if (player=1) then
      begin
	 hulldemand[5] := hulldemand[5] + hulldemand[8];
	 hulldemand[8] :=0;
	 hulldemand[2] := hulldemand[2] div 3;
	 hulldemand[3] := hulldemand[3] + (hulldemand[2]*2);
	 hulldemand[4] := hulldemand[4] + hulldemand[2];
	 if ((hulldemand[9] = 0) and (hullsupply[9]=0)) then
	 begin {if the fed have no tech 10 planets}
	    hulldemand[3] := hulldemand[3] + hulldemand[4] + hulldemand[5] + hulldemand[7];
	 end;
      end;
      if (player=2) then
      begin
	 hulldemand[5] := hulldemand[5] + hulldemand[8];
	 hulldemand[8] :=0;
	 hulldemand[2] := hulldemand[2] div 2;
	 hulldemand[3] := hulldemand[3] + hulldemand[2];
	 hulldemand[3] := hulldemand[3] + (hulldemand[4] div 2);
	 hulldemand[5] := hulldemand[5] + (hulldemand[4] div 2);
	 hulldemand[4] :=0;
	 if ((hulldemand[9] = 0) and (hullsupply[9]=0)) then
	 begin {if the lizard have no tech 10 planets}
	    hulldemand[3] := hulldemand[3] + hulldemand[5] + hulldemand[7];
	 end;
      end;
      if ((player = 3) or (player =4)) then
      begin
	 hulldemand[5]:=hulldemand[5] + hulldemand[8];
	 hulldemand[8]:=0;
	 if ((hulldemand[9] = 0) and (hullsupply[9]=0)) then
	 begin {if the rom/kling have no tech 10 planets}
	    hulldemand[3] := hulldemand[3] + hulldemand[5];
	    if player=3 then hulldemand[7]:=hulldemand[7] + hulldemand[4];
	 end;
      end;
      if (player=5) then
      begin
	 hulldemand[3] := hulldemand[3] div 2;
	 hulldemand[2] := hulldemand[2] + hulldemand[3] + hulldemand[4];
	 hulldemand[7] := hulldemand[7] + hulldemand[8] + hulldemand[5];
	 hulldemand[8]:=0;
	 hulldemand[5]:=0;
	 hulldemand[4]:=0;
      end;
      if (player=6) then
      begin
	 hulldemand[3] := hulldemand[3] + hulldemand[4];
	 hulldemand[5] := hulldemand[5] + (hulldemand[7] div 2);
	 hulldemand[8] := hulldemand[8] + (hulldemand[7] div 2);
	 hulldemand[4] := 0;
	 hulldemand[7] := 0;
      end;
      if player=7 then
      begin
	 hulldemand[3] := hulldemand[3] div 2;
	 hulldemand[2] := hulldemand[2] + hulldemand[3];
	 hulldemand[4] := hulldemand[4] + hulldemand[3];
	 hulldemand[3] := 0;
	 hulldemand[5]:=hulldemand[5]+hulldemand[7];
	 hulldemand[7]:=0;
      end;
      if player=8 then
      begin
	 hulldemand[7] := hulldemand[7] + hulldemand[4] + hulldemand[5] +hulldemand[2] ;
	 hulldemand[2] :=0;
	 hulldemand[4]:=0;
	 hulldemand[5]:=0;
      end;
      if player = 9 then
      begin
	 hulldemand[3]:= hulldemand[3] div 2;
	 hulldemand[2] := hulldemand[2] + hulldemand[3];
	 hulldemand[8] := hulldemand[8] + hulldemand[4] + hulldemand[5]+ hulldemand[7] +  hulldemand[3];
	 hulldemand[7]:=0;
	 hulldemand[3]:=0;
	 hulldemand[4]:=0;
	 hulldemand[5]:=0;
      end;
      if ((player = 10) or (player=11)) then
      begin
	 hulldemand[2] := hulldemand[2] + hulldemand[3];
	 hulldemand[3] := hulldemand[4] div 2;
	 hulldemand[7] := hulldemand[7] + hulldemand[4] div 2;
	 hulldemand[8] := hulldemand[8] + hulldemand[5] ;
	 hulldemand[4] :=0;
	 hulldemand[5] :=0;
      end;
   end;

{ Recycle ships that are old and out of date}
{ normal life span 50 turns = 500 points
  100 points per tech bellow eng tech
  50 points per tech bellow torp tech -1
  10 points per tech bellow beam tech -1}
   procedure recycle;
   var
      i	    : integer;
      score : integer;
      tech  : word;
      s	    : stateptr;
   begin
      for i:= 1 to nvessel do
	 with vessels[i]^do
	 begin
	    s:= getState(id);
	    score:=0;
	    {engine tech}
	    tech := engines[eng].tech;
	    if tech<6 then score:=score + (100* ( 6-tech));
	    {beam tech}
	    if bcount>0 then
	    begin
	       tech := weapons[beam].tech +1;
	       if tech<6 then score:=score + (10* ( 6-tech));
	    end;
	    {torp tech}
	    if tcount>0 then
	    begin
	       tech := parts.torps[torp].tech+1;
	       if tech<6 then score:=score + (50* ( 6-tech));
	    end;
	    if hull = 16 then score := 1; {recycle medium deep space freighters}
	    {add age if some technology is out of date}
	    if score>0 then score:=score+(s^.age*10);
	    {reasons a ship will be spared from recycling}
	    if hulls[hull].tech>6 then score:=0;
	    if isTeraformer(hull) then score:=0;
	    tech := s^.task;
	    if tech and $200 >0 then score:=0;
	    if tech and $400 >0 then score:=0;
	    if tech and $800 >0 then score:=0;
	    {tasks that won't be interrupted!}
	    tech:= s^.ctask;
	    if tech = $2001 then score:=0;
	    if tech = $4002 then score:=0;
	    if tech = $4001 then score:=0;
	    if tech = $4004 then score:=0;
	    if tech = $4003 then score:=0;
	    if tech = $10 then score:=0;
	    if tech = $9 then score:=0;
	    {ok if score is above 500 then recycle}
	    if (score>500) then
	    begin
	       {$ifdef d_ships}
	       writeln('Recycling ',id,' score ',score);
	       {$endif}
	       mission:=6;
	       s^.ctask:=$FFFF; {recycle task}
	       speed:=eng;
	       s^.action:=1;
	       s^.target:= nearestOwnedWorld(x,y);
	       checkActions(i,s);
	    end;
	 end;
   end;


   procedure doBases;
   var
      i,c	: word;
      p		: planetptr;
      devel	: boolean;
      pb	: word;
      t		: integer;
      lowEtechR	: integer;
   begin
      writeln('Using StarBases');
      shipLimit:=false;
      initBase; {needed for initialising ship building}
      lowEtechR:=1;
      {calculate ship demand}
      for i:=0 to 9 do
	 hulldemand[i]:=0;
      hulldemand[0]:=5;
      if (turnNumber<50) then hulldemand[0]:=13;
      hulldemand[2]:=1;
      hulldemand[1]:= 2+ (nworlds div 10);
      
      {get more medium sized ships when we need minesweepers (there should be enemies around}
      if ((stasks[1]<sLimits[1]) and (targetCount>0)) then
	 hulldemand[3] := hulldemand[3] + (sLimits[1] - stasks[1]);

      {players that are fighter reliant must have some fighter factories}
      if player>8 then hulldemand[6]:=6;
      {make a copy of the bases}
      for i:= 1 to baseCount do
      begin
	 new(sbases[i]);
	 sbases[i]^ := getBase(i)^;
	 if sbases[i]^.htech=10 then hulldemand[9]:=hulldemand[9]+2;
	 lowEtechR := max(lowEtechR,sbases[i]^.Etech);
      end;
      lowEtechR := min(6,lowEtechR);
      if player<9 then hulldemand[6]:=0;
      nbase:=baseCount;
      FleetModifier;
      {adjust demands according to supply}
      for i:=0 to 9 do
      begin
	 hulldemand[i]:= hulldemand[i] - hullsupply[i];
	 {if hulldemand[i] >25 then hulldemand[i] := 20;}
      end;
      {$ifdef d_base}
      write('hd');
      for i:= 0 to 9 do
      begin
	 write(',');
	 write(hulldemand[i]);
      end;
      writeln;
      writeln('st ',stasks[0],' ', stasks[1],' ',stasks[2],' ',stasks[3],' ',stasks[4], ' ', stasks[5], ' ', stasks[6]);
      writeln('sL ',sLimits[0],' ', sLimits[1],' ',sLimits[2],' ',sLimits[3],' ',sLimits[4],' ', slimits[5],' ', slimits[6] );
      {$endif}
      pb:=0;
      for i:=1 to nbase do
	 with sbases[i]^ do
	 begin
	    write('.');
	    devel:=false;
	    {find the planet that this base belongs to}
	    p:= worlds[findPlanet(baseID)];

	    {if we are borg and this is a tech 10 world ...}
	    if ((pb<9) and (htech=10) and (player=6)) then
	       begin
		  inc(pb);
		  p^.fcode[1]:='P';
		  p^.fcode[2]:='B';
		  p^.fcode[3]:=chr(48 + pb);
	       end;
	    
	    {load up fighters on carriers}
	    loadFighters(i);
	    
	    {sell supplies (only if more than 10000)}
	    while p^.supplies>10000 do
	    begin
	       p^.supplies:=p^.supplies-10;
	       p^.credits:=p^.credits+10;
	    end;

	    {if we need to develope technology we will not
	    perform certain tasks}
	    if ((Etech<6) or (Htech<6) or (wtech<6) or (ttech<6)) then devel:=true;
	    
	    {ok we are ready to operate the base first tech tree}
	    while upgradeTech(Etech,p) do;
	    while upgradeTech(Htech,p) do;
	    while upgradeTech(Wtech,p) do;
	    while upgradeTech(Ttech,p) do;
	    
	    {build torps and load them if needed and can build}
	    if not(devel) then loadTorps(i,p);

	    {load supplies on ships}
	    if not(devel) then loadSupplies(i,p);
		
		
	    {here is where we will build ships if we can achieve a certain tech level}
	    if ((Etech>=lowEtechR) and (Htech>=3) and (Wtech>2)) then
	       buildShip(i,p);
	    
	    {build fighters}
	    if not(devel) then
	       while buildFighter(fighters,p) do;

	    {fix ships with damage}
	    fixShips(i);

	    {fed super refit mission!}
	    if player=1 then
	    begin
	       if Etech=10 then engineRefit(i,p);
	       if Wtech=10 then weaponRefit(i,p);
	    end;


	    t:=200;
	    if devel then t:= p^.credits div 40;
	    c:= resourceState(p);
	    if c = 1 then t := 15;
	    if c = 2 then t := 5;
	    if c = 3 then t := 1;
	    
	    while ((defense<200) and (p^.credits>10)
		   and (p^.dmined>1) and (t>0)) do
	    begin
	       dec(t);
	       inc(defense);
	       p^.credits:=p^.credits-10;
	       p^.dmined:=p^.dmined-1;
	    end;
	    
	    {set mission (for max defence if needed)}
	    mission:=6;
	    {if (defense<200) then mission:=2; }
	    if (damage>0) then mission:=5;
	    
	 end;
      writeln;
      recycle;
   end; { doBases }

   procedure resetBases;
   var
      i	: word;
   begin
      for i:= 1 to nbase do
	 dispose(sbases[i]);
      nbase:=0;
      shipLimit:=false;
   end; { resetBases }

end.

