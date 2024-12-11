{ Empire - A Danson 2010 }

{ unit which looks at the big picture state of the empire
economically in particular. happens first before all other processing }


unit Empire;

interface
uses RST;

var {empire economic state vars}
   colplan	  : integer; {percentage of planets colonised in total (including enemy)}
   baseReady	  : integer; {percentage of bases that have adequate resources}
   ammunition	  : longint; { number of torpedos/fighters that COULD be built}
   fuel		  : longint; { the amount of fuel available}
   trit,dura,moly : longint; { amount of these minerals available at starbases.}
   money	  : longint; {credits available at starbases}
   

{returns the economic utility of a planet}
{ 0 - minimal - don't develope much}
{ 1 - moderate -  useful for supplies, colonists or one mineral (supply depot)}
{ 2 - high - potential to become a starbase in the future but not yet}
{ 3 - important - should/does have a starbase, important for natives}
function planetUtility(p : planetptr):word;

{returns the economic state - is the planet happy in terms of what materials it needs}
{ 0 - surplus of materials for the utility of this planet.}
{ 1 - neutral - no need for materials but no supply either.}
{ 2 - needs materials - supplies to build up planet}
{ 3 - needs money - to buy tech, ships, torps or anything}
{ 4 - needs minerals - for constructions of bases or ships }
function planetEconomicState(p : planetptr):word;{returns the economic utility of a planet}

{Empire Economic state - fills global vars about the econmy}
procedure EmpireState;

implementation

{returns true if there is a base for id}
function hasBase(id : word):boolean;
var i : word;
begin
   hasBase:=false;
   for i:= 1 to baseCount do
   begin
      if getBase(i)^.baseId = id then hasBase:=true;
   end;
end;

{returns the economic utility of a planet}
{ 0 - minimal - Basic developement required}
{ 1 - moderate -  useful for supplies, colonists or one mineral (supply depot)}
{ 2 - high - potential to become a starbase in the future but not yet}
{ 3 - important - should/does have a starbase, important for natives}
function planetUtility(p : planetptr):word;
var
   result : word;
   t,d,m  : longint;
begin
   result := 0;
   with p^ do
   begin
      t:= tmined + tground;
      d:= dmined + dground;
      m:= mmined + mground;
      {conditions that make a world kinda handy}
      if ( (tground>3000) or (dground>3000) or (mground>3000)) then result :=1;
      {useful natives!}
      if nrace = 2 then result:=1;
      if nrace = 3 then result:=1;
      if nrace = 4 then result:=1;      
      {planets with more than a certain amount of materials should get starbases!}
      if ((t>1999) and (d>1999) and (m>1999)) then result :=2;
      { finally any planet that already has a base or has humanoids should be high priority }
      if nrace = 1 then result:=3;
      if hasBase(id) then result:=3;
   end;
   planetUtility:=result;
end; { planetUtility }

{returns the economic state - is the planet happy in terms of what materials it needs}
{ 0 - surplus of materials for the utility of this planet.}
{ 1 - neutral - no need for materials but no supply either.}
{ 2 - needs materials - supplies to build up planet}
{ 3 - needs money - to buy tech, ships, torps or anything}
{ 4 - needs minerals - for constructions of bases or ships }
function planetEconomicState(p : planetptr):word;
var
   result : word;
   t,d,m  : longint;
begin
   result:=1;
   with p^ do
   begin
      t:= tmined + tground;
      d:= dmined + dground;
      m:= mmined + mground;
      if supplies<100 then result:=2;
      if (hasBase(id) or ((t>1999) and (d>1999) and (m>1999)) ) then
      begin
	 {has base needs lots of materials!}
	 if ((tmined>2000) or (dmined>2000) or (mmined>2000)) then result:=0;
	 if money<3000 then result:=3;
	 if ((tmined<1500) or (dmined<1500) or (mmined<1500)) then result:=4;	 
      end
      else
      begin
	 result:=0; {materials are always available if doesn't have/need a starbase}
      end;      
   end;
   planetEconomicState:=result;
end; { planetEconmicState }


{Empire Economic state - fills global vars about the econmy}
procedure EmpireState;
var
   i	   : integer;
   p	   : planetptr;
   bc,br   : integer; {base count, base ready}
   ut,ec   : word;{ammo, utility, economic state}
   utcount : array[0..3] of integer; {utility count}
   eccount : array[0..4] of integer; {economic state count}
begin
   colplan:=0;
   baseReady:=0;
   ammunition:=0;
   fuel:=0;
   trit:=0;
   dura:=0;
   moly:=0;
   money:=0;
   for i:= 0 to 3 do
      utcount[i]:=0;
   for i:= 0 to 4 do
      eccount[i]:=0;
   bc:=0; {used temporarily to count planets}
   for i:= 1 to 11 do
      bc:=bc+ getScore(i,1);
   colplan := bc div 5;
   bc:=0;
   br:=0;
   for i:= 1 to planetCount do
   begin
      p:= getPlanet(i);
      ut:= planetUtility(p);
      ec:= planetEconomicState(p);
      inc(utcount[ut]);
      inc(eccount[ec]);
      fuel:=fuel + p^.Nmined;
      if hasBase(p^.id) then
      begin
	 inc(bc);
	 trit:= trit + p^.tmined;
	 dura:= dura + p^.dmined;
	 moly:= moly + p^.mmined;
	 money:= money + p^.credits;
	 if ec<2 then inc(br);
      end;
   end;
   baseReady:=0;
   if bc>0 then
      baseReady:= (br*100) div bc;
   ammunition:= trit;
   if moly< ammunition then ammunition:=moly;
   if dura< ammunition then ammunition:=dura;
   if (money div 31) < ammunition then ammunition:=money div 31;
   {$ifdef d_Empire}
   writeln('Empire state...');
   writeln(' Percent colonised ',colplan);
   writeln(' Percent bases ready ',baseReady, ' of ', baseCount, ' bases');
   writeln(' Mark 5 Ammo that could be built ',ammunition);
   writeln(' Fuel Available ',fuel);
   writeln(' Resources available at starbases');
   writeln('  Money      ',money);
   writeln('  Tritanium  ', trit);
   writeln('  Duranium   ',dura);
   writeln('  Molybdenum ',moly);
   writeln(' Planet Utility counts');
   writeln('  minimal    ',utcount[0]);
   writeln('  moderate   ',utcount[1]);
   writeln('  high       ',utcount[2]);
   writeln('  important  ',utcount[3]);
   writeln(' Economy state counts');
   writeln('  surplus     ',eccount[0]);
   writeln('  neutral     ',eccount[1]);
   writeln('  need supply ',eccount[2]);
   writeln('  need money  ',eccount[3]);
   writeln('  need ore    ',eccount[4]);
   {$endif}
end; { EmpireState }

end.