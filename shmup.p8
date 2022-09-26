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

	player = {
		x = 60,
		y = 60,
		vx = 0,
		vy = 0,
		spd = 2,
		spr = 3
	}

	flamespr = 5

	muzzle = 0

	score = 1664
	maxlives = 3
	lives = 3

	bullets = {}
	enemies = {}
	local enemy = {
		x = 60,
		y = 5,
		spr = 21,
		spd = 1
	}
	add(enemies, enemy)
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

function draw_spr(s)
	spr(s.spr, s.x, s.y)
end

function draw_list(l)
	for i in all(l) do
		draw_spr(i)
	end
end

function collide(a, b)
	local a_left = a.x
	local a_top = a.y
	local a_right = a.x + 7
	local a_bottom = a.y + 7

	local b_left = b.x
	local b_top = b.y
	local b_right = b.x + 7
	local b_bottom = b.y + 7
	
	if a_left > b_right or b_left > a_right or a_top > b_bottom or b_top > a_bottom then
		return false
	end

	return true
end

-->8
-- update

function update_game()
	player.vx = 0
	player.vy = 0
	player.spr = 2
	
	if btn(0) then
		player.vx = -player.spd
		player.spr = 1
	end
	
	if btn(1) then
		player.vx = player.spd
		player.spr = 3
	end
	
	if btn(2) then
		player.vy = -player.spd
	end
	
	if btn(3) then
		player.vy = player.spd
	end

	player.x += player.vx
	player.y += player.vy

	if player.x > 127 then
		player.x = -7
	end
	
	if player.x < -7 then
		player.x = 127
	end

	if player.y < 0 then
		player.y = 0
	end
	
	if player.y > 120 then
		player.y = 120
	end
	
	-- shoot
	if btnp(5) then
		add(bullets, {
			x = player.x,
			y = player.y - 4,
			spd = 4,
			spr = 16
		})
		sfx(0)
		muzzle = 6
	end
	
	for bullet in all(bullets) do
		bullet.y -= bullet.spd

		if bullet.y < -8 then
			del(bullets, bullet)
		end
	end

	-- moving enemies
	for enemy in all(enemies) do
		enemy.y += enemy.spd
		enemy.spr += 0.2
		if enemy.spr >= 26 then
			enemy.spr = 21
		end
		if enemy.y > 128 then
			del(enemies, enemy)
		end
	end

	for enemy in all(enemies) do
		if collide(enemy, player) then
			sfx(1)
			del(enemies, enemy)
			lives -= 1
		end
	end
	
	for enemy in all(enemies) do
		for bullet in all(bullets) do
			if collide(bullet ,enemy) then
				del(bullets, bullet)
				del(enemies, enemy)
				score += 10
			end
		end
	end

	if (lives <= 0) then
		mode = "gameover"
	end

	if btnp(4) then
		mode = "gameover"
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

	draw_spr(player)
	spr(flamespr, player.x, player.y + 8)

	draw_list(enemies)

	draw_list(bullets)

	if muzzle > 0 then
		circfill(player.x + 3, player.y - 2, muzzle, 7)
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
00999900000000000000000000000000000000000330033000000000000000000330033003300330000000000000000000000000000000000000000000000000
09aaaa900000000000000000000000000000000033b33b3303b00b3003b00b3033b33b3333b33b33000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000003bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb3000000000000000000000000000000000000000000000000
9a7777a9000000000000000000000000000000003b7717b33b7717b33b7717b33b7717b33b7717b3000000000000000000000000000000000000000000000000
9a7777a9000000000000000000000000000000000b7117b03b7117b33b7117b30b7117b00b7117b0000000000000000000000000000000000000000000000000
9aa77aa9000000000000000000000000000000000037730000377300003773000037730000377300000000000000000000000000000000000000000000000000
09aaaa90000000000000000000000000000000000303303003033030030330300303303003033030000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000300003003300330300000033000000303000030000000000000000000000000000000000000000000000000
__sfx__
0001000038550365503555033550315502f5502c5502a550285502655024550205501e5501c550195501655014550105500e5500b550085500555002550005502450000000000000000000000000000000000000
000100002e6502b65025650226501f6401c64019640166401363012630106300e6300c6200b620096200662004610026100161000610006000060000600026000260001600006000060000600006000060000600
