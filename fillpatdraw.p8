pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
function _init()

cartdata('fillpatgen_02')
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
--subview=mkrectq('0 0 128 48')
spritearea=mkrectq('0 0 128 128')
--spritearea_w=mkrectq('1 1 128 128')
canvas=mkrectq('8 8 64 64')
canvas.pix=tablefill(0,32,32)
canvas.upd=true
--palette=mkrectq('80 8 40 40')
--palette.upd=true
--palsel=mkrectq('79 7 11 11')
playbtn=mkrectq('70 36 20 9')
playbtn.cnt=0
playbtn.stp=1
playbtn.wait=6
playbtn.mx=0
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
piecesrect.l=1

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

local spos=getsprpos(mouse.x,mouse.y)
local srect=selectrect
local prect=piecesrect
if confirm and playbtn.cnt==0 then
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
elseif menuwin.enable and playbtn.cnt==0 then
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
if playbtn.cnt==0 then 
selectrecttool()
end
end

if presskey=="\t" and playbtn.cnt==0 then
menuwin.enable=not menuwin.enable
end
if playbtn.cnt>0 then
 if presskey=="\t" then playbtn.cnt=0 fillp()
 elseif mouse.lt then playbtn.cnt+=playbtn.wait-(playbtn.cnt%playbtn.wait) playbtn.stp=0
 elseif mouse.rt then playbtn.cnt+=playbtn.mx-playbtn.wait-(playbtn.cnt%playbtn.wait)+1 playbtn.stp=0
 elseif presskey==' ' then playbtn.stp=playbtn.stp==0 and 1 or 0
 end
 if playbtn.mx>0 then playbtn.cnt=(playbtn.cnt%playbtn.mx)+playbtn.stp
 else playbtn.cnt+=playbtn.stp
 end
end



end

function _draw()

-- play fillpat draw --
if playbtn.cnt>0 then
 cls()
 local f=fillpat.draw(flr(playbtn.cnt/playbtn.wait)+1,0,0)
 if playbtn.mx==0 then
  if f then
   playbtn.mx=(flr(playbtn.cnt/playbtn.wait))*playbtn.wait-1
   playbtn.cnt=1 fillpat.draw(flr(playbtn.cnt/playbtn.wait)+1,0,0)
  end
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
local h=srect.h
local w=srect.w
local rowlen=flr(spritearea.w/w)

if prect.enable then
local frect=mkrect(srect.x-1,srect.y-1,srect.w-2,srect.h-2)
for i=1,prect.l do
 y=flr((i+prect.x-1)/rowlen)+prect.y
 x=(i+prect.x-1)%(rowlen)
 rect(x*w,y*h+1,x*w+1,y*h,7)
 rect((x+1)*w-1,y*h+1,(x+1)*w-2,y*h,6)
 rect(x*w,(y+1)*h-1,x*w+1,(y+1)*h-2,6)
 rect((x+1)*w-1,(y+1)*h-1,(x+1)*w-2,(y+1)*h-2,13)
// local anm=flr((prect.fls/4)%(prect.w*prect.h))
 local anm=flr((prect.fls/4)%(prect.l))
 anm=(anm-i+1+prect.l)%prect.l
-- if anm<4 and anm>=0 and x<prect.w and y<prect.h then
 if anm<4 and anm>=0 then
 frect.x=(x)*srect.w+1
 frect.y=(y)*srect.h+1
 frect.draw(({15,14,8,2})[(anm%4)+1])
 end
end
x=prect.x 
y=prect.y
ex=prect.l>0 and prect.ex or prect.x
ey=prect.l>0 and prect.ey or prect.y+1

local ul=prect.l+x>rowlen and rowlen-x or prect.l
local dl=(prect.l-ul-1)%rowlen+1
if prect.h<2 then
rect(x*w,y*h,ex*w-1,h*ey-1,8)
else
color(8)
line(x*w,y*h,x*w,(y+1)*h)
line(x*w,y*h,(x+ul)*w-1,y*h)
line((x+ul)*w-1,y*h,(x+ul)*w-1,(ey-1)*h)
line(0,(y+1)*h,x*w-1,(y+1)*h)
line(ex*w,(ey-1)*h,(x+ul)*w-1,(ey-1)*h)
line(0,(y+1)*h,0,(ey)*h-1)
line(0,(ey)*h-1,dl*w-1,ey*h-1)
line(dl*w-1,ey*h-1,dl*w-1,(ey-1)*h)
end
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
print('…patterns :'..(prect.l)..'',30,45,7)
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
if selectrect.enable then
 if mouse.lut then
 srect.x=srect.w<0 and srect.ex or srect.x
 srect.y=srect.h<0 and srect.ey or srect.y
 srect.w=abs(srect.w)+8
 srect.h=abs(srect.h)+8
 srect.refresh()
 selectrect.enable=false
 piecesrect.enable=true
 return
 elseif mouse.rt then
 srect.enable=false
 return
 end
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
  prect.l=1
  if mouse.rt then
  prect.enable=false
  end
 elseif mouse.rt then
  prect.fls=0
  prect.l=1
  prect.w=1
  prect.h=1
  prect.refresh()
  return
 elseif mouse.lt then
  prect.fls=1
 elseif mouse.l and prect.fls>0 then
  prect.w=spos.x-prect.x+1
  prect.h=spos.y-prect.y+1
  if prect.w*srect.w>spritearea.w then
  prect.w=flr(spritearea.w/srect.w)
  end
  if prect.h*srect.h>spritearea.h then
  prect.h=flr(spritearea.h/srect.h)
  end
  prect.l=spos.x-prect.x+1+((spos.y-prect.y)*flr(spritearea.w/srect.w))
  prect.l=prect.l<0 and 0 or prect.l
  prect.refresh()
  prect.fls+=1
 elseif mouse.lut and prect.fls>0 then
 --confirm
 prect.enable=not (prect.l>0)
 srect.enable=false
 confirm=prect.l>0
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
 + block in pat    : 2*2~32*32
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
local bl=prect.l
local rl=flr(spritearea.w/srect.w)
local liblen=3
setmaquee('pickuping patterns...',1,5)
local log=""
for b=1,bl do
by=(prect.y+flr((prect.x+b-1)/rl))*path
bx=(prect.x+b-1)%rl*patw
pat[b]={}
log=log..' '..by..""
if bx==0 then 
log=log.."\n"
end
for cv=1,15 do
pat[b][cv]={}
for cy=1,path do
pat[b][cv][cy]={}
for cx=1,patw do
local p=patterns(cx+bx,cy+by,cv)
add(pat[b][cv][cy],p)

end
end
end
end
--vdmp({log})

setmaquee('to unique patterns...',1,5)
local upt
for b in all(pat) do
for cv in all(b) do
 upt=uniquepat(cv,upt)
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
for b,blk in pairs(pat) do
pid[b]={}
for cv,ct in pairs(blk) do
pid[b][cv]={}
for y,row in pairs(ct) do
pid[b][cv][y]={}
for x,p in pairs(row) do
 for i,v in pairs(upt) do
  if v==p then pid[b][cv][y][x]=i end
 end
end
end
end
end
//local btext={}
setmaquee('join codes...',1,5)
local btext=''
for b,blk in pairs(pat) do
for cv,ct in pairs(blk) do
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
--btext=btext.."\n-cv: "..cv.."- "..join(bt,"")
end--cv
end--b

--printh(btext,'btext',true)

setmaquee('compressing code...',1,5)
local ztext=''
local rt=''
local pre=sub(btext,1,liblen)
local c=1
local i=0
btext=sub(btext,liblen+1)
while #pre>0 do
local t=sub(btext,1,liblen)
btext=sub(btext,liblen+1)
if pre==t and c<255 then c+=1
else
c=tohex(c)
c=#c<2 and '0'..c or c
ztext=ztext..pre..c.."" c=1
end
pre=t

end
--until #btext==0
--ztext=ztext..pre..c
//ztext=sub(ztext,1,#ztext)
//vdmp({ztext,t})
local text='--replace fillpatdata--'.."\n"
..'fillpat={d='.."\n"
..'-- col-pid data --'.."\n"
.."[[\n"..join({#pat,#pat[1][1],#pat[1][1][1],join(upt,'')},' ')..' '..ztext.."\n]]\n"
--.."[[\n"..join({#pat*#pat[1],#pat[1][1][1],#pat[1][1][1][1],join(upt,'')},' ')..' '..ztext.."\n]]\n"
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
 d=sub(d,2)
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
local f=(tonum('0x'..sub(d,1,3))-1)*4
local m=tonum('0x'..sub(d,4,5))
d=sub(d,6)
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
if d==nil then
vdmp({(dd%w),(flr(dd/w)%h)})
end
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
4 16 16 ffffffc0c100fff0ffec000083778801e888c0017ffc8000ffe117c0fe012480c0002666f800f0008888fe00fcc8ff4384211013ffe8ff00e00031111011c80042213771eeeeefff00ffb7fffffcecc81133fcb73fc3ff0fff3c000177ffeeddceff01e03c00e100087337ffdbbbfffe7777ffe0b1138fff7ffff77fff9fec93fc00f1008f73fe807000ff61ec8080c83333fecc33776aa86667ffd1c888a800777f7333e8cec420ffd6177f88cce8cfce003777ff3108cfe01b00edd3f7bffdc088ff104622ff91ff80e6c0ecefe88f000fe00ffeefff73c88d01ff0eff118cfff7ff17ceef7733fec80017fc803000bbbbe5110133feee078608667376bfff1000ffefccc800345330ee404013800818ce8808feb9088c01760880013788ef19df8ccf003f16ece934eeefff778cff17fbfeffe00cb399e733117ff773dcefff70feedfff9ffe49337988ff60f100fc00f001fc0ff01eff00f800f913fc211c8800013017f3bfffffdffeef733d113eeffff8e9bb9fdfefddddeeff7bdfffb77bbf79efff3cffc734eff1ff771bdef937fffdf46ef8b77cdddffb733557b8fce0ff30fe81f30ffc1efc80f593ff3700037e00193e836883266fff8137f0008e007f8130ffc0ff01cf7f39cfedbe1fc3ff0fff5880060007eefbfecebffe0f717ffb77788cff7cefe470f001ff7ff40fe88ffd3c600988cf001ff9708ce80137100e40003ce0846000680885ab90033f70012fef00cf201fbff1377013f3667b3ffffcedbb9fefbf830f310f3fe37feeeec8001cccc337ee21010ffff4223313773008ff3defe9787fef7f064227bdebbf73ffeec000422ff3388dfcfe33008f300e63311ff816cfeececccffe2ffeb7773b110cceee222fff2fe07fa803310e023ecce4ef19000fecfff30cfff0bff08ef8cf733bb813371183337133388928ccc777eeceeccae000a7013ceee23100003c16f7da5773b007b03ffef8c40001023dcceeff1fefdb37701cffdffa000837fdfff377f7f77493b3bbbbbfffedffff1113effdbff7bbfdebdde1fff54eefc0fc1cff130e800f013cc20ec8881378422e2336cc8d111d00dff0e023f3ffffc970fffdb77ddbbbbb76eecfff4acc8e4ec1110ffe3f017088ec008e137e0084e71008cccf37ffe007e7110f3370120fbbb377484ce00c099989dff630003eefda1f7fff71383f3e80c11371008ef71fec0300fffc2ffa1eeae035380123133abdfdbffff71eef013ff9ffff3f7dddef77bdeff736f97ff56efddddf777e80f 001130020100301004030010a00501006040070100101008010010800901006020010100a0100b010010a00c01006010010100d0100e010010b006010010100f01010010010c006010110101201001060130101401001050150100105002010010200c01011010010b0060101401016010140100109017010180100101006010010c0190101a010010101b0101c010010201d0101e010010a00c010060100c0101d010060101f010010402001021010010400c0100601011010010100601022010010302301006020010d024010250102601001ff001ff001ff0012302701001040280100605029010010302a0102b0102c0202d0100101015010060402e0102f010010203001024010010503101032010330103401035010360100103037010010703801016010140101c0100104039010010900c01006010010803a0101c010010d01601006010010e01101006010010f006010014b03a0103b010010e03c0103d010012a0380103e010010c03f0100401040010010b03a0104101042010430100109027010440101d0102e010010b0020100c010060404501046010010704701001010480100601001030110100601049010010403801023010010104a01006010010500c0104b010010304c0101d0104d0104e0104f0100601001040500100c010510100103015010040105201053010540100601001020550100101016010560100104057010060101e0100101058010060105901014010020101d010060105a01001050060205b010010105c0105d0105e01006010010105f01060010010506101006020620100103063010640100108006040650100401066010060103a0100107067010060800c0100107041010060400c010060300107068010690106a01069010010206b01069020012c038010020101c0106c010010c06d0106e0106f01070010710100107027010720100101038010040200101073010740100106075010760102f0107701006030780107101079010010407a010010107b010010107c010060307d0107e0107f010800100104081010820104901001010830108401006020850108601087010010508801001010890106c0108a0108b0108c0108d0108e0108f01001060900100102091010920101c010200109301094010950100105096010970100103098010990109a0109b0100601036010010609c010010609d0109e01001070960109f010010f0a0010a101001060a201001080a30100103075010a401041010a50104a0106401001060a6010a7010a8010a9010aa010ab010ac010ad010ae010af01001ff001ff001ff001ff0012900501041010b00103d010010b0050100c010060104b010010c0b101006010b2010010d006010b3010010e05a010010e02301001080380106c010010603d01001150b401001130b5010010b0b6010b701001020b8010010b0b90103601001a00ba01097010010b027010010303d010010b0bb01001010bc01001070b501001010bd010010d0be0107101024010bf01001020c0010010a0c10100101024010c2010c301039010010a0be0107101001020c4010c501001030c6010c701001060c8010040103a010c901001010ca01001030cb0106c01001060cc010cd010010303901001010ce010b6010cf01001060d0010d1010d20102c010d3010d4010d50102c010d6010d701001ff001ff0010e03a0101403062010010301b01016010d801001010a3010010300c01001060380100c01006030d9010010a0090100602001010da0102f010010a01101006010010100d010db010010b0060200f010dc010010c00601011010dd010010604101014010010501501001050de010010200c020010b00c010140103a010140100109075010180100101006020010b019010df010010101b0101c010010201d0101e010010a00c010060100c0101d010060101f010010402001021010010400c010060101101001010060102201001040e0010e101001ff001ff001ff00139005010e2010e3010e4010e5010e601001030e7010e8010e9010a1010ea01001020eb010ec0100604001020a2010ed010ee01001020ef0100101023010060300101011010060100102037010010701d0100602014010f0010f101001020f2010010900601014010010803a0101c010010d03a0100c010010e01101006010010f006010013b027010c3010010e0f30109e01001570f4010140100601078010f501001080de01041010810100101034010f6010f7010010701b010110100604042010f801001070f9010b20104801006020010200c0100601049010010507c010b20104a01006010010500c0104b010010304c010010104d0104e0104f0100601001040130100c0105101001030150101c0105201053010540100601001020fa0100101016010560100104057010060101e010010105801006010fb01001010040101d010060105a01001050060205b010010105c0105d0105e01006010010105f01060010010506101006020620100103063010640100108006040650100401066010060103a0100107067010060800c0100107041010060400c010060300107068010690106a01069010010206b01069020013c0fc010fd010420101c010710100107038010fe0100104024010ff010740100106005011000102f010770101101006021010107101079010010410201001011000103d0107c0100603103011040107f010800100104006010820104901001010830110501006020850108601087010010510601001010890106c0108a011070108c011080108e0108f01001060310100102091010920110901011010690110a01095010010509601097010010309801099010010110b0100601036010010609c010010609d0109e01001070960109f010010f0a0010a101001060a201001080a30100103075010a401041010a50104a0106401001060a6010a7010a8010a9010aa010ab010ac010ad010ae010af01001ff001ff001ff001ff00129005010410110c0110d010010b0b60100c010060110e010010c02801006010b20103d010010c0eb0110f010010e110010010e02301001080380106c010010603d010011511101001130b5010010b0b6010b701001020b8010010b0b90103601001a011201097010010b038010010303d010010b113010010111401001070b501001010bd010010d0be0107101024010bf01001020c0010010a0c10100101024010c2010c301039010010a0be0107101001020c4010c501001030c6010c701001060c8010040103a010c901001010ca01001030cb0106c01001060cc010cd010010303901001010ce010b6010cf01001060d0010d1010d20102c010d3010d4010d50102c010d6010d701001ff001ff0010f002010130101401062010010403a0111501001050b101006020010100c0100103005010060411601001010b60100602001060b101006020110102e010930111701047010060100106038010060203a0100a01118010010a11901006010010111a01118010010b11b01006010160111c0100107004010010411b0100101011010010701101006010010601101001030160100601001010270100c01001080270101801001010110100c0100101006010010911d0111e01001050020101e01001040270111f0100104011010060100c01016010060101f010010400c01120010010400c010060101d020060112101001041220110d01001ff001ff001ff0013d09a0112301001041240112501126010710100104005010eb01006011270100103030010010303c0112801001020b601011010060300103129010010512a0103a0112b01006020110100103082010010804101014010010112c010e10100117016010010e01d01006010010e011010013b0050112d010010e12e010f1010015b0f9010010d12f011300100601001070380104401011010060113101004010010113201133010010603801020010060612d010010603801020011340100601001040880104b010010313501001010c001136011370100c01001041380101c01139010010311b010060113a0113b0113c01006010010313d0103a0113e011110100104006020010105801006010010113f01027010160100c0104b0100105088010060114001001010ff0106501041010060100c01141010600100105142010060211601001010f2010010114301064010010808801006030650107101001010810100108067010060501d01006021440100107041010060800107068010690106a01069010010214501069020013b038010040103a01146010c3010010c147011480114901006010b7010010a0de0101c01042010620114a0114b010010403a0114c01001010f90105101075010060414d0108001001040110114e010b60114f010750100604036011500107101001030bd011510115201153010490108a0107b011540100601155011560106e0103d010010315701031010010209101092011580103a011590115a0115b0103e010010515c01001030a00115d0115e0115f01160011610100106162010710100105163010b301080010010715c010010f0a0010a1010010616401001080a301001030750103a0104101165011350106401001060a6010a7010a8010a901069010ab01166010ad010ae010af01001ff001ff001ff001ff0012a167010010e0750116801078011690116a010010a0050100c010b20116b010010c04f010060116c010010d1000116d010010d0240116e0116f010012417001001130b5010010c17101001020b8010010b0b90117201001b9038010010617301001080960107101001020240102f0102401001070b901174010010117501001020c0010010a1760100102128010c301039010010a0240117401001020c4010c501001010380106b010040106c01001060c8010040103a010c901001010ca0117701001021780109701001060cc010cd010010309f0100101097010b6010cf01001060d0010d1010d20102c01179010d40117a0102c010d6010d701001ff001ff0011703a0117b01004010010c17c010060417d0103d01001030050101d010060100102038010060303a0108f010010517e0100601004010010217f01006020020118001001071810100601001020b101006010410108f010010818201006010010200c010060100a01183010010503801065010010501501001011840100103038010040100101011010060100105015010010103a010010301101006010270101c010010c00c020010c18501186010270100401001020160101e010010a00c010060100c010160100601184010010401101187010010400c010060101d010010100601121010010418801001ff001ff001ff00143038011890118a0102c010040100101071010010918b010010418a01001060de0100102096010010b09a010e0010010218c0100108006010140101c0100101098010010218d0100104038010010a039010010303a01011010010a18e010010301101006010010e01101001c003801044010110100601042010620118f01001080770111a0100603001010060212d0100106028010b20119001006010010400c0104b010010313501001010c001015011370100c01001041910101601074010010304f0100601192010730101d010060100102193010010103a011940103d01001030090100602001010670100601001011600102701041010060104b01001050060214001001011950115901196010060100101197010800100105198010060211601001031990106401001080880100603065010010103a0100601004010c3010010606701006081440100107041010060601101006010010706801069010a901069010010214501069020013b03801002010410101401146010010c147010010118a0119a010740100109038010410100c01006010420119b0114b010010403a0100101038010e20119c01020010060202e0119d0119e0108001001040060119f0111b01121010830102e010e0010060114001005011a00109701001031a10115101001010960101e0108a011a2011a3010b2011a4010b20118a01001041a50103101001021a601092011a70117c01159011a8011a9011aa0100104142011ab0100103098011ac01188011ad01006011ae01001061af0107101001051b0010b301001070b90115c010010f0a0010a1010010603001001080a301001031b10103a010130114e011350106401001060a6010a7011b2010ae010aa010ab01166010ad010ae010af01001ff001ff001ff001ff0012a167011b3011b4010010c07501168010b2010010c0b60100c010d90103d010010c1b5011b6010010e1b7011b8010010d024011b9010b401001070b5010011c1ba010011f038011bb010010104a0114e010010b1bc011bd01001a1038010010f1be0100107038010010302701001010ca011bf01001061a1010010109601071010010202401001091c0010010217501001020c30100109024011c10100102128010c301039010010a1c20117401001020c4011c30100401001010b90102c011c101001060c8010040103a011c401001010ca01001031c50109701001060cc011c60100102038011c701001010ce01038010cf01001060d0010d1010d20102c010d3010d40117a0102c011c8010d701001ff001ff00103
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
 d=sub(d,2)
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
local f=(tonum('0x'..sub(d,1,3))-1)*4
local m=tonum('0x'..sub(d,4,5))
d=sub(d,6)
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
if d==nil then
vdmp({(dd%w),(flr(dd/w)%h)})
end
rectfill(xx,yy,xx+3,yy+3,flr(dd/(w*h))%15+1)
end
end
return false
end
}


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
