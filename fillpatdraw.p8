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
savebtn=mkrectq('75 52 20 10')
exptbtn=mkrectq('97 52 28 10')
loadbtn=mkrectq('75 65 20 10')
cleabtn=mkrectq('97 65 28 10')

cprect=nil

mousestate={l=0,r=0,m=0,stx=0,sty=0}
keystate=''
premouse=getmouse()
mouse=getmouse()
currentcel={x=-1,y=-1,fls=0}

corout=nil
--spritestore

selectrect=mkrectq('0 0 1 1')
selectrect.fls=0
selectrect.enable=false
piecesrect=mkrectq('0 0 1 1')
piecesrect.enable=false
piecesrect.fls=0

//stop()
setcol(7)

end
function _update60()
poke(0x5f2d,1)
premouse.x=mouse.x
premouse.y=mouse.y
mouse=getmouse()
updatekey()
presskey=getkey()

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
 if not mouse.l then
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
 end
end

end

function _draw()

-- sprite sheet only mode --
if viewsprite then
cls()
palt(0,false)
spr(0,0,0,16,16)
palt()

//fillp(0x9009)
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
local ex=prect.w>=0 and (prect.ex+1)-1 or (srect.ex)+1
local ey=prect.h>=0 and (prect.ey+1)-1 or (srect.ey)+1
x=prect.w>=0 and prect.x or (prect.x+1)-2
y=prect.h>=0 and prect.y or (prect.y+1)-2
rect(x*srect.w,y*srect.h,srect.w*ex-1,srect.h*ey-1,8)

 for y=0,prect.h do
 local oy
 if y==prect.h then
 oy=2
 elseif y==0 then
 oy=0
 else
 oy=1
 end
 for x=0,prect.w do
 local ox
 if x==prect.w then
 ox=2
 elseif x==0 then
 ox=0
 else
 ox=1
 end
 local anm=flr((prect.fls/4)%(prect.w*prect.h))
 if anm<x+(y*prect.w)+4 and anm>=x+(y*prect.w) and ox<2 and oy<2 then
 rect(x*srect.w-ox,y*srect.h-oy,(1+x)*srect.w-ox-1,(1+y)*srect.h-oy-1,15)
 else
 rect(x*srect.w-ox,y*srect.h-oy,x*srect.w-ox+1,y*srect.h-oy+1,7)
 end
 end
 end
end
print((prect.w)*srect.w,00,90,7)
x=mouse.x-2
y=mouse.y-2
pset(x,y,7)
pset(x+4,y,7)
pset(x,y+4,7)
pset(x+4,y+4,7)
 print(mouse.x..' '..mouse.y,0,0)

//rect(mouse.x,mouse.y,mouse.x+3,mouse.y+3,7)
//spr(1,mouse.x-4,mouse.y-4)

return
end

fillp(0xf5f5)
rectfill(0,0,128,128,1)
fillp(0x0000)
--spriteatea--
palt(0,false)
spr(0,0,80-subview.y,16,16)
palt()
rect(view.x,view.y+80-subview.y,view.ex-1,view.ey+79-subview.y,7)
map(0,0,0,0,16,16)
palt(0,false)
palette_draw()
palt(0,true)

--canvas draw--

fillp(0x1a4a)
canvas.draw(1,true)
fillp(0x0000)

local ofx=0
local ofy=0
local ofw=0
local ofh=0
local vx=view.x
local vy=view.y
if vx<0 then
ofx=-vx
vx=0
end
if vy<0 then
ofy=-vy
vy=0
end
if view.ex>spritearea_w.ex then
//ofw=-vx
ofw=view.ex-spritearea_w.ex+1
ofx=ofw
end
if view.ey>spritearea_w.ey then
//ofh=-vy
ofh=view.ey-spritearea_w.ey+1
ofy=ofh
end

palt(0,false)
sspr(vx,vy,32-ofx,32-ofy,8+((ofx-ofw)*2),8+((ofy-ofh)*2),64-(ofx*2),64-(ofy*2))
//sspr(vx,vy+32,32-ofx,32-ofy,8+((ofx-ofw)*2),8+((ofy-ofh)*2),64-(ofx*2),64-(ofy*2))
palt()


if corout and costatus(corout)~='dead' then
 coresume(corout)
// return
else
 corout=nil

 --cell flash--
 if mouse.r==false and canvas.contp(mouse.x,mouse.y) then
  local ccel=currentcel
  local x=((ccel.x-1)*8)-(view.x%4)*2
  local y=((ccel.y-1)*8)-(view.y%4)*2
  if ccel.fls>0 then
  rect(x,y,x+7,y+7,({13,13,5,5,1,1})[ccel.fls])
  ccel.fls-=1
  end
 end


 if mouse.r==false then
// pal(1,0)
 pal(7,({7,8,13,2})[flr(pget(mouse.x,mouse.y)/4)%4+1])
 pal(2,colsel)
 palt(1,true)
 else
 palt(2,true)
 palt(7,true)
 pal(1,7)
 end
 
 spr(1,mouse.x-4,mouse.y-4)
 pal()
 if isdebug then
 color(7)
 print(mouse.x..' '..mouse.y,0,0)
 print(view.x..' '..view.y,30,0)
 print(panhold,60,0)
 local p=canvaspos(mouse.x,mouse.y)
 print(p.x..' '..p.y,72,0)
// print(history.current,80,0)
// print(#history.pages,90,0)
 local celpos=pos2cel(flr((mouse.x-canvas.x+2)/2)+(view.x%4),flr((mouse.y-canvas.y+2)/2)+(view.y%4))
 print(patterns(celpos.x,celpos.y),98,0)
 local cols=patcols(celpos.x,celpos.y)
 print(tohex(cols[2])..tohex(cols[1]),118,0)
 end

--[[
cls()
rectfill(0,0,128,128,1)
--fillp(0xfcfc)
--rectfill(0,0,3,3,0x67)
fillpat.draw(1,40,40)
]]

end

 if keystate==' ' then
 spr(17,mouse.x-4,mouse.y-4)
 else
 end

local cx=canvas.x
local cy=canvas.y

if maqueetext and costatus(maqueetext)~='dead' then
coresume(maqueetext)
else maqueetext=nil
end

end

function setview(x,y)
view.x=x
view.y=y
view.refresh()
if view.y-4<subview.y then
subview.y=view.y-4
end
if view.ey>spritearea.h then
subview.y=spritearea.h-subview.h+4
elseif view.ey-subview.y>subview.h-4 then
subview.y=view.ey-subview.h+4
end
subview.refresh()
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
 sub(a,#a-1,#a)
return a
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
function palette_draw()
spr(2,palette.x,palette.y,5,4)
spr(8,palette.x,palette.y+32,5,1)
palsel.draw(15)
//selcol
end

function palettemouse(mouse)
local w=palette.w
local h=palette.h

local x=mouse.x-palette.x
local y=mouse.y-palette.y
setcol(flr(x/10)+flr(y/10)*4)
end

function setcol(col)
color(col)
//stop(col)
colsel=col
palsel.x=(col%4)*10+palette.x-1
palsel.y=flr(col/4)*10+palette.y-1
end

function canvaspset(mouse,premouse)

local h=mouse.y-premouse.y
local w=mouse.x-premouse.x
local l=sqrt(h*h+(w*w))
local th=atan2(h,w)
local iswrite=false

l=l==0 and 1 or l

for i=1,l,1 do
 local px=ceil(((sin(th)*i)+premouse.x-canvas.x)/2)+1+view.x
 local py=flr(((cos(th)*i)+premouse.y-canvas.y)/2)+1+view.y
 
 if spritearea_w.contp(px,py) and canvas.contp(mouse.x,mouse.y) then
  local prec=getsprpix(px,py)
  local c=pos2cel(px,py)
  recordcells(c.x,c.y,getpatcel(c.x,c.y))
  psetsprram(px,py,colsel)
  iswrite=true
--cell start:1~
  if #patcols(c.x,c.y)>2 then
--  start:1~
  swappatcol(prec,colsel,c.x,c.y)
  end
 end
end
return iswrite
end

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

function swappatcol(from,to,cx,cy)
local cw=4
local ch=4
local pat=getpatcel(cx,cy)
cy-=1
cx-=1
pat.each(function(p,x,y,o)
 if p==from then
 local x=cx*cw+x
 local y=cy*ch+y
 psetsprram(x,y,to)
 end
end)
end

hexkey='0123456789abcdef'
function patterns(cx,cy)
local pat=getpatcel(cx,cy)
local cols={}
--local ex=''
local pats=''
local row=''
pat.each(function(p,x,y)
if #cols==0 then add(cols,p)
elseif #cols==1 and cols[1]~=p then add(cols,p)
end
row=row..tostr(p~=cols[1] and 1 or 0)
if x==4 then
 local hx=tonum('0b'..row)+1
 pats=pats..sub(hexkey,hx,hx)
 row=''
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

function fillcanvas(col,sx,sy,r,b)
local gp
b=(b==nil) and getsprpix(sx,sy) or b
if r.contp(sx-1,sy-1)==false or spritearea.contp(sx-1,sy-1)==false then return end
gp=getsprpix(sx,sy)
if gp==b and gp~=col then
p=pos2cel(sx,sy)
recordcells(p.x,p.y,getpatcel(p.x,p.y))
psetsprram(sx,sy,col)
fillcanvas(col,sx,sy-1,r,b)
fillcanvas(col,sx,sy+1,r,b)
fillcanvas(col,sx-1,sy,r,b)
fillcanvas(col,sx+1,sy,r,b)
end
end

function cpcanvas(from,to)
if from==nil or to==nil then return end
local p={}
local s={}
local fm=band(from.x,1)==1
local tm=band(to.x,1)==1
for y=0,from.h-1 do
for x=0,from.w-1 do
local pos=pos2cel(to.x+x,to.y+y)
recordcells(pos.x,pos.y,getpatcel(pos.x,pos.y))
end
end
for y=0,from.h-1 do
for x=0,from.w-8,8 do
local pos=getmempos(from.x+x,from.y+y)
if pos then
 add(p,fm
  and 
 rotr(bor(
 band(peek4(pos),0xffff.fff0)
 ,lshr(band(peek(pos+4),0x0f),16)
 ),4)
  or
 peek4(pos))
end
end
end

for y=0,from.h-1 do
for x=0,from.w-8,8 do
local pos=getmempos(to.x+x,to.y+y)
if pos then
 pos=getmempos(to.x+x,to.y+y)
 if pos then
  if tm then
  poke4(pos,bor(band(peek4(pos),0x0000.000f),shl(p[1],4)))
  poke(pos+4,bor(band(peek4(pos+4),0xf0),lshr(band(p[1],0xf000.0000),12)))
  else
  poke4(pos,p[1])
  end
 end
end
del(p,p[1])
end
end
end

function lcanvas(r)
local p
local s
for y=0,r.h-1 do
s=shl(band(peek4(getmempos(r.x,r.y+y)),0x0000.000f),28)
for x=r.w-8,0,-8 do
local pos=getmempos(r.x+x,r.y+y)
p=peek4(pos)
poke4(pos,bor(lshr(p,4),s))
s=shl(band(p,0x0000.000f),28)
end
end
end
function rcanvas(r)
local p
local s
for y=0,r.h-1 do
s=lshr(band(peek4(getmempos(r.x+r.w-8,r.y+y)),0xf000.0000),28)
for x=0,r.w-8,8 do
local pos=getmempos(r.x+x,r.y+y)
p=peek4(pos)
poke4(pos,bor(shl(p,4),s))
s=lshr(band(p,0xf000.0000),28)
end
end
end
function ucanvas(r)
local h=r.h
local s={}
for x=0,r.w-8,8 do
add(s,peek4(getmempos(r.x+x,r.y)))
end
for y=0,h-2 do
memcpy(getmempos(r.x,y+r.y),getmempos(r.x,y+1+r.y),r.w/2)
end
for x=0,r.w-8,8 do
poke4(getmempos(r.x+x,h-1+r.y),s[1])
del(s,s[1])
end
end
function dcanvas(r)
local h=r.h
local s={}
for x=0,r.w-8,8 do
add(s,peek4(getmempos(r.x+x,r.y+h-1)))
end
for y=h-2,0,-1 do
memcpy(getmempos(r.x,y+r.y+1),getmempos(r.x,y+r.y),r.w/2)
end
for x=0,r.w-8,8 do
poke4(getmempos(r.x+x,r.y),s[1])
del(s,s[1])
end
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
function undo()
if history.current>0 then
history.current-=1
else
return
end
local h=history.pages[history.current+1]
attachcels(h)
local t=tablefill('●',#history.pages)
if history.current>0 then
t[history.current]='★'
end
setmaquee('undo: '..join(t,''),6,5)

end
function redo()
local h=history.pages[history.current+1]
attachcels(h)
history.current+=(history.current<#history.pages and 1 or 0)
local t=tablefill('●',#history.pages)
if history.current>0 then
t[history.current]='★'
end
setmaquee('redo'..join(t,''),2,15)

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
sethistory(getrecord())
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
 + block in pat    : 8x8 pat
 + block size      : 4x3 block
 + 1 file pix size : 128*96 pix
 + format like
  - ppccppcc...ppcc ppccppcc..
  - llllllll... (4char delimit)
  
* -p- pattern index*
 + index data      : 00~ff
 + maxpatten num   : 256
 
* -c- color data   *
 + color raw value : 0~f
 + 2 color value   : 00~ff

* - - new line     *
 
* pattern liblary  *
 + raw pattern     : 0000~ffff
 + reffer from -p- pattern index

]]
function exporttxt(name,txt)
local pat={}
local col={}
local patw=8
local path=8
local blkw=4
local blkh=3

for by=1,blkh do
pat[by]={}
col[by]={}
for bx=1,blkw do
pat[by][bx]={}
col[by][bx]={}
for cy=1,path do
pat[by][bx][cy]={}
col[by][bx][cy]={}
for cx=1,patw do
local c=patcols(cx+((bx-1)*patw),cy+((by-1)*path))
local p=patterns(cx+((bx-1)*patw),cy+((by-1)*path))
add(pat[by][bx][cy],p)
local hx=tohex(shl(c[2],4)+c[1])
hx=#hx<2 and '0'..hx or hx

add(col[by][bx][cy],hx)
end
end
end
end

local upt
for by in all(pat) do
for bx in all(by) do
 upt=uniquepat(bx,upt)
end
end

local pid={}
for by,blky in pairs(pat) do
pid[by]={}
for bx,blkx in pairs(blky) do
pid[by][bx]={}
for y,row in pairs(blkx) do
pid[by][bx][y]={}
for x,p in pairs(row) do
 for i,v in pairs(upt) do
  if v==p then pid[by][bx][y][x]=i end
 end
end
end
end
end

local btext={}
for by,blky in pairs(pat) do
for bx,blkx in pairs(blky) do
local bt={}
for y,row in pairs(blkx) do
for x,p in pairs(row) do
for i,id in pairs(upt) do
i=tohex(i)
i=#i<2 and '0'..i or i
if p==id then
add(bt,col[by][bx][y][x]..i) end
end
end
end
add(btext,bt)
end
end

local text='--replace fillpatdata--'.."\n"
..'fillpat={cpi='.."\n"
..'-- col-pid data --'.."\n"
.."[[\n"..join(btext,'',"\n").."]]\n"
..',pat='.."\n"
..'-- pat data --'.."\n"
.."[[\n"..join(upt,'').."\n]]\n"
.."\n"
..[[
,draw=function(i,x,y)
local o=fillpat
local pr=flr(i/12)
local c=0
local s=1
if pr==0 then pr=1
else repeat
if sub(o.pat,s,s)=="\n" then c+=1
if c==pr then pr=s+1 end
end
s+=1
until #o.pat<s or (c==pr and pr==s+1)
end
for cy=1,8 do
for cx=1,8 do
local row=(i*256)+i
local fx=shl(band(cx-1,7),2)
local fy=shl(cy-1,5)
local clpi=sub(o.cpi,row+fx+fy+1,row+fx+fy+4)
local idp=shl(tonum('0x'..sub(clpi,3,4))-1,2)
fillp(tonum('0x'..sub(o.pat,idp+pr,idp+pr+3)))
local xx=(cx-1)*4+x
local yy=(cy-1)*4+y
rectfill(xx,yy,xx+3,yy+3,tonum('0x'..sub(clpi,1,2)))
end
end
fillp()
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
fillpat={cpi=
-- col-pid data --
[[
660196029603790497059602f90699016601960799015908590999019f0a9901960b950c590d950ef90ff9079f10990199015911591295139f14f9109f15791699019901990195139f179f189f19791a990199019901951b591c9901791d7701990199019901791e790b751a770177019901791e791577017701770177017701
901e901f000100010001000190209021901999019022000190239002901a09199007942409119025902690274907092490139428990199019901990149040929902a9901192b99019901192c1921092d901109219225191e191f292e922f0927000190307931273227339734090a000100010001701107350735072800010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001d036d02900010d130001000100010001d036d02900010d130001000100010001d037d01100010d1a0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
00010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001071a0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
0001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001
]]
,pat=
-- pat data --
[[
0000001307ff300000c8000e377700077ec013ff003f48861fff133700ef310010007310777700f801ff1137008f44ce33337fff7b8f000f137f0001000c0003000808ce0002311100092acc377f3fff11117331037f067711337773777f330003ff021002c073000fff22222000
]]

,draw=function(i,x,y)
local o=fillpat
local pr=flr(i/12)
local c=0
local s=1
if pr==0 then pr=1
else repeat
if sub(o.pat,s,s)=="\n" then c+=1
if c==pr then pr=s+1 end
end
s+=1
until #o.pat<s or (c==pr and pr==s+1)
end
for cy=1,8 do
for cx=1,8 do
local row=(i*256)+i
local fx=shl(band(cx-1,7),2)
local fy=shl(cy-1,5)
local clpi=sub(o.cpi,row+fx+fy+1,row+fx+fy+4)
local idp=shl(tonum('0x'..sub(clpi,3,4))-1,2)
fillp(tonum('0x'..sub(o.pat,idp+pr,idp+pr+3)))
local xx=(cx-1)*4+x
local yy=(cy-1)*4+y
rectfill(xx,yy,xx+3,yy+3,tonum('0x'..sub(clpi,1,2)))
end
end
fillp()
end
}


__gfx__
0000000000000000000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff0003300030003030300333b0
0000000000001000000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000b33333333333333333b00
0070070000070700000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff0000bbbbbbbbbbbbbbbbb000
0007700000701070000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000000000000000000000000
0007700001012101000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000000000000000000000000
0070070000701070000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000000000000000000000000
0000000000070700000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000000000000000000000000
0000000000001000000000000011111111112222222222333333333300000000ccccccccccddddddddddeeeeeeeeeeffffffffff000000000000000000000000
00000000001771700000000000111111111122222222223333333333100000001111111111111111111111111111111111111111000000000000000000000000
00000000177177170000000000111111111122222222223333333333100000000000000000000000000000000000000000000000000000000022222222222222
00000000177717174444444444555555555566666666667777777777100000000000000000000000000000000000000000000000000000000228882822288828
00000000017777774444444444555555555566666666667777777777100000000000000000000000000000000000000000000000000000000228882822288828
00000000011777774444444444555555555566666666667777777777100011111111111111111000004444444444444444444444444000000228002822280028
0000000017177777444444444455555555556666666666777777777710011ccc1ccc1c1c1ccc1100044999494949994999499949994400000228222822288828
0000000017777777444444444455555555556666666666777777777710011ccc1ccc1c1c1ccc11c0044999494949994999499949994490000228222822280028
0000000001777770444444444455555555556666666666777777777710011c001c0c1c1c1c0011c0044900499949094909490940904490000228882888288828
0000000000000000444444444455555555556666666666777777777710011ccc1ccc1ccc1ccc11c0044999409049994949499044944490000220002000200020
222222222220000044444444445555555555666666666677777777771001100c1c0c1ccc1c0011c0044900490949004949490944944490000822222222222222
8828882828220000444444444455555555556666666666777777777710011ccc1c1c10c01ccc11c0044999490949444999494944944490000088888888888888
882888282822800044444444445555555555666666666677777777771001100010101101100011c0044000404040444000404044044490000000000000000000
082808282822800088888888889999999999aaaaaaaaaabbbbbbbbbb100c11111111111111111c00094444444444444444444444444900000000000000000000
882880282822800088888888889999999999aaaaaaaaaabbbbbbbbbb1000ccccccccccccccccc000009999999999999999999999999000000000000000000000
082808202022800088888888889999999999aaaaaaaaaabbbbbbbbbb100000000000000000000000000000000000000000000000000000000000000000000000
282828282822800088888888889999999999aaaaaaaaaabbbbbbbbbb100000000000000000000000000000000000000000000000000000000000000000000000
202020202022800088888888889999999999aaaaaaaaaabbbbbbbbbb100000000000000000000000000000010000000010000000111111111000000010000001
222222222228000088888888889999999999aaaaaaaaaabbbbbbbbbb100033333333333333333000000000010000000010000000000000001000000010000001
888888888880000088888888889999999999aaaaaaaaaabbbbbbbbbb10033b333bbb3bbb3bb33300000000010000000010000000000000001000000010000001
000000000000000088888888889999999999aaaaaaaaaabbbbbbbbbb10033b333bbb3bbb3bbb33b0000000010000000010000000000000001000000010000001
000000000000000088888888889999999999aaaaaaaaaabbbbbbbbbb10033b333b0b3b0b3b0b33b0000000010000000010000000000000001000000010000001
000000000000000088888888889999999999aaaaaaaaaabbbbbbbbbb10033b333b3b3bbb3b3b33b0000000010000000010000000000000001000000010000001
0000000000000000ccccccccccddddddddddeeeeeeeeeeffffffffff10033b333b3b3b0b3b3b33b0000000010000000010000000000000001000000010000001
0000000000000000ccccccccccddddddddddeeeeeeeeeeffffffffff10033bbb3bbb3b3b3bb033b0000000011111111110000000000000001000000010000001
66666666666699777777666699999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666699999997777666699999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666669999999999977666999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
666666999999999997776699fff99999000999000000000000000000009990000000000000000000000000000000000000000000000000000000000000000000
666666999999999995559999fff99999009999990000000000000000099999000000000000000000000000000000000000000000000000000000000000000000
666669999999999955599999ff999999009999999000000000000000999999000000000000000000000000000000000000000000000000000000000000000000
66666999999999995599999999999999009999999900000000000009999999000000000000000000000000000000000000000000000000000000000000000000
66666999999995559999999999999999009999999990000000900099999999000000000000000000000000000000000000000000000000000000000000000000
6666595599955559999999ffff999999009944999990000000900099994499000000000000000000000000000000000000000000000000000000000000000000
666695555555559999999ffffff99999099944499999000090900999944499900000000000000000000000000000000000000000000000000000000000000000
6699955555555599fff99fffffff9999099944499999000099000999944499900000000000000000000000000000000000000000000000000000000000000000
9999599555555999ffff9fffffff9999099944499999900999009999944499900000000000000000000000000000000000000000000000000000000000000000
9999999595555999ffff99ffffff9997099944999999999999999999994499900000000000000000000000000000000000000000000000000000000000000000
9999999999555999ffff999ffff99997099999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000
99999999999559999999999999999977099999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000
99999999999959999fff999999999777099999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000
9999999999995999fffff9ffff999777099999999999999999999999999999900000000000000000000000000000000000000000000000000000000000000000
9999999999995999fffff9ffff997777009999999911999999999119999999900000000000000000000000000000000000000000000000000000000000000000
99999999999959999fff99ffff997777009999999111999999999111999999000000000000000000000000000000000000000000000000000000000000000000
99999999999959999999999fff997777000999991111999999999111199999000000000000000000000000000000000000000000000000000000000000000000
99999999999959999999999999977777000999992222999999999222299999000000000000000000000000000000000000000000000000000000000000000000
99999999999995999999999999777777000099992222999999999222299990000000000000000000000000000000000000000000000000000000000000000000
99999999999995559999999997777777000099992222999999999222299990000000000000000000000000000000000000000000000000000000000000000000
99999999999999995555999977777777000009999229999111999922999900000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999577777777777000000999999777777777999999000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999999777777777777000000999977772777277799990000000000000000000000000000000000000000000000000000000000000000000000
99999999999999999977777777777777000000007777777222777777000000000000000000000000000000000000000000000000000000000000000000000000
99999999999999977777777777777777000000007777777777777777000000000000000000000000000000000000000000000000000000000000000000000000
99999999999977777777777777777777000000000007777777777700000000000000000000000000000000000000000000000000000000000000000000000000
99999999999777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999777777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999997777777777777777777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
003b3b3b3b3b3b3b3b003b3b3b3b3b0006060606060606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
