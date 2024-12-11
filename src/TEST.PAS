uses vector;

var
   x,y,dx,dy:real;
   brg,d:real;
   tx,ty:integer;

begin

     for tx:= -10000 to 10000 do
     for ty:= -10000 to 10000 do
     begin
     x:=0;
     y:=0;
     dx:=tx;
     dy:=ty;
     brg:=calcbearing(x,y,dx,dy);
     d:=distance(x,y,dx,dy);
     calcvector(brg,d,dx,dy);
     if (not(tx=round(dx)) or not(ty=round(dy))) then
     begin
     write('i');
     writeln(tx);
     writeln(ty);
     write('r');
     writeln(round(dx));
     writeln(round(dy));
     end
     end;
end.