{ can work out the class of ship for any hull
will also give task words for ships so they know what they can do.}
unit shipclas;

interface

   {the task word is this in hex
   0 freighter/scout only works if the entire word is zero
   1 raider (attacks freighters)
   2 warship (kills raiders and warships also can escort)
   100 minelayer (good mine layer)
   200 alchemy ship (special task)
   400 refinery ship (special task fuel making)
   4 medium warship ( hunter killers!)
   8 heavy warship (battlegroup leaders and starbase killers)
   40 can cloak
   20 transport (ships with weapons and can carry a large amount of colonits)
   800 special ships
   80 teraformers
   10 fighter factory

   the following do no appear in task words but are possible current tasks
   1000 repair
   2000 load ordinance
   2001 battlegroup
   4000 defender
   4001 rescue
   4002 tanker
   4003 minesweep
   4004 ionstorm
   FFFF recycle

   classes
   0 freighter/scout
   1 small warship (destroyers and frigates)
   2 medium warship (cruisers)
   3 battlecruiser
   4 battleships
   8 factory/transport carriers
   9 light carriers
   10 medium carrier
   11 heavy carrier
   }

function loadout(hullid : word):integer;
function getfirepower(hulid: word):word;
function getSupplyCode(    hullid : word):word;
procedure getshipclass(var hulid,class,task: word);
function iscloaker(hulid : word):boolean;
function isSpecial(hulid : word):boolean;
function isTeraformer(hulid: word):boolean;
function iscarrier(hulid : word):boolean;
function getCombatFcode(hulid : word): string;

{starbase ship building utility functions}
   procedure initBase;
   procedure setSupply(t,d,m	: longint);
   {return index into hulls part list}
   function bestFhunter(tech,cst: word):word;
   function bestCruiser(tech,cst: word):word;
   function BattleCruiser(tech,cst : word):word;
   function BattleShip(tech,cst : word):word;
   function lightCarrier(tech,cst : word):word;
   function heavyCarrier(tech,cst : word):word;
   function factory(tech,cst	: word):word;
   function colonyFreighter(tech: word):word;
   function supplyFreighter(tech : word):word;
   {conversion utils}
   function findHull(hid,tech : word):word; {converts hull id to index}
   function getHullid(id : word):word; {converts index to id}
   {return hullid}
   function tanker(tech : word):word;
   function sweeper(tech:word):word;
   function layer(tech : word):word;
   
implementation
uses hull,RST;

var
   hullid	  : array[1..20] of word;
   cost		  : array[1..20] of word; {cost to build}
   class	  : array[1..20] of word; {class of vessel}
   eff		  : array[1..20] of real; {firepower * mass}
   tsup,dsup,msup : longint;
   
   function getCombatFcode(hulid : word):String;
   var
      fc    : string[3];
      class : word;
      task  : word;
   begin
      getShipClass(hulid,class,task);
      fc[3] := char(random(10)+48);{inititialise fc}
      fc[2] := char(random(10)+48);
      fc[1] := char(random(26)+65);
      if class = 1 then fc[1] := '1'; {small ships fight first to soften targets}
      if class = 2 then fc[1] := '2'; {cruisers (thor included) fight second to soften targets}
      if class = 9 then fc[1] := '3'; {light carriers fight next}
      if class = 10 then fc[1] := '4'; {medium carriers}
       if class = 3 then fc[1] := '5'; {battle cruisers (to clean up the remainder and to soften up planets)}
      if class = 4 then fc[1] := '6'; {battle ships }
      if class = 11 then fc[1] := '7'; {heavy carriers to finish}
     
      if hulid = 56 then fc[1] := 'f';
      getCombatFcode := fc;
   end;

   function layer(tech : word):word;
   var
      i,t	 : word; {counter and hullid}
      blc	 : integer; {best layer cargo hold (we are looking for the largest hold)}
      lc	 : integer; {layer cargo hold}
      class,task : word; { class and task word for current ship}
   begin
      blc:=0;
      lc:=0;
      layer:=0;
      for i:=1 to 20 do
      begin
	 t:= race[player].hull[i];
	 if (t>0) then
	 begin
	    getShipClass(t,class,task);
	    if (((task and $100)>0) and (hulls[t].tech<=tech)) then
	    begin {this ship is a minelayer!}
	       lc := hulls[t].cargo;
	       if (task and $40) > 0 then lc := lc + 100;
	       if lc>blc then
	       begin
		  blc:=lc;
		  layer:=t;
	       end;
	    end;
	 end;
      end;
   end; { layer }
   
   function Sweeper(tech : word):word;
   var
      i,t	 : word; {counter and hullid}
      bswc,bbc	 : integer; {best sweeper cost and best beam count}
      swc,bc	 : integer; {sweeper cost and beam count}
      class,task : word;
   begin
      bswc := 1000;
      bbc := 0;
      sweeper:=0;
      for i:= 1 to 20 do
      begin
	 t:= race[player].hull[i];
	 class:=0;
	 if t>0 then 
	    getShipClass(t,class,task);
	 if (((class=1) or (class=2)) and (hulls[t].tech<=tech)) then
	    begin
	       swc := hulls[t].tcost + hulls[t].dcost + hulls[t].mcost + hulls[t].cost;
	       bc := hulls[t].beams;
	       if bc > bbc then
	       begin
		  bbc := bc;
		  bswc := swc;
		  sweeper := t;
	       end;
	       if ((bc=bbc) and (swc<bswc)) then
	       begin
		  bswc := swc;
		  sweeper := t;
	       end;
	    end;
      end;
   end;   
   
   function tanker(tech : word):word;
   var
      i,t    : word;
      te,bte : real;
   begin
      bte :=0;
      tanker:=0;
      for i:=1 to 20 do
      begin
	 t := race[player].hull[i];
	 if t>0 then
	 begin
	    te:= int(hulls[t].fueltank) / int(hulls[t].mass);
	    if ((te>bte) and (hulls[t].tech<=6)) then
	    begin
	       bte:=te;
	       tanker:=t;
	    end;
	 end;
      end;
   end;

   procedure setSupply(t,d,m	: longint);
   begin
      tsup:=t;
      dsup:=d;
      msup:=m;
   end;

   function getfirepower(hulid: word):word;
   var
      f	: word;
   begin
      f:=hulls[hulid].beams+(2*hulls[hulid].tubes)+(3*hulls[hulid].bays);
      getfirepower:=f;
   end; { getfirepower }

   procedure initBase;
   var
      i,t    : word;
   begin
      for i:=1 to 20 do
      begin
	 hullid[i] := race[player].hull[i];
	 if hullid[i]>0 then
	 begin
	    cost[i] := hulls[hullid[i]].cost;
	    getShipClass(hullid[i],class[i],t);
	    eff[i] := getfirepower(hullid[i])*(hulls[hullid[i]].mass);
	 end;
      end;
   end; { initBase }

   function bestPerClass(clss,tech,cst : word):word;
   var
      i	       : word;
      b	       : word;
      c	       : real;
      st,hid   : word;
      tc,dc,mc : word;
   begin
      b:=0;
      c:=0;
      hid:=0;
      bestPerClass:=0;
      for i:= 1 to 20 do
	 if hullid[i] >0 then
	 begin
	    st:=hulls[hullid[i]].tech;
	    tc:=hulls[hullid[i]].tcost;
	    dc:=hulls[hullid[i]].dcost;
	    mc:=hulls[hullid[i]].mcost;
	    hid:=hullid[i];
	    if ((class[i]=clss) and (eff[i]>c) and (cost[i]<cst) and
		(st <= tech ) and not(hid=105) and not(hid=104)
		and (tc<tsup) and (dc<dsup) and (mc<msup) and (hid>0) ) then
	    begin
	       b:=i;
	       c:=eff[i];
	    end;
	 end;
      bestPerClass:=b;
   end;

   function bestFhunter(tech,cst:word):word;
   begin
      bestFhunter:=bestPerClass(1,tech,cst);
   end;

   function bestCruiser(tech,cst: word):word;
   var
      b	: word;
   begin
      b:=bestPerClass(2,tech,cst);
      bestCruiser:=b;
   end;

   function BattleCruiser(tech,cst : word):word;
   begin
      BattleCruiser:=bestPerClass(3,tech,cst);
   end;

   function BattleShip(tech,cst : word):word;
   begin
      BattleShip:=bestPerClass(4,tech,cst);
   end;

   function lightCarrier(tech,cst : word):word;
   var
      b	: word;
   begin
      b:=bestPerClass(9,tech,cst);
      if b=0 then b:= bestPerClass(10,tech,cst);
      lightCarrier:=b;
   end;

   function heavyCarrier(tech,cst : word):word;
   var
      b	: word;
   begin
      b:= bestPerClass(11,tech,cst);
      if b=0 then b:= bestPerClass(10,tech,cst);   
      heavyCarrier:=b;
   end; { heavyCarrier }

   function factory(tech,cst	: word):word;
      var
      i	: word;
      b	: word;
      c	: word;
   begin
      b:=0;
      c:=0;
      for i:= 1 to 20 do
      if hullid[i]>0 then
      begin
	 if ((class[i]=8) and (hulls[hullid[i]].cargo >c) and (cost[i]<cst) and
	     (hulls[hullid[i]].tech <= tech )) then
	 begin
	    b:=i;
	    c:=hulls[hullid[i]].cargo;
	 end;
      end;
      factory:=b;
   end;

   function colonyFreighter(tech : word):word;
   var
      i	: word;
      b	: word;
   begin
      b:=0;
      for i:= 1 to 20 do
      if hullid[i]>0 then
      begin
	 if ((class[i]=0) and (hulls[hullid[i]].cargo=200) and
	     (hulls[hullid[i]].tech <= tech ) and isFreighter(hullid[i])) then
	 begin
	    b:=i;
	 end;
      end;
      colonyFreighter:=b;
   end; { colonyFreighter }

   function supplyFreighter(tech : word):word;
   var
      i	  : word;
      b,c : word;
   begin
      b:=0;
      c:=200;
      for i:= 1 to 20 do
      if hullid[i]>0 then
      begin
	 if ((class[i]=0) and (hulls[hullid[i]].cargo>c) and
	     (hulls[hullid[i]].tech <= tech )) then
	 begin
	    b:=i;
	    c:=hulls[hullid[i]].cargo;
	 end;
      end;
      supplyFreighter:=b;
   end;

   function findHull(hid,tech : word):word;
   var
      i	: word;
   begin
      findHull:=0;
      if hid=0 then exit;
      for i:= 1 to 20 do
      begin
	 if ((hullid[i]=hid) and (hulls[hullid[i]].tech<=tech)) then
	 begin
	    findhull:=i;
	    exit;
	 end;
      end;
   end; { findHull }

   function getHullid(id : word):word;
   begin
      getHullid:=0;
      if id>20 then exit;
      if id<1 then exit;
      getHullid:=hullid[id];
   end; { getHullid }

   function isTeraformer(hulid: word):boolean;
   begin
      isTeraformer:=false;
      if ((hulid=8) or (hulid=3) or (hulid=64)) then isTeraformer:=true;
   end; { isTeraformer }

   function iscloaker(hulid : word):boolean;
   begin
      iscloaker:=false;
      case hulid of
	25, 22, 21, 27, 26, 32, 28, 33, 31, 47, 29, 36, 38, 44, 43, 45, 46
	: isCloaker:= true;
      end;
   end; { iscloaker }

   function isSpecial(hulid : word):boolean;
   begin
      isSpecial:=false;
      case hulid of
	41, 39, 69, 7, 42 : isSpecial:=true;
      end;
   end;

   function iscarrier(hulid : word):boolean;
   begin
      iscarrier:=false;
      if (hulls[hulid].bays>0) then iscarrier:=true;
   end;

   function loadout(hullid : word):integer;
   var
      class,task : word;
      mult	 : word;
   begin
      getShipClass(hullid,class,task);
      loadout:= 20;
      if not(isCarrier(hullid)) then
      begin
	 mult:=1;
	 if class=0 then mult:=0;
	 if class=1 then mult:=6;
	 if class=2 then mult:=8;
	 if class=3 then mult:=10;
	 if class=4 then mult:=12;
	 loadout:=max(hulls[hullid].tubes * mult,10);
	 exit;
      end
      else
      begin
	 mult:=1;
	 if class=8 then mult:=0;
	 if class=9 then mult:=10;
	 if class=10 then mult:=15;
	 if class=11 then mult:=16;
	 loadout:=max(hulls[hullid].bays*mult,30);
      end;      
   end;

   function getSupplyCode(    hullid : word):word;
   var
      task,class : word;
   begin
      getSupplyCode:=10;
      if hullid=0 then exit;
      getShipClass(hullid,class,task);
      if (task=0) then
      begin
	 if hulls[hullid].cargo>200 then
	    getSupplyCode:=1
	 else   
	    getSupplyCode:=0;
      end;
      if (task and $1=$1) then getSupplyCode:=2;
      if (task and $2 = $2) then getSupplyCode:=3;
      if task and $4=$4 then
	 begin
	    if not(isCarrier(hullid)) then getSupplyCode:=4;
	    if isCarrier(hullid) then getSupplyCode:=7;
	 end;
      if task and $8=$8 then
	 begin
	    if not(isCarrier(hullid)) then getSupplyCode:=5;
	    if isCarrier(hullid) then getSupplyCode:=8;
	 end;
      if (task and $200) = $200 then getSupplyCode:=9;
      if (task and $400) = $400 then getSupplyCode:=9;
      if (task and $10 = $10) then getSupplyCode:=6;
   end;
   
   procedure getshipclass(var hulid,class,task : word);
   var
      thisship : shiphull;
      b,f,t    : word;
   begin
      thisship := hulls[hulid];
      b:=0;
      f:= getfirepower(hulid);
      if not(iscarrier(hulid)) then
	 begin
	    if (thisship.mass> 79) then b:=1;
	    if ((thisship.mass>149) or ((f*thisship.mass)>1080))  then b:=2; {set up so some small ships are categorised as cruisers}
	    if ((b=2) and (f<8)) then b:=1; {for ships too weak to be cruisers}
	    if (thisship.mass>179) then b:=3;
	    if ((thisship.mass>390) and (f>19)) then b:=4;
	 end;
      if (iscarrier(hulid)) then
      begin
	 b:=8;
	 if (f>14) then b:=9;
	 if ((f>19) and (thisship.mass>170)) then b:=10;
	 if (f>27) then b:=11;
      end;
      t:=0;
      if ((b=0) and (thisship.cargo<20)) then b:=1;
      if (b=1) then t:=$1;
      if (b=2) then t:=$2;
      if (b=3) then t:=$4;
      if (b=4) then t:=$8;
      if (b=8) then t:=$1;
      if (b=9) then t:=$4;
      if (b=10) then t:=$4;
      if (b=11) then t:=$8;
      if ((thisship.cargo > 150) and (b<3)) then t:= t or $20;
      if ((thisship.tubes > 0) and (thisship.cargo >99) and (b<4)) then t:=t or $100;
      if ((b=8) and (thisship.cargo>99)) then t:=t or $10;
      if (iscloaker(hulid)) then t:=t or $40;
      if (isSpecial(hulid)) then t:=t or $800;
      if (isTeraformer(hulid)) then t:=t or $80;
      if (hulid = 105) then t:= $200;
      if ((hulid = 104) {or (hulid=97)excluding sharware }) then t:= $400;
      if ((thisship.tubes=0) and (thisship.beams=0) and (thisship.bays=0)) then
	 begin
	    b:=0;
	    t:=0;
	 end;
      task:=t;
      class:=b;
   end; { getshipclass }


end.