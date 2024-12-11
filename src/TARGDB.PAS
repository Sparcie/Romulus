unit targdb;
{ Remembers targets for the computer and updates the targets appropriately
also may provide information to diplomacy about the status of an enemy fleet

}

interface
uses RST,vector,shipclas;

var
   dbcount   : integer; {count of ships in the DB}
   dbtarg    : array[1..500] of targetptr;

procedure targetdb;
procedure resetdb;

   procedure shipCombat(id : word); {report ship combat (id was in combat and killed!)}
   function warshipCount(race: word):integer; {count of warships}
   function warshipFP(race : word):longint; {fp of all ships for a race}

implementation

   function warshipCount(race : word):integer;
   var i    : integer;
      count : integer;
   begin
      count:=0;
      for i:= 1 to dbcount do
	 if race = dbtarg[i]^.owner then 
	    if getFirePower(dbtarg[i]^.hull)>0 then inc(count);
      warshipCount:=count;
   end; { warshipCount }
      
   function warshipFP(race : word):longint;
   var i : integer;
      fp : longint;
   begin
      fp:=0;
      for i:= 1 to dbcount do
	 if race = dbtarg[i]^.owner then 
	    fp:=fp+ getFirePower(dbtarg[i]^.hull);
      warshipFP:=fp;
   end; { warshipFP }      

   procedure shipCombat(id : word);
   var
      i	: integer;
   begin
      for i:= 1 to dbcount do
	 if dbtarg[i]^.id = id then
	 begin
	    dbtarg[i]^ := dbtarg[dbcount]^;
	    dispose(dbtarg[dbcount]);
	    dec(dbcount);
	 end;
   end;
   
procedure targetdb;
var
   i,c	 : integer;
   found : boolean;
   t	 : targetptr;
begin
   Writeln('Updating target database...');
   for i:= 1 to targetCount do
   begin
      t:= getTarget(i);
      if i<50 then
      begin {these are confirmed to be correct targets}
	 found:=false;
	 for c:= 1 to dbcount do
	    if t^.id = dbtarg[c]^.id then
	    begin
	       found :=true;
	       dbtarg[c]^ := t^;
	    end;
	 if (not(found) and (dbcount<500)) then
	 begin
	    inc(dbcount);
	    new(dbtarg[dbcount]);
	    dbtarg[dbcount]^:=t^;
	 end;
      end;
      if i>49 then
      begin {these are guesses so should be updated with confirmed contacts of the past}
	 found:=false;
	 for c:= 1 to dbcount do
	    if ((t^.id = dbtarg[c]^.id) and (t^.owner=dbtarg[c]^.owner)) then
	    begin
	       t^.hull:= dbtarg[c]^.hull;
	    end;
      end;
   end;
   {check that we don't own the id!}
   for i:= 1 to shipCount do
   begin
      for c:= 1 to dbcount do
	 if dbtarg[c]^.id = getShip(i)^.id then
	 begin
	    dbtarg[c]^ := dbtarg[dbcount]^;
	    dispose(dbtarg[dbcount]);
	    dec(dbcount);
	 end;
   end;
   writeln(dbcount,' ships in the DB');
end; { targetdb }

procedure resetdb;
var i : integer;
begin
   {$ifdef d_targdb}
   writeln(dbcount ,' ships were in the database');
   {$endif}
   for i:= 1 to dbcount do
      dispose(dbtarg[i]);
   dbcount:=0;
end;

begin;
   dbcount:=0;
end.