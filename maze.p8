pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--maze
--by @nlordell

root=nil
function state(x,...)
	x:init(...)
	root=x
end

function _init()
	state(sscreen)
--	state(maze,{
--		size=16,
--		zoom=0x0.2,
--	})
end

function _update()
	root:update()
end

function _draw()
	root:draw()
--debug info
--	print(""..(stat(1)*100).."%",
--		1,1,3)
end
-->8
--start screen

sscreen={
	difs={
		{" easy ", 8,0x0.1},
		{"normal",16,0x0.2},
		{"~hard~",24,0x0.4},
		{" hard ",32,0x0.4},
		{"expert",64,0x0.8},
	},

	dif=function(s)
		local d=s.difs[s.sel+1]
		return {
			label=d[1],
			size=d[2],
			zoom=d[3],
		}
	end,

	init=function(s)
		s.sel=1
		--remove all menu items
		for i=1,5 do
			menuitem(i)
		end
	end,

	update=function(s)
		if(btnp(⬅️)) s.sel-=1
		if(btnp(➡️)) s.sel+=1
		s.sel%=#s.difs
		
		if btnp(❎) or btnp(🅾️) then
			state(maze,s:dif())
		end
	end,

	draw=function(s)
		cls()
		--todo: we can make the start
		--      screen prettier...
		print("\^w\^tmaze",44,42,7)
		print("difficulty",16,84,7)
		local l=s:dif().label
		print("⬅️ \f9"..l.."\f7 ➡️",
			70,84,7)
	end,
}
-->8
--maze game

maze={
	v=0.125,

	init=function(s,o)
		gen_kruskal(o.size)
		mset(0,0,mget(0,0)|0x10)
		s.x=0
		s.y=0
		s.dx=0
		s.dy=0
		s.e=o.size-2
		s.z=o.zoom
		menuitem(1,"restart",
			function() s:reinit() end)
	end,

	reinit=function(s)
		s.x=0
		s.y=0
		s.dx=0
		s.dy=0
		for i=0,63 do
			for j=0,63 do
				mset(i,j,mget(i,j)&0xef)
			end
		end
		mset(0,0,mget(0,0)|0x10)
	end,

	update=function(s)
		if s.dx==0 and s.dy==0 then
			local x,y=s.x,s.y
			if x==s.e and y==s.e then
				state(win)
				return
			end
			if(btn(⬅️)) x-=1
			if(btn(➡️)) x+=1
			if(btn(⬆️)) y-=1
			if(btn(⬇️)) y+=1
			--only allow one direction
			y=x~=s.x and s.y or y
			if x~=s.x or y~=s.y then
				local m,f=
					(mget(
						max(x,s.x),
						max(y,s.y))-1)&3,
					x~=s.x and 2 or 1
				if	m&f~=0 then
					s.dx=s.x-x
					s.dy=s.y-y
					s.x=x
					s.y=y
					--todo:highlight path
					mset(x,y,mget(x,y)|0x10)
				else
					s.dx=(x-s.x)*s.v
					s.dy=(y-s.y)*s.v
					--todo: play bump sound
				end
			end
		else
			s.dx=s.dx>=0
				and max(s.dx-s.v,0)
				or  min(s.dx+s.v,0)
			s.dy=s.dy>=0
				and max(s.dy-s.v,0)
				or  min(s.dy+s.v,0)
		end
	end,

	draw=function(s)
		cls()
		for y=0,127 do
			tline(0,y,127,y,
				0,y*s.z,s.z,0)
		end
	
		local d=1/s.z
		local x,y,e=
			(s.x+s.dx)*d,
			(s.y+s.dy)*d,
			s.e*d
		sspr(0,0,8,8,x,y,d,d)
		sspr(0,8,8,8,e,e,d,d)
	end,
}
-->8
--maze generation

function gen_rcrsvbktrckr(n)
	local m,v=n-1,{}
	for i=0,m do
		for j=0,m do
			local t=1
			if(i==m)t+=1
			if(j==m)t+=2
			mset(i,j,t|((i==m or j==m)
				and 0 or 0x10))
		end
	end
	function c(x,y)
		mset(x,y,mget(x,y)&0xef)
		local ds=
			{{1,0},{-1,0},{0,1},{0,-1}}
		while #ds>0 do
			local i=flr(rnd(#ds))+1
			local xx,yy=
				x+ds[i][1],y+ds[i][2]
			deli(ds,i)
			if
				mget(xx,yy)&0x10~=0
				and xx>=0 and xx<m
				and yy>=0 and yy<m
			then
				local mx,my=
					max(x,xx),max(y,yy)
				mset(mx,my,mget(mx,my)+
					(x==xx and 1 or 2))
				c(xx,yy)
			end
		end
	end
	c(0,0,0)
end

function gen_kruskal(n)
	local walls={}
	local cells={}
	local m=n-1
	for i=0,m do
		for j=0,m do
			if i<m and j<m then
				local c=i+j*n
				add(cells,{[c]=true})
				if(i<m-1)add(walls,{c,c+1})
				if(j<m-1)add(walls,{c,c+n})
			end
			local t=1
			if(i==m) t+=1
			if(j==m) t+=2
			mset(i,j,t)
		end
	end
	function join(wall)
		local a,b=wall[1],wall[2]
		local sa,sb
		foreach(cells,function(s)
			if(s[a]) sa=s
			if(s[b]) sb=s
		end)
		if(sa[b]) return
		for c,_ in pairs(sb) do
			sa[c]=true
			sb[c]=false
		end
		local ax,ay,bx,by=
			a%n,a\n,b%n,b\n
		local mx,my=
			max(ax,bx),max(ay,by)
		mset(mx,my,mget(mx,my)+
			(ax==bx and 1 or 2))
	end
	while #walls>0 do
		local i=flr(rnd(#walls))+1
		local wall=walls[i]
		deli(walls,i)
		join(wall)
	end
end

-->8
--win screen

win={
	init=function(s)
		print("\^w\^t\#0\fcwin",
			53,59)
	end,

	update=function(s)
		if btnp(❎) or btnp(🅾️) then
			state(maze,sscreen:dif())
		end
	end,

	draw=function(s)
	end,
}
__gfx__
00000000ffffffffffff2222ffffffffffff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff2222ffffffffffff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff2222ffffffffffff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff2222ffffffffffff22220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999ffff2222ffff222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999ffff2222ffff222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999ffff2222ffff222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00009999ffff2222ffff222222222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff1111ffffffffffff11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff1111ffffffffffff11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff1111ffffffffffff11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffff1111ffffffffffff11110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b33bffff1111ffff111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003bb3ffff1111ffff111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003bb3ffff1111ffff111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000b33bffff1111ffff111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
