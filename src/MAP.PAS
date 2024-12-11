{ reads the XYplan data from xyplan.dat}

unit map;
interface

type
   pos	     = record
		  x,y,owner : integer;
	       end;	    
   cluster   = record
		  planets  : array[1..40] of integer;
		  size	   : integer;
		  owned	   : integer;
		  bigEnemy : integer;
		  Ecount   : integer;
	       end;	   
   scoutInfo =  record
		   id	    : integer; {id}
		   beams    : integer; {beam count}
		   bays	    : integer; {fighter bays}
		   fighters : integer; {fightercount}
		   turn	    : integer; {turn it was discovered}
		end;
   {scout information should only last for 10 turns before it is discarded}
		   

var
   chart     : array[1..500] of pos;
   clusters  : array[1..40] of cluster;
   nclusters : integer;
   scouted   : array[1..50] of scoutInfo;
   nscouted  : integer;

procedure resetMap;
procedure checkClusters;

procedure addScouted(s : scoutInfo);
function isScouted(id : integer):integer;
procedure planetCaptured(id : integer);

implementation

uses vector;

var xyplan : file;
   i,b	   : word;

procedure resetMap;
begin
   for i:=1 to 500 do
      chart[i].owner:=0;
   nscouted :=0;
end; { resetMap }

procedure addScouted(s : scoutInfo);
var i : integer;
begin
   for i := 1 to nscouted do
   begin
      if scouted[i].id = s.id then
      begin {update the old record and exit}
	 scouted[i]:=s;
	 exit;
      end;
   end;
   if nscouted=50 then exit;
   inc(nscouted);
   scouted[nscouted] := s;
end; { addScouted }

function isScouted(id : integer):integer;
var i  : integer;
   res : integer;
begin
   res:=0;
   for i:= 1 to nscouted do
   begin
      if scouted[i].id =id then res:=i;
   end;
   isScouted:=res;
end; { isScouted }

procedure planetCaptured(id : integer);
var i : integer;
begin
   for i := 1 to nscouted do
   begin
      if scouted[i].id = id then
      begin
	 scouted[i] := scouted[nscouted];
	 dec(nscouted);
      end;
   end;
end; { planetCaptured }

procedure checkClusters;
var
   i,c,z   : integer;
   Ec	   : integer;
   ben,bec : integer;
begin
   for i:= 1 to nclusters do
   begin
      {count the number of enemy worlds.}
      ben:=0;
      bec:=0;
      for c:= 1 to 11 do
      begin
	 Ec:=0;
	 for z:= 1 to clusters[i].size do
	    if chart[clusters[i].planets[z]].owner = c+10 then
	       ec:=ec+1;
	 if ec>bec then
	 begin
	    bec:=ec;
	    ben:=c;
	 end;
      end;
      clusters[i].bigEnemy:=ben;
      clusters[i].ecount:=bec;
      clusters[i].owned:=0;
      for z:= 1 to clusters[i].size do
	    if chart[clusters[i].planets[z]].owner = 1 then
	       inc(clusters[i].owned);
      {$ifdef d_map}
      if ((bec>0) or (clusters[i].owned>0)) then
      begin
	 writeln('  Cluster:',i);
	 write('  Planets:');
	 for z:= 1 to clusters[i].size do write(clusters[i].planets[z],' ');
	 writeln;
	 writeln(' Owned:',clusters[i].owned);
	 writeln(' Enemy:',ben,' count:',bec);
      end;	 
      {$endif}
   end;
end;

procedure findClusters;
var
   i,c,z,cc,cp : integer;
   found       : boolean;
begin
   writeln('Charting Clusters');
   resetMap;
   nclusters:=0;
   for i:= 1 to 500 do
   begin {for every planet...}
      if ((chart[i].owner = 0) and (nclusters<40)) then
      begin {ok we're not listed as in a cluster}
	 found:=true;
	 inc(nclusters);
	 cc:=nclusters;
	 clusters[cc].size :=1;
	 clusters[cc].planets[1]:=i;
	 chart[i].owner:=cc;
	 c:=1;
	 cp:= clusters[cc].planets[c];
	 while found do
	 begin
	    found:=false;
	    for z:= 1 to 500 do
	       if clusters[cc].size<40 then
		  if distance(chart[cp].x,chart[cp].y,chart[z].x,chart[z].y) < 82 then	
		     if chart[z].owner = 0 then		
		     begin
			found:=true;
			inc(clusters[cc].size);
			clusters[cc].planets[clusters[cc].size] := z;
			chart[z].owner:=cc;
		     end;
	    if c<clusters[cc].size then
	    begin
	       inc(c);
	       found:=true;
	    end;
	    cp:= clusters[cc].planets[c];
	 end;
	 if clusters[cc].size >3 then write('.');
	 if clusters[cc].size <4 then dec(nclusters);
      end;
   end;

   writeln;
   {$ifdef d_map}
   writeln;
   writeln(' Cluster Count: ',nclusters);
   cc:=0;
   cp:=0;
   for i:= 1 to nclusters do
   begin
      cc:=cc + clusters[i].size;
      if clusters[i].size > cp then cp:= clusters[i].size;
   end;
   writeln(' Planets in clusters: ',cc);
   writeln(' Largest cluster: ',cp);
   {$endif}
   resetMap;
end;

begin
   writeln('Reading map');
   assign(xyplan,'xyplan.dat');
   reset(xyplan,1);
   for i:=1 to 500 do
   begin
      blockread(xyplan,chart[i],sizeof(pos),b);
      if not(b = sizeof(pos)) then
      begin
	 writeln('Could not read map');
	 halt(1);
      end;
   end;
   close(xyplan);
   findClusters;
end.