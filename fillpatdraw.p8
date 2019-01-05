pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()

cartdata('fillpatgen_01')
current_file=char2str(dgetchar())
if current_file then
//loadpng(current_file)
else
current_file='fillpat_data'
end

isdebug=false

memstart=0x0000
memend=0x1fff
memrowlen=0x0040

viewsprite=true
panhold=0
writing=0
corout=nil
pagesel=1
viewmove=0
history={pages={},current=0,records={}}

view=mkrectq('0 0 32 32')
view.stx=0
view.sty=0
subview=mkrectq('0 0 128 48')
spritearea=mkrectq('0 0 128 128')
spritearea_w=mkrectq('1 1 128 128')
canvas=mkrectq('8 8 64 64')
canvas.pix=tablefill(0,32,32)
canvas.upd=true
palette=mkrectq('80 8 40 40')
palette.upd=true
palsel=mkrectq('79 7 11 11')
playbtn=mkrectq('70 36 20 9')
playbtn.cnt=0
playbtn.stp=1
playbtn.wait=4
savebtn=mkrectq('70 48 20 9')
loadbtn=mkrectq('70 60 20 9')
cleabtn=mkrectq('70 72 24 9')
exptbtn=mkrectq('50 72 28 9')
menuwin=mkrectq('24 32 80 64')


cprect=nil

mousestate={l=0,r=0,m=0,stx=0,sty=0}
keystate=''
premouse=getmouse()
mouse=getmouse()
currentcel={x=-1,y=-1,fls=0}

corout=nil
cocallback=nil
--spritestore

selectrect=mkrectq('0 0 1 1')
selectrect.fls=0
selectrect.enable=false
piecesrect=mkrectq('0 0 1 1')
piecesrect.enable=false
piecesrect.fls=0
confirm=false
menuwin.enable=false
//stop()
//setcol(7)

end
function _update60()
poke(0x5f2d,1)
premouse.x=mouse.x
premouse.y=mouse.y
mouse=getmouse()
updatekey()
presskey=getkey()

if playbtn.cnt>0 then
 if mouse.lt then playbtn.cnt+=playbtn.wait playbtn.stp=0 end
 if mouse.rt then playbtn.cnt-=playbtn.wait playbtn.stp=0 end
 if presskey==' ' then playbtn.stp=playbtn.stp==0 and 1 or 0 end
end

local spos=getsprpos(mouse.x,mouse.y)
local srect=selectrect
local prect=piecesrect
if confirm then
 if mouse.lt then
  if exptbtn.contp(mouse.x-2,mouse.y-2) then
  entryname(function(name,txt)
  cocallback={
  func=function(prm) exporttxt(prm.name,prm.txt)
  end
  ,prm={name=name,txt=txt}
  }
  end	
  ,'exportto:')
  confirm=false
  elseif not menuwin.contp(mouse.x,mouse.y) then
  confirm=false
  end
 end
elseif menuwin.enable then
 if mouse.lt then 
  if playbtn.contp(mouse.x,mouse.y) then
  playbtn.cnt=1
  mouse.lt=false
  elseif savebtn.contp(mouse.x,mouse.y) then
  entryname(function(name,txt) savepng(name,txt) menuwin.enable=false end,'saveto:')
  elseif loadbtn.contp(mouse.x,mouse.y) then
  entryname(function(name,txt) loadpng(name,txt) menuwin.enable=false end,'loadto:')
  elseif cleabtn.contp(mouse.x,mouse.y) then
  entryname(function(name,txt) clearsprite(name,txt) menuwin.enable=false end,'type yes then clear:','')
  elseif not menuwin.contp(mouse.x,mouse.y) then
  menuwin.enable=false
  end
 end
else
selectrecttool()

end

if presskey=="\t" then
menuwin.enable=not menuwin.enable
end

end

function _draw()

-- play fillpat draw --
if playbtn.cnt>0 then
 cls()
 local f=fillpat.draw(flr(playbtn.cnt/playbtn.wait)+1,0,0)
 if f then playbtn.cnt=1 fillpat.draw(flr(playbtn.cnt/playbtn.wait)+1,0,0)
 else playbtn.cnt+=playbtn.stp
 end
 print(flr(playbtn.cnt/playbtn.wait)+1,0,122)
 print('😐'..stat(1),90,122)
 
 return
end

-- sprite sheet only mode --
if viewsprite then
cls()

palt(0,false)
spr(0,0,0,16,16)
palt()

local x
local y

ccel=currentcel
x=ccel.x*8
y=ccel.y*8
if ccel.fls>16 then
rectfill(x+2,y+2,x+5,y+5,13)
ccel.fls-=1
elseif ccel.fls>0 then
rect(x,y,x+7,y+7,({1,1,5,5,13,13,7,7})[flr(ccel.fls/2)])
ccel.fls-=1

end

local srect=selectrect
if srect.enable then
local ex=srect.w>=0 and (srect.ex+8)-1 or (srect.ex)+1
local ey=srect.h>=0 and (srect.ey+8)-1 or (srect.ey)+1
x=srect.w>=0 and srect.x or (srect.x+8)-2
y=srect.h>=0 and srect.y or (srect.y+8)-2
rect(x,y,ex,ey,7)
rect(x+1,y+1,ex-1,ey-1,7)
end
local prect=piecesrect
if prect.enable then
local frect=mkrect(srect.x-1,srect.y-1,srect.w-2,srect.h-2)
for y=0,prect.h do
 local oy
 if y==0 then
 oy=0
 elseif y==prect.h then
 oy=2
 else
 oy=1
 end
 for x=0,prect.w do
 local ox
 if x==0 then
 ox=0
 elseif x==prect.w then
 ox=2
 else
 ox=1
 end
 rect((x+prect.x)*srect.w-ox,(y+prect.y)*srect.h-oy,(x+prect.x)*srect.w-ox+1,(y+prect.y)*srect.h-oy+1,7)
 local anm=flr((prect.fls/4)%(prect.w*prect.h))
 local anm-=x+(y*prect.w)
 if anm<4 and anm>=0 and x<prect.w and y<prect.h then
 frect.x=(prect.x+x)*srect.w+1
 frect.y=(prect.y+y)*srect.h+1
 frect.draw(({15,14,8,2})[(anm%4)+1])
 end
end

end


local ex=prect.w>=0 and (prect.ex+1)-1 or (srect.ex)+1
local ey=prect.h>=0 and (prect.ey+1)-1 or (srect.ey)+1
x=prect.w>=0 and prect.x or (prect.x+1)-2
y=prect.h>=0 and prect.y or (prect.y+1)-2
rect(x*srect.w,y*srect.h,srect.w*ex-1,srect.h*ey-1,8)


end

if menuwin.enable then
fillp(0xa5a5)
menuwin.draw(2,true)
fillp()
menuwin.draw(2,false)
print('⌂menu ',menuwin.x+4,menuwin.y+4,7)
rectfill(playbtn.x,playbtn.y,playbtn.ex,playbtn.ey,2)
rectfill(playbtn.x,playbtn.y,playbtn.ex-1,playbtn.ey-1,14)
print('play',playbtn.x+2,playbtn.y+2,2)

rectfill(savebtn.x,savebtn.y,savebtn.ex,savebtn.ey,1)
rectfill(savebtn.x,savebtn.y,savebtn.ex-1,savebtn.ey-1,12)
print('save',savebtn.x+2,savebtn.y+2,1)

rectfill(loadbtn.x,loadbtn.y,loadbtn.ex,loadbtn.ey,3)
rectfill(loadbtn.x,loadbtn.y,loadbtn.ex-1,loadbtn.ey-1,11)
print('load',loadbtn.x+2,loadbtn.y+2,3)
print('close with tab key',menuwin.x+4,menuwin.ey-8,6)

rectfill(cleabtn.x,cleabtn.y,cleabtn.ex,cleabtn.ey,2)
rectfill(cleabtn.x,cleabtn.y,cleabtn.ex-1,cleabtn.ey-1,8)
print('celar',cleabtn.x+2,cleabtn.y+2,2)
print('close with tab key',menuwin.x+4,menuwin.ey-8,6)

//return
end

if confirm then

local srect=selectrect
fillp(0xa5a5)
menuwin.draw(1,true)
--rectfill(24,32,104,96,1)
fillp()
menuwin.draw(13,false)
--rect(24,32,104,96,13)
print('cell size:'..srect.w..'❎'..srect.h..'',30,35,7)
print('…patterns :'..(prect.w*prect.h)..'',30,45,7)
rectfill(exptbtn.x,exptbtn.y,exptbtn.ex,exptbtn.ey,4)
rectfill(exptbtn.x,exptbtn.y,exptbtn.ex-1,exptbtn.ey-1,9)
print('export',exptbtn.x+2,exptbtn.y+2,4)

end
if corout and costatus(corout)~='dead' then
 coresume(corout)
// return
else
 if cocallback~=nil then cocallback.func(cocallback.prm) end
 cocallback=nil
 corout=nil
end

x=mouse.x-2
y=mouse.y-2
pset(x,y,7)
pset(x+4,y,7)
pset(x,y+4,7)
pset(x+4,y+4,7)
if isdebug then
print((prect.w)*srect.w,00,90,7)
print(mouse.x..' '..mouse.y,0,0)
end

if maqueetext and costatus(maqueetext)~='dead' then
coresume(maqueetext)
else maqueetext=nil
end
return
end

end

-->8
--utils
caller={}
function vdmp(v,_x,_y)
local tstr=htbl([[
number=#;string=$;boolean=%;function=*;nil=!;
]])
tstr.table='{'
local p=0
if _x==nil then _x=0 _y=0 color(6) end
if _y==0 then cls() end
if type(v)~='table' then v={v} end
for i,str in pairs(v) do
	if type(str)=='table' then
	 if p>0 then _y+=1 end
 	print(i..tstr[type(str)],_x*4,_y*6)
		_y=vdmp(str,_x+1,_y+1)
  _y+=1
  print('}',_x*4,_y*6)
  _y+=1
  p=0
	else
 	str=tstr[type(str)]..':'..tostr(str)
 	print(str,(_x+p)*4,_y*6)
		p=p+#(str..'')+1
	end
end
cursor(0,(_y+1)*6)
if _x==0 then
 stop()
end
return _y
end

function camdsp(x,y)
x=x==nil and 0 or x
y=y==nil and 0 or y

return {x=(x-cam.x%128),y=(y-cam.y%128)}
end

function mkrectq(q)
q=split(q,' ')
for i,v in pairs(q) do
q[i]=tonum(v)
end
return mkrect(q[1],q[2],q[3],q[4])
end
function mkrect(x,y,w,h)
return rectf.new(x,y,w,h)
end
rectf={}
rectf.new=function(x,y,w,h)
	local o={x=x,y=y,w=w,h=h,ex=x+w,ey=y+h}
	o.contp=function(x,y)
	o.refresh()
 return (o.x<=x and o.y<=y and o.ex>x and o.ey>y)
	end
	o.hover=function(sr)
	o.refresh()
	sr.refresh()
 return (o.contp(sr.x,sr.y) or o.contp(sr.x,sr.ey-1) or o.contp(sr.ex-1,sr.y) or o.contp(sr.ex-1,sr.ey-1))
	end
	o.refresh=function()
	o.ex=o.x+o.w
	o.ey=o.y+o.h
	end
	o.draw=function(col,fill)
	o.refresh()
	if fill then rectfill(o.x,o.y,o.ex-1,o.ey-1,col)
	else rect(o.x,o.y,o.ex-1,o.ey-1,col) end
	end
	o.sc=function(col,fill)
	end
	o.circ=function(col,fill)
	o.refresh()
	local w=o.w
	local h=o.h
	local midx=w/2+o.x
	local midy=h/2+o.y
	local hol=w<=h
	local s=hol and h/2 or w/2
	for y=0,hol and 0 or w-h do
	for x=0,hol and h-w or 0 do
 	if fill then circfill(midx+x,midy+y,s,col)
 	else circ(midx+x,midy+y,s,col) end
	end
	end
	end
	return o
end

function cto(v)
return v*8
end
function toc(v)
return flr(v/8)
end

function join(s,d,dd)
local a=''
if dd~=nil then
 local ss={}
 for i,v in pairs(s) do add(ss,join(v,d)) end
 s=ss
 d=dd
end
for i,v in pairs(s) do
a=a..v..d
end
return sub(a,1,#a-#d)
end

function split(str,d,dd)
local a={}
local c=0
local s=''
local tk=''
if dd~=nil then str=split(str,dd) end
//for i=0,#str-1 do

while #str>0 do
 if type(str)=='table' then
  s=str[1]
  add(a,split(s,d))
  del(str,s)
 else
  s=sub(str,1,1)
  str=sub(str,2)
  if s==d then 
   add(a,tk)
   tk=''
  else
   tk=tk..s
  end
 end
end
add(a,tk)
return a
end

function replace(s,f,r)
local a=''
local i=2
while #s>0 do
 local t=sub(s,1,#f)
 if t==f then a=a..r i=#f+1
 else a=a..sub(s,1,1) end
s=sub(s,i)
end
return a
end

function cat(f,s)
for k,v in pairs(s) do
 if tonum(k)==nil then
 f[k]=v
 else
 add(f,v)
 end
end
return f
end

function tonorm(str)
str=tonum(str)~=nil and tonum(str) or str
str=str=='nil' and nil or str
str=str=='true' and true or str
str=str=='false' and false or str
return str
end

function htbl(ht,ri)
caller.htbl=htbl
local t={}
local c=0
local res
local p
local k=''
ri=ri==nil and 0 or ri+1
ht=replace(ht,"\n",'')
while #ht>0 do
p=sub(ht,1,1)
ht=sub(ht,2)
 if p=='{' or p=='=' then
  res=htbl(ht,ri) --ht,current
  if res==nil then add(t,res.t)
  elseif p=='=' then
   t[k]=res.t[1]
  else
   if #k>0 then
    t[k]=res.t
   else
    add(t,res.t)
   end
  end
  ht=res.ht
  k=''
 elseif p=='(' then
 --exe func
  res=htbl(ht,ri)
  ht=res.ht
  if caller[k]==nil then print(k) end
  add(t,caller[k](#res.t==1 and res.t[1] or res.t))
  k=''
 elseif p=='}' or p==';' or p==')' then
  if #k>0 then
   add(t,tonorm(k))
  end
  k=''
  return {t=t,ht=ht}
 elseif p==' ' then
  if #k>0 then add(t,tonorm(k)) end
  k=''
 else
  k=k..p
 end
end
if #k>0 then
add(t,tonorm(k))
end
return t
end

function tablefill(v,n,r)
local t={}
if r~=nil and r>0 then
for r=1,n do 
//	add(t,tablefill(v,n))
	t[r]=tablefill(v,n)
end
else
for i=1,n do
//add(t,v)
t[i]=v
end
end

return t
end

function mkfillpp(colp,patp)
return {col=split(colp,' ',"\n"),pat=split(patp,' ',"\n")}
end

function idof(t,i)
local c=1
for k,v in pairs(roots) do
if(c==i)then tesv=v.id return v end
c+=1
end
return nil
end
tesv=0

function drev(d)
if d=='r' then return 'l'
elseif d=='l' then return 'r'
elseif d=='t' then return 'd'
elseif d=='b' then return 'b'
end
return nil
end
-->8
--canvas works



--start=1~
function getsprpix(x,y)
x-=1
y-=1
local p=peek(memstart+flr(x/2)+(y*memrowlen))
if band(x+1,1)==1 then p=band(p,0x0f)
else p=shr(band(p,0xf0),4)
end
return p
end

--start:1~
function psetsprram(x,y,v)
local lr=band(x,1)
x=flr((x-1)/2)
y=y-1
if x<0 or y<0 then return end
local p=peek(memstart+x+(y*memrowlen))
local msk=shl(0xf,lr*4)
p=bor(band(p,msk), shl(v,bxor(lr,1)*4))
poke(memstart+x+(y*memrowlen),p)
end

hexkey='0123456789abcdef'
-- *lower id override higher id --
function patterns(cx,cy,col)
local pat=getpatcel(cx,cy)
local cols={}
local pats=''
local row=''
local isset=false
pat.each(function(p,x,y)
--row=row..(p==col and '0' or '1')
--row=row..(p>=col and '0' or '1')
if p==col then
isset=true
p='0'
elseif isset and p>=col then
p='0'
else
p='1'
end
row=row..p

if x==4 then
 local hx=tonum('0b'..row)+1
 pats=pats..sub(hexkey,hx,hx)
 row=''
if y==4 then
 isset=false
end
end
end)

return pats
end

function uniquepat(tbl,ntbl)
local dp
local pre
if ntbl==nil then
 ntbl={}
end
 for y,row in pairs(tbl) do
	 for i,v in pairs(row) do
	  dp=false
	  for j,vv in pairs(ntbl) do
	 	 dp=dp or (v==vv)
	 	end
 		if dp==false then add(ntbl,v) end
 	end
 end
return ntbl
end

function canvaspos(x,y)
return {x=flr((x-canvas.x)/2)+1+view.x,y=flr((y-canvas.y)/2)+1+view.y}
end

function pos2cel(x,y)
local cw=4
local ch=4
return {x=flr((x-1)/cw)+1,y=flr((y-1)/ch)+1}
end

function getsprpos(x,y,r)
local cw=(r==nil) and 8 or r.w
local ch=(r==nil) and 8 or r.h
return {x=flr(x/cw),y=flr(y/ch)}
end

function attachcels(cels)
local cw=4
local ch=4
if cels==nil then return false end
cels=#cels==0 and {cels} or cels
for cel in all(cels) do
recordcells(cel.cx,cel.cy,getpatcel(cel.cx,cel.cy))
 cel.each(function(p,x,y)
  local x=(cel.cx-1)*cw+x
  local y=(cel.cy-1)*ch+y
  psetsprram(x,y,p)
 end)
end
history.pages[history.current+1]=getrecord()
clearrecord()
end

--start:1~
function patcols(cx,cy)
local cels=getpatcel(cx,cy)
local cols={}
cels.each(function(p,x,y,o)
 if #cols==0 then add(cols,p) end
 for co in all(cols) do
  if co==p then return end
 end
 add(cols,p)
end)
//stop(#cols)
if #cols==1 then cols[2]=cols[1] end
return cols
end

--start:1~
function getpatcel(cx,cy)
local o={cx=cx,cy=cy}

local cw=4
local ch=4
local pat={}
cx-=1
cy-=1
for y=1,ch do
 pat[y]={}
 for x=1,cw do
  pat[y][x]=getsprpix(cx*cw+x,cy*ch+y)
 end
end
o.dat=pat
o.each=function(func)
 for y,row in pairs(o.dat) do
  for x,p in pairs(row) do
   local r=func(p,x,y,o)
  end
 end
 return r
end

return o
end

function pateach(func)
for y,row in pairs(cels) do
 for x,p in pairs(row) do
  local r=func(p,x,y)
 end
end
return r
end

function setmaquee(text,fg,bg)
maqueetext=cocreate(function()
local prm={d=128,b=30,bg=bg,fg=fg}
while maqueeslide(text,prm) do
yield()
end
end)
end
function maqueeslide(text,prm)
local p=prm.d
local b=prm.b
 rectfill(0,121,127,127,prm.bg)
 print(text,p,122,prm.fg)
 if p>1 then
  prm.d=p/1.2
 elseif b>0 then
  prm.b-=1
 elseif b==0 and p<-128 then
  return false
 else
  prm.d=-abs(p)*1.2
 end
 return true
end


function getmempos(x,y)
local p=memstart+(x/2)+(y*memrowlen)
return (p>=memstart and p<=memend) and p or false
end


-->8
--controlls
function getmouse()
local mb=stat(34)
local mst=mousestate
local mo={x=stat(32),y=stat(33),l=band(mb,1)>0,r=band(mb,2)>0,m=band(mb,4)>0,sx=mst.stx,sy=mst.sty}

if mo.l then 
mst.l+=1
mo.lut=false
else
mo.lut=mst.l>0
mst.l=0
end

if mo.r then 
mst.r+=1
mo.rut=false
else
mo.rut=mst.r>0
mst.r=0
end

if mo.m then 
mst.m+=1
mo.mut=false
else
mo.mut=mst.m>0
mst.m=0
end

mo.mt=mousestate.m==1
mo.rt=mousestate.r==1
mo.lt=mousestate.l==1

if mo.lt then
mst.stx=mo.x
mst.sty=mo.y
end
mo.sx=mst.stx
mo.sy=mst.sty

return mo
end

function updatekey()
presskey=stat(31)
end
function getkey()
return presskey
end

function selectrecttool()
local spos=getsprpos(mouse.x,mouse.y)
local srect=selectrect
local prect=piecesrect
if not prect.enable and not srect.enable and mouse.lt then
srect.x=spos.x*8
srect.y=spos.y*8
srect.refresh()
selectrect.enable=true
selectrect.fls=0
end
if selectrect.enable and mouse.l then
srect.w=spos.x*8-srect.x
srect.h=spos.y*8-srect.y
srect.refresh()
selectrect.fls+=1
end
if selectrect.enable and mouse.lut then
srect.x=srect.w<0 and srect.ex or srect.x
srect.y=srect.h<0 and srect.ey or srect.y
srect.w=abs(srect.w)+8
srect.h=abs(srect.h)+8
srect.refresh()
selectrect.enable=false
piecesrect.enable=true
return
end
local ccel=currentcel
if ccel.x~=spos.x or ccel.y~=spos.y then
ccel.x=spos.x
ccel.y=spos.y
ccel.fls=20
end

spos=getsprpos(mouse.x,mouse.y,selectrect)
if piecesrect.enable then
 if not mouse.l and not mouse.lut then
 prect.x=spos.x
 prect.y=spos.y
 prect.w=1
 prect.h=1
 prect.refresh()
 prect.fls=0
 elseif mouse.l then
  prect.w=spos.x-prect.x+1
  prect.h=spos.y-prect.y+1
  if prect.w*srect.w>spritearea.w then
  prect.w=flr(spritearea.w/srect.w)
  end
  if prect.h*srect.h>spritearea.h then
  prect.h=flr(spritearea.h/srect.h)
  end
  prect.refresh()
  prect.fls+=1
 elseif mouse.lut then
 --confirm
 prect.enable=false
 srect.enable=false
 confirm=true
 end
end
end
-->8
--memory

--writing cart data--
chastr='abcdefghijklmnopqrstuvwxyz1234567890-_(),. '
function str2char(str)
 chs={}
 for i=1,#str do
  for p=1,#chastr do
   local s=sub(chastr,p,p)
   if sub(str,i,i)==s then add(chs,p) end
  end
 end
 return chs
end

function dsetchar(chs)
 local d=0
 for i,c in pairs(chs) do
  local b=band(i-1,0b11)
  d+=shl(shr(c,16),shl(b,3))
  if b==3 then dset(shr(band(i-1,0xfffc),2),d) d=0 end
 end
 if d>0 then dset(shr(band(#chs,0xfffc),2),d) end
 
end


function dgetchar()
 local d
 local chs={}
 repeat
  local b=band(#chs,0x3)
  if b==0 then d=dget(shr(band(#chs,0xfffc),2)) end
   local lbits=shl(b,3)
   local c=shl(shr(band(d,shl(0x.00ff,lbits)),lbits),16)
  if c then add(chs,c) end
 until c==0
 return chs
end

function char2str(chs)
 str=''
 for i,c in pairs(chs) do
  local s=sub(chastr,c,c)
  if s then str=str..s end
 end
 return str
end

function dsetclear(str)
 local d=0
 local b=0
 for i=1, #str do
  local b=band(i-1,0x3)
  local rbits=shr(band(i-1,0xfffc),2)
  local lbits=shl(b,3)
  if b==0 then d=dget(rbits) end
  d=shr(band(d,rotl(0xffff.ff00,lbits)),lbits)
  if b==3 then dset(rbits,d) d=0 end
 end
 if b<3 then dset(shr(band(#str-1,0xfffc),2),d) end
end

function clearrecord()
history.records={}
end
function recordcells(cx,cy,ncel)
for cel in all(history.records) do
if cel.cx==ncel.cx and cel.cy==ncel.cy then return false end
end
add(history.records,ncel)
return true
end

function getrecord()
return history.records
end
function sethistory(record)

if history.current<16 then
history.pages[history.current+1]=record
history.current+=1
else
del(history.pages,history.pages[1])
add(history.pages,record)
end
if #history.pages>history.current-1 then
 for i=history.current+1,#history.pages do
  local p=#history.pages
 del(history.pages,history.pages[i])
 end
end
clearrecord()
end

function clearsprite(name)
local r=spritearea
local cw=r.w/4
local ch=r.h/4
if name=='yes' then
for cy=1,ch do
for cx=1,cw do
 recordcells(cx,cy,getpatcel(cx,cy))
end
end

for y=1,r.h do
for x=1,r.w do
 psetsprram(x,y,0)
end
end
--sethistory(getrecord())
sfx(53)
setmaquee('all cleared',8,2)
end

end

function savepng(name,txt)
cstore()
export(name..'.png')
dsetclear(current_file)
dsetchar(str2char(name))
current_file=name

setmaquee('saved: '..name..'.png',12,1)
sfx(54)
end
function loadpng(name,txt)
import(name..'.png')
reload()
dsetclear(current_file)
dsetchar(str2char(name))
current_file=name

setmaquee('loaded: '..name..'.png',11,3)
sfx(55)
end

function tohex(num)
local hex=''
local len=#hexkey
num=tonum(num)
repeat
local p=band(num,0xf)
hex=sub(hexkey,p+1,p+1)..hex
num=shr(num-p,4)
until num==0
return hex
end
--format rule--
--[[
* pattern block    *
 + block in pat    : 2x2~32*32
 + block size      : 1~256 block
 + 1 file pix size : 128*128 pix
 + format like
  - blocks cel_x cel_y lib data
  - datadata.t2 (2char delimit)
  - datadata.t3 (3char delimit)
  - liblibli... (4char delimit)
  
* -lib- pat library*
 + pattarn value   : 0000~ffff
 + maxpatten num t2: 256
 + maxpatten num t3: 4096
 
* -data- lib index *
 + lib index value : 00~ff   t2
 + lib index value : 000~fff t3

* -\n- new line    *
 + when add other exported data
    then add to next line
 + block index be added 
    from blocks of next line
]]
function exporttxt(name,txt)
local pat={}
local col={}
local srect=selectrect
local prect=piecesrect
local patw=srect.w/4
local path=srect.h/4
local blkw=prect.w
local blkh=prect.h
local liblen=2
setmaquee('pickuping patterns...',1,5)
for by=1,blkh do
pat[by]={}
for bx=1,blkw do
pat[by][bx]={}
for cv=1,15 do
pat[by][bx][cv]={}
for cy=1,path do
pat[by][bx][cv][cy]={}
for cx=1,patw do
local p=patterns(cx+((bx-1)*patw)+(prect.x*patw),cy+((by-1)*path+(prect.y*path)),cv)
add(pat[by][bx][cv][cy],p)

end
end
end
end
end

setmaquee('to unique patterns...',1,5)
local upt
for by in all(pat) do
for bx in all(by) do
for cv in all(bx) do
 upt=uniquepat(cv,upt)
end
end
end

//vdmp({#upt})

local mx=''
repeat
mx=mx..'f'
until liblen<=#mx
mx=tonum("0x"..mx)
if #upt>mx then 
setmaquee('** patterns '..#upt..'/'..mx..' over **',8,7)return false
end
--vdmp(upt)

setmaquee('apply indexes...',1,5)
local pid={}
for by,blky in pairs(pat) do
pid[by]={}
for bx,blkx in pairs(blky) do
pid[by][bx]={}
for cv,ct in pairs(blkx) do
pid[by][bx][cv]={}
for y,row in pairs(ct) do
pid[by][bx][cv][y]={}
for x,p in pairs(row) do
 for i,v in pairs(upt) do
  if v==p then pid[by][bx][cv][y][x]=i end
 end
end
end
end
end
end

//local btext={}
setmaquee('join codes...',1,5)
local btext=''
for by,blky in pairs(pat) do
for bx,blkx in pairs(blky) do
for cv,ct in pairs(blkx) do
local bt={}
for y,row in pairs(ct) do
for x,p in pairs(row) do
for i,id in pairs(upt) do
//i=#i<2 and '0'..i or i
if p==id then
i=tohex(i)
while #i<liblen do
i='0'..i
end
add(bt,i) break end
end--id
end--x
end--y
btext=btext..join(bt,"")
//btext=btext.."\n-cv: "..cv.."- "..join(bt,"")
end--cv
end--bx
end--by
--vdmp(#btext)
printh(btext,'btext',true)

setmaquee('compressing code...',1,5)
local ztext=''
local i=1
local rt=''
//local pre=sub(btext,1,2)
local pre=sub(btext,1,liblen)
local c=1
//btext=sub(btext,3,#btext)
btext=sub(btext,liblen+1,#btext)
while #pre>0 do
--local t=sub(btext,1,2)
local t=sub(btext,1,liblen)
--btext=sub(btext,3,#btext)
btext=sub(btext,liblen+1,#btext)
if pre==t and c<255 then c+=1
else
c=tohex(c)
c=#c<2 and '0'..c or c
ztext=ztext..pre..c.."" c=1
end
pre=t

i+=2
end
--until #btext==0
--ztext=ztext..pre..c
ztext=sub(ztext,1,#ztext)
//vdmp({ztext,t})
local text='--replace fillpatdata--'.."\n"
..'fillpat={d='.."\n"
..'-- col-pid data --'.."\n"
.."[[\n"..join({#pat*#pat[1],#pat[1][1][1],#pat[1][1][1][1],join(upt,'')},' ')..' '..ztext.."\n]]\n"
..[[
,c=function(p,i)
local op=fillpat.p
return op[p][2]*op[p][3]*15*i
end
,p={{}}
,draw=function(i,x,y)
 local o=fillpat
 local d=''
 local dd=''
 local ii=0
 local op=o.p
if o.dd==nil then
d=o.d
repeat
 local s=sub(d,1,1)
 d=sub(d,2,#d)
 if s==" " or s=="\n" then
  add(op[#op],dd)
  if s=="\n" then add(op,{}) end
  dd=''
 else
  dd=dd..s
 end
until #d==0
dd={}
del(op,op[#op])
local p=#op
for pp=1,p do
d=op[pp][5]
dd[pp]={}
local lb=op[pp][4]
while #d>0 do
local f=(tonum('0x'..sub(d,1,2))-1)*4
local m=tonum('0x'..sub(d,3,4))
d=sub(d,5,#d)
repeat
add(dd[pp],tonum('0x'..sub(lb,f+1,f+4))+0x.8)
m-=1
until m<1
end
end
o.dd=dd
end
p=0
dd=0
i-=1
repeat
p+=1
i-=dd
if o.dd[p+0]==nil then return true end
dd=op[p][1]
until i-dd<0
local w=op[p][2]
local h=op[p][3]
for dd=o.c(p,i),o.c(p,i+1)-1 do
d=o.dd[p][dd+1]
if d~=0xffff.8 then 
fillp(d)
local xx=4*(dd%w)+x
local yy=4*(flr(dd/w)%h)+y
rectfill(xx,yy,xx+3,yy+3,flr(dd/(w*h))%15+1)
end
end
return false
end
}
]]
// stop(txt,0,0)
printh(text,''..name..'.p8l',true)
setmaquee('exported: '..name..'.p8l',9,4)
sfx(56)

end

function entryname(callbk,label,default)

corout=cocreate(function()
local s
local fname=default==nil and current_file or default
local cnt=0
local cstr
local mus=mouse
while s~="\r" do
 rectfill(0,72,127,80,0)
 rect(0,72,127,80,1)
 s=getkey()
 mus=mouse
 poke(0x5f30,1)
 if s=="\r" then
  keystate=s
  
  if #fname==0 then fname=current_file end
  callbk(fname,text)
  return
 elseif s=="\b" then
  if #fname==0 then return end
  fname=sub(fname,1,#fname-1)
 elseif cnt>0 and (mus.rt or mus.lt) then
// stop()
  fname=''
  return
 else
  cstr=(flr(cnt/4%4)<3) and '_' or ''
  if s~=nil and s~="\r" then fname=fname..s end
 end
 print(label..fname..cstr,8,74,6)
 cnt+=1
 yield()
 
end
end)

end
-->8
--replace fillpatdata--
fillpat={d=
-- col-pid data --
[[
4 16 16 ffffffc0c100fff0ffec00008377e888c0017ffc8000ffe117c0fe012480c0002666f800f0008888fe00ffe8ff00e000311110113771fffcfcb73fc3ff0fff3ceeddefffdbbbfffe7777ffe0fc00f100fe8000017000ff61ec8080c83333eeeefecc33776aa86667ffd1c888a800777f7333e8cec420ffd6177f88cce8cfce003777ff3108cfe01b00edd3f7bffdc088ff104622ff91ff80e6c0ecefe88f000fe00ffeefff73c88d01ff0eff118cfff7ff17ceef7733fec8001777fffc803000bbbbe5110133feee078608667376bfff1000ffefccc800345330ee404013800818ce8808feb9088c01760880013788ef19df8ccfc800003f16ece934eeefff778cff17fbfeffe00c37ffb399e733117ff773dcefff70feedfff9ffe49337988ff60f100fc00f001fc0ff01eff00f800f913fc2117fffc8800013017f3bfffffdffeef733d113eeffff8e9bb9fdfefddddeeff7bdfffb77bbf79efff3cffc734eff1ff771bdef937fffdf46ef8b77cdddffb733557b8fce0ff30fe81f30ffc1efc80f593f088ffff1eeccf667888c001100ff0fe0f999d731ecc842230117e1e03c00ff43c42111134221b7fff300000333ff1fe0fd93cfff 0113020103010403010a050106040701010a08010602010109010a01010a0b01060101010c010d01010b060101010e010f01010c060110011101010612011301010514010105020101020b011001010b0601130115011301010c0601010f16011701010218011901010a0b0106010b01180106011a01010a0b0106011001010106011b0101ff01ff01ff01391c01010e1d011e011f022001010a21012201010e2301010724011501130117010104250101090b010601010826011701010d15010601010e10010601010f060101a3260127012801010a1c01290118012a01010b02010b0106042b012c0101072d0101012e0106010103100106012f0101042401300101013101060101050b0132010103330118013401350136010601010437010b01380101031401040139013a013b01060101023c01010115013d0101043e010601190101013f01060140011301020118010601410101050602420101014301440145010601010146014701010548010602490101034a014b01010806044c0104014d010601260101074e0106080b010107270106040b01060301074f01500151015001010252015002012c2401020117015301010c5401550156015701580101071c01590101012401040201015a015b0101065c015d015e015f01060360015801610101046201010163010101640106036501660167016801010469016a012f0101016b016c0106026d016e016f010105700101017101530172017301740175017601770101067801010279017a0117017b017c017d017e0101057f01800101038101820183018401060185010106860101068701880101077f018901010f8a018b0101068c0101088d0101035c018e0127018f0131014b010106900191019201930194019501960197019801990101ff01ff01ff01ff0129050127019a019b01010b05010b0106013201010c9c0106019d01010d06019e01010e4101010e300101082401530101069b0101159f010113a001010ba101a2010102a301010ba401850101a0a5018001010b1c0101039b01010ba6010101a7010107a0010101a801010da90158012201aa010102ab01010aac0101012201ad01ae012501010aa90158010102af01b0010103b101b2010106b30104012601b4010101b5010103b60153010106b701b801010325010101b901a101ba010106bb01bc01bd011f01be01bf01c0011f01c101c20101ff01ff010a300106029d010108020103010403c3017c019b010107050106040701010a08010602010109010a01010a0b01060101010c010d01010b060101010e010f01010c060110011101010612011301010514010105020101020b011001010b0601130115011301010c0601010f160117010102180119010104c40101050b0106010b01180106011a010103c5010601c60101040b0106011001010106011b010103c701c801010e22019b0101ff01ff01ff01241c01010e1d011e011f022001010a21012201010e2301010724011501130117010104250101090b010601010826011701010d15010601010e10010601010f060101a3260127012801010a1c01290118012a01010b02010b0106042b012c0101072d0101012e0106010103100106012f0101042401300101013101060101050b0132010103330118013401350136010601010437010b01380101031401040139013a013b01060101023c01010115013d0101043e010601190101013f01060140011301020118010601410101050602420101014301440145010601010146014701010548010602490101034a014b01010806044c0104014d010601260101074e0106080b010107270106040b01060301074f01500151015001010252015002012c2401020117015301010c5401550156015701580101071c01590101012401040201015a015b0101065c015d015e015f01060360015801610101046201010163010101640106036501660167016801010469016a012f0101016b016c0106026d016e016f010105700101017101530172017301740175017601770101067801010279017a0117017b017c017d017e0101057f01800101038101820183018401060185010106860101068701880101077f018901010f8a018b0101068c0101088d0101035c018e0127018f0131014b010106900191019201930194019501960197019801990101ff01ff01ff01ff0129050127019a019b01010b05010b0106013201010c9c0106019d01010d06019e01010e4101010e300101082401530101069b0101159f010113a001010ba101a2010102a301010ba401850101a0a5018001010b1c0101039b01010ba6010101a7010107a0010101a801010da90158012201aa010102ab01010aac0101012201ad01ae012501010aa90158010102af01b0010103b101b2010106b30104012601b4010101b5010103b60153010106b701b801010325010101b901a101ba010106bb01bc01bd011f01be01bf01c0011f01c101c20101ff01ff010a30010604010702010301040306035d0101060501060407018101c901ca01010708010602010109010a01010a0b01060101010c010d01010b060101010e010f01010c060110011101010612011301010514010105020101020b011001010b06011301150113010109cb0101020601010ccc010102160117010102180119010104020101050b0106010b01180106011a010103cd010601ce0101040b0106011001010106011b010103c70106013201010d2201550101ff01ff01ff01241c01010e1d011e011f022001010a21012201010e2301010724011501130117010104250101090b010601010826011701010d15010601010e10010601010f060101a3260127012801010a1c01290118012a01010b02010b0106042b012c0101072d0101012e0106010103100106012f0101042401300101013101060101050b0132010103330118013401350136010601010437010b01380101031401040139013a013b01060101023c01010115013d0101043e010601190101013f01060140011301020118010601410101050602420101014301440145010601010146014701010548010602490101034a014b01010806044c0104014d010601260101074e0106080b010107270106040b01060301074f01500151015001010252015002012c2401020117015301010c5401550156015701580101071c01590101012401040201015a015b0101065c015d015e015f01060360015801610101046201010163010101640106036501660167016801010469016a012f0101016b016c0106026d016e016f010105700101017101530172017301740175017601770101067801010279017a0117017b017c017d017e0101057f01800101038101820183018401060185010106860101068701880101077f018901010f8a018b0101068c0101088d0101035c018e0127018f0131014b010106900191019201930194019501960197019801990101ff01ff01ff01ff0129050127019a019b01010b05010b0106013201010c9c0106019d01010d06019e01010e4101010e300101082401530101069b0101159f010113a001010ba101a2010102a301010ba401850101a0a5018001010b1c0101039b01010ba6010101a7010107a0010101a801010da90158012201aa010102ab01010aac0101012201ad01ae012501010aa90158010102af01b0010103b101b2010106b30104012601b4010101b5010103b60153010106b701b801010325010101b901a101ba010106bb01bc01bd011f01be01bf01c0011f01c101c20101ff01ff010c0b0106040105020103010403240106021c011001cf01010405010604070130012a01d001d101010608010602010109010a01010a0b01060101010c010d01010b060101010e010f01010c060110011101010612011301010514010105020101020b011001010b060113011501130101092401d20101010601010cd301d401010116011701010218011901010a0b0106010b01180106011a0101047b01d50101040b0106011001010106011b01010330010602010d2201c901d60101ff01ff01ff01231c0101055c01d701530101061d011e011f02200101021401d801d9010105210122010106da0101072301010724011501130117010104250101090b010601010826011701010d15010601010e10010601010f0601014cdb01010edc019b010146260127012801010a1c01290118012a01010b02010b0106042b012c0101072d0101012e0106010103100106012f0101042401300101013101060101050b0132010103330118013401350136010601010437010b01380101031401040139013a013b01060101023c01010115013d0101043e010601190101013f01060140011301020118010601410101050602420101014301440145010601010146014701010548010602490101034a014b01010806044c0104014d010601260101074e0106080b010107270106040b01060301074f01500151015001010252015002012c2401020117015301010c5401550156015701580101071c01590101012401040201015a015b0101065c015d015e015f01060360015801610101046201010163010101640106036501660167016801010469016a012f0101016b016c0106026d016e016f010105700101017101530172017301740175017601770101067801010279017a0117017b017c017d017e0101057f01800101038101820183018401060185010106860101068701880101077f018901010f8a018b0101068c0101088d0101035c018e0127018f0131014b010106900191019201930194019501960197019801990101ff01ff01ff01ff0129050127019a019b01010b05010b0106013201010c9c0106019d01010d06019e01010e4101010e300101082401530101069b0101159f010113a001010ba101a2010102a301010ba401850101a0a5018001010b1c0101039b01010ba6010101a7010107a0010101a801010da90158012201aa010102ab01010aac0101012201ad01ae012501010aa90158010102af01b0010103b101b2010106b30104012601b4010101b5010103b60153010106b701b801010325010101b901a101ba010106bb01bc01bd011f01be01bf01c0011f01c101c20101ff01ff0103
1 16 16 ffffffc8c13cfff0fff3ffee1000001303ff3dee8377b901eccc7fffcc898888377fffed17ff0000fe8137ffdaef3777f879f7999ddfffcbaccfd7ff6546f773fea9f77ffcc8ff7331ff8cef1013ffecff12ec0871130011b9ddeeee3efdc80073318cff110fd93f00ff3fff001f4eecefff70ffb7fffffcecc8000119b3fcb73fc3ff0fff3c0060000f136d77ffeeddceff01ff78ffdbbbfffefe00f10077778fff319effe8ff37fecc0133ccee3bdfffe0b113ff9fec93ffe1fc3ff1fffe80e0003773ffc380e87000ff71edb788c8037fcfff000801118c8973777bb96677ffddc8883337b9bfbfec777ffff77333c4ac77f7ffdffec8177f88ce77103333eeef7330f7ffffc0e91316cb00887bcfe81f01ed1ff3dbf7bfff5eeeff91088c3003ffb1eec0008f6c8000200112b910fc8e32220137889b6cc839fffeff0fffff00c88d0eff118cff17ceef77330017fc803000bbbbed99feee07f708ee7376ffefccc800375331eecc4013800818ce88080377088088ef19df8ccfcc00003f16ece934ff7fe00cbbdd117ff77bdefffeedfff9fc00937ffeddffbb9cff1cffc0fff0ffc21180003377c880017f3bfffffdf733d113eeffff8eff779bb9fdfefddddeeff7bdfffb77bbf79ecffc734eff1ff771bdef46ef8b77cdddffb733557b8fce0ff30f30ffc1efc80f593f 01130201030104020501010a06010701080109010a010b0101010c0101080d0108010e0101010f010e01010a10011101010112011301010b1401010115011601010c140117011801010619011a0101051b0101051c0101021d011e01010b1f0120012101220101092301240101012501010c2601270101012801290101022a012b01010a10012c012d012e0114012f01010430013101010432013301340101013501360101032e0137013801010d39013a013b0101ff01ff01ff01233c0101043d0114043e013f01010340014101420243010101100114024401450146014701010248013901010549014a01360139014b01160101034c0101074d014e014f01240101045001010951015201010853015401010d55015601010e57011801010f5801014b59015a01010e51010e01012a4d012201010c5b0104015c01010b5d015e015f01510101093c01600161016201010b6301640114013e014502650166010107670101016801690101036a016b01500101044d012e01010155016c0101056d016e0101036f013901700171017201730101047401750176010103100177017801390179017a0101027b0101017c017d0101047e017f01800101018101820149018301840185018601180101058701070124010101880189018a018b0101018c018d010105570114010701660101038e018f010108900114029101920104019301140159010107390194013701950114019601140297019801010799019a0114029b019c0109019d015601010739019e013901360101029f01a0010e01012c4d018401a1012401010ca2014a01a301a401770101073c01a50101014d0104020101a601a70101067c01a8014701a9011403aa017701ab010104ac01010156010101ad011403ae01af01b0018d0101040701b10180010101b201b3011402b401b501b6010105b7010101b8012401b9019f019001ba01bb019b010106bc010102bd01be01a101bf01c001c101c20101053901c3010103320113019f01c401140116010106c50101063901c60101073901c701010fc801c3010106c9010108ca0101037c012801cb01cc01cd01ce010106cf018301d001d10113016a013601d2013b0201ff01ff01ff01ff01292801cb01d3010e01010b2801d4011401d501010cd60114010801010d1401d701010e1801010e2e0101084d01240101060e010115d8010113d901010b0601da010102db01010bdc01160101a0dd01de01010b3c0101030e01010bdf010101e0010107d9010101e101010de20177013901e3010102e401010ae50101013901e60105015001010ae20177010102e701e8010103e901ea010106eb0104015901cc0101017b010103ec0124010106ed01ee01010350010101ef010601f0010106f101f201f30142018901f401f5014201f601f70101ff01ff0103
1 16 16 ffffffecf003f00ff308ff73fe03f37f9ffffffe8110401303ff0ffe1437eccc00117fffec8977ffc8881337ffe993ff0000fec137ffdbff3377fc31f7b99ddffff9accf97ffa546f773f77ffec839ff8cef137fff12ec08711388880001b1ddeeee3efdc80073318cff110fd93f00ff3fff0738ee87f8130ffc0ff01cf7f39cfedbe1fc3ff0fff0fff188006000feed7eefbfffefff0003000f0138dbbb1efff0ff17ffb777f7bfff378133ccee37773bdff8cf117ffffcfec7fff8fc00f7330fffc068f100ff71fe9b88c8037f8eff00087777feeefecc01118c8973777bb96677ffdd3337f9bfbfec777fff777333c4ac77f7ffdf177f88ce31003333eeef7330ceffed0116cb008810007bcfe81f00ed0ff3dbf75eeeff91088c3003ffb1eec0ffe0008f001f6c8000200112b910fc8e32220137889b6cc80133feff18ccf001ff00fff7ff9708ce77338013fc80c0007100bbbbed987376ffefccc800075331eecc808818ce88087eff088019df8ccff700cc0012fee934ff7ff00cbbddf77bdeff937ffeddffbb9cfff7ff1cffc0ffcfffb7fffbffffee80001377ecc80017013f3667b3fffffdff33d113eeffffcedbb9fefbfddddeeff7bdfffb77bbf79efff3cffc734eff1ff771bdef46ef8b77cdddffb733557b8fce0ff30fff0f30ffc1efc80f593f 010b0201030104010501060101030201070108010105090101060a010b010c010d010e010f01010a100111011201010113011401010a15011601010117011801010b190114011a011b01010c19011c011d0101061e011f010105200101052101010222012301010b2401250102012601010927010601010128011201010b29012a01010102012b0101022c012d01010a2e012f013001310119013201010433013401010435013601370101013801390101043a013b0101ff01ff01ff013902013c013d013e013f01400101034101420143014401450101024601470119040102480149014a0101024b010101310119034c014d014e0101024f0101074b010e0150015102520101025301010950015401010802015501010d02015601010e57015801010f5901014b5a015b0101595c0144015d0101085e015f01600101014b0161020107170162011904630164010107650112016601670139010102680169016a0101056b0112016c016d0101056e016f010103700101017101720115017301010474017501760101032e01770178014b0179017a0101027b01010127017c0101047d017e017f01010180018101820101014401830184015801010585018601060101018701880189018a0101018b014a010105570119018601640101038c018d0101088e0119028f019001440191011901920101074b0193019401950119019601190297019801010799019a0119029b019c010d019d019e0101074b0128014b01390101029f0161011201013ca001a1016301a201a30101070a01a40101044b01a501a60101060201a7011401a801a9011902aa01a301ab010104ac010101a70112016b0119030d01a501ad014a0101041901ae017f010101af01b0011902b101b2010c010105b3010101b4010601b501b6018e019b01b7019b01010682010102b801b901ba01bb014d01bc01bd0101054b01be010103350152010101bf0119011b010106c00101064b015b0101074b01c101010fc201be0101064801010821010103270102015f01c301c401c5010106c601c701c801c9015201ca0139015101cb0201ff01ff01ff01ff012902015f01a101cc01010bcd01ce011901cf01010cd0011901d1011201010c4601d201010ed301010e310101080a010601010612010115d4010113d501010b0a01d6010102d701010bd8011b0101a0d9017701010b0a0101031201010bda010101db010107d5010101dc01010ddd01a3014b01de010102df01010ae00101014b01e101e2016a01010add01a3010102e301e4010103e501e6010106e70144019201c30101017b010103e80106010106e901ea0101036a010101eb01cd01ec010106ed01ee01ef01f0018801f101f201f001f301f40101ff01ff0103
]]
,c=function(p,i)
local op=fillpat.p
return op[p][2]*op[p][3]*15*i
end
,p={{}}
,draw=function(i,x,y)
 local o=fillpat
 local d=''
 local dd=''
 local ii=0
 local op=o.p
if o.dd==nil then
d=o.d
repeat
 local s=sub(d,1,1)
 d=sub(d,2,#d)
 if s==" " or s=="\n" then
  add(op[#op],dd)
  if s=="\n" then add(op,{}) end
  dd=''
 else
  dd=dd..s
 end
until #d==0
dd={}
del(op,op[#op])
local p=#op
for pp=1,p do
d=op[pp][5]
dd[pp]={}
local lb=op[pp][4]
while #d>0 do
local f=(tonum('0x'..sub(d,1,2))-1)*4
local m=tonum('0x'..sub(d,3,4))
d=sub(d,5,#d)
repeat
add(dd[pp],tonum('0x'..sub(lb,f+1,f+4))+0x.8)
m-=1
until m<1
end
end
o.dd=dd
end
p=0
dd=0
i-=1
repeat
p+=1
i-=dd
if o.dd[p+0]==nil then return true end
dd=op[p][1]
until i-dd<0
local w=op[p][2]
local h=op[p][3]
for dd=o.c(p,i),o.c(p,i+1)-1 do
d=o.dd[p][dd+1]
if d~=0xffff.8 then 
fillp(d)
local xx=4*(dd%w)+x
local yy=4*(flr(dd/w)%h)+y
rectfill(xx,yy,xx+3,yy+3,flr(dd/(w*h))%15+1)
end
end
return false
end
}


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111100000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111000000000000000000000
00000000000000000055000000000000000000000000000000000000000000000000000000000000005500000000000111111111110000000000000000000000
00000000000000005511000000000000000000000000000000000000000000000000000000000000551100000000000011111111100000000000000000000000
00000000000000551110000000000000000000000000000000000000000000000000000000000055111000000000000001111111000000000000000000000000
00000000000005111155555555555500000000000000000000000000000000000000000000000511115555555555550001111100000000000000000000000000
00000000000051115511111111111155000000000000000000000000000000000000000000005111551111111111115500000000000000000000000000000000
00000000000511151111111111ccc1110000000000000000000000000000000000000000000511151111111111ccc11100000000000000000000000000000000
0000000000051111111111cccc1c1100000000000000006666600000000000000000000000051111111111cccc1c110000000000000000666660000000000000
0000000000511111111cccccccc11000000000000006667777777000000000000000000000511111111cccccccc1100000000000000666777777700000000000
000000000051111111ccccccccc1100000000000666777777777770000000000000000000051111111ccccccccc1100000000000666777777777770000000000
00000000005111111ccccccccc1110000000000666777777777777700000000000000000005111111ccccccccc11100000000006667777777777777000000000
0000000005111111cccccccccc110000000666666777777555577770000000000000000005111111cccccccccc11000000066666677777755557777000000000
000000000511111cccccccccc111000006666666677755555555577700000000000000000511111cccccccccc111000006666666677755555555577700000000
00000000051111ccccccccccc11000666666666666755555555555777000000000000000051111ccccccccccc110006666666666667555555555557770000000
00000000511111cccccccccc111006666666666666666666655555777000000000000000511111cccccccccc1110066666666666666666666555557770000000
0000000051111ccccccccccc10006666666666666666666666665557700000000000000051111ccccccccccc1000666666666666666666666666555770000000
0000000051111cccccccccc100667776666666666666666666666557770000000000000051111cccccccccc10066777666666666666666666666655777000000
000000005111cccccccccc106677766666666667777777776666666577000000000000005111cccccccccc106677766666666667777777776666666577000000
000000001111cccccccc11067777766666667777777777777766666667000000000000001111cccccccc11067777766666667777777777777766666667000000
000000001111ccccccc110677777766666777777777777777777666667000000000000001111ccccccc110677777766666777777777777777777666667000000
000000001111ccccc11106777775556667777777777777777777666667000000000000001111ccccc11106777775556667777777777777777777666667000000
000000001111cccc111067777555566677777777777777777777766667000000000000001111cccc111067777555566677777777777777777777766667000000
000000001111cc17110677775555666677777777777777777777766667000000000000001111cc17110677775555666677777777777777777777766667000000
000000001111c171100677755556666777777777777771111777776666000000000000001111c171100677755556666777777777777771111777776666000000
000000001111c77110067755556666677777777777771dddd117766660000000000000001111c77110067755556666677777777777771dddd117766660000000
000000001111c7761006775555666667777777777777711dd117766760000000000000001111c7761006775555666667777777777777711dd117766760000000
00000000611c777660067755556666777777777777777171d61776776000000000000000611c777660067755556666777777777777777171d617767760000000
00000000061c777760067755566666777777777777777711166777776000000000000000061c7777600677555666667777777777777777111667777760000000
00000000061c777760077765566666777711777777777711c67777766000000000000000061c777760077765566666777711777777777711c677777660000000
00000000066c7777600077655666677771dd77777777777ccc7777660000000000000000066c7777600077655666677771dd77777777777ccc77776600000000
000000000666c77760007776556667771dd17777777777777777666000000000000000000666c77760007776556667771dd17777777777777777666000000000
000000000666777766000777656667771d17177777d117777776600000000000000000000666777766000777656667771d17177777d117777776600000000000
000000000666777766000077765677771d111777716117777766600000000000000000000666777766000077765677771d111777716117777766600000000000
000000000666677766000007776667771dd11177711d77777666000000000000000000000666677766000007776667771dd11177711d77777666000000000000
000000000666677766000000777667771166cc77777777766667660000000000000000000666677766000000777667771166cc77777777766667660000000000
000000000666677766d000000776667711166c77777776676776600000000000000000000666677766d000000776667711166c77777776676776600000000000
000000000066666766d000000076667777777777776666677766600000000000000000000066666766d000000076667777777777776666677766600000000000
0000000000d6666666d0000000006666777777776666667776776000000000000000000000d6666666d000000000666677777777666666777677600000000000
0000000000d76666666d000000006777777666666667777777611600000000000000000000d76666666d00000000677777766666666777777761160000000000
00000000000d66666666d000000006777666666777777777761111100000000000000000000d66666666d0000000067776666667777777777611111000000000
00000000000d766666666d00000000666661111677777777111111100000000000000000000d766666666d000000006666611116777777771111111000000000
000000000000d666666666d0000000000d11116166777777611111c000000000000000000000d666666666d0000000000d11116166777777611111c000000000
000000000000d7666666666d00000000d111111161677771111111c000000000000000000000d7666666666d00000000d111111161677771111111c000000000
000000000000d76666666666d0000000d1111111c11677711111ccc100000000000000000000d76666666666d0000000d1111111c11677711111ccc100000000
0000000000000d76666666666dd00000d111111ccc1676611111ccc0000000000000000000000d76666666666dd00000d111111ccc1676611111ccc000000000
0000000000000d7666666666666ddd00d111111ccc1666611111cc10000000000000000011100d7666666666666ddd00d111111ccc1666611111cc1000000000
00000000000000d766666666666666ddd111111ccc166666111111000000000000000001111100d766666666666666ddd111111ccc1666661111110000000000
000000000000000d7666666666666666dd11111cc11666661111d00000000000000000011111100d7666666666666666dd11111cc11666661111d00000000000
000000000000000d7666666666666666d6dd111111666666ddd6d00000000000000000111111100d7666666666666666d6dd111111666666ddd6d00000000000
0000000000000000d7666666666666dd666d6666666666666666ddd0000000000000001111111000d7666666666666dd666d6666666666666666ddd000000000
00000000000000000d76666666666dd666666666666666666666d6dd0000000000000111111100000d76666666666dd666666666666666666666d6dd00000000
000000000000000000d766666666dd6666666666666666666667d66d00000000000001111111000000d766666666dd6666666666666666666667d66d00000000
0000000000000000000d7666666dd666666666d6666666666667666dd00000000000011111100000000d7666666dd666666666d6666666666667666dd0000000
00000000000000000000dddddddd6666666666666666666666766666dd00000000000011111000000000dddddddd6666666666666666666666766666dd000000
000000000000000000000ddd66dd666666666666d666666667766666dd000000000000011000000000000ddd66dd666666666666d666666667766666dd000000
000000000000000000000d6666d6666666666667d666667777666667dd000000000000000000000000000d6666d6666666666667d666667777666667dd000000
00000000000000000000d66666d6666666666677d66777777d66667dd7d0000000000000000000000000d66666d6666666666677d66777777d66667dd7d00000
00000000000000000000d77666d6666666666777d6777777d666667dd7d0000000000000000000000000d77666d6666666666777d6777777d666667dd7d00000
00000000000000000000d77666dd77766677777ddd7777dd666667ddd7d0000000000000000000000000d77666dd77766677777ddd7777dd666667ddd7d00000
000000000000000000000d77766ddd7777777dddddddddd677777ddd7dd00000000000000000000000000d77766ddd7777777dddddddddd677777ddd7dd00000
000000000000000000000dddddddddddddddddd00000000ddddddddddd000000000000000000000000000dddddddddddddddddd00000000ddddddddddd000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000001111111111111111100000000000000000000000000000000000000000000000000000111111111111111111100000000
00000000000000000000000000000001111111111111111100000000000000000000000000000000000000000000000000001111111555111111111100000000
00000000000000000000000000000001111111111111111100000000000000000000000000000000000000000000000000001111115555555111111100000000
00000000000000000055000000000001111111111111111100000000000000000000000000000000005500000000000000001111155555555511111100000000
00000000000000005511000000000000111111111111111100000000000000000000000000000000551100000000000000001111155555555511111100000000
00000000000000551110000000000000111111111111111100000000000000000000000000000055111000000000000000001111155555555511111000000000
00000000000005111155555555555500111111111111111000000000000000000000000000000511115555555555550000001111155555551111111000000000
00000000000051115511111111111155111111111111100000000000000000000000000000005111551111111111115500011111155555111111100000000000
00000000000511151111111111ccc1110111111111110000000000000000000000000000000511151111111111ccc11100011111555111000000000000000000
0000000000051111111111cccc1c1100001111110000006666600000000000000000000000051111111111cccc1c110000011111111000666660000000000000
0000000000511111111cccccccc11000000000000006667777777000000000000000000000511111111cccccccc1100000011111000666777777700000000000
000000000051111111ccccccccc1100000000000666777777777770000000000000000000051111111ccccccccc1100000011110666777777777770000000000
00000000005111111ccccccccc1110000000000666777777777777700000000000000000005111111ccccccccc11100000000006667777777777777000000000
0000000005111111cccccccccc110000000666666777777555577770000000000000000005111111cccccccccc11000000066666677777755557777000000000
000000000511111cccccccccc111000006666666677755555555577700000000000000000511111cccccccccc111000006666666677755555555577700000000
00000000051111ccccccccccc11000666666666666755555555555777000000000000000051111ccccccccccc110006666666666667555555555557770000000
00000000511111cccccccccc111006666666666666666666655555777000000000000000511111cccccccccc1110066666666666666666666555557770000000
0000000051111ccccccccccc10006666666666666666666666665557700000000000000051111ccccccccccc1000666666666666666666666666555770000000
0000000051111cccccccccc100667776666666666666666666666557770000000000000051111cccccccccc10066777666666666666666666666655777000000
000000005111cccccccccc106677766666666667777777776666666577000000000000005111cccccccccc106677766666666667777777776666666577000000
000000001111cccccccc11067777766666667777777777777766666667000000000000001111cccccccc11067777766666667777777777777766666667000000
000000001111ccccccc110677777766666777777777777777777666667000000000000001111ccccccc110677777766666777777777777777777666667000000
000000001111ccccc11106777775556667777777777777777777666667000000000000001111ccccc11106777775556667777777777777777777666667000000
000000001111cccc111067777555566677777777777777777777766667000000000000001111cccc111067777555566677777777777777777777766667000000
000000001111cc17110677775555666677777777777777777777766667000000000000001111cc17110677775555666677777777777777777777766667000000
000000001111c171100677755556666777777777777771111777776666000000000000001111c171100677755556666777777777777771111777776666000000
000000001111c77110067755556666677777777777771dddd117766660000000000000001111c77110067755556666677777777777771dddd117766660000000
000000001111c7761006775555666667777777777777711dd117766760000000000000001111c7761006775555666667777777777777711dd117766760000000
00000000611c777660067755556666777777777777777171d61776776000000000000000611c777660067755556666777777777777777171d617767760000000
00000000061c777760067755566666777777777777777711166777776000000000000000061c7777600677555666667777777777777777111667777760000000
00000000061c777760077765566666777711777777777711c67777766000000000000000061c777760077765566666777711777777777711c677777660000000
00000000066c7777600077655666677771dd77777777777ccc7777660000000000000000066c7777600077655666677771dd77777777777ccc77776600000000
000000000666c77760007776556667771dd17777777777777777666000000000000000000666c77760007776556667771dd17777777777777777666000000000
000000000666777766000777656667771d17177777d117777776600000000000000000000666777766000777656667771d17177777d117777776600000000000
000000000666777766000077765677771d111777716117777766600000000000000000000666777766000077765677771d111777716117777766600000000000
000000000666677766000007776667771dd11177711d77777666000000000000000000000666677766000007776667771dd11177711d77777666000000000000
000000000666677766000000777667771166cc77777777766667660000000000000000000666677766000000777667771166cc77777777766667660000000000
000000000666677766d001100776667711166c77777776676776600000000000000000000666677766d000000776667711166c77777776676776600000000000
000000000066666766d001100076667777777777776666677766600000000000000000000066666766d000001076667777777777776666677766600000000000
0000000000d6666666d0011000006666777777776666667776776000000000000000000000d6666666d000011100666677777777666666777677600000000000
0000000000d76666666d001000006777777666666667777777611600000000000000000000d76666666d00111110677777766666666777777761160000000000
00000000000d66666666d000000006777666666777777777761111100000000000000000000d66666666d0111110067776666667777777777611111000000000
00000000000d766666666d00000000666661111677777777111111100000000000000000000d766666666d011110006666611116777777771111111000000000
000000000000d666666666d0000000000d11116166777777611111c000000000000000000000d666666666d0110000000d11116166777777611111c000000000
000000000000d7666666666d00000000d111111161677771111111c000000000000000000000d7666666666d00000000d111111161677771111111c000000000
000000000000d76666666666d0000000d1111111c11677711111ccc100000000000000000000d76666666666d0000000d1111111c11677711111ccc100000000
0000000000110d76666666666dd00000d111111ccc1676611111ccc0000000000000000000000d76666666666dd00000d111111ccc1676611111ccc000000000
0000000011110d7666666666666ddd00d111111ccc1666611111cc10000000000000000000000d7666666666666ddd00d111111ccc1666611111cc1000000000
00000001111110d766666666666666ddd111111ccc166666111111000000000000000000001110d766666666666666ddd111111ccc1666661111110000000000
000000111111110d7666666666666666dd11111cc11666661111d00000000000000000000111110d7666666666666666dd11111cc11666661111d00000000000
000000111111110d7666666666666666d6dd111111666666ddd6d00000000000000000001111110d7666666666666666d6dd111111666666ddd6d00000000000
0000011111111100d7666666666666dd666d6666666666666666ddd0000000000000000011111110d7666666666666dd666d6666666666666666ddd000000000
00000111111111000d76666666666dd666666666666666666666d6dd0000000000000001111111110d76666666666dd666666666666666666666d6dd00000000
000001111111110000d766666666dd6666666666666666666667d66d00000000000000011111115100d766666666dd6666666666666666666667d66d00000000
0000011111111000000d7666666dd666666666d6666666666667666dd00000000000000111111551000d7666666dd666666666d6666666666667666dd0000000
00000011111110000000dddddddd6666666666666666666666766666dd00000000000001111155110000dddddddd6666666666666666666666766666dd000000
000000011111000000000ddd66dd666666666666d666666667766666dd000000000000011155510000000ddd66dd666666666666d666666667766666dd000000
000000001110000000000d6666d6666666666667d666667777666667dd000000000000001111100000000d6666d6666666666667d666667777666667dd000000
00000000000000000000d66666d6666666666677d66777777d66667dd7d0000000000000000000000000d66666d6666666666677d66777777d66667dd7d00000
00000000000000000000d77666d6666666666777d6777777d666667dd7d0000000000000000000000000d77666d6666666666777d6777777d666667dd7d00000
00000000000000000000d77666dd77766677777ddd7777dd666667ddd7d0000000000000000000000000d77666dd77766677777ddd7777dd666667ddd7d00000
000000000000000000000d77766ddd7777777dddddddddd677777ddd7dd00000000000000000000000000d77766ddd7777777dddddddddd677777ddd7dd00000
000000000000000000000dddddddddddddddddd00000000ddddddddddd000000000000000000000000000dddddddddddddddddd00000000ddddddddddd000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010111111111111111111111111111111111111111111111111111111111111111110101010111111111111111111111111111111111111111110101010
00000001000000000000000000000000000000000000000000000000000000000000000010000001000000000011111111112222222222333333333310000000
10101011000000000000000000000000000000000000000000000000000000000000000010101011000000000011111111112222222222333333333310101010
00000001000000000000000000000000000000000000000000000000000000000000000010000001000000000011111111112222222222333333333310000000
10101011000000000000000000000000000000000000000000000000000000000000000010101011000000000011111111112222222222333333333310101010
00000001000000000000000000000000000000000000000000000000000000000000000010000001000000000011111111112222222222333333333310000000
10101011000000000000000000000000000000000000000000000000000000000000000010101011000000000011111111112222222222333333333310101010
00000001000000999999000000000000000000000000000000000000000099999900000010000001000000000011111111112222222222333333333310000000
10101011000000999999000000000000000000000000000000000000000099999900000010101011000000000011111111112222222222333333333310101010
00000001000099999999999900000000000000000000000000000000009999999999000010000001000000000011111111112222222222333333333310000000
1010101100009999999999990000000000000000000000000000000000999999999900001010101100000000001111111111222222222fffffffffff10101010
0000000100009999999999999900000000000000000000000000000099999999999900001000000144444444445555555555666666666f777777777f10000000
1010101100009999999999999900000000000000000000000000000099999999999900001010101144444444445555555555666666666f777777777f10101010
0000000100009999999999999999000000000000000000000000009999999999999900001000000144444444445555555555666666666f777777777f10000000
1010101100009999999999999999000000000000000000000000009999999999999900001010101144444444445555555555666666666f777777777f10101010
0000000100009999999999999999990000000000000099000000999999999999999900001000000144444444445555555555666666666f777777777f10000000
1010101100009999999999999999990000000000000099000000999999999999999900001010101144444444445555555555666666666f777777777f10101010
0000000100009999444499999999990000000000000099000000999999994444999900001000000144444444445555555555666666666f777777777f10000000
1010101100009999444499999999990000000000000099000000999999994444999900001010101144444444445555555555666666666f777777777f10101010
0000000100999999444444999999999900000000990099000099999999444444999999001000000144444444445555555555666666666f777777777f10000000
1010101100999999444444999999999900000000990099000099999999444444999999001010101144444444445555555555666666666fffffffffff10101010
0000000100999999444444999999999900000000999900000099999999444444999999001000000188888888889999999999aaaaaaaaaabbbbbbbbbb10000000
1010101100999999444444999999999900000000999900000099999999444444999999001010101188888888889999999999aaaaaaaaaabbbbbbbbbb10101010
0000000100999999444444999999999999000099999900009999999999444444999999001000000188888888889999999999aaaaaaaaaabbbbbbbbbb10000000
1010101100999999444444999999999999000099999900009999999999444444999999001010101188888888889999999999aaaaaaaaaabbbbbbbbbb10101010
0000000100999999444499999999999999999999999999999999999999994444999999001000000188888888889999999999aaaaaaaaaabbbbbbbbbb10000000
1010101100999999444499999999999999999999999999999999999999994444999999001010101188888888889999999999aaaaaaaaaabbbbbbbbbb10101010
0000000100999999999999999999999999999999999999999999999999999999999999001000000188888888889999999999aaaaaaaaaabbbbbbbbbb10000000
1010101100999999999999999999999999999999999999999999999999999999999999001010101188888888889999999999aaaaaaaaaabbbbbbbbbb10101010
0000000100999999999999999999999999999999999999999999999999999999999999001000000188888888889999999999aaaaaaaaaabbbbbbbbbb10000000
1010101100999999999999999999999999999999999999999999999999999999999999001010101188888888889999999999aaaaaaaaaabbbbbbbbbb10101010
00000001009999999999999999999999999999999999999999999999999999999999990010000001ccccccccccddddddddddeeeeeeeeeeffffffffff10000000
10101011009999999999999999999999999999999999999999999999999999999999990010101011ccccccccccddddddddddeeeeeeeeeeffffffffff10101010
00000001009999999999999999999999999999999999999999999999999999999999990010000001ccccccccccddddddddddeeeeeeeeeeffffffffff10000000
10101011009999999999999999999999999999999999999999999999999999999999990010101011ccccccccccddddddddddeeeeeeeeeeffffffffff10101010
00000001000099999999999999991111999999999999999999111199999999999999990010000001ccccccccccddddddddddeeeeeeeeeeffffffffff10000000
10101011000099999999999999991111999999999999999999111199999999999999990010101011ccccccccccddddddddddeeeeeeeeeeffffffffff10101010
00000001000099999999999999111111999999999999999999111111999999999999000010000001ccccccccccddddddddddeeeeeeeeeeffffffffff10000000
10101011000099999999999999111111999999999999999999111111999999999999000010101011ccccccccccddddddddddeeeeeeeeeeffffffffff10101010
00000001000000999999999911111111999999999999999999111111119999999999000010000001ccccccccccddddddddddeeeeeeeeeeffffffffff10000000
10101011000000999999999911111111999999999999999999111111119999999999000010101011ccccccccccddddddddddeeeeeeeeeeffffffffff10101010
00000001000000999999999922222222999999999999999999222222229999999999000010000000111111111111111111111111111111111111111100000000
10101011000000999999999922222222999999999999999999222222229999999999000010101010101010101010101010101010101010101010101010101010
00000001000000009999999922222222999999999999999999222222229999999900000010000000000000000000000000000000000000000000000000000000
10101011000000009999999922222222999999999999999999222222229999999900000010101010101010101010101010101010101010101010101010101010
00000001000000009999999922222222999999999999999999222222229999999900000010001111111111111111100000444444444444444444444444400000
10101011000000009999999922222222999999999999999999222222229999999900000010111ccc1ccc1c1c1ccc111014499949494999499949994999441010
00000001000000000099999999222299999999111111999999992222999999990000000010011ccc1ccc1c1c1ccc11c004499949494999499949994999449000
10101011000000000099999999222299999999111111999999992222999999990000000010111c101c1c1c1c1c1011c014491049994919491949194090449010
00000001000000000000999999999999777777777777777777999999999999000000000010011ccc1ccc1ccc1ccc11c004499940904999494949904494449000
1010101100000000000099999999999977777777777777777799999999999900000000001011101c1c1c1ccc1c1011c014491049194910494949194494449010
00000001000000000000999999997777777722777777227777779999999900000000000010011ccc1c1c10c01ccc11c004499949094944499949494494449000
1010101100000000000099999999777777772277777722777777999999990000000000001011101010101111101011c014401040404044401040404414449010
000000010000000000000000777777777777772222227777777777770000000000000000100c11111111111111111c0009444444444444444444444444490000
1010101100000000000000007777777777777722222277777777777700000000000000001010ccccccccccccccccc01010999999999999999999999999901010
00000001000000000000000077777777777777777777777777777777000000000000000010000000000000000000000000000000000000000000000000000000
10101011000000000000000077777777777777777777777777777777000000000000000010101010101010101010101010101010101010101010101010101010
00000001000000000000000000000077777777777777777777770000000000000000000010000000000000000000000000000000000000000000000000000000
10101011000000000000000000000077777777777777777777770000000000000000000010103333333333333333301010222222222222222222222222201010
00000001000000000000000000000000000000000000000000000000000000000000000010033b333bbb3bbb3bb3330002288828222888288828882828220000
10101011000000000000000000000000000000000000000000000000000000000000000010133b333bbb3bbb3bbb33b012288828222888288828882828228010
00000001000000000000000000000000000000000000000000000000000000000000000010033b333b0b3b0b3b0b33b002280028222800280828082828228000
10101011000000000000000000000000000000000000000000000000000000000000000010133b333b3b3bbb3b3b33b012282228222888288828802828228010
00000001000000000000000000000000000000000000000000000000000000000000000010033b333b3b3b0b3b3b33b002282228222800280828082020228000
10101011000000000000000000000000000000000000000000000000000000000000000010133bbb3bbb3b3b3bb033b012288828882888282828282828228010
0000000011111111111111111111111111111111111111111111111111111111111111110003300030003030300333b002200020002000202020202020228000
101010101010101010101010101010101010101010101010101010101010101010101010101b33333333333333333b1018222222222222222222222222281010
0000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbb00000888888888888888888888888800000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
66666666666699777777666699999999777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
66666666699999997777666699999999700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
66666669999999999977666999999999700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
666666999999999997776699fff99999700999000000000000000000009990070000000000000000000000000000000000000000000000000000000000000000
666666999999999995559999fff99999709999990000000000000000099999070000000000000000000000000000000000000000000000000000000000000000
666669999999999955599999ff999999709999999000000000000000999999070000000000000000000000000000000000000000000000000000000000000000
66666999999999995599999999999999709999999900000000707009999999070000000000000000000000000000000000000000000000000000000000000000
66666999999995559999999999999999709999999990000007900799999999070000000000000000000000000000000000000000000000000000000000000000
6666595599955559999999ffff999999709944999990000000970099994499070000000000000000000000000000000000000000000000000000000000000000
666695555555559999999ffffff99999799944499999000097900799944499970000000000000000000000000000000000000000000000000000000000000000
6699955555555599fff99fffffff9999799944499999000099707999944499970000000000000000000000000000000000000000000000000000000000000000
9999599555555999ffff9fffffff9999799944499999900999009999944499970000000000000000000000000000000000000000000000000000000000000000
9999999595555999ffff99ffffff9997799944999999999999999999994499970000000000000000000000000000000000000000000000000000000000000000
9999999999555999ffff999ffff99997799999999999999999999999999999970000000000000000000000000000000000000000000000000000000000000000
99999999999559999999999999999977799999999999999999999999999999970000000000000000000000000000000000000000000000000000000000000000
99999999999959999fff999999999777799999999999999999999999999999970000000000000000000000000000000000000000000000000000000000000000
9999999999995999fffff9ffff999777799999999999999999999999999999970000000000000000000000000000000000000000000000000000000000000000
9999999999995999fffff9ffff997777709999999911999999999119999999970000000000000000000000000000000000000000000000000000000000000000
99999999999959999fff99ffff997777709999999111999999999111999999070000000000000000000000000000000000000000000000000000000000000000
99999999999959999999999fff997777700999991111999999999111199999070000000000000000000000000000000000000000000000000000000000000000
99999999999959999999999999977777700999992222999999999222299999070000000000000000000000000000000000000000000000000000000000000000
99999999999995999999999999777777700099992222999999999222299990070000000000000000000000000000000000000000000000000000000000000000
99999999999995559999999997777777700099992222999999999222299990070000000000000000000000000000000000000000000000000000000000000000
99999999999999995555999977777777700009999229999111999922999900070000000000000000000000000000000000000000000000000000000000000000
99999999999999999999577777777777700000999999777777777999999000070000000000000000000000000000000000000000000000000000000000000000
99999999999999999999777777777777700000999977772777277799990000070000000000000000000000000000000000000000000000000000000000000000
99999999999999999977777777777777700000007777777222777777000000070000000000000000000000000000000000000000000000000000000000000000
99999999999999977777777777777777700000007777777777777777000000070000000000000000000000000000000000000000000000000000000000000000
99999999999977777777777777777777700000000007777777777700000000070000000000000000000000000000000000000000000000000000000000000000
99999999999777777777777777777777700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
99999999777777777777777777777777700000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
99999997777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000d0000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
003b3b3b3b3b3b3b3b003b013b3b3b0006060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000200003f00030405063c06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000003f12131415163c06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000003f22232425263c06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000003f32333435363c06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000003f08090a0b0c3c06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000001718191a1b1c1d06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000002728292a2b2c2d06060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3a00000000000000003738391e1f202100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
003d3d3d3d3d3d3d3d0d0e0f2e2f303100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001040e076502d630386202f6101d6101a6102161023610216101f6101c6101b6101b61017610306102c6102a6103a60024610236101e61020610216102161020610206101f6101d6101c6101b6101b6101a610
0102000008330046103522037250392503b2503f2002620001200012000120001200262001120001200012003a2003f2003f2003f2003b2003b2003f2003f2003f2003b2003b2003f2003f2003f2003b2003b200
000116201f6101f6102161025610276102a6102d61030610326103361034610366103761038610396103a6103a6103c6103c6103c6103b6103a6103a610386103661036610356103561035610356103761038610
00020000270401f040170401f040170400f040160400f04007040020000100001000010000100004000010001c0001b0001900018000170001700016000160001500013000130000000000000000000000000000
000200000c040180402704018040270403404027040340403e0400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000224701c47016470104700c4700747005470034700347010630166601f6402a630376303c6203f6203f6303f6403f6403e6303d6303b63039630376203562033610326103161031610316103161033610
010800000e7701f75023730247200e7501f73023720247100e7601f74023730247100e7301f72023710107000e7101f70000700107001d7000070000700107001d70000700007000070000700007000070000700
010300001c7701f75028730247201c7501f73028720247101c7601f74028730247101c7301f72028710247001c7101f7002870024700000000000000000000000000000000000000000000000000000000000000
010800003c6103c600246100c6102b3523035235352393522b3223032235332393322b3123031235322393222b312303123530039300000000000000000000000000000000000000000000000000000000000000
01010000303503c450304103c41037340374403741037410303203c420304003c4003731037410374003740000000000000000000000000000000000000000000000000000000000000000000000000000000000
