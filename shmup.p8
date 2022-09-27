pico-8 cartridge // http://www.pico-8.com
version 33
__lua__


function _init()
	mode = "start"
	blinkt = 1
	t = 0

	stars = {}
	init_starfield()
end

function start_game()
	t = 0
	wave = 0

	next_wave()

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

	shoot_cd = 0
	fire_rate = 5

	score = 0
	maxlives = 3
	lives = 3

	invul = 0
	invul_duration = 60

	bullets = {}
	enemies = {}
	particles = {}
	shwaves = {}
end

function _update()
	blinkt += 1

	if mode == "game" then
		update_game()
	elseif mode == "start" then
		update_start()
	elseif mode == "wavetext" then
		update_wavetext()
	elseif mode == "win" then
		update_win()
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
	elseif mode == "wavetext" then
		draw_wavetext()
	elseif mode == "win" then
		draw_win()
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

function explode(ex, ey, blue)
	add(particles, {
		x = ex,
		y = ey,
		vx = 0,
		vy = 0,
		age = 8,
		max_age = 0,
		size = 10,
		blue = blue
	})

	for i = 1, 30 do
		add(particles, {
			x = ex,
			y = ey,
			vx = (rnd() - 0.5) * 6,
			vy = (rnd() - 0.5) * 6,
			age = rnd(2),
			max_age = 10 + rnd(10),
			size = 1 + rnd(3),
			blue = blue
		})
	end

	sparkle(ex, ey, 20, 6)

	big_shwave(ex, ey)
end

function page_red(age)
	local c = 7

	if age > 5 then
		c = 10
	end
	if age > 7 then
		c = 9
	end
	if age > 10 then
		c = 8
	end
	if age > 12 then
		c = 2
	end
	if age > 15 then
		c = 5
	end

	return c
end

function page_blue(age)
	local c = 7

	if age > 5 then
		c = 6
	end
	if age > 7 then
		c = 12
	end
	if age > 10 then
		c = 13
	end
	if age > 12 then
		c = 1
	end
	if age > 15 then
		c = 1
	end

	return c
end

function shwave(swx, swy)
	add(shwaves, {
		x = swx,
		y = swy,
		c = 9,
		r = 3,
		max_r = 6,
		spd = 1 -- spread speed
	})
end

function big_shwave(swx, swy)
	add(shwaves, {
		x = swx,
		y = swy,
		c = 6,
		r = 3,
		max_r = 25,
		spd = 3.5 -- spread speed
	})
end

function sparkle(sx, sy, sn, sc)
	for i = 1, sn do
		add(particles, {
			x = sx,
			y = sy,
			vx = (rnd() - 0.5) * 10,
			vy = (rnd() - 0.5) * 10,
			c = sc,
			age = rnd(2),
			max_age = 10 + rnd(10),
			size = 1 + rnd(3),
			blue = blue,
			spark = true
		})
	end
end

function print_center(s, y, c, custom_x)
	local x = 64
	if custom_x then
		x = custom_x
	end
	print(s, x - ((#s / 2) * 4), y, c)
end

-->8
-- update

function update_game()
	t += 1
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
	if btn(5) then
		if shoot_cd <= 0 then
			add(bullets, {
				x = player.x,
				y = player.y - 4,
				spd = 4,
				spr = 16
			})
			sfx(0)
			muzzle = 6
			shoot_cd = fire_rate
		end
	end

	shoot_cd -= 1
	if shoot_cd < 0 then
		shoot_cd = 0
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

	-- collision enemies x bullets
	for enemy in all(enemies) do
		for bullet in all(bullets) do
			if collide(bullet ,enemy) then
				del(bullets, bullet)
				enemy.hp -= 1
				enemy.flash = 2
				shwave(bullet.x + 4, bullet.y + 4)
				sparkle(enemy.x + 4, enemy.y + 4, 4, 3)

				if enemy.hp <= 0 then
					score += enemy.scr
					sfx(2)
					del(enemies, enemy)
					explode(enemy.x + 4, enemy.y + 4)

					if #enemies <= 0 then
						next_wave()
					end
				else
					score += 5
					sfx(3)
				end
			end
		end
	end

	-- collision player x enemies
	if invul <= 0 then
		for enemy in all(enemies) do
			if collide(enemy, player) then
				sfx(1)
				del(enemies, enemy)
				explode(player.x + 4, player.y + 4, true)
				lives -= 1
				invul = invul_duration

				if #enemies <= 0 then
					next_wave()
				end
			end
		end
	else
		invul -= 1
	end

	if (lives <= 0) then
		mode = "gameover"
	end

	if btnp(4) then
		mode = "gameover"
	end

	-- engine animation
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
	update_starfield()
	if not btn(4) and not btn(5) then
		btn_released = true
	end

	if btn_released then
		if btnp(4) or btnp(5) then
			start_game()
			btn_released = false
		end
	end
end

function update_wavetext()
	update_game()

	wavetext_t -= 1

	if wavetext_t <= 0 then
		mode = "game"
		spawn_wave()
	end
end

function update_win()
	update_starfield()
	if not btn(4) and not btn(5) then
		btn_released = true
	end

	if btn_released then
		if btnp(4) or btnp(5) then
			mode = "start"
			btn_released = false
		end
	end
end

function update_gameover()
	update_starfield()

	if not btn(4) and not btn(5) then
		btn_released = true
	end

	if btn_released then
		if btnp(4) or btnp(5) then
			mode = "start"
			btn_released = false
		end
	end
end

-->8
-- draw

function draw_game()
	draw_starfield()

	if invul <= 0 then
		draw_spr(player)
		spr(flamespr, player.x, player.y + 8)
	else
		-- blinking when invulnerable
		if sin(t / 5) < 0 then
			draw_spr(player)
			spr(flamespr, player.x, player.y + 8)
		end
	end

	for enemy in all(enemies) do
		if enemy.flash > 0 then
			enemy.flash -= 1
			for i = 1, 15 do
				pal(i, 7)
			end
		end
		draw_spr(enemy)
		pal()
	end

	draw_list(bullets)

	if muzzle > 0 then
		circfill(player.x + 3, player.y - 2, muzzle, 7)
	end

	draw_shwaves()
	draw_explosions()

	draw_ui()

	local scoretext = "score "..score
	print(scoretext, 127 - (#scoretext * 4), 3, 12)
end

function draw_start()
	draw_starfield()
	rect(0, 0, 127, 127, 1)
	print_center("shmup", 48, 12)
	print_center("press any key to start", 80, blink())
end

function draw_wavetext()
	draw_game()
	print_center("wave "..wave, 48, blink())
end

function draw_win()
	draw_starfield()
	rect(0, 0, 127, 127, 11)
	print_center("you win!", 48, 11)
	print_center("score "..score, 64, 12)
	print_center("press any key to continue", 80, blink())
end

function draw_gameover()
	draw_starfield()
	rect(0, 0, 127, 127, 8)
	print_center("game over", 48, 8)
	print_center("press any key to continue", 80, blink())
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

function draw_explosions()
	for p in all(particles) do
		local pc = 7

		if p.blue then
			pc = page_blue(p.age)
		else
			pc = page_red(p.age)
		end

		if p.spark then
			pset(p.x, p.y, p.c)
		else
			circfill(p.x, p.y, p.size, pc)
		end

		p.x += p.vx
		p.y += p.vy

		-- apply friction
		p.vx *= 0.85
		p.vy *= 0.85

		p.age += 1

		if p.age > p.max_age then
			p.size -= 0.5
			if p.size <= 0 then
				del(particles, p)
			end
		end
	end
end

function draw_shwaves()
	for sw in all(shwaves) do
		circ(sw.x, sw.y, sw.r, sw.c)
		sw.r += sw.spd
		if sw.r > sw.max_r then
			del(shwaves, sw)
		end
	end
end

-->8
-- waves and enemies

function spawn_enemy(ex, ey)
	add(enemies, {
		x = ex,
		y = ey,
		spd = 1,
	  spr = 21,
		hp = 2,
		scr = 30,
		flash = 0
	})
end

function spawn_wave()
	spawn_enemy(flr(rnd(120)), -8)
end

function next_wave()
	wave += 1

	if wave > 4 then
		mode = "win"
	else
		mode = "wavetext"
		wavetext_t = 60
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
00000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000099900000000005555550505000000005050550000000000500000000000000000000000000000000000000000000000000000000
00000000070000000000999999900000050055222222500000050055555250000000000555050000000000000000000000000000000000000000000000000000
00070000000007000009aaaaaaaa9900005022888888250000505555885555500000000550055000000000000000000000000000000000000000000000000000
0000770aaa900000009aaaa777aaa990005288899998825000555222985555000000000000055000000000000000000000000000000000000000000000000000
0000007777aa0000009aaaa7777aaa9005228999aaa9825000225552222585000005550000000550000000000000000000000000000000000000000000000000
00000a7777770700009aa777777aaa0000228a9a7aa9822500522522222885500005550000055550000000000000000000000000000000000000000000000000
0000a7777777a000099aa7777777aa00052889a777a9882500555229552888500000500000555550000000000000000000000000000000000000000000000000
000097777777a00009aaa7777777aa9005289aa77aa9882000059229928285500000000000555500000000000000000000000000000000000000000000000000
000007777777a00009aaa7777777aa9000289aaaaaa9885000559528855225000000000550555500000000000000000000000000000000000000000000000000
00770777777a7000009aaa77777aaa900058899a9999885000558958529985500000000550000000000000000000000000000000000000000000000000000000
000000777aa007000099aaaaaaaaa900005588999988225000555259528825500550000000000000000000000000000000000000000000000000000000000000
000070000000000000099aaaaaa99900005528888222250000052525825255000555550000555500000000000000000000000000000000000000000000000000
00000007007000000000999aa9999000000055522250550000005555555550000555555000555500000000000000000000000000000000000000000000000000
00000000007000000000000999000000000050555005505000005550500500000005500000555000000000000000000000000000000000000000000000000000
__sfx__
000100002f5302d5302a5302653024520215201f5201d5201b520185201652014520125200f5200d5200b52009510075100551004510025100051000510005100050000500025000150000500005000050000500
000100002e6502b65025650226501f6401c64019640166401363012630106300e6300c6200b620096200662004610026100161000610006000060000600026000260001600006000060000600006000060000600
000100002b7300d63026730186300b720046200272001720007100063000600006300000000630000000063000000006302170000630000000063000000006300000000000000000000000000000000000000000
000100000d63026640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
