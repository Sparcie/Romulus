{ ship state unit stores the current state of the ships and saves it}
{now also saves map state target database and planet database}

unit shipstat;
interface

type
   state     = record
		  id	 : word;
		  task	 : word;
		  ctask	 : word;
		  action : word;
		  target : word;
		  owner	 : word;
		  age	 : word;
	       end;	 
   group     = record
		  target  : word;
		  size	  : word;
		  maxsize : word;
		  ships	  : array[1..10] of word;
	       end;	  
   states    = array[1..500] of state;
   groups    = array[1..20] of group;
   statesptr = ^states;
   groupsptr = ^groups;
   stateptr  = ^state;
   groupptr  = ^group;
var
   shipstates	: statesptr;
   battlegroups	: groupsptr;
   scount	: word;
   gcount	: word;
	       

function getState(id : word):stateptr;
procedure makeGroup(t,s	: word);
function getRallyGroup:groupptr;
function getGroup(t : word):groupptr;
function groupFull(t: word):boolean;
procedure resetGroups;

procedure save;
procedure load;

implementation

uses RST,map,bsystem,messages,targdb;

var
   oldexitproc : pointer;

const
   pchars : array[1..11] of char =  ('1','2','3','4','5','6','7','8','9','a','b');

{returns a pointer to a shipstate for a ship id}
function getState(id : word):stateptr;
var
   i	 : word;
   tempp : stateptr;
begin
   tempp:=nil;
   for i:=1 to scount do
   begin
      if (shipstates^[i].id = id) then tempp:= @(shipstates^[i]);
   end;
   if (tempp=nil) then
   begin
      scount:=scount+1;
      shipstates^[scount].id:=id;
      shipstates^[scount].task := $FFFF;
      shipstates^[scount].ctask := 0;
      shipstates^[scount].action :=0;
      shipstates^[scount].target :=0;
      shipstates^[scount].owner:=0;
      shipstates^[scount].age:=0;
      tempp:= @(shipstates^[scount]);
   end;
   getState:=tempp;
end; { getState }

procedure resetGroups;
var
   i : word;
begin
   for i:=1 to gcount do
   begin
      battlegroups^[i].size :=0;
   end;
end; { resetGroups }

{returns a group that needs more ships}
function getRallyGroup:groupptr;
var
   i : word;
begin
   getRallyGroup:=nil;
   for i:=1 to gcount do
   begin
      if ( (battlegroups^[i].target>0)
	  and (battlegroups^[i].size<battlegroups^[i].maxsize)) then
	 getRallyGroup:=@(battlegroups^[i]);
   end;
end; { getRallyGroup }

function getGroup(t : word):groupptr;
var
   i : word;
begin
   getGroup:=nil;
   for i:=1 to gcount do
   begin
      if (battlegroups^[i].target=t) then getGroup:=@(battlegroups^[i]);
   end;
end; { getGroup }

function groupFull(t	: word):boolean;
var g : groupptr;
begin
   groupFull:=false;
   g:= getGroup(t);
   if g=nil then exit;
   if ((g^.size = g^.maxsize) and (g^.ships[10]=g^.size)) then groupFull:=true;
   if g^.ships[9]>40 then groupFull:=true;
end;

procedure makeGroup(t,s	: word);
begin
   if not(getGroup(t)=nil) then exit;
   if not(getRallyGroup = nil) then exit;
   if gcount=20 then exit;
   inc(gcount);
   battlegroups^[gcount].target:=t;
   battlegroups^[gcount].size:=0;
   battlegroups^[gcount].maxsize:=s;
end;

procedure save;
var
   statefile : file;
   i	     : word;
begin
   writeln('saving ship state...');
   assign(statefile,'ship'+pchars[player]+'.rom');
   rewrite(statefile,1);
   {write ship states}
   blockwrite(statefile,scount,sizeof(word));
   for i:=1 to scount do
   begin
      inc(shipstates^[i].age);
      blockwrite(statefile,shipstates^[i],sizeof(state));
   end;
   blockwrite(statefile,gcount,sizeof(word));
   for i:=1 to gcount do
   begin
      blockwrite(statefile,battlegroups^[i],sizeof(group));
      {$ifdef d_state}
      write('g :');
      writeln(i);
      write(' t :');
      writeln(battleGroups^[i].target);
      write('s :');
      write(battleGroups^[i].size);
      write(' ms :');
      write(battleGroups^[i].maxsize);
      write(' full:');
      writeln(groupFull(battleGroups^[i].target));
      {$endif}
   end;
   for i:=1 to 500 do
   begin
      if (chart[i].owner=1) then chart[i].owner:=3;
      blockwrite(statefile,chart[i].owner,sizeof(word));
   end;
   {save the diplomatic state}
   for i:= 1 to 11 do
   begin
      blockwrite(statefile,attitude[i],sizeof(word));
      blockwrite(statefile,dipstate[i],sizeof(byte));
      blockwrite(statefile,offer[i],sizeof(byte));
      blockwrite(statefile,accept[i],sizeof(byte));
      {$ifdef d_state}
      writeln('pl ',i,' att ',attitude[i],' dip ',dipstate[i],
	      ' off ',offer[i],' acc ',accept[i]);
      {$endif}
   end;
   {save the target DB so that we can continue to identify ships}
   for i:= 1 to dbcount do
   begin
      blockwrite(statefile,dbtarg[i]^,sizeof(target));
   end;
   close(statefile);
   {$ifdef d_state}
   write('gcount ');
   writeln(gcount);
   {$endif}
end; { save }

function checkShip(id : word):boolean;
var
   i : word;
begin
   checkShip:=false;
   for i:= 1 to shipcount do
   begin
      if getship(i)^.id = id then checkShip:=true;
   end   
end; { checkShip }

procedure load;
var
   statefile : file;
   temps     : state;
   tempg     : group;
   i,c	     : word;
begin
   writeln('loading ship state...');
   resetMap;
   gcount:=0;
   scount:=0;
   if not(checkFile('ship'+pchars[player]+'.rom')) then
   begin
      writeln('No state file...');
      exit;
   end;
   assign(statefile,'ship'+pchars[player]+'.rom');
   reset(statefile,1);
   blockread(statefile,c,sizeof(word));
   for i:=1 to c do
   begin
      blockread(statefile,temps,sizeof(state));
      if checkship(temps.id) then
      begin
	 inc(scount);
	 shipstates^[scount]:=temps;
      end;
   end;
   blockread(statefile,c,sizeof(word));
   for i:=1 to c do
   begin
      blockread(statefile,tempg,sizeof(group));
      if (tempg.target>0) then
      begin
	 inc(gcount);
	 battlegroups^[gcount]:=tempg;
	 {$ifdef d_state}
	 write('g :');
	 writeln(gcount);
	 write(' t :');
	 writeln(tempg.target);
	 write('s :');
	 write(tempg.size);
	 write(' ms :');
	 writeln(tempg.maxsize);
	 {$endif}
      end;
   end;
   for i:= 1 to 500 do
      blockread(statefile,chart[i].owner,sizeof(word));
   if not(eof(statefile)) then
      for i:= 1 to 11 do
      begin
	 blockread(statefile,attitude[i],sizeof(word));
	 blockread(statefile,dipstate[i],sizeof(byte));
	 blockread(statefile,offer[i],sizeof(byte));
	 blockread(statefile,accept[i],sizeof(byte));
	 {$ifdef d_state}
	 writeln('pl ',i,' att ',attitude[i],' dip ',dipstate[i],
		 ' off ',offer[i],' acc ',accept[i]);
	 {$endif}
      end;
   while not(eof(statefile)) do
   begin
      if dbcount<500 then
      begin
	 inc(dbcount);
	 new(dbtarg[dbcount]);
      end;
      blockread(statefile,dbtarg[dbcount]^,sizeof(target));      
   end;
   close(statefile);
   {$ifdef d_state}
   write('gcount ');
   writeln(gcount);
   {$endif}
end; { load }

{$f+}
procedure exit;
begin
   dispose(shipstates);
   dispose(battlegroups);
   exitproc:=oldexitproc;
end; { exit }
{$f-}


begin
   scount:=0;
   gcount:=0;
   new(shipstates);
   new(battlegroups);
   oldexitproc:=exitproc;
   exitproc := @exit;
end.