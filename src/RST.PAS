{loads Result data from an RST file, the records bellow actually reflect what is in the RST}

unit RST;

interface

{starbase missions
0 none
1 refuel
2 max def
3 load torps
4 unload freighters
5 repair base 6 force surrender}
type 
    starbase = record
		  baseID    : word;
		  owner	    : word;
		  defense   : word;
		  damage    : word;
		  Etech	    : word;
		  Htech	    : word;
		  Wtech	    : word;
		  Ttech	    : word;
		  Estore    : array[1..9] of word;
		  Hstore    : array[1..20] of word;
		  Bstore    : array[1..10] of word;
		  Tstore    : array[1..10] of word;
		  torps	    : array[1..10] of word;
		  fighters  : word;
		  opID	    : word; {fix or repair ship id}
		  op	    : word; {0 nothing 1 fix 2 recylce}
		  mission   : word; {see top }
		  buildhull : word; {0 = none }		  
		  Etype	    : word;  {engines to be fitted}
		  Btype	    : word;  {beams to be fitted}
		  Bcount    : word; {no. of beams}
		  Ttype	    : word; {torp type}
		  Tcount    : word; 
		  zero	    : word; {should be zero (unused for actual building)}
	       end;	    
{native races
0 none
1 humanoid
2 bovinoid
3 reptilian
4 avian
5 amorphous
6 insectoid
7 amphibian
8 ghipsoldal
9 siliconoid}

    planet = record
		owner	  : word;
		id	  : word;
		fcode	  : array[1..3] of char;
		mines	  : word;
		factories : word;
		defposts  : word;
		Nmined	  : longint;
		Tmined	  : longint;
		Dmined	  : longint;
		Mmined	  : longint;
		colonists : longint;
		supplies  : longint;
		credits	  : longint;
		Nground	  : longint;
		Tground	  : longint;
		Dground	  : longint;
		Mground	  : longint;
		Ndens	  : word;		
		Tdens	  : word;
		Ddens	  : word;
		Mdens	  : word;
		Ctax	  : integer;
		Ntax	  : integer;
		Chappy	  : word;
		Nhappy	  : word;
		Ngov	  : word; 
		natives	  : longint;
		nrace	  : word;
		temp	  : word;
		buildbase : word;
	     end;
{cargo tranfers
fuel
tritanium
duranium
molybdenum
colonists
supplies
id to tranfer to
}
   {missions
   0 none
   1 explore
   2 mine sweep
   3 lay mines
   4 kill
   5 sensor sweep
   6 colonize
   7 tow
   8 intercept
   9 race mission
     1 super refit
     2 hisss!
     3 super spy
     4 pillage
     5 rob
     6 repair
     7 lay web mines
     8 dark sense
     9 build fighters
     10 rebel ground assault
     11 build fighters
   10 cloak
   11 beam up fuel
   12 bu duranium
   13 bu tritanium
   14 bu molybdenum
   15 bu supplies
   }

   starship = record
		 id	    : word;
		 owner	    : integer;
		 fcode	    : array[1..3] of char;
		 speed	    : integer;
		 dx	    : integer; {waypoint location relative}
		 dy	    : integer;
		 x	    : integer; {location}
		 y	    : integer;
		 eng	    : word;
		 hull	    : word;
		 beam	    : word;
		 bcount	    : word;
		 fbays	    : word;
		 torp	    : word;
		 fish	    : integer; {torpedos or fighters carried}
		 tcount	    : word;
		 mission    : word;
		 enemy	    : word;
		 tow        : word; {mission param usually a ship id for tow}
		 damage	    : word;
		 crew	    : word;
		 colonists  : word;
		 name	    : array[1..20] of char;
		 fuel	    : integer;
		 tritanium  : word;
		 duranium   : word;
		 molybdenum : word;
		 supplies   : word;
		 unloadToP  : array[1..7] of word;
		 unloadToS  : array[1..7] of word;
		 intercept  : integer; {intercept ship id or zero}
		 money	    : word;
	      end;
   
   target = record
	       id      : word;
	       owner   : integer;
	       speed   : integer;
	       x,y     : integer;
	       hull    : word;
	       heading : integer;
	       name    : array[1..20] of char;
	    end;
   vcrobject = record {an object that appears in a vcr combat}
		  name	: array[1..20] of char;
		  dam	: word; {damage at start of combat}
		  crew	: word; {crew remaining}
		  id	: word; {id of the ship}
		  owner	: byte; {the race/player id that owns the ship}
		  phown	: byte; {special byte for phost ownership}
		  pic	: byte; {ship picture (as found in resource.pln)}
		  hull	: byte; {phost hull number if available.}
		  beamt	: word; {beam type}
		  beamc : byte; {beam count} 
		  pxp   : byte; {phost xp level}
		  fbays : word; {fighter bay count}
		  torpt : word; {torpedo type}
		  fish  : word; {number of torps/fighters} 
		  torpc : word; {number of torpedo launchers} 
	       end;					   
   vcr = record {vcr record (stores information about a combat}
	    seed    : word;
	    sig	    : word; {always zero for thost or is = 48879-seed if phost}
	    temp    : word; {thost = planet temp phost=capabilities flags}
	    ctyp    : word; {combat type 0 = ship to ship 1=ship to planet}
	    lmass   : word; {mass of left vessel}
	    rmass   : word; {mass of right vessel}
	    lship   : vcrobject;	   
	    rship   : vcrobject;
	    lshield : word; {left vessels shields}
	    rshield : word; {right vessels shields}
	 end;				   
   starbaseptr= ^starbase;
   planetptr  = ^planet;
   starshipptr= ^starship;
   targetptr  = ^target;
   vcrptr = ^vcr;

         procedure loadRST(rst :string);
	 procedure resetRST;

	 function planetCount:word;
	 function shipCount:   word;
	 function baseCount: word;
	 function targetCount:word;
         function combatcount:word;
	 function player:word;
	 function turnNumber:word;
         function getScore(player,index : word):word;

	 function getPlanet(i : word):planetptr;
         function getShip(i : word):starshipptr;
	 function getBase(i : word):starbaseptr;
	 function getTarget(i : word):targetptr;
         function getCombat(i : word):vcrptr;

         procedure copyTimestamp(d : pointer);
         function timestampchecksum:word;
	 {utility}
	 function min(a,b : longint):longint;
	 function max(a,b : longint):longint;

implementation
uses bsystem,hull;
      type
	 RSTheader   = record
			  sections    : array[1..8] of longint;
			  signature   : array[1..6] of char;
			  version     : array[1..2] of char;
			  winplandata : longint;
			  leechdata   : longint;
		       end;{there is a extra longint if it is version 01}
	 generaldata = record
			  timestamp    : array[1..18] of byte;
			  score	       : array[1..44] of word;
			  player       : word;
			  password     : array[1..20] of char;
			  checksums    : array[1..3] of longint;
			  turn	       : word;
			  timechecksum : word;
		       end;	       
	 shipxy	     = record
			  x,y	     : integer;
			  owner,mass : word;
		       end;	     
	 msgHeader   = record
			  faddr	 : longint;
			  length : integer;
		       end;	 
	 msgBuff     = array[1..2000] of msgHeader;
	 msgBuffptr  = ^msgBuff;

      var
	 header				    : RSTheader;
	 gendata			    : generaldata;
	 planets			    : array[1..500] of planetptr;
	 starbases			    : array[1..500] of starbaseptr;
	 ships				    : array[1..500] of starshipptr;
	 targets			    : array[1..500] of targetptr;
	 combats			    : array[1..50] of vcrptr;
	 msgs				    : msgBuffptr;
	 pcount,bcount,scount,tcount,mcount : word;
	 ccount				    : word;

	    procedure sanitiseShip(ss : starshipptr);
	    var i   : integer;
	       sane : boolean;
	    begin
	       sane:=true;
	       with ss^ do
	       begin
		  for i:= 1 to 7 do
		  begin
		     if unloadToP[i]>0 then
		     begin
			sane:=false;
			unloadtoP[i]:=0;
		     end;
		     if unloadToS[i]>0 then
		     begin
			sane:=false;
			unloadtoS[i]:=0;
		     end;
		  end;
		  if (((beam>10) or (beam<1)) and (bcount>0)) then
		  begin
		     bcount:=0;
		     sane:=false;
		     beam:=1;
		  end;
		  if (((torp>10) or (torp<1)) and (tcount>0)) then
		  begin
		     tcount:=0;
		     sane:=false;
		     torp:=1;
		  end;
		  if bcount>50 then
		  begin
		     sane:=false;
		     bcount:=0;
		  end;
		  if tcount>50 then
		  begin
		     sane:=false;
		     tcount:=0;
		  end;
		  if ((speed<0) or (speed>9)) then
		  begin
		     speed:=0;
		     sane:=false;
		  end;
		  if not(sane) then
		     writeln(' Ship not sane!!! id:',id);		     
	       end;
	    end;

	    function combatcount:word;
	    begin
	       combatcount:=ccount;
	    end;

	    function getCombat(i : word):vcrptr;
	    begin
	       getCombat := combats[i];
	    end;
	 
	    function turnNumber:word;
	    begin
	       turnNumber:=gendata.turn;
	    end;
      
	    function min(a,b : longint):longint;
	    begin
	       min:=a;
	       if b<a then min:=b;
	    end; { min }
	 
	    function max(a,b : longint):longint;
	    begin
	       max:=a;
	       if b>a then max:=b;
	    end; { min }

        function getScore(player,index : word):word;
	begin
	   getScore:=0;
	   if ((player>11) or (player<1)) then exit;
	   if ((index>4) or (index<1)) then exit;
	   getScore:=gendata.score[ ((player-1)*4) + (index) ];
	end;
      
        procedure copyTimestamp(d : pointer);
	begin
	   copymem(@gendata.timestamp,d,18);
	end;

	function timestampchecksum:word;
	begin
	   timestampchecksum:=gendata.timechecksum;
	end;

	function targetExists(id : word):boolean;
	var
	   i : word;
	begin
	   targetExists:=false;
	   for i:= 1 to tcount do
	      if id=targets[i]^.id then targetExists:=true;
	end;	    
	 
	 procedure loadRST(rst :string);
	 var rstfile	: file;
	    bytesread,i	: word;
	    sxy		: shipxy;
	    msgout	: text;
	    b		: byte;
	 begin
            write('Reading result file ');
            writeln(rst);
	    Assign(rstfile,rst);
	    reset(rstfile,1);
	    blockread(rstfile,header,sizeof(RSTheader),bytesread);
	    if not(bytesread = sizeof(RSTheader)) then
	    begin
	       writeln('RST header too small!!!');
	       halt(1);
	    end;
            for i:=1 to 8 do
	    begin
	       dec(header.sections[i]); {necessary for the pointers to be correct}
            end;
	    {ok now we need to seek to a section and read it}
	    {going to read ships}
	    seek(rstfile,header.sections[1]);
	    blockread(rstfile,scount,sizeof(scount));
	    write(scount);
	    writeln(' Ships loading...');
	    for i:=1 to scount do
	    begin
	       new(ships[i]);
	       blockread(rstfile,ships[i]^,sizeof(starship),bytesread);
	       if not(bytesread=107) then
	       begin
		  writeln(bytesread);
		  writeln('could not read ship data');
		  halt(1);
	       end;
	       sanitiseShip(ships[i]);
	    end;
	    {attempt to read planets}
	    seek(rstfile,header.sections[3]);
	    blockread(rstfile,pcount,sizeof(pcount));
	    write(pcount);
	    writeln(' Planets loading...');
	    for i:=1 to pcount do
	    begin
	       new(planets[i]);
	       blockread(rstfile,planets[i]^,sizeof(planet),bytesread);
	       if not(bytesread=85) then
	       begin
		  writeln(bytesread);
		  writeln('could not read planet data');
		  halt(1);
	       end;
	    end;
	    {attempt to read bases}
	    seek(rstfile,header.sections[4]);
	    blockread(rstfile,bcount,sizeof(bcount));
	    write(bcount);
	    writeln(' Bases loading...');
	    for i:=1 to bcount do
	    begin
	       new(starbases[i]);
	       blockread(rstfile,starbases[i]^,sizeof(starbase),bytesread);
	       if not(bytesread = 156) then
	       begin
		  writeln(bytesread);
		  writeln('could not read base data');
		  halt(1);
	       end;
	    end;
	    {attempt to read targets}
	    seek(rstfile,header.sections[2]);
	    blockread(rstfile,tcount,sizeof(tcount));
	    write(tcount);
	    writeln(' Targets loading...');
	    for i:=1 to tcount do
	    begin
	       new(targets[i]);
	       blockread(rstfile,targets[i]^,sizeof(target),bytesread);
	       if not(bytesread=34) then
	       begin
		  writeln(bytesread);
		  writeln('could not read target data');
		  halt(1);
	       end;
	    end;
	    {read the gen data}
	    writeln('reading General Data...');
	    seek(rstfile,header.sections[7]);
	    blockread(rstfile,gendata,sizeof(generaldata),bytesread);
	    if not(bytesread=sizeof(generaldata)) then
	    begin
	       writeln(bytesread);
	       writeln('could not read general data');
	       halt(1);
	    end;  
	    {read the shipxy data and create new targets}
	    writeln('reading non-scanable targets (shipXY)');
	    seek(rstfile,header.sections[6]);
	    for i:= 1 to 500 do
	    begin
	       blockread(rstfile,sxy,sizeof(sxy),bytesread);
	       if not(bytesread=sizeof(shipxy)) then
	       begin
		  writeln(bytesread);
		  writeln('could not read ShipXY data');
		  halt(1);
	       end;
	       if (not(sxy.x=0) and not(sxy.y=0) and not(sxy.owner=player)
		   and not(targetExists(i))) then
	       begin
		  write('.');
		  inc(tcount);
		  new(targets[tcount]);
		  targets[tcount]^.id:=i;
		  targets[tcount]^.x:=sxy.x;
		  targets[tcount]^.y:=sxy.y;
		  targets[tcount]^.owner:=sxy.owner;
		  targets[tcount]^.heading:=-1; {don't know}
		  targets[tcount]^.speed:=0; {don't know}
		  targets[tcount]^.hull := guessHull(sxy.owner,sxy.mass);
	       end;
	    end;
	    writeln;
	    {read vcr combat from the result file}
	    writeln('Reading combat ...');
	    seek(rstfile,header.sections[8]);
	    blockread(rstfile, ccount, sizeof(ccount),bytesread);
	    if not(bytesread=sizeof(ccount)) then
	    begin
	       writeln(bytesread);
	       writeln('could not read vcr count');
	       halt(1);
	    end;
	    if ccount>50 then ccount:=50;
	    for i:= 1 to ccount do
	    begin
	       write('.');
	       new(combats[i]);
	       blockread(rstfile,combats[i]^,sizeof(vcr),bytesread);
	       if not(bytesread=sizeof(vcr)) then
	       begin
		  writeln(bytesread);
		  writeln('could not read combat');
		  halt(1);
	       end;
	    end;
	    writeln;
	    {ok now we attempt to read messages}
	    writeln('Attempting to read messages');
	    seek(rstfile,header.sections[5]);
	    blockread(rstfile,mcount,sizeof(mcount),bytesread);
	    if not(bytesread=sizeof(mcount)) then
	       begin
		  writeln(bytesread);
		  writeln('could not read Message Header');
		  halt(1);
	       end;
	    write(mcount); writeln(' Messages in inbox');
	    {we need to read the directory of messages and then each
	     message individually}
	    {read a max of 2000 messages}
	    if mcount>2000 then mcount:=2000;
	    new(msgs);
	    for i:= 1 to mcount do
	    begin
	       blockread(rstfile,msgs^[i],sizeof(msgHeader),bytesread);
	       if not(bytesread=sizeof(msgHeader)) then
	       begin
		  writeln(bytesread);
		  writeln('could not read Message Header');
		  halt(1);
	       end;
	    end;
	    {ok now we need to actually copy messages into a temp file for
	    later processing}
	    assign(msgout,'msgout.log');
	    rewrite(msgout);
	    for i:= 1 to mcount do
	    begin
	       {seek to the begining of the message}
	       write('.');
	       seek(rstfile,msgs^[i].faddr-1);
	       {ok now read length bytes and decrypt them and write them to the message file}
	       for bytesread:= 1 to msgs^[i].length do
	       begin
		  blockread(rstfile,b,1);
		  b:= b - 13;
		  write(msgout,char(b));
	       end;
	       {write end of message tag}
	       writeln(msgout);
	       writeln(msgout,'******');
	    end;	    
	    close(msgout);	    
	    dispose(msgs);
	    writeln;
	    close(rstfile);
	 end;

	 function planetCount:word;
	 begin
	    planetCount:=pcount;
	 end; { planetCount }
	 
	 function shipCount:   word;
	 begin
	    shipCount:=scount;
	 end; { shipCount }
	 
	 function baseCount: word;
	 begin
	    baseCount:=bcount;
	 end; { baseCount }
	 
	 function targetCount:word;
	 begin
	    targetCount:=tcount;
	 end; { targetCount }
	 
	 function player:word;   
	 begin
	    player:=gendata.player;
	 end; { player }
	 
	 function getPlanet(i : word):planetptr;
	 begin
	    getPlanet:=planets[i];
	 end; { getPlanet }
	 
         function getShip(i : word):starshipptr;
	 begin
	    getShip:=ships[i];
	 end; { getShip }
	 
	 function getBase(i : word):starbaseptr;
	 begin
	    getBase:=starbases[i];
	 end; { getBase }
	 
	 function getTarget(i : word):targetptr;
	 begin
	    getTarget:=targets[i];
	 end; { getTarget }
	 	 
	 procedure resetRST;
	 var
	    i : word;
	 begin
	    for i:=1 to bcount do
	    begin
	       dispose(starbases[i]);
	    end;
	    bcount:=0;
	    for i:=1 to scount do
	    begin
	       dispose(ships[i]);
	    end;
	    scount:=0;
	    for i:=1 to pcount do
	    begin
	       dispose(planets[i]);
	    end;
	    pcount:=0;
	    for i:=1 to tcount do
	    begin
	       dispose(targets[i]);
	    end;
	    tcount:=0;
	    for i:= 1 to ccount do
	       dispose(combats[i]);
	    ccount:=0;
	 end;




      begin
	 tcount:=0;
	 pcount:=0;
	 scount:=0;
	 bcount:=0;
	 ccount:=0;
      end.









