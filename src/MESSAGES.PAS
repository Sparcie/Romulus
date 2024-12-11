{ message parser for romulus }
{expanded to also read vcr records and process those.}

unit messages;

interface

uses vector,map,rst,targdb;

type
   IonStorm  = record
		  x,y	  : integer; {location}
		  radius  : integer; {size}
		  heading : integer;
		  volt	  : integer; {magnitude}
	       end;	  
   MineField =  record
		   id	  : word;
		   x,y	  : integer;
		   radius : integer;
		   web	  : boolean;
		   enemy  : boolean;
		end;	  


var
   storms	  : array[0..20] of IonStorm; {we don't expect any more than 20 storms}
   mines	  : array[0..100] of MineField;
   mcount, scount : integer;   {diplomatic stuff... here so the shipstat unit can save them.}
   attacked	  : array[1..11] of boolean;
   Attitude	  : array[1..11] of integer; {1000 hate 500 neutral 0 love}
   dipstate	  : array[1..11] of byte; {0=no contact 1=ceasefire 2=peace 3=war}
   offer	  : array[1..11] of byte; {0 none 1=offer ceasefire 2=offer peace 3 = sent assistance request}
   accept	  : array[1..11] of byte; {0 none 1=ceasefire offered 2=peace offered 10+x = assistance request (x is enemy)}
   send		  : array[1..11] of byte; {0 nothing 1=declare war 2=offer ceasfire 3=offer peace 4=accept ceasefire
					  5=accept peace 10+x = request assist by attacking race x}

const {messages!}	      
   msgfooter: string	      = char($0d)+char($0d)+'Romulus Computer AI'+char($0d)+'(send HELP for message codes)';
   msgs:array[1..6] of string = ('We are declaring war on you!'+char($0d)+char($0d)+'ROMU WAR',
				 'We would like to offer you a'+char($0d)+' cease-fire.'+char($0d)+char($0d)+
				 'ROMU OFFER CEASE',
				 'We would like to sign a peace'+char($0d)+'treaty with you'+char($0d)+char($0d)+
				 'ROMU OFFER PEACE',
				 'We accept your offer for a'+char($0d)+'cease-fire'+char($0d)+char($0d)+
				 'ROMU ACCEPT CEASE',
				 'We accept your offer for a'+char($0d)+'peace treaty'+char($0d)+char($0d)+
				 'ROMU ACCEPT PEACE',
				 'Please assist us!'+char($0d)+'A larger player is attacking us!'+char($0d)+char($0d)+
				 'ROMU ASSIST ');
   helpmsg:string             = 'Romulus message codes'+char($0d)+
                                ' ROMU WAR = declare war'+char($0d)+
                                ' ROMU OFFER CEASE = offer a cease-fire'+char($0d)+
			        ' ROMU OFFER PEACE = offer a peace treaty'+char($0d)+
                                ' ROMU ACCEPT CEASE = accept a cease-fire'+char($0d)+
                                ' ROMU ACCEPT PEACE = accept peace treaty'+char($0d)+
                                ' ROMU ASSIST x = please attack race x (1..11)';

procedure resetmsgs;
procedure parseMessages;

function inMines(x,y	:integer ):word;
function inStorm(x,y : integer ): word;
function enemyMineFieldCount:word;
procedure processVCR;

implementation

type
   message = record
		data : array[0..1024] of char;
		size : word;
	     end;    
   msgptr  =  ^message;

function enemyMineFieldCount:word;
var
   i	 : integer;
   count : integer;
begin
   enemyMineFieldCount:=0;
   count:=0;
   if mcount=0 then exit;
   for i:= 0 to (mcount-1) do
   begin
      if mines[i].enemy then inc(count);
   end;
   enemyMineFieldCount:=count;
end;

function inMines(x,y: integer ):word;
var
   i : word;
begin
   inMines:=101;
   if mcount=0 then exit;
   for i:=0 to (mcount-1) do
   begin
      if mines[i].enemy then
	 if (round(distance(x,y,mines[i].x,mines[i].y)) <= mines[i].radius) then
	 begin
	    inMines:=i;
	    exit;
	 end;
   end;
end; { inMines }
		  
function inStorm(x,y: integer):word;
var
   i : word;
begin
   inStorm:=21;
   if scount=0 then exit;
   for i:= 0 to (scount-1) do
   begin
      if storms[i].volt>125 then
	 if trunc(distance(x,y,storms[i].x,storms[i].y)) <= (storms[i].radius+81) then
	 begin
	    inStorm:=i;
	    exit;
	 end;
   end;
end;

procedure resetmsgs;
var i : integer;
begin
   for i:= 1 to 11 do attacked[i]:=false;
   mcount:=0;
   scount:=0;
end; { reset }

function findword(s : msgptr; wrd:string):word; {returns where it found the first letter of the word}
var
   pos	    : word;
   progress : word;
begin
   pos:=0;
   progress:=1;
   findword :=0;
   with s^ do
   begin
      while pos<size do
      begin
	 if (wrd[progress] = data[pos]) then
	 begin
	    if progress=1 then findword:=pos;
	    inc(progress);
	    if (progress=length(wrd)+1) then exit;
	 end
	 else
	 begin
	    progress:=1;
	    findword:=0;
	 end;
	 inc(pos);
      end;
   end;
end; { findword }

function nextWord(s : msgptr; wrd:string; pos:word):word; {returns where it found the first letter of the word}
var
   progress : word;
begin
   progress:=1;
   nextword :=pos;
   with s^ do
   begin
      while pos<size do
      begin
	 if (wrd[progress] = data[pos]) then
	 begin
	    if progress=1 then nextword:=pos;
	    inc(progress);
	    if (progress=length(wrd)+1) then exit;
	 end
	 else
	 begin
	    progress:=1;
	    nextword:=0;
	 end;
	 inc(pos);
      end;
   end;
end; { nextWord }

function getNumber(s : msgptr; var pos:word):longint;
var
   done	: boolean;
   num	: word;
   gn   : longint;
begin
   gn:=0;
   done:=false;
   with s^ do
      while not(done) do
      begin
	 num := ord(data[pos]);
	 if ((num>47) and (num<58)) then
	 begin {is a digit}
	    gn:=(gn * 10) + (num-48);
	 end
	 else
	 begin {is not a digit}
	    if (gn>0) then done:=true;
	 end;
	 inc(pos);
      end;
   getNumber:=gn;
end; { getNumber }

procedure isIonStorm(s : msgptr);
var
   pos : word;
begin
   Writeln('Ion Storm Found');
   if scount=20 then exit;
   pos:= findWord(s,'Centered');
   storms[scount].x := getNumber(s,pos);
   storms[scount].y := getNumber(s,pos);
   pos:= findWord(s,'Radius');
   storms[scount].radius := getNumber(s,pos);
   pos:= findWord(s,'Heading');
   storms[scount].heading := getNumber(s,pos);
   pos:= findWord(s,'Voltage');
   storms[scount].volt := getNumber(s,pos);
   {$ifdef d_messages}
   writeln('Storm found');
   writeln('(',storms[scount].x,',',storms[scount].y,')');
   writeln(' radius ',storms[scount].radius);
   writeln(' heading ',storms[scount].heading);
   writeln(' Voltage ',storms[scount].volt);
   {$endif}
   inc(scount);
end; { isIonStorm }

procedure isMineField(s	: msgptr; nid:word );
var
   pos : word;
   i   : word;
begin
   if (mcount>0) then
      for i:= 0 to (mcount-1) do
	 if (nid = mines[i].id) then exit;
   pos := findWord(s,'Enemy');
   if pos > 0 then
      begin
	 writeln('Enemy Mines detected! id:', nid);
	 pos := findWord(s,'AT');
	 if mcount=100 then exit;
	 mines[mcount].id := nid;
	 mines[mcount].x := getNumber(s,pos);
	 mines[mcount].y := getNumber(s,pos);
	 pos:= findWord(s,'The field is');
	 mines[mcount].radius := getNumber(s,pos) div 2;
	 mines[mcount].web := false;
	 mines[mcount].enemy:= true;
	 pos := findWord(s,'Crystalline');
	 if pos>0 then mines[mcount].web :=true;
	 {$ifdef d_messages}
	 writeln('mines found');
	 writeln('(',mines[mcount].x,'	,',mines[mcount].y,')');
	 writeln(' radius ',mines[mcount].radius);
	 writeln(' web ',mines[mcount].web);
	 {$endif}
	 inc(mcount);
      end;
   pos := findWord(s,'our');
   if pos > 0 then
      begin
	 writeln('Friendly Mines detected! id:', nid);
	 pos := findWord(s,'at');
	 if mcount=100 then exit;
	 mines[mcount].id := nid;
	 mines[mcount].x := getNumber(s,pos);
	 mines[mcount].y := getNumber(s,pos);
	 pos:= findWord(s,'field contains');
	 mines[mcount].radius := trunc(sqrt(getNumber(s,pos)));
	 mines[mcount].web := false;
	 mines[mcount].enemy:= false;
	 if player=7 then mines[mcount].web :=true;
	 {$ifdef d_messages}
	 writeln('mines found');
	 writeln('(',mines[mcount].x,'	,',mines[mcount].y,')');
	 writeln(' radius ',mines[mcount].radius);
	 writeln(' web ',mines[mcount].web);
	 {$endif}
	 inc(mcount);
      end;
end; { isMineField }

procedure diploMessage(s : msgptr);
var
   r   : integer;
   c   : char;
   pos : word;
begin
   {work out who it is that sent this}
   c:=s^.data[3];
   if c='0' then exit; {anonymous message! we can't use this!}
   r:= ord(c) - 48;
   if r<1 then exit;
   if r=17 then r:=10;
   if r=18 then r:=11;
   if r>11 then exit;
   pos:=findWord(s,'ROMU');
   if pos=0 then {not a romulus message}
   begin
      pos:=findWord(s,'HELP');
      if pos>0 then send[r]:=7;
      exit;
   end;
   if ((nextWord(s,'ASSIST',pos)>pos) and (dipstate[r]=2)) then
   begin {a request to attack a player.}
      pos:= nextWord(s,'ASSIST',pos);
      accept[r] := 10 + lo(getNumber(s,pos));
      writeln('Assistance requested by ',r,' against ',(accept[r]-10));
      if accept[r]>21 then accept[r]:=0;
      if accept[r]<11 then accept[r]:=0;
   end;
   if nextWord(s,'ACCEPT',pos)>pos then
   begin {the player is accepting something!}
      if nextWord(s,'PEACE',pos)>pos then
	 if offer[r]=2 then
	 begin
	    writeln('Peace treaty accepted by player ',r);
	    offer[r]:=0;
	    accept[r]:=0;
	    dipstate[r]:=2;
	    attitude[r]:=0;
	    exit;
	 end;
      if nextWord(s,'CEASE',pos)>pos then
	 if offer[r]=1 then
	 begin
	    writeln('Cease-fire accepted by player ',r);
	    offer[r]:=0;
	    accept[r]:=0;
	    dipstate[r]:=1;
	    attitude[r]:=0;
	 end;
      exit;
   end;
   if nextWord(s,'OFFER',pos)>pos then
   begin {the player is Offering something!}
      if nextWord(s,'PEACE',pos)>pos then
      begin
	 writeln('Peace treaty offered by player ',r);
	 accept[r]:=2;
	 exit;
      end;
      if nextWord(s,'CEASE',pos)>pos then
      begin
	 writeln('Cease-fire offered by player ',r);
	 accept[r]:=1;
	 exit;
      end;
      exit;
   end;
   if nextWord(s,'WAR',pos)>pos then
   begin
      writeln('Player ',r,' has declared war on us.');
      dipstate[r]:=3;
      offer[r]:=0;
      accept[r]:=0;
      attitude[r]:=600;
   end;
end;

procedure planetFoundMessage(s : msgptr; id:integer);
var
   pos	 : word;
   si	 : scoutInfo;
   clans : longint; {clans the planet has}
   defp	 : integer; { max defense posts }
   base	 : boolean; { star base?}
begin
   {check that this is a planet found message (this type also does natives found and a few other message types)}
   pos:=0;
   pos := nextWord(s, 'There are enemy colonists' ,pos);
   if pos = 0 then exit; {if this isn't found then this isn't a found planet!}
   si.id := id; {set up the basics}
   si.turn := turnNumber;
   pos := nextWord(s,'Sensors show',pos); {find the bit before the clan count}
   clans := getNumber(s,pos);
   base:=false;
   pos := findWord(s,'starbase');
   if pos>0 then base := true;
   if clans<51 then defp:=clans;
   if clans>50 then defp:= trunc(sqrt(clans-50)) + 50;

   si.beams := round(sqrt(defp / 3.0));
   if base then si.beams := round(sqrt((defp+200.0) /3.0));
   si.beams := min(10,si.beams);

   si.bays := trunc(sqrt(defp));
   if base then si.bays:=si.bays+5;

   si.fighters := round(sqrt(defp - 0.75));
   if base then si.fighters:=si.fighters+60;

   addScouted(si);
   {$ifdef d_messages}
   writeln('planet scouted');
   writeln(' id: ',si.id);
   writeln(' turn discovered: ',si.turn);
   writeln(' beam count: ',si.beams);
   writeln(' bay count: ',si.bays);
   writeln(' fighters: ',si.fighters);
   if base then writeln(' a starbase was found');
   {$endif}

end;

procedure identifyMessage(s : msgptr );
var
   mt : char; {message type}
   id : integer; {identifier in the header}
begin {ok work out the type of message and pass it onto it's sub processor}
   with s^ do
   begin
      {the 3rd character in a message should identify the type of message}
      { the 4th -> 8th should be identifiers }
      {$ifdef d_messages}
      writeln(data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]);
      writeln(size);
      {$endif}
      id:= ord(data[6]) - 48;
      id:= id + (ord(data[5])-48)*10;
      id:= id + (ord(data[4])-48)*100;
      id:= id + (ord(data[3])-48)*1000;
      mt:= data[2];
      if (mt='i') then isIonStorm(s);
      if (mt='m') then isMineField(s, id);
      {message types no longer parsed (information gathered from vcr)}
      {if (mt='f') then fleetmessage(s,id);
      if ((mt='p') and (data[3]='0')) then planetMessage(s,id);}
      if (mt='r') then diploMessage(s);
      if (mt='z') then planetFoundMessage(s,id);
   end;
end; { identifyMessage }

procedure parseMessages;
var
   m	  : msgptr;
   msgin  : text;
   cin	  : char;
   ecount : byte;
begin {split into individual messages }
   writeln('Reading Messages');
   new(m);
   m^.size:=0;
   assign(msgin,'msgout.log');
   reset(msgin);
   ecount:=0;
   while not(eof(msgin)) do
   begin
      read(msgin,cin);
      if cin='*' then inc(ecount);
      m^.data[m^.size] := cin;
      m^.size := m^.size+1;
      if ecount = 6 then
      begin
	 ecount:=0;
	 read(msgin,cin); {read the end line characters (2 of them)}
	 read(msgin,cin);
	 identifyMessage(m);
	 m^.size:=0; {reset message}
      end;
   end;
   close(msgin);
   dispose(m);
end; { parseMessages }

function shipExists(id,v : word) :boolean;
var i : word;
begin
   shipExists:=false;
   for i:= 1 to shipcount do
      if getShip(i)^.id = id then shipExists:=true;
   for i:= 1 to targetCount do
      if getTarget(i)^.owner = id then shipExists:=true;
   for i:= v+1 to combatCount do
      with getCombat(i)^ do
      begin
	 if lship.id = id then shipExists:=true; {ship continued in combat against another ship!}
	 if ((rship.id = id) and (ctyp=0)) then shipExists:=true; 
      end;
end;

function planetExists(id,v : word) :boolean;
var i : word;
begin
   planetExists:=false;
   for i:= 1 to planetCount do
      if getPlanet(i)^.id = id then planetExists:=true;
   for i:= v+1 to combatCount do
      with getCombat(i)^ do
      begin
	 if ((rship.id = id) and (ctyp=1)) then planetExists:=true; 
      end;
end;

procedure processVCR;
var i	   : integer;
   com	   : vcrptr;
   s	   : scoutInfo;
begin
   if combatcount=0 then exit;
   writeln('Processing combat ...');
   for i:= 1 to combatcount do
   begin
      com:= getCombat(i);
      with com^ do
      begin
	 if ctyp = 0 then
	 begin {ship to ship combat (just record changes in the targdb)}
	    {work out which ship no longer exists (at this point in combat) and remove it from the db}
	    if shipExists(lship.id,i) then shipCombat(rship.id);
	    if shipExists(rship.id,i) then shipCombat(lship.id);
	    writeln('Combat between ship id ',lship.id,' and ship id ', rship.id);
	 end;
	 if ctyp = 1 then
	 begin {ship to planet combat (work out changer to db)}
	    writeln('Combat between ship id ',lship.id,' and planet ',rship.id);
	    {is the planet an enemy?}
	    if not(rship.owner = player) then
	    begin
	       {insert item into scouted planet db (for working out assaults)}
	       s.id := rship.id;
	       s.beams := rship.beamc;
	       s.bays := rship.fbays;
	       s.fighters := rship.fish;
	       s.turn := turnNumber;
	       if not(shipExists(lship.id,i)) then
		  addScouted(s) {we died, (the ship) so add scouting info}
	       else
		  planetCaptured(rship.id); {we survived, so we captured the planet}
	    end
	    else
	    begin
	       {it was an enemy attacking us! did we survive?}
	       if planetExists(rship.id,i) then shipCombat(lship.id);
	    end;   
	 end;
	 {ok who attacked us... record for the diplomacy section!}
	 if not(lship.owner=player) then
	 begin
	    {left ship was the enemy}
	    writeln('Enemy was player ',lship.owner, ' on the left hand side');
	    if ((lship.owner>0) and (lship.owner<12)) then attacked[lship.owner]:=true;
	 end;
	 if not(rship.owner=player) then
	 begin
	    {right ship was the enemy}
	    writeln('Enemy was player ',rship.owner, ' on the right hand side');
	    if ((rship.owner>0) and (rship.owner<12)) then attacked[rship.owner]:=true;
	 end;
      end;      
   end;	   
end;

end.