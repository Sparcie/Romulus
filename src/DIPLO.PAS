{Diplomacy unit: sets and manages attitudes to other races}
unit Diplo;

interface
uses RST,map,shipstat,shipclas,messages,vector,targdb;


procedure doDiplomacy;
procedure resetDip;
function isEnemy(r : integer):boolean;
function intendWar(r : integer):boolean;

var
   sLimits : array[0..6] of word; {limits for ship tasks
				  see shiputil.pas for info}
   rStr     : array[1..11] of longint; {race strength}
   rBFP     : array[1..11] of longint; {race border firepower}
   rMFI     : array[1..11] of longint; {race minefield indicator}
   aggressive: boolean; {aggressively attack worlds! weak Defences!}

implementation

   function nearestOccupiedWorld(x,y : integer; ours:boolean):word;
   var
      i,d,sd : word;
   begin
      nearestOccupiedWorld:=0;
      sd:=9000;
      for i:=1 to 500 do
	 if ( ((chart[i].owner=3) or (chart[i].owner>10) and not(ours))
	     or (ours and (chart[i].owner=1)) )then
	 begin
	    d := trunc(distance(x,y,chart[i].x,chart[i].y));
	    if (d<sd) then
	    begin
	       nearestOccupiedWorld := i;
	       sd:=d;
	    end;
	 end;
   end; { nearestOccupiedWorld }

   function intendWar(r : integer):boolean;
   var i : integer;
   begin
      intendwar:=false;
      if r>11 then exit;
      if r<1 then exit;
      if attitude[r]>650 then intendwar:=true;
      if rBFP[r] < 50 then intendwar:=true;
   end;     

   function isEnemy(r : integer):boolean;
   begin
      isEnemy:=false;
      if r>11 then exit;
      if r<1 then exit;
      if dipstate[r]=3 then isEnemy:=true;
      if dipstate[r]=0 then isEnemy:=true;
   end;

   function CheckWord(a,b : word):boolean;
   begin
      checkWord:=false;
      if ( (a and b) >0) then checkWord:=true;
   end;

   function isWarship(taskword : word):boolean;
   begin
      isWarship:=false;
      if checkword(taskword,$01) then isWarship:=true;
      if checkword(taskword,$02) then isWarship:=true;
      if checkword(taskword,$04) then isWarship:=true;
      if checkword(taskword,$08) then isWarship:=true;
      if checkword(taskword,$80) then isWarship:=false;
      if checkword(taskword,$200) then isWarship:=false;
      if checkword(taskword,$400) then isWarship:=false;
   end;

   function isReady(taskWord : word):boolean;
   begin
      isReady:=true;
      if taskword=$1000 then isReady:=false;
      if taskword=$2000 then isReady:=false;
      if taskword=$4004 then isReady:=false;
      if taskword=$4002 then isReady:=false;
   end;

   procedure resetDip;
   var i : word;
   begin
      for i:=1 to 11 do
      begin
	 attitude[i]:=500;
	 dipstate[i]:=0;
	 offer[i]:=0;
	 accept[i]:=0;
	 send[i]:=0;
	 attacked[i]:=false;
	 rStr[i]:=0;
      end;
   end; { resetDip }

   function raceStrength(r,dfp :integer) :longint;
   {returns the relative strength of a race}
   var
      fp,avg : longint;
      wc     : integer;
      i,c    : word;
      t	     : targetptr;
   begin
      {work out the average firepower from the targets}
      fp:= warshipFP(r);
      wc:= warshipCount(r);
      {$ifdef d_diplo}
      writeln('player ',r);
      writeln('numbers (P ',getscore(r,1),',S ',getscore(r,2),',F ',
	      getscore(r,3),',B ',getscore(r,4),')');
      writeln('FirePower: ',fp,' Target Count ',wc);
      {$endif}
      if wc>0 then avg:=fp div wc;
      if wc=0 then avg:=dfp;
      {ok we have the average firepower... work out the relative strength}
      fp := fp + (avg * (getScore(r,2)-wc)) + (50* getScore(r,4)) + getScore(r,1);
      {$ifdef d_diplo}
      writeln('Relative Power: ',fp);
      {$endif}
      raceStrength:=fp;
   end;

   procedure checkContact;
   var
      r	     : integer; {current race}
      t,tc   : integer; {current target, and target count}
      p,d,sd : integer; {current planet, distance and shortest distance}
      i,c    : integer; {temp variables}
      con    : boolean; {is there contact}
      targ   : targetptr;
      plan   : planetptr;
   begin
      for r:=1 to 11 do
      begin
	 con:=false;
	 {check to see if there are any targets}
	 for t:= 1 to targetCount do
	 begin
	    targ := getTarget(t);
	    if targ^.owner=r then con:=true;
	 end;
	 { check minimum distance to enemy worlds }
	 sd:=10000;
	 for i:= 1 to planetCount do
	 begin
	    plan:= getPlanet(i);
	    p:= plan^.id;
	    for c:= 1 to 500 do
	       if (chart[c].owner-10) = r then
	       begin
		  d := trunc( distance(chart[p].x,chart[p].y,chart[c].x,chart[c].y) );
		  if d<sd then sd:=d;
	       end;
	 end;
	 if sd<300 then con:=true;
	 if (not(con) and (dipstate[r]>0)) then
	 begin
	    {$ifdef d_diplo}
	    writeln('lost contact with player ',r,' planets are ',sd,' away');
	    {$endif}
	    dipstate[r]:=0;
	    attitude[r]:=500;
	    offer[r]:=0;
	    accept[r]:=0;
	 end;
	 {$ifdef d_diplo}
	 if con then writeln('player ',r,' in contact ',sd,' away');
	 {$endif}
      end;  
   end; { checkContact }

  procedure checkOffers(wr : real);
  var
     i	 : integer;
      wc : integer;
  begin
     wc:=0;
     for i:=1 to 11 do
	if dipstate[i]=3 then inc(wc);
     for i:= 1 to 11 do
     begin
	if ((accept[i] = 1) and (dipstate[i]=3) and
	    ( (wr<50) or (wc>1) or (attitude[i]<500) )) then
	begin {cease fire acceptance}
	   send[i]:=4;
	   dipstate[i]:=1;
	   accept[i]:=0;
	   offer[i]:=0;
	   attitude[i]:=300;
	end;
	if ( (accept[i]=2) and not(dipstate[i]=2) and
	    ((attitude[i]<250) or (wc>1)) ) then
	begin {peace Acceptance}
	   dec(wc);
	   send[i]:=5;
	   dipstate[i]:=2;
	   accept[i]:=0;
	   offer[i]:=0;
	   attitude[i]:=0;
	end;
	if ((attitude[i] < 25) and (accept[i]>10) and (accept[i]<22) and (dipstate[i]=2)) then
	begin
	   if ((dipstate[accept[i]-10] = 1) or (dipstate[accept[i]-10] = 2)) then
	   begin {assistance requested}
	      inc(wc);
	      dipstate[accept[i]-10] := 3;
	      attitude[accept[i]-10] := 700;
	      send[accept[i]-10] := 1;
	      accept[accept[i]-10] :=0;
	      offer[accept[i]-10] :=0;
	      offer[i]:=0;
	   end;
	   accept[i]:=0;
	end;
	if ( ((attitude[i] > 100) or not(dipstate[i]=2) ) and (accept[i]>10) and (accept[i]<22)) then
	   accept[i]:=0; {assistance request rejected}
	{check for wierd states}
	if ((accept[i]=2) and (offer[i]=2)) then
	begin
	   if dipstate[i] = 3 then dec(wc);
	   accept[i]:=0;
	   offer[i]:=0;
	   send[i]:=5;
	   dipstate[i]:=2;
	end;
	if ((accept[i]=1) and (offer[i]=1)) then
	begin
	   if dipstate[i] = 3 then dec(wc);
	   accept[i]:=0;
	   offer[i]:=0;
	   send[i]:=4;
	   dipstate[i]:=1;
	end;
	{stuff that is no longer relevant can be cancelled}
	if (dipstate[i] = accept[i]) then
	begin
	   if accept[i]=1 then send[i]:=4;
	   if accept[i]=2 then send[i]:=5;
	   accept[i]:=0;
	end;
     end;
  end; { checkOffers }

   procedure makeOffers(wc :integer) ;
   var
      i	: word;
   begin
      for i:= 1 to 11 do
      begin
	 if (attitude[i]<300) then
	 begin {someone we really like! (or don't want to hurt us)}
	    if (not(dipstate[i]=2) and not(offer[i]=2)) then
	    begin
	       send[i]:=3;
	       offer[i]:=2;
	    end;
	 end;
         if ((attitude[i]>750) and (dipstate[i]=1)) then
         begin
              dipstate[i]:=3;
              offer[i]:=0;
              accept[i]:=0;
         end;
	 if ((attitude[i]>650) and not(dipstate[i]=3) and (wc=0) and (rBFP[i]>30)) then
	 begin {someone we want to go to war with (only if we are not at war or we really hate them! }
	    if dipstate[i]=2 then
	       send[i]:=1;
	    dipstate[i]:=3;
	    offer[i]:=0;
	    accept[i]:=0;
	 end;
	 {stuff that is no longer relevant can be cancelled}
	 if (dipstate[i] = offer[i]) then
	    offer[i]:=0;
      end;
   end;

   procedure askCeaseFire;
   var
      i : integer;
   begin
      for i:= 1 to 11 do
      begin
	 if ((dipstate[i]=3) and (accept[i]=1)) then
	    begin
	       send[i]:=4;
	       offer[i]:=0;
	       accept[i]:=0;
	       dipstate[i]:=1;
	       attitude[i]:=0;
	    end;
	 if ((dipstate[i]=3) and (accept[i]=2)) then
	    begin
	       send[i]:=5;
	       offer[i]:=0;
	       accept[i]:=0;
	       dipstate[i]:=2;
	       attitude[i]:=0;
	    end;
	 if ((dipstate[i]=3) and not(offer[i]=1)) then
	    begin
	       send[i]:=2;
	       offer[i]:=1;
	       accept[i]:=0;
	    end;
      end;
   end;

   procedure askAssistance(enemy : word);
   var i : word;
   begin
      for i:= 1 to 11 do
	 if ((dipstate[i]=2) and (offer[i]=0) and (send[i]=0)) then
	 begin
	    send[i]:=10+enemy;
	    offer[i]:=3;
	 end;
   end;

   procedure setLimits(state : word);
   {state 0 normal 1 defensive 2 aggressive
   3 slight defensive 4 slight aggression}
   begin
      {first set the default so we know what it is}
      sLimits[1]:=9; {mine layers}
      slimits[0]:=0;
      slimits[5]:= enemyMineFieldCount div 3;
      slimits[6]:=0;
      {players that can transport troops effectively}
      if ((player>1) and (player<6)) then
	 sLimits[0]:=2; {transports}
      if player=2 then sLimits[0]:=14; {lizards allowed more!}
      sLimits[3] := shipCount div 10; {defensive ship limit 10% of fleet}
      if state=1 then
      begin {basic rules for defensive stance}
	 sLimits[1]:=19; {more mine layers!}
	 sLimits[0]:=0; { no transports}
	 if player=2 then sLimits[0]:=3; {unless lizard}
	 sLimits[3] := shipCount div 3; {up to a third of the fleet will defend}
      end;
      if state=3 then
      begin {slight defence stance}
          sLimits[1]:=12; {slightly more minelayers}
          slimits[3] := shipCount div 5; {up to a fifth will defend}
      end;
      if state=4 then
      begin
          sLimits[1]:=7; {some minelayers}
          sLimits[3]:= shipCount div 15;
      end;
      if state=2 then
      begin {basic rules for aggressive stance}
	 sLimits[1]:=5; {less mine layers!}
	 sLimits[0]:=4; { more transports}
	 if player=2 then sLimits[0]:=20; {unless lizard}
	 sLimits[3] := shipCount div 20; {5% of fleet will defend}
      end;
   end;

   procedure scoreEffect(st :longint);
   var
      i	  : integer; {misc}
      att : longint;
   begin
      att:=0;
      for i:= 1 to 11 do
      begin
	 if dipstate[i]>0 then
	 begin
	    if (getScore(player,2)> getScore(i,2)) then attitude[i]:=attitude[i]+10;
	    if (getScore(player,1)> getScore(i,1)) then attitude[i]:=attitude[i]+5;
	    if (getScore(player,4)> getScore(i,4)) then attitude[i]:=attitude[i]+5;
	    if (getScore(player,2)< getScore(i,2)) then attitude[i]:=attitude[i]-10;
	    if (getScore(player,1)< getScore(i,1)) then attitude[i]:=attitude[i]-5;
	    if (getScore(player,4)< getScore(i,4)) then attitude[i]:=attitude[i]-5;
	    if (st+100 < rstr[i]) then attitude[i]:=attitude[i]-10;
	    if (st-100 > rStr[i]) then attitude[i]:=attitude[i]+10;
	    if attitude[i]>1000 then attitude[i]:=1000;
	    if attitude[i]<0 then attitude[i]:=0;
	    if dipstate[i]=3 then att:=att+rBFP[i];
	    if dipstate[i] = 3 then
	       if st< rStr[i] - ((st div 10) * 3) then askAssistance(i);
	 end;
         {trying new method of deciding stance
	 if st>att+(st div 5) then setLimits(2);
	 if st<att-(st div 5) then setLimits(1);}
         if att>200 then setLimits(4);
         if att>400 then setLimits(2);
         if att<-200 then setLimits(3);
         if att<-400 then setLimits(1);
      end;
   end; { scoreEffect }

   procedure territoryCheck(am :integer) ;
   var i   : integer;
      ch   : integer;
      e	   : integer;
      rad  : integer;
      dist : integer;
      t	   : targetptr;
   begin
      { we are going to check each cluster, see if we are in it,
       and whether any enemies are present!}
      for i:= 1 to nclusters do
      begin
	 if ((clusters[i].Ecount>0) and (clusters[i].owned>0)) then
	 begin
	    { enemies attract aggressiveness based on the size of the cluster
	     they are in}
	    ch:=am div 4;
	    e:= clusters[i].bigEnemy;
	    if (clusters[i].size>10) then ch:=am div 2;
	    if (clusters[i].size>20) then ch:=(am div 4) * 3;
	    if (clusters[i].size>30) then ch:=am;
	    attitude[e]:= attitude[e] + ch;
	    if attitude[e]>1000 then attitude[e]:=1000
	 end;
      end;
      {check all our planets to  see if they are in a minefield}
      for i:= 1 to 500 do
	 if chart[i].owner=1 then
	 begin
	    ch := inMines(chart[i].x,chart[i].y);
	    if ch<101 then
	    begin
	       ch := nearestOccupiedWorld(mines[ch].x,mines[ch].y,false);
	       if ch>0 then
	       begin
		  if ((chart[ch].owner>10) and (chart[ch].owner<22)) then
		  begin
		     ch:=chart[ch].owner - 10;
		     attitude[ch]:=attitude[ch]+5;
		  end;
	       end;
	    end;
	 end;
      {check all enemy targets to see if there are any inside our territory}
      for i:= 1 to targetCount do
      begin
	 t:=getTarget(i);
	 ch:= nearestOccupiedWorld(t^.x,t^.y,true);
	 if ch>0 then
	 begin
	    e:= nearestOccupiedWorld(chart[ch].x,chart[ch].y,false);
	    dist:= trunc(distance(t^.x,t^.y,chart[ch].x,chart[ch].y ));
	    rad := 36*3;
	    if e>0 then
	       rad:= min(rad , trunc(distance(chart[ch].x,chart[ch].y,chart[e].x,chart[e].y)) div 2);
	    if dist<rad then
	       if ((t^.owner>0) and (t^.owner<12) and not(isEnemy(t^.owner))) then
		  attitude[t^.owner] := attitude[t^.owner] + getFirepower(t^.hull) + 1;
	 end;
      end;
   end; { territoryCheck }

   procedure territoryAttack;
   var
      i	    : integer;
      be,bs : integer;
   begin
      bs:=0;
      be:=0;
      for i:= 1 to nclusters do
	 if ((clusters[i].Ecount > bs) and (clusters[i].bigEnemy>0)) then
	 begin
	    bs:= clusters[i].Ecount;
	    be:= clusters[i].bigEnemy;
	 end;
      if be>0 then attitude[be]:=attitude[be]+100;
   end;

   procedure largeEnemyCheck(st : longint);
   var i : integer;
      le : integer;
   begin
      le:=0;
      for i:= 1 to 11 do
      begin
	 if ((le=0) and ((dipstate[i]=3) or (attitude[i]>650))) then le:=i;
	 if le>0 then
	    if ((rStr[i]>rStr[le]) and ((dipstate[i]=3) or (attitude[i]>650))) then le:=i;
      end;
      if le>0 then
	 if rStr[le]>st then
	 begin
	    {$ifdef d_diplo}
	    writeln('Large Enemy ',le,' found');
	    {$endif}
	    for i:= 1 to 11 do
	       if ((dipstate[i]>0) and not(i=le)) then attitude[i]:=attitude[i]-100;
	 end;
   end;

   { check the balance of a race border!}
   procedure borderBalance(r:integer; var fpb,mfb:longint);
   var
      i,z,c:integer;
      brd:array[1..100] of integer;
      bc:integer;
      fp:longint;
      t:targetptr;
      s:starshipptr;
   begin
        {$ifdef d_diplo}
        writeln(' Border check for race ',r);
        {$endif}
        bc:=0;
        {work out which worlds are border worlds}
        for i:= 1 to 500 do
        if chart[i].owner-10=r then
        begin
             {check to see if we have already marked this as a border}
             {convert to closest owned world}
                      c:= nearestOccupiedWorld(chart[i].x,chart[i].y,true);
                      z:=1;
                      while z<bc+1 do
                      begin
                           if brd[z] = c then z:=200;
                           z:=z+1;
                      end;
                      if z=bc+1 then
                      begin
                           {we didn't find this border world!}
                           inc(bc);
                           brd[bc]:=c;
                      end;
        end;
        {ok we know the borders! we need to count up the firepower available
          to both sides}
        fp:=0;
        for i:= 1 to dbcount do
          if dbtarg[i]^.owner = r then
            for c:= 1 to bc do
            begin
                 t:=dbtarg[i];
                 z:= trunc(distance(chart[brd[c]].x,chart[brd[c]].y,t^.x,t^.y));
                 if z<200 then
                 begin
                      fp := fp + getFirePower(t^.hull);
                      break;
                 end;
            end;
        {$ifdef d_diplo}
        writeln(' Enemy border Firepower ',fp,' over ',bc,' border worlds');
        {$endif}
        fp:=fp*-1; {make the enemy firepower a negative number}
        {count up the firepower of friendly ships}
        for i:= 1 to shipCount do
        begin
             s:=getShip(i);
             for c:= 1 to bc do
             begin
                 z:= trunc(distance(chart[brd[c]].x,chart[brd[c]].y,s^.x,s^.y));
                 if z<200 then
                 begin
                      fp := fp + getFirePower(s^.hull);
                      break;
                 end;
             end;
        end;
        {$ifdef d_diplo}
        writeln(' Firepower Balance ',fp);
        {$endif}
        fpb:=fp;
        {work out whether the enemy is well defended in minefields}
        {for each border world we will check to see which enemy worlds
         have a minefield over them}
        mfb:=0;
        for c:= 1 to 500 do
        begin
             z:=0;
             fp:=500;
             for i:= 1 to bc do
             begin
                 z:= trunc(distance(chart[c].x,chart[c].y,chart[brd[i]].x,chart[brd[i]].y));
                 if z<fp then fp:=z;
             end;
             if fp<300 then
             begin
                 if inMines(chart[c].x,chart[c].y)<101 then mfb := mfb+1;
             end;
        end;
        {$ifdef d_diplo}
        writeln(' Enemy worlds under mines ',mfb);
        {$endif}
   end;

   procedure doDiplomacy;
   var
      warcount : real; {count of warships}
      warready : real; {count of ready warships}
      i,ch     : integer; {misc integers}
      ship     : starshipptr;
      target   : targetptr;
      state    : stateptr;
      fp       : integer; {firepower}
      st       : longint; {relative strength}
   begin
      {count the number of warships and the number that are ready}
      Writeln('Processing Diplomacy...');
      setLimits(0);
      warcount:=0;
      warready:=0;
      fp:=0;
      for i:= 1 to shipcount do
      begin
	 ship := getShip(i);
	 state := getState(ship^.id);
	 if isWarship(state^.task) then
	 begin
	    fp:=fp + getFirePower(ship^.hull);
	    warCount:=warCount+1;
	    if isReady(state^.ctask) then warready:=warready+1;
	 end;
      end;
      checkContact;
      {$ifdef d_diplo}
      writeln('Firepower:',fp);
      if warcount>0 then fp:=fp div trunc(warcount); {make it the average!}
      if shipcount>0 then writeln('Average firepower:',fp);
      writeln('Warships Ready:',round(warready));
      {work out our relative strength for debug purposes}
      st := raceStrength(player,fp);
      writeln('Our Relative Strength ',st);
      {$else}
      if warcount>0 then fp:=fp div trunc(warcount); {make it the average!}
      st := raceStrength(player,fp);
      {$endif}
      for i:= 1 to 11 do
      begin
	 rStr[i]:=0;
	 if dipstate[i]>0 then rStr[i]:=raceStrength(i,fp);
      end;
      if warcount>0 then warready := (warready/warcount);
      warready:=warready*100;
      writeln('Percentage Ready:',round(warready));

      {work out who we have contact with and check who has attacked us}
      for i:= 1 to targetCount do
      begin
	 target:=getTarget(i);
	 if dipstate[target^.owner]=0 then dipstate[target^.owner]:=3;
      end;
      {check for attacks and apply cease fire attitude adjustment}
      {also check borders!}
      for i:=1 to 11 do
	 begin
	    if ((attacked[i]) and not(dipstate[i]=3)) then
	    begin
	       attitude[i]:=1500;
	       dipstate[i]:=3;
	    end;
	    if dipstate[i]=1 then attitude[i]:=attitude[i]+10;
            rBFP[i]:=0;
            rMFI[i]:=0;
            if dipstate[i]>0 then borderBalance(i,rBFP[i],rMFI[i]);
            attitude[i] := attitude[i] + (rBFP[i] div 10);
	 end;

      {find out if we are at war and with how many races}
      ch:=0;
      for i:= 1 to 11 do
	 if dipstate[i]=3 then inc(ch);

      {territory effect on attitude}
      writeln('Checking Teritory...');
      checkClusters;
      if ch=0 then
	 TerritoryCheck(40)
      else
	 TerritoryCheck(10);
      {if we are war ready and not at war, attack someone with the right territory}
      if ((ch=0) and (warready>85)) then territoryattack;

      {check if there are any larger enemies we are at war with}
      largeEnemyCheck(st);

      {scores effect on attitude}
      scoreEffect(st);

      {check for offers and accept or reject based on attitude!}
      checkOffers(warready);

      {work out if we are aggressive or not}
      {if warready<40 then setLimits(1);}

      if ch=0 then
      begin
	 setLimits(1); {defensive stance! no need to attack!}
      end;
      if ch>1 then
      begin {we NEED to find someone to make peace with}

	 {new code here! }

      end;
      if (warready<35) then {we need a break so ask for a cease fire!}
      begin
	 askCeaseFire;
      end;
      makeOffers(ch);
   end;

end.