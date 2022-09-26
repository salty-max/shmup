pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
function _init()
	mode = "start"
	blinkt = 1

	stars = {}
	init_starfield()
end

function start_game()
	mode = "game"

	shipx = 60
	shipy = 60
	shipvx = 0
	shipvy = 0
	shipspd = 2
	shipspr = 2

	flamespr = 5

	bullx = 60
	bully = -10
	bullspd = 4

	muzzle = 0

	score = 1664
	maxlives = 3
	lives = 1

	bullets = {}
end

function _update()
	blinkt += 1

	if mode == "game" then
		update_game()
	elseif mode == "start" then
		update_start()
	else
		update_gameover()
	end
end

function _draw()
	cls(0)
	if mode == "game" then
		draw_game()
	elseif mode == "start" then
		draw_start()
	else
		draw_gameover()
	end
end

-->8
-- tools

function create_star(x, y, spd, c)
	local s = {
		x = x,
		y = y,
		spd = spd
	}
	add(stars, s)
end

function init_starfield()
	for i = 1, 100 do
		create_star(flr(rnd(128)), flr(rnd(128)), rnd(1.5) + 0.5)
	end
end

function draw_starfield()
	for star in all(stars) do
		local c = 6
		-- color brightness based on speed
		if star.spd < 1 then
			c = 1
		elseif star.spd < 1.5 then
			c = 13
		end
		pset(star.x, star.y, c)
	end
end

function update_starfield()
	for star in all(stars) do
		star.y += star.spd

		-- if star is out of bound, delete it and create a new random one at the top
		if star.y > 128 then
			del(stars, star)
			create_star(flr(rnd(128)), 0, rnd(1.5) + 0.5)
		end
	end
end

function blink()
	local ct = {5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 7, 7, 6, 6}
	if blinkt > #ct then
		blinkt = 1
	end
	return ct[blinkt]
end

-->8
-- update
function update_game()
	shipvx = 0
	shipvy = 0
	shipspr = 2
	
	if btn(0) then
		shipvx = -shipspd
		shipspr = 1
	end
	
	if btn(1) then
		shipvx = shipspd
		shipspr = 3
	end
	
	if btn(2) then
		shipvy = -shipspd
	end
	
	if btn(3) then
		shipvy = shipspd
	end

	if btnp(4) then
		mode = "gameover"
	end
	
	-- shoot
	if btnp(5) then
		add(bullets, {
			x = shipx,
			y = shipy - 4
		})
		sfx(0)
		muzzle = 6
	end
	
	shipx += shipvx
	shipy += shipvy
	
	for bullet in all(bullets) do
		bullet.y -= bullspd

		if bullet.y < -8 then
			del(bullets, bullet)
		end
	end

	-- animate engine
	flamespr += 1

	if flamespr > 9 then
		flamespr = 5
	end

	-- muzzle flash
	if muzzle > 0 then
		muzzle -= 1
	end

	-- stars animation
	update_starfield()
	
	if shipx > 127 then
		shipx = -7
	end
	
	if shipx < -7 then
		shipx = 127
	end
	
	if shipy < -7 then
		shipy = 127
	end
	
	if shipy > 127 then
		shipy = -7
	end
end

function update_start()
	if btnp(5) then
		start_game()
	end

	update_starfield()
end

function update_gameover()
	if btnp(5) then
		start_game()
	end

	update_starfield()
end

-->8
-- draw
function draw_game()
	draw_starfield()

	spr(shipspr, shipx, shipy)
	spr(flamespr, shipx, shipy + 8)

	for bullet in all(bullets) do
		spr(16, bullet.x, bullet.y)
	end

	if muzzle > 0 then
		circfill(shipx + 3, shipy - 2, muzzle, 7)
	end

	draw_ui()

	local scoretext = "score "..score
	print(scoretext, 127 - (#scoretext * 4), 3, 12)
end

function draw_start()
	draw_starfield()
	rect(0, 0, 127, 127, 1)
	print("shmup", 52, 48, 12)
	print("press ❎ to start", 30, 80, blink())
end

function draw_gameover()
	draw_starfield()
	rect(0, 0, 127, 127, 8)
	print("game over", 46, 48, 8)
	print("press ❎ to continue", 24, 80, blink())
end

function draw_ui()
	local heartspr = 14
	for i = 1, maxlives do
		if lives < i then
			heartspr = 13
		end
		spr(heartspr, i * 9 - 7, 2)
	end
end

__gfx__
00000000000220000002200000022000000000000000000000000000000000000000000000000000000000000000000000000000088008800880088000000000
000000000028820000288200002882000000000000077000000770000007700000c77c0000077000000000000000000000000000800880088888888800000000
007007000028820000288200002882000000000000c77c000007700000c77c000cccccc000c77c00000000000000000000000000800000088888888800000000
0007700000288e2002e88e2002e882000000000000cccc00000cc00000cccc0000cccc0000cccc00000000000000000000000000800000088888888800000000
00077000027c88202e87c8e20288c72000000000000cc000000cc000000cc00000000000000cc000000000000000000000000000080000800888888000000000
007007000211882028811882028811200000000000000000000cc000000000000000000000000000000000000000000000000000008008000088880000000000
00000000025582200285582002285520000000000000000000000000000000000000000000000000000000000000000000000000000880000008800000000000
00000000002992000029920000299200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a7777a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a7777a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000038550365503555033550315502f5502c5502a550285502655024550205501e5501c550195501655014550105500e5500b550085500555002550005502450000000000000000000000000000000000000
