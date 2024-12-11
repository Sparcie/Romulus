{ AI section for doing the plaents economy }

unit planets;

interface

uses rst,map,vector,diplo;

type
   units =  record
	       id	  : word;
	       tritanium  : longint;
	       duranium	  : longint;
	       molybdenum : longint;
	       colonists  : longint;
	       supplies	  : longint;
	       credits	  : longint;
	    end;


var
   worlds    : array[1..500] of planetptr;
   nworlds   : word;
   supply    : array[1..200] of units;
   demand    : array[1..200] of units;
   nsup,ndem : word;

procedure doworlds;
procedure mapworlds;
procedure clearworlds;

function atPlanet(x,y,target:integer ):boolean;
function nearestWorld(x,y : integer):word;
function nearestOwnedWorld(x,y : integer):word;
function nearestUnOwnedWorld(x,y : integer):word;
function nearestAmorphous(x,y : integer):word;
function nearestBase(x,y : integer):word;
function nearestEnemyWorld(x,y : integer):word;

function nearestColonySupply(x,y : integer):word;
function colonyDemand:word;
function biggestDemand:word;
function bestDelivery(x,y,t,d,m,s : integer):integer;
function mineralDemand:word;
function bestSupply:word;
function findPlanet(id : word):word;
function planetMoney(id : word):longint;
function planetMaterial(id : word):longint;
function findSupply(id : word):word;
function bestFuelSupply(x,y :integer ):word;
function fuelDemand:word;
function fighterDemand:word;
function moneySupply:word;
function moneyDemand:word;

   function ctosRatio:real; {percentage of colony demand compared to total number of demand.}

implementation

   {returns which mineral is currently in the most demand}
   {0 = supplies}
   {1 = duranium}
   {2 = tritanium}
   {3 = molybdenum}
   function mineralDemand:word;
   var
      t,d,m,s : longint;
      i	      : word;
      c	      : longint;
   begin
      t:=0; d:=0; m:=0; s:=0;
      for i := 1 to ndem do
      begin
	 t:=t+demand[i].tritanium;
	 d:=d+demand[i].duranium;
	 m:=m+demand[i].molybdenum;
	 s:=s+demand[i].supplies;
      end;
      mineraldemand:=0;
      c:=s;
      if t>c then
      begin
	 c:=t;
	 mineralDemand:=2;	 
      end;
      if d>c then
      begin
	 c:=d;
	 mineralDemand:=1;
      end;
      if m>c then
      begin
	 mineralDemand:=3;
      end;
   end;

   {finds the planets which is the best money supply}
   function moneySupply:word;
   var
      i	 : integer;
      bs : word;
      bm : longint;
      m	 : longint;
   begin
      bs:=0;
      bm:=0;
      for i:=1 to nsup do
      begin
	 m:= supply[i].supplies + supply[i].credits;
	 if m>bm then
	 begin
	    bm:=m;
	    bs:=supply[i].id;
	 end;
      end;
      moneySupply:=bs;
   end; { moneySupply }

   {finds the planet that demands the most money}
   function moneyDemand:word;
   var
      i	 : integer;
      bs : word;
      bm : longint;
      m	 : longint;
   begin
      bs:=0;
      bm:=0;
      for i:=1 to ndem do
      begin
	 m:= demand[i].credits;
	 if m>bm then
	 begin
	    bm:=m;
	    bs:=demand[i].id;
	 end;
      end;
      moneyDemand:=bs;
   end; { moneyDemand }

   {finds where fighters are needed}
   function fighterDemand:word;
   var i     : word;
      wb,wfc : word;
   begin     
      wb:=0;
      wfc:=60;
      for i := 1 to baseCount do
	 with getBase(i)^ do
	 begin
	    if fighters<wfc then
	    begin
	       wb:=baseID;
	       wfc:=fighters;
	    end;
	 end;
      fighterDemand:=wb;
   end;

   {measures the ratio of demand (colony versus ore)}
   function ctosRatio:real;
   var
      count : real;
      cl    : real;
      i	    : word;
   begin
      count:=ndem;
      cl := 0;
      for i:= 1 to ndem do
	 if demand[i].colonists>0 then
	 begin
	    cl:=cl+1;
	 end;
      if count=0 then exit;
      ctosRatio:= cl/count;
   end;

   {finds a planet in need of fuel}
   function fuelDemand:word;
   var
      i,c    : word;
      sc,wsc : word;
      ship   : starshipptr;
   begin
      fuelDemand:=0;
      wsc:=0;
      for i:= 1 to nworlds do
      begin
	 sc:=0;
	 if ((worlds[i]^.Nmined<200) and (worlds[i]^.owner=player)) then
	 begin
	    for c:= 1 to shipCount do
	    begin
	       ship:=getShip(c);
	       if atPlanet(ship^.x,ship^.y,worlds[i]^.id) then inc(sc);
	    end;
	    if sc>wsc then
	    begin
	       fuelDemand:= worlds[i]^.id;
	       wsc:=sc;
	    end;
	 end;
      end;
   end; { fuelDemand }

   {finds a planets that may supply fuel}
   function bestFuelSupply(x,y :integer ):word;
   var
      bff,ff : longint;
      i	     : word;
   begin
      bestfuelsupply:=0;
      bff:=0;
      for i:= 1 to nworlds do
      begin
	 ff := min(worlds[i]^.Nmined,1000);
	 ff := ff div max(trunc(distance(x,y,chart[worlds[i]^.id].x,chart[worlds[i]^.id].y)/50),1);
	 if ((ff>bff) and (worlds[i]^.owner=player)) then
	 begin
	    bff:=ff;
	    bestFuelsupply:= worlds[i]^.id;
	 end;
      end;
   end; { bestFuelSupply }

   {finds the supply record for a world}
   function findSupply(id : word):word;
   var
      i,c    : word;
      result : word;
   begin
      findsupply:=0;
      result:=0;
      for i:= 1 to nsup do
	 if ( (supply[i].tritanium >0) or (supply[i].duranium >0) or (supply[i].molybdenum >0) or
	    (supply[i].colonists >0) or (supply[i].supplies >0) ) then	    	 
	    if supply[i].id = id then result:=i;
      {ok check to make sure a ship hasn't already taken our supply away!}
      if result = 0 then exit;
      i:= supply[result].id;
      for c:= 1 to nworlds do
	 if worlds[c]^.id = i then i:=c;
      if (supply[result].tritanium > worlds[i]^.Tmined) then supply[result].tritanium:=worlds[i]^.Tmined;
      if (supply[result].duranium > worlds[i]^.Dmined) then supply[result].duranium:=worlds[i]^.Dmined;   
      if (supply[result].molybdenum > worlds[i]^.Mmined) then supply[result].Molybdenum:=worlds[i]^.Mmined;
      if (supply[result].colonists > worlds[i]^.colonists-100) then supply[result].colonists:=worlds[i]^.colonists-100;
      if (supply[result].supplies > worlds[i]^.supplies-100) then supply[result].supplies:=worlds[i]^.supplies-100;
      if (supply[result].supplies<1) then supply[result].supplies:=0;
      if (supply[result].colonists<1) then supply[result].colonists:=0;
      if (supply[result].molybdenum<1) then supply[result].molybdenum:=0;
      if (supply[result].tritanium<1) then supply[result].tritanium:=0;
      if (supply[result].duranium<1) then supply[result].duranium:=0;
      findsupply:=result;
   end;

   {finds a planet record by id}
   function findPlanet(id : word):word;
   var
      i	: word;
   begin
      findPlanet:=0;
      for i:= 1 to nworlds do
      begin
	 if worlds[i]^.id=id then findPlanet:=i;
      end;
   end;

   {returns the minimum material on a planet}
   function planetMaterial(id : word):longint;
   var
      i	: word;
   begin
      i:= findPlanet(id);
      planetMaterial := 0;
      if worlds[i]^.nrace=1 then exit;
      if worlds[i]^.Nmined>200 then
	 planetMaterial := min(min(worlds[i]^.tmined,worlds[i]^.dmined), worlds[i]^.mmined);
   end;

   function planetMoney(id : word):longint;
   begin
      planetMoney:= worlds[findPlanet(id)]^.credits;
   end;

   function nearestBase(x,y : integer):word;
   var
      i,d,sd : word;
   begin     
      sd:=5000;
      nearestBase:=0;
      for i:= 1 to baseCount do
	 with getBase(i)^ do
	 begin
	    d := trunc(distance(x,y,chart[baseid].x,chart[baseid].y));
	    if d<sd then
	    begin
	       nearestbase := baseid;
	       sd:=d;
	    end;
	 end;      
   end; { nearestColonySupply }

   function bestSupply :word;
   var
      bests    : longint; {best supply amount}
      s	       : longint; {current supply amount}
      i	       : word; {loop counter}
      dist     : integer; {current distance / 50 from biggest demmand}
      x,y      : integer; { xy of biggest demand}
      dem      : integer; {biggest demmand id}
      t,d,m,sm : integer; {resource multipliers for the supply (ie what is valuable)}
   begin
      bestSupply:=0;
      bests:=0;
      dem := biggestDemand;
      if dem=0 then exit;
      x:= chart[dem].x;
      y:= chart[dem].y;
      t:=1; d:=1; m:=1;
      for i:= 1 to ndem do
      begin
	 if demand[i].id = dem then
	    with demand[i] do
	    begin
	       if ((tritanium>duranium) and (tritanium>molybdenum)) then t:=3;
	       if ((duranium>tritanium) and (duranium>molybdenum)) then d:=3;
	       if ((molybdenum>tritanium) and (molybdenum>duranium)) then m:=3;
	       if tritanium = 0 then t:=0;
	       if duranium = 0 then d:=0;
	       if molybdenum = 0 then m:=0;
	       if supplies = 0 then sm:=0;
	    end;
      end;
	 
      for i:= 1 to nsup do
      begin
	 dist := trunc(distance(x,y,chart[supply[i].id].x,chart[supply[i].id].y) / 50);
	 s:= d * supply[i].duranium + m * supply[i].molybdenum +  t * supply[i].tritanium +
	 sm*supply[i].supplies + supply[i].credits;
         if dist>1 then
  	    s:= s div dist;
	 if (s>bests) then
	 begin
	    bests:=s;
	    bestSupply:=supply[i].id;
	 end;	 
      end;
   end;

   {works out the best place to deliver the cargo and subtracts the cargo from the demand}
   {x,y ship xy}
   {t,d,m,s cargo thats on the ship (minerals and supplies)}
   function bestDelivery(x,y,t,d,m,s : integer):integer;
   var
      bestd	  : longint; {the biggest demand we are gonna service}
      dem	  : longint; {the current demand}
      dist	  : integer; {distance to the current demand}
      i		  : integer; {loop counter}
      bestid	  : integer; {id of the big demand we are going to service (index into demand array)}
      tm,dm,mm,sm : integer; {multipliers for the cargo}
   begin
      bestd:=0;
      bestid:=0;
      {change the cargo params to multipliers}
      tm:=0;
      dm:=0;
      mm:=0;
      sm:=0;
      if t>0 then tm:=1;
      if d>0 then dm:=1;
      if m>0 then mm:=1;
      if s>0 then sm:=1;
      if t>199 then tm:=2;
      if d>199 then dm:=2;
      if m>199 then mm:=2;
      if s>199 then sm:=2;
      for i:= 1 to ndem do
	 with demand[i] do
	 begin
	    dem := tm*tritanium + dm*duranium + mm*molybdenum + sm*supplies + credits;
	    dist := trunc(distance(x,y,chart[id].x,chart[id].y) / 100);
	    if dist>1 then
	       dem:= dem div dist;
	    if dem>bestd then
	    begin
	       bestid:=i;
	       bestd:=dem;
	    end;
	 end;
      bestDelivery:=0;
      if bestid>0 then
	 with demand[bestid] do
	 begin
	    bestDelivery:=id;
	    tritanium:=tritanium-t;
	    duranium:=duranium-d;
	    molybdenum:=molybdenum-m;
	    supplies:=supplies-s;
	 end;	 
   end;
   
   function biggestDemand:word;
   var
      bestd : longint;
      d	    : longint;
      i,s   : word;
   begin
      biggestDemand:=0;
      bestd:=0;
      s:=0;
      for i:= 1 to ndem do
      begin
	 d:= demand[i].duranium + demand[i].molybdenum +  demand[i].tritanium + demand[i].supplies;
	 if (d>bestd) then
	 begin
	    bestd:=d;
	    biggestDemand:=demand[i].id;
	    s:=i;
	 end;
      end;
      if s=0 then exit;
   end; { biggestDemand }

   function colonyDemand:word;
   var
      i,s : word;
      bd  : longint;
   begin
      colonyDemand:=0;
      s:=0;
      bd:=0;
      for i:= 1 to ndem do
	 if demand[i].colonists>bd then
	 begin
	    colonyDemand:=demand[i].id;
	    s:=i;
	    bd:=demand[i].colonists
	 end;
      if s>0 then
         demand[s].colonists := demand[s].colonists div 2;
   end;

   function nearestColonySupply(x,y : integer):word;
   var
      i,d,sd : word;
   begin     
      sd:=5000;
      nearestColonySupply:=0;
      for i:= 1 to nsup do
	 if ((supply[i].colonists>0) and (chart[supply[i].id].owner=1) ) then
	 begin
	    d := trunc(distance(x,y,chart[supply[i].id].x,chart[supply[i].id].y));
	    if d<sd then
	    begin
	       nearestColonySupply:= supply[i].id;
	       sd:=d;
	    end;
	 end;      
   end; { nearestColonySupply }

   function atPlanet(x,y,target	:integer ):boolean;
   begin
      atPlanet:=false;
      if target=0 then exit;
      if ((x = chart[target].x) and (y = chart[target].y) ) then atPlanet:=true;
   end; { atPlanet }

   function nearestUnOwnedWorld(x,y : integer):word;
   var
      i,d,sd : word;
   begin
      nearestUnownedWorld:=0;
      sd:=1000;
      for i:=1 to 500 do
	 if (chart[i].owner=0) then
	 begin
	    d := trunc(distance(x,y,chart[i].x,chart[i].y));
	    if (d<sd) then
	    begin
	       nearestUnownedWorld := i;
	       sd:=d;
	    end;
	 end;
   end; { nearestUnOwnedWorld }

   function nearestAmorphous(x,y : integer):word;
   var
      i,d,sd : word;
   begin
      nearestAmorphous:=0;
      sd:=1000;
      for i:=1 to 500 do
	 if (chart[i].owner=4) then
	 begin
	    d := trunc(distance(x,y,chart[i].x,chart[i].y));
	    if (d<sd) then
	    begin
	       nearestAmorphous := i;
	       sd:=d;
	    end;
	 end;
   end; { nearestUnOwnedWorld }

   function nearestWorld(x,y : integer):word;
   var
      i,d,sd : word;
   begin
      nearestWorld:=0;
      sd:=1000;
      for i:=1 to 500 do
      begin
	 d := trunc(distance(x,y,chart[i].x,chart[i].y));
	 if (d<sd) then
	 begin
	    nearestWorld := i;
	    sd:=d;
	 end;
      end;
   end; { nearestWorld }
   
   function nearestEnemyWorld(x,y : integer):word;
   var
      i,d,sd : word;
   begin
      nearestEnemyWorld:=0;
      sd:=9000;
      for i:=1 to 500 do
	 if ((chart[i].owner=3) or ( isEnemy(chart[i].owner-10) )) then
	 begin
	    d := trunc(distance(x,y,chart[i].x,chart[i].y));
	    if (d<sd) then
	    begin
	       nearestEnemyWorld := i;
	       sd:=d;
	    end;
	 end;
   end; { nearestEnemyWorld }

   function nearestOwnedWorld(x,y : integer):word;
   var
      i,d,sd : word;
   begin
      nearestOwnedWorld:=0;
      sd:=9000;
      for i:=1 to 500 do
	 if (chart[i].owner=1) then
	 begin
	    d := trunc(distance(x,y,chart[i].x,chart[i].y));
	    if (d<sd) then
	    begin
	       nearestOwnedWorld := i;
	       sd:=d;
	    end;
	 end;
   end; { nearestOwnedWorld }

   procedure clearworlds;
   var
      i	:  word;
   begin
      for i:= 1 to nworlds do
      begin
	 dispose(worlds[i]);
      end;
      nworlds:=0;
      ndem:=0;
      nsup:=0;
   end; { clearworlds }

   procedure addSupply(z : units);
   var i : integer;
   begin
      if nsup = 200 then Exit;
      if ((z.colonists =0) and (z.tritanium=0) and (z.duranium=0) and
	  (z.molybdenum=0) and (z.supplies=0)) then exit;
      
      {any supply greater than this can be ignored (we want large supplies considered equal)}
      if z.tritanium>10000 then z.tritanium:=10000;
      if z.duranium>10000 then z.duranium:=10000;
      if z.molybdenum>10000 then z.molybdenum:=10000;
      if z.colonists>2000 then z.colonists:=2000;
      if z.supplies>20000 then z.supplies:=20000;
      if z.credits>100000 then z.credits := 100000;
	 
      for i:= 1 to nsup do
      begin
	 if z.id = supply[i].id then
	 begin
	    if z.tritanium>supply[i].tritanium then supply[i].tritanium:=z.tritanium;
	    if z.duranium>supply[i].duranium then supply[i].duranium:=z.duranium;
	    if z.molybdenum>supply[i].molybdenum then supply[i].molybdenum:=z.molybdenum;
	    if z.colonists>supply[i].colonists then supply[i].colonists:=z.colonists;
	    if z.supplies>supply[i].supplies then supply[i].supplies := z.supplies;
	    if z.credits>supply[i].credits then supply[i].credits :=z.credits;
	    exit;
	 end;
      end;
      nsup:=nsup+1;
      supply[nsup]:=z;
   end; { addSupply }

   procedure addDemand(z : units);
   var i : integer;
   begin
      if ndem = 200 then Exit;
      if ((z.colonists =0) and (z.tritanium=0) and (z.duranium=0) and
	  (z.molybdenum=0) and (z.supplies=0)) then exit;
      for i:= 1 to ndem do
      begin
	 if z.id = demand[i].id then
	 begin
	    if z.tritanium>demand[i].tritanium then demand[i].tritanium:=z.tritanium;
	    if z.duranium>demand[i].duranium then demand[i].duranium:=z.duranium;
	    if z.molybdenum>demand[i].molybdenum then demand[i].molybdenum:=z.molybdenum;
	    if z.colonists>demand[i].colonists then demand[i].colonists:=z.colonists;
	    if z.supplies>demand[i].supplies then demand[i].supplies := z.supplies;
	    if z.credits>demand[i].credits then demand[i].credits :=z.credits;
	    exit;
	 end;
      end;
      ndem:=ndem+1;
      demand[ndem]:=z;
   end; { addDemand }

   function checkBase(id :integer) :boolean;
   var i : word;
   begin
      checkBase:=false;
      for i:= 1 to baseCount do
      begin
	 if (getBase(i)^.baseID = id) then checkBase:=true;
      end;
   end;

   function maxFact(pop	: longint):word;
   begin
      if pop<101 then
      begin
	 maxfact:=pop;
	 exit;
      end;
      maxfact:= trunc(sqrt(pop-100))+100;
   end; { maxFact }

   function maxMine(pop	: longint):word;
   begin
      if pop<201 then
      begin
	 maxmine:=pop;
	 exit;
      end;
      maxmine:= trunc(sqrt(pop-200))+200;
   end; { maxMine }

   function maxdefp(pop	: longint):word;
   begin
      if pop<51 then
      begin
	 maxdefp:= pop;
	 exit;
      end;
      maxdefp:= trunc(sqrt(pop-50))+50;
   end; { maxdefp }

   procedure mapworlds;
   var i,b : integer;
      w	   : planetptr;
   begin
      b:= planetCount;
      for i:= 1 to b do
      begin
	 w:=getPlanet(i);
	 if (w^.owner = player) then chart[w^.id].owner:=1;	 
      end;
   end; { mapworlds }

   function defendBase(id : word):boolean;
   var i : integer;
      d	 : integer;
   begin
      defendBase:=false;
      if id>500 then exit;
      if id<1 then exit;
      for i:= 1 to 500 do
	 if isEnemy(chart[i].owner - 10) then
	 begin
	    d := trunc(distance(chart[id].x,chart[id].y,chart[i].x,chart[i].y));
	    if d<150 then defendBase := true;
	 end;
   end;
   
   procedure doworlds;
   var
      i,b	    : integer;
      u		    : units;
      base, getbase : boolean;
      t,d,m,mc,mm   : longint;
      hp	    : word;
   begin
      hp:=0;
      writeln('economising planets...');
      {first things first we need to copy the worlds from the RST}
      b:= planetCount;
      nworlds:=b;
      for i:= 1 to b do
      begin
	 new(worlds[i]);
	 worlds[i]^ := getPlanet(i)^;
	 if (not(worlds[i]^.owner = player) and (worlds[i]^.owner>0)) then
	    chart[worlds[i]^.id].owner:=3;
      end;
      {ok the copy has been made we iterate through and establish the economy
      on each world}
      for i:= 1 to nworlds do
	 if (worlds[i]^.owner = player) then {only process worlds we own}
	    with worlds[i]^ do
	    begin
	       {work out if this world should be a base or has one}
	       write('.');
	       chart[id].owner:=1;
	       if nrace = 5 then
	       begin
		  chart[id].owner:=4;
		  {$ifdef d_planets}
		  write('A');
		  {$endif}
	       end;
	       {randomize the FC}
	       if (random(10)>6) then
	       begin
		  fcode[3] := char(random(10)+48);{inititialise fc}
		  fcode[2] := char(random(10)+48);
		  fcode[1] := char(random(26)+65);
	       end;
	       b:= nearestEnemyWorld(chart[id].x,chart[id].y);
	       if b>0 then
		  if distance(chart[id].x,chart[id].y,chart[b].x,chart[b].y )<100.0 then
		  begin
		     fcode[1]:='A';
		     fcode[2]:='T';
		     fcode[3]:='T';
		  end;
	       if ((nrace = 1) and (hp<9)) then
	       begin
		  inc(hp);
		  fcode[1]:='P';
		  fcode[2]:='B';
		  fcode[3]:=chr(48 + hp);
	       end;
	       mc := trunc(sin(3.14*((100-temp)/100)) *100000);
	       if player = 7 then
		  mc := 1000 * trunc(temp);
	       base:=checkBase(id);
	       t := tmined + tground;
	       d := dmined + dground;
	       m := mmined + mground;
	       getbase:=false;
	       if ((t>1999) and (d>1999) and (m>1999) and not(base)) then getbase:=true;
	       if ((nrace = 1) and not(base)) then getbase:=true;
	       if (not(base) and defendBase(id)) then getBase:=true;
	       {ok now if we know that we have a base we generate demand based on
	       what we have and know we need}
	       if base then
	       begin
		  {$ifdef d_planets}
		  write('b');
		  {$endif}
		  {sell some supplies if we don't have enough money }
		  if ((credits < 3000) and (supplies >100)) then
		  begin
		     credits:= credits+ (supplies-100);
		     supplies:=100;
		  end;
		  
		  u.id:=id;
		  u.credits:=10000-credits; {we allways need credits at a base}
		  u.supplies:=0;
		  b:=1000;
		  if mc<maxint then b:=mc;
		  u.colonists := min(1000,b) - colonists;
		  if u.colonists<1 then u.colonists :=0;
		  if ((player=6) and (nrace>0)) then u.colonists:=0;
		  u.tritanium := 500 - tmined;
		  if u.tritanium<1 then u.tritanium :=0;
		  u.duranium := 500 - dmined;
		  if u.duranium<1 then u.duranium :=0;
		  u.molybdenum := 500 - mmined;
		  if u.molybdenum<1 then u.molybdenum :=0;
		  if nrace=1 then {humanoids demand more material}
		  begin
		     if tmined<4000 then
			u.tritanium := 4000 - tmined;
		     if dmined<4000 then 
			u.duranium := 4000 - dmined;
		     if mmined<4000 then
			u.molybdenum := 4000 - mmined;
		     u.supplies := 4000;
		  end;
		  if ((colonists>2000) or (nrace = 8)) then
		  begin
		     if tmined<1000 then
			u.tritanium := 1000 - tmined;
		     if dmined<1000 then 
			u.duranium := 1000 - dmined;
		     if mmined<1000 then
			u.molybdenum := 1000 - mmined;
		  end;
		  addDemand(u);
		  if not(nrace=1) then
		  begin
		     {offer supplies and minerals over 1000}
		     u.credits := 0;
		     if supplies>250 then
			u.supplies:= supplies - 250;
		     if tmined>1000 then
			u.tritanium := tmined - 1000;
		     if dmined>1000 then
			u.duranium := dmined - 1000;
		     if mmined>1000 then
			u.molybdenum := mmined - 1000;
		     addSupply(u);
		  end;
	       end;
	       if getbase then
	       begin
		  u.id:=id;
		  u.credits:=900;
		  u.supplies:=0;
                  b:=1000;
                  if mc<maxint then b:=mc;
		  u.colonists := min(1000,b) - colonists;
		  if u.colonists<1 then u.colonists :=0;
		  if ((player=6) and (nrace>0)) then u.colonists:=0;
		  u.tritanium := 402 - tmined;
		  if u.tritanium<1 then u.tritanium :=0;
		  u.duranium := 120 - dmined;
		  if u.duranium<1 then u.duranium :=0;
		  u.molybdenum := 340 - mmined;
		  if u.molybdenum<1 then u.molybdenum :=0;
		  if ((player=6) and (nrace=1)) then
		  begin
		     u.tritanium:=10000;
		     u.duranium:=10000;
		     u.molybdenum:=10000;
		     u.colonists:=0;
		     u.credits:=10000;
		  end;
		  addDemand(u);
	       end;
	       b:=200;
	       if mc<maxint then b:=mc;
	       if (not(player=6) or (nrace=0)) then
		  if ((not(base)) and (not(getbase)) and
		      ( (colonists < min(200,b)) or (supplies = 0))
		      and not(colonists>=mc ) ) then
		  begin
		     u.id:=id;
		     u.credits :=0;
		     u.supplies:=50;
		     u.colonists:=mc-colonists;
		     if u.colonists<1 then u.colonists :=0;
		     u.tritanium:=0;
		     u.duranium:=0;
		     u.molybdenum:=0;
		     addDemand(u);
		  end;
	       if ((not(base)) and (not(getbase))) then
	       begin
		  u.id:=id;
		  u.credits:=credits;
		  u.supplies:=supplies div 2;
		  u.colonists := 0;
		  u.tritanium :=tmined;
		  u.duranium := dmined;
		  u.molybdenum := mmined;
		  addSupply(u);
	       end;
	       if (colonists>2000) then
	       begin
		  u.id:=id;
		  u.credits:=0;
		  if credits>10000 then
		     u.credits:= credits-10000;
		  u.supplies:=supplies;
		  u.colonists := colonists-2000;
		  u.tritanium := 0;
		  u.duranium := 0;
		  u.molybdenum := 0;
		  addSupply(u);
	       end;
	       {ok now supply and demand is done we need to check for building factories
	       mines and defense posts}
	       t:= maxfact(colonists);
	       d:= maxmine(colonists);
	       m:= maxdefp(colonists);
	       {factories built using money}
	       while ((supplies>1) and (factories<t) and (credits>3)) do
	       begin
		  factories:=factories+1;
		  supplies:=supplies-1;
		  credits:=credits-3;
	       end;	       
	       {one factory + mine + def post = 3 4 10 3 = 20 supplies
	       if turnNumber>10 then
		  while ((supplies>120) and (factories<t) and (mines<d) and (defposts<m)) do
		  begin
		     factories:=factories+1;
		     mines:=mines+1;
		     defposts:=defposts+1;
		     supplies:=supplies-20;
		  end;}
	       {factories built without money}
	       if turnNumber>10 then
		  while ((supplies>3) and (factories<t)) do
		  begin
		     factories:=factories+1;
		     supplies:=supplies-4;
		  end;
	       {mine building ... kept to a minimum so natives don't riot}
	       mm := 150;
	       if player = 1 then mm:=175;
	       if ((nrace = 0) or (natives=0)) then mm:=500;
	       {built with money}
	       while ((supplies>1) and (credits>4) and (mines<d) and (mines<mm)) do
	       begin
		  mines:=mines+1;
		  credits:=credits-4;
		  supplies:=supplies-1;
	       end;
	       {built with supplies}
	       if turnNumber>10 then
		  while ((supplies>104) and (mines<d) and (mines<mm)) do
		  begin
		     mines:=mines+1;
		     supplies:=supplies-5;
		  end;
	       {def posts ... last thing to build if we can}
	       {build with money}
	       while ((supplies>1) and (credits>10) and (defposts<m)) do
	       begin
		  defposts:=defposts+1;
		  supplies:=supplies-1;
		  credits:=credits-10;
	       end;
	       {built with suppies}
	       if turnNumber>10 then
		  while ((supplies>110) and (defposts<m)) do
		  begin
		     defposts:=defposts+1;
		     supplies:=supplies-11;
		  end;
	       {ok we should work out tax rates for natives and colonists}
	       b := 50;
	       if (player = 7) then b := 100;
	       t:=2;
	       d:=2;
	       m:=50;
	       if (chappy>90) then d:=-2;
	       while (not(ctax=m)) do
		  begin
		     t:= (1000 - trunc(sqrt(colonists)) - (80 * Ctax) - (abs(b - temp)*3) -
		     ((factories + mines) div 3)) div 100;
		     m:=ctax;
		     if ((t>d) and (ctax<100)) then Ctax:=Ctax+1;
		     if ((t<d) and (ctax>0)) then Ctax:=ctax-1;
		  end;
	       if CHappy<70 then ctax:=0;
	       {check to see if we make income... if not enough set tax to zero}
	       m := round( (colonists / 100.0) * ( ctax / 10.0) ) ;
	       if m<5 then ctax:=0;
	       {check to see if we are growing (only if smaller than 600 clans)}
	       if colonists<1000 then
	       begin
		  m := round( sin(3.14*(temp/100)) * (colonists / 20.0) * (5.0 / (5.0 + cTax)));
		  if player=7 then
		     m:= round( (temp/100) * (colonists / 20.0) * (5.0 / (5.0 +ctax)) );
		  if m<1 then
		     while ((m<1) and (ctax>0)) do
		     begin
			ctax:=ctax-1;
			m := round( sin(3.14*(temp/100)) * (colonists / 20.0) * (5.0 / (5.0 + cTax)));
			if player=7 then
			   m:= round( (temp/100) * (colonists / 20.0) * (5.0 / (5.0 +ctax)) );
		     end;		  
	       end;		    
	       {now for the natives ... }
	       d:=1;
	       t:=2;
	       m:=50;
	       if nhappy>90 then d:=-1;
	       if nhappy<80 then d:=10;
	       while (not(ntax=m)) do
	       begin
		  t:= (1000 - trunc(sqrt(natives)) - (85*Ntax) - ((factories+mines)div 2) - (50 * (10 - ngov )))div 100;
		  m:=ntax;
		  if ((t>d) and (ntax<15)) then ntax:=ntax+1;
		  if ((t<d) and (ntax>0)) then ntax:=ntax-1;
	       end;
	       {finally if we want to get a base we check if we can and build one if possible}
	       if ((getBase) and (supplies>100)) then {we want to have lotsa money so sell supplies}
	       begin
		  credits:= credits+ (supplies-100);
		  supplies:=100;
	       end;
	       if ((getbase) and (credits>899) and (tmined>401) and (dmined>119) and(mmined>339)) then
	       begin
		  {$ifdef d_planets}
		  write('B');
		  {$endif}
		  buildbase:=1;
		  credits:=credits-900;
		  tmined:=tmined-402;
		  dmined:=dmined-120;
		  mmined:=mmined-340;
	       end;	     
	    end;
      writeln('');
   end;

end.
