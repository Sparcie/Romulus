{common functions for bobsfury A Danson 2004}
unit bsystem;

interface

function checkfile(filename:string):boolean;
procedure copymem(source,dest:pointer;size:word);

implementation
uses dos;

function checkfile(filename:string):boolean;
var s:pathstr;
begin
     checkfile:=true;
     s:=fsearch(filename,'');
     if s='' then
        begin
         checkfile:=false;
        end;
end;

procedure copymem16(srcseg,srcofs,desseg,desofs,size:word);
var c,of1,of2:word;
begin
 c:=0;
 while c< size do
 begin
    of1:=c+ srcofs;
    of2:=c+ desofs;
    asm
     push es
     push di
     mov ax,srcseg
     mov es,ax
     mov di,of1
     mov bx,[es:di]
     mov ax,desseg
     mov es,ax
     mov di,of2
     mov [es:di],bx
     pop di
     pop es
    end;
   c:=c+2;
 end;
end;

procedure copymem(source,dest:pointer;size:word);
var c,of1,of2,srcseg,srcofs,desseg,desofs:word;
begin
 srcseg:= seg(source^);
 srcofs:= ofs(source^);
 desseg:= seg(dest^);
 desofs:= ofs(dest^);
 if (size mod 2) = 0 then
  begin
   copymem16(srcseg,srcofs,desseg,desofs,size);
   exit;
  end;
 for c:=0 to (size-1) do
  begin
    of1:=c+ srcofs;
    of2:=c+ desofs;
    asm
     push es
     push di
     mov ax,srcseg
     mov es,ax
     mov di,of1
     mov bh,[es:di]
     mov ax,desseg
     mov es,ax
     mov di,of2
     mov [es:di],bh
     pop di
     pop es
    end;
  end;
end;

end.