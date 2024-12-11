{ generates turn files }

unit turn;

interface

const
   pchars : array[1..11] of string[2] =  ('1','2','3','4','5','6','7','8','9','10','11');
procedure maketurn;

implementation
uses RST,shiputil,planets,bases,bsystem,messages;

type
   trnHeader = record
		  playerid     : word;
		  ncommands    : longint;
		  lastdate     : array[1..10] of byte;
		  lasttime     : array[1..8] of byte;
		  unused       : word;
		  timechecksum : word;
		  unused2      : byte;
	       end;	       
   trnFooter = record
		  checksum : longint;
		  sig	   : longint;
		  fizz	   : array[1..204] of byte;
		  id	   : array[1..11] of longint;
	       end;	   
   command   = record	   
		  commandcode : word;
		  id	      : word; {id of the object}
		  nparams     : word;
		  ptype	      : byte; {0 chars, 1 word 2 longint 4 message }
		  params      : array[1..20] of integer;
		  lparam      : longint;
	       end;	      
   cmds	     = array[1..1200] of command;
   bufbytes  = array[1..1000] of byte;
   cmdptr    = ^cmds;
   buf	     = ^bufbytes;
   bow	     = array[0..20] of word;
   bowptr    = ^bow;
   strptr    = ^string;

var	   
   checksum : longint;
   commanda : cmdptr;
   commandb : cmdptr;
   nca,ncb  : word;
   header   : trnHeader;
   footer   : trnFooter;
   turnfile : file;
   messgs   : array[1..20] of strptr;
   mcount   : integer;

   function commandSize(c : command):word;
   var
      s	: word;
   begin
      s:=2*sizeof(word);
      if c.ptype = 0 then s:= s + c.nparams;
      if c.ptype = 1 then s:= s + (c.nparams*sizeof(word));
      if c.ptype = 2 then s:= s + sizeof(longint);
      if c.ptype = 4 then
      begin
	 s:=s+(c.nparams*sizeof(integer));
	 s:=s+length( messgs[c.params[3]]^ );
      end;
      commandSize:=s;
   end;

   procedure addcommand(c : command);
   begin
      if nca<1200 then
      begin
	 nca:=nca+1;
	 commanda^[nca] := c;
	 exit;
      end;
      if ncb=1200 then exit;
      ncb:=ncb+1;
      commandb^[ncb] := c;
   end;

   procedure shipChangeFC(id,sid : word);
   var
      c	: command;
   begin
      c.commandcode := $01;
      c.id := id;
      c.nparams:=3;
      c.ptype:=0;
      c.params[1] := ord(vessels[sid]^.fcode[1]);
      c.params[2] := ord(vessels[sid]^.fcode[2]);
      c.params[3] := ord(vessels[sid]^.fcode[3]);
      addcommand(c);
   end; { shipChangeFC }

   procedure shipChangeSpeed(id,speed : word);
   var
      c	: command;
   begin
      c.commandcode:= $02;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=speed;
      addcommand(c);
   end; { shipChangeSpeed }

   procedure shipChangeWaypoint(id : word; dx,dy:integer);
   var
      c	: command;
   begin
      c.commandcode := $03;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := dx;
      c.params[2] := dy;
      c.nparams:=2;
      addCommand(c);
   end; { shipChangeWaypoint }


   procedure shipChangeMission(id : word; m:integer);
   var
      c	: command;
   begin
      c.commandcode := $04;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := m;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeMission }

   procedure shipChangeEnemy(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $05;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeEnemy }

   procedure shipChangeTow(id : word; t:integer);
   var
      c	: command;
   begin
      c.commandcode := $06;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := t;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeTow }

   procedure shipBeamDown(id,sid : word );
   var
      c	: command;
      i	: word;
   begin
      c.commandcode := $08;
      c.id:=id;
      c.ptype:=1;
      for i:=1 to 7 do
	 c.params[i] := vessels[sid]^.unloadtoP[i];
      c.nparams:=7;
      addCommand(c);
   end; { shipBeamDown }

   procedure shipChangeIntercept(id : word; t:integer);
   var
      c	: command;
   begin
      c.commandcode := $0A;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := t;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeIntercept }

   procedure shipChangefuel(id : word; f:integer);
   var
      c	: command;
   begin
      c.commandcode := $0B;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := f;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangefuel }

   procedure shipChangeT(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $0C;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeT }

   procedure shipChangeD(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $0D;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end;

   procedure shipChangeM(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $0E;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeM }

   procedure shipChangeSupplies(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $0F;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end;

   procedure shipChangeColonists(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $10;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end;

   procedure shipChangeFish(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $11;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeFish }

   procedure shipChangeMoney(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $12;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { shipChangeMoney }

   procedure processShips;
   var
      i,c : word;
      old : starshipptr;
   begin
      for i:= 1 to nvessel do
	 with vessels[i]^ do
	    for c:= 1 to shipcount do
	       if getShip(c)^.id = id then
	       begin
		  old:= getShip(c);
		  if not(money=old^.money) then shipChangeMoney(id,money);
		  if not(fish=old^.fish) then shipChangeFish(id,fish);
		  if not(colonists=old^.colonists) then
		     shipChangeColonists(id,colonists);
		  if not(supplies=old^.supplies) then
		     shipChangeSupplies(id,supplies);
		  if not(molybdenum=old^.molybdenum) then
		     shipChangeM(id,molybdenum);
		  if not(duranium=old^.duranium) then shipChangeD(id,duranium);
		  if not(tritanium=old^.tritanium) then
		     shipChangeT(id,tritanium);
		  if not(fuel=old^.fuel) then shipChangeFuel(id,fuel);
		  if not(intercept=old^.intercept) then
		     shipChangeIntercept(id,intercept);
		  if unloadToP[7]>0 then shipBeamDown(id,i);
		  if not(tow=old^.tow) then shipChangeTow(id,tow);
		  if not(enemy=old^.enemy) then shipChangeEnemy(id,enemy);
		  if not(mission=old^.mission) then
		     shipChangeMission(id,mission);
		  if  not(dx=old^.dx) or not(dy=old^.dy) then
		     shipChangeWaypoint(id,dx,dy);
		  if not(speed=old^.speed) then shipChangeSpeed(id,speed);
		  if not( (fcode[1]=old^.fcode[1]) or
			 (fcode[2]=old^.fcode[2]) or (fcode[3]=old^.fcode[3]))
		     then shipChangeFC(id,i);
	       end;
   end;

   procedure planetChangeFC(id,wid : word);
   var
      c	: command;
   begin
      c.commandcode := $15;
      c.id := id;
      c.nparams:=3;
      c.ptype:=0;
      c.params[1] := ord(worlds[wid]^.fcode[1]);
      c.params[2] := ord(worlds[wid]^.fcode[2]);
      c.params[3] := ord(worlds[wid]^.fcode[3]);
      addcommand(c);
   end; { planetChangeFC }

   procedure planetChangeMines(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $16;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeMines }

   procedure planetChangeFactories(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $17;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeFactories }

   procedure planetChangeDef(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $18;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeDef }

   procedure planetChangeFuel(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $19;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeFuel }

   procedure planetChangeT(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1A;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeT }

   procedure planetChangeD(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1B;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeT }

   procedure planetChangeM(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1C;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeM }

   procedure planetChangeColonists(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1D;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeColonists }

   procedure planetChangeSupplies(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1E;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeSupplies }

   procedure planetChangeMoney(id : word; e:longint);
   var
      c	: command;
   begin
      c.commandcode := $1F;
      c.id:=id;
      c.ptype:=2;
      c.lparam := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeMoney }

   procedure planetChangeCtax(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $20;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeCtax }

   procedure planetChangeNtax(id : word; e:integer);
   var
      c	: command;
   begin
      c.commandcode := $21;
      c.id:=id;
      c.ptype:=1;
      c.params[1] := e;
      c.nparams:=1;
      addCommand(c);
   end; { planetChangeDef }

   procedure planetBuildBase(id : word);
   var
      c	: command;
   begin
      c.commandcode := $22;
      c.id:=id;
      c.ptype:=1;
      c.nparams:=0;
      addCommand(c);
   end; { planetBuildBase }

   procedure processPlanets;
   var
      i,c : word;
      old : planetptr;
   begin
      for i:=1 to nworlds do
	 with worlds[i]^ do
	    for c:= 1 to planetCount do
	       if getPlanet(c)^.id = id then
	       begin
		  old := getPlanet(c);
		  if not( (fcode[1]=old^.fcode[1]) or
			 (fcode[2]=old^.fcode[2]) or (fcode[3]=old^.fcode[3]))
		     then planetChangeFC(id,i);
		  if not(mines=old^.mines) then planetChangeMines(id,mines);
		  if not(factories=old^.factories) then
		     planetChangeFactories(id,factories);
		  if not(defposts=old^.defposts) then
		     planetChangeDef(id,defposts);
		  if not(Nmined=old^.Nmined) then planetChangeFuel(id,Nmined);
		  if not(Tmined=old^.Tmined) then planetChangeT(id,Tmined);
		  if not(Dmined=old^.Dmined) then planetChangeD(id,Dmined);
		  if not(Mmined=old^.Mmined) then planetChangeM(id,Mmined);
		  if not(colonists=old^.colonists) then
		     planetChangeColonists(id,colonists);
		  if not(supplies=old^.supplies) then
		     planetChangeSupplies(id,supplies);
		  if not(credits=old^.credits) then
		     planetChangeMoney(id,credits);
		  if not(ctax=old^.ctax) then planetChangeCtax(id,ctax);
		  if not(ntax=old^.ntax) then planetChangeNtax(id,ntax);
		  if buildbase>0 then planetBuildBase(id);
	       end;
   end;

   procedure baseChangeDefense(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $28;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseChangeDefense }

   procedure baseChangeEtech(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $29;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseChangeEtech }

   procedure baseChangeHtech(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $2A;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseChangeHtech }

   procedure baseChangeWtech(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $2B;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseChangeWtech }

   procedure baseBuildEngines(id : word; e : bowptr);
   var
      c	: command;
      i	: word;
   begin
      c.commandcode:= $2C;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=9;
      for i:= 0 to 8 do
	 c.params[i+1]:=e^[i];
      addcommand(c);
   end;

   procedure baseBuildHulls(id : word; e : bowptr);
   var
      c	: command;
      i	: word;
   begin
      c.commandcode:= $2D;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=20;      
      for i:= 0 to 19 do
	 c.params[i+1]:=e^[i];
      addcommand(c);
   end;

   procedure baseBuildBeams(id : word; e : bowptr);
   var
      c	: command;
      i	: word;
   begin
      c.commandcode:= $2E;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=10;
      for i:= 0 to 9 do
	 c.params[i+1]:=e^[i];
      addcommand(c);
   end; { baseBuildBeams }

   procedure baseBuildTubes(id : word; e : bowptr);
   var
      c	: command;
      i	: word;
   begin
      c.commandcode:= $2F;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=10;
      for i:= 0 to 9 do
	 c.params[i+1]:=e^[i];
      addcommand(c);
   end;

   procedure baseBuildTorps(id : word; e : bowptr);
   var
      c	: command;
      i	: word;
   begin
      c.commandcode:= $30;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=10;
      for i:= 0 to 9 do
	 c.params[i+1]:=e^[i];
      addcommand(c);
   end; { baseBuildTorps }

   procedure baseBuildFighters(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $31;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseBuildFighters }

   procedure baseFRShip(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $32;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseFRShip }

   procedure baseFR(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $33;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseFR }

   procedure baseMission(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $34;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseMission }

   procedure baseBuildShip(id,h,e,bt,bc,tt,tc : word);
   var
      c	: command;
   begin
      c.commandcode:= $35;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=7;
      c.params[1]:=h;
      c.params[2]:=e;
      c.params[3]:=bt;
      c.params[4]:=bc;
      c.params[5]:=tt;
      c.params[6]:=tc;
      c.params[7]:=0;
      addcommand(c);
   end; { baseBuildShip }

   procedure baseChangeTtech(id,e : word);
   var
      c	: command;
   begin
      c.commandcode:= $36;
      c.id:=id;
      c.ptype:=1;
      c.nparams :=1;
      c.params[1]:=e;
      addcommand(c);
   end; { baseChangeTtech }

   procedure ProcessBases;
   var
      i,c,z : word;
      d	    : boolean;
      old   : Starbaseptr;
   begin
      for i:=1 to nbase do
	 with sbases[i]^ do
	    for c:= 1 to baseCount do
	       if getBase(c)^.baseid = baseid then
	       begin
		  old:=getBase(c);
		  if not(old^.defense=defense) then baseChangeDefense(baseid,defense);
		  if not(old^.Etech=Etech) then baseChangeEtech(baseid,Etech);
		  if not(old^.Htech=Htech) then baseChangeHtech(baseid,Htech);
		  if not(old^.Wtech=Wtech) then baseChangeWtech(baseid,Wtech);
		  if not(old^.Ttech=Ttech) then baseChangeTtech(baseid,Ttech);
		  d:=false;
		  for z:=1 to 9 do
		     if not(old^.Estore[z]=Estore[z]) then d:=true;
		  if d then baseBuildEngines(baseid,@(Estore[1]));
		  d:=false;
		  for z:=1 to 20 do
		     if not(old^.Hstore[z]=Hstore[z]) then d:=true;
		  if d then baseBuildHulls(baseid,@(Hstore[1]));
		  d:=false;
		  for z:=1 to 10 do
		     if not(old^.Bstore[z]=Bstore[z]) then d:=true;
		  if d then baseBuildBeams(baseid,@(Bstore[1]));
		  d:=false;
		  for z:=1 to 10 do
		     if not(old^.Tstore[z]=Tstore[z]) then d:=true;
		  if d then baseBuildTubes(baseid,@(Tstore[1]));
		  d:=false;
		  for z:=1 to 10 do
		     if not(old^.torps[z]=torps[z]) then d:=true;
		  if d then baseBuildTorps(baseid,@(torps[1]));
		  if not(old^.fighters=fighters) then baseBuildFighters(baseid,fighters);
		  if not(old^.opId = opId) then baseFRShip(baseid,opId);
		  if not(old^.op = op) then baseFR(baseid,op);
		  if not(old^.mission = mission) then baseMission(baseid,mission);
		  if not(old^.buildhull=buildhull) then
		     baseBuildShip(baseid,buildhull,etype,btype,bcount,ttype,tcount);
	       end;
   end; { ProcessBases }

   procedure sendMessage(m : string; r:integer);
   var
      c	: command;
   begin
      c.commandCode:=$3c;
      c.id := length(m);
      c.ptype:=4;
      c.nparams:=2;
      c.params[1]:=player;
      c.params[2]:=r;
      if mcount=20 then exit;
      inc(mcount);
      c.params[3]:=mcount;
      new(messgs[mcount]);
      messgs[mcount]^:=m;
      addcommand(c);
   end; { sendMessage }

   procedure processMessages;
   var
      i	: integer;
      n	: string;
   begin
      for i:= 1 to 11 do
      begin
	 if ((send[i]>0) and (send[i]<6)) then
	    sendMessage(msgs[send[i]]+msgfooter,i);
	 if ((send[i]>10) and (send[i]<22)) then
	 begin
	    str(send[i]-10,n);
	    sendMessage(msgs[6] + n + msgfooter,i);
	 end;
	 if send[i]=7 then
	    sendMessage(helpmsg+msgfooter,i);
      end;
   end;

   procedure writeToTurn(d : buf; size:word );
   var
      i	: word;
   begin
      for i:= 1 to size do
      begin {calculate checksum}
	 checksum:=checksum+d^[i];
      end;
      blockwrite(turnfile,d^,size);
   end;

   procedure makeHeader;
   var
      pos : longint;
      i	  : word;
   begin
      pos:=sizeof(trnHeader)+ ((nca+ncb)*sizeof(longint)) +1 ;
      header.playerid:=player;
      header.ncommands:=nca+ncb;
      write('Commands ');
      writeln(header.ncommands);
      copyTimeStamp(@header.lastDate);
      header.timeCheckSum := timeStampChecksum;
      writeToTurn(@header,sizeof(trnHeader));
      {ok work out the positions of all the commands}
      for i:=1 to nca do
      begin
	 writeToTurn(@pos,sizeof(longint));
	 pos:= pos + commandsize(commanda^[i]);
      end;
      if ncb>0 then
	 for i:=1 to ncb do
	 begin
	    writeToTurn(@pos,sizeof(longint));
	    pos:= pos + commandsize(commandb^[i]);
	 end;
   end; { makeHeader }

   procedure writeCommand(c : command);
   var
      o	: char;
      i	: word;
      m	: string;
   begin
      writeToTurn(@(c.commandcode),sizeof(word));
      writeToTurn(@(c.id),sizeof(word));
      if c.nparams>0 then
	 for i:=1 to c.nparams do
	 begin
	    if c.ptype=0 then
	    begin
	       o := chr(lo(c.params[i]));
	       writeToTurn(@o,1);
	    end;
	    if c.ptype=1 then
	       writeToTurn(@c.params[i],sizeof(integer));
	    if (c.ptype=4) then
	    begin
	       writeToTurn(@c.params[i],sizeof(integer));
	    end;
	 end;
      if c.ptype=2 then
	 writeToTurn(@c.lparam,sizeof(longint));
      {ok now we need to encrpt and send a message ... if that is what we are
       doing}
      if c.ptype=4 then
      begin
	 m:=messgs[c.params[3]]^;
	 for i:= 1 to length(m) do
	 begin
	    o:=m[i];
	    o:= char( ord(o) + 13);
	    writeToTurn(@o,1);
	 end;
      end;
   end;

   procedure writeAllCommands;
   var
      i	: word;
   begin
      for i:=1 to nca do
	 writeCommand(commanda^[i]);
      if ncb>0 then
	 for i:=1 to ncb do
	    writeCommand(commandb^[i]);
   end;

   procedure makeFooter;
   var
      i	   : word;
      fizz : file;
   begin
      footer.checksum:=checksum+ (header.timeCheckSum*3)+13;
      footer.sig:=$DEADCAD;
      for i:= 1 to 11 do
	 footer.id[i]:=0;
      footer.id[player] :=checksum+ (header.timeCheckSum*3)+13;
      {now we need to read the fizz.bin so we can fill in the key segment}
      if not(checkfile('fizz.bin')) then
      begin
	 writeln('cannot find fizz.bin! can not write turn file signature!');
	 halt(1);
      end;
      assign(fizz,'fizz.bin');
      reset(fizz,1);
      seek(fizz,136);
      blockread(fizz,footer.fizz,204);
      close(fizz);
      writeToTurn(@footer,sizeof(trnFooter));
   end;

   procedure maketurn;
   var
      i : integer;
   begin
      writeln('Making turn file');
      nca:=0;
      ncb:=0;
      mcount:=0;
      checksum:=0;
      new(commanda);
      new(commandb);
      {$ifdef Debug}
      write('Memory Available ->');
      writeln(memavail);
      write('Max Block ->');
      writeln(maxavail);
      {$endif}
      processships;
      processPlanets;
      processbases;
      processMessages;
      
      assign(turnfile,'player'+pchars[player]+'.trn');
      rewrite(turnfile,1);
      makeHeader;
      writeAllCommands;
      makeFooter;
      close(turnfile);      
      dispose(commanda);
      dispose(commandb);
      for i:= 1 to mcount do
	 dispose(messgs[i]);
   end; { maketurn }

end.