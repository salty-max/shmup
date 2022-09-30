pico-8 cartridge // http://www.pico-8.com
version 33
__lua__


function _init()
	blinkt = 1
	t = 0
	lockout = 0
	start_screen()

	stars = {}
	init_starfield()
end

function start_screen()
	mode = "start"
	music(7)
end

function start_game()
	t = 0
	wave = 3

	next_wave()

	player = spawn_player()

	flamespr = 5

	muzzle = 0

	shoot_cd = 0
	fire_rate = 5

	score = 0
	maxlives = 3
	lives = 1

	invul = 0
	invul_duration = 60

	bullets = {}
	enemies = {}
	particles = {}
	shwaves = {}
end

function _update()
	blinkt += 1
	t += 1

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

function create_entity(x, y)
	return {
		x = x,
		y = y,
		w = 8,
		h = 8
	}
end

function spawn_bullet(x, y)
	local b = create_entity(x, y)
	b.spd = 4
	b.spr = 16
	b.w = 6
	b.h = 6
	add(bullets, b)
end

function spawn_player()
	local p = create_entity(60, 60)
	p.vx = 0
	p.vy = 0
	p.spd = 3
	p.spr = 2

	return p
end

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
	spr(s.spr, s.x, s.y, ceil(s.w / 8), ceil(s.h / 8))
end

function draw_list(l)
	for i in all(l) do
		draw_spr(i)
	end
end

function collide(a, b)
	local a_left = a.x
	local a_top = a.y
	local a_right = a.x + (a.w - 1)
	local a_bottom = a.y + (a.h - 1)

	local b_left = b.x
	local b_top = b.y
	local b_right = b.x + (b.w - 1)
	local b_bottom = b.y + (b.h - 1)
	
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
			spawn_bullet(player.x + 1, player.y - 4)
			sfx(0)
			muzzle = 5
			shoot_cd = fire_rate
		end
	end

	shoot_cd -= 1
	if shoot_cd < 0 then
		shoot_cd = 0
	end
	
	for b in all(bullets) do
		b.y -= b.spd

		if b.y < -8 then
			del(bullets, b)
		end
	end

	-- moving enemies
	for e in all(enemies) do
		e.y += e.spd
		
		e.frame += 0.2
		if flr(e.frame) > #e.anim then
			e.frame = 1
		end

		e.spr = e.anim[flr(e.frame)]

		if e.y > 128 then
			del(enemies, e)
		end
	end

	-- collision enemies x bullets
	for e in all(enemies) do
		for b in all(bullets) do
			if collide(b ,e) then
				del(bullets, b)
				e.hp -= 1
				e.flash = 2
				shwave(b.x + 4, b.y + 4)
				sparkle(e.x + 4, e.y + 4, 4, 7)

				if e.hp <= 0 then
					score += e.scr
					sfx(2)
					del(enemies, e)
					explode(e.x + 4, e.y + 4)
				else
					score += 5
					sfx(3)
				end
			end
		end
	end

	-- collision player x enemies
	if invul <= 0 then
		for e in all(enemies) do
			if collide(e, player) then
				sfx(1)
				del(enemies, e)
				explode(player.x + 4, player.y + 4, true)
				lives -= 1
				invul = invul_duration
			end
		end
	else
		invul -= 1
	end

	if (lives <= 0) then
		mode = "gameover"
		lockout = t + 30
		music(6)
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

	if mode == "game" and #enemies <= 0 then
		next_wave()
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
			music(0)
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
	if t < lockout then return end

	if not btn(4) and not btn(5) then
		btn_released = true
	end

	if btn_released then
		if btnp(4) or btnp(5) then
			start_screen()
			btn_released = false
		end
	end
end

function update_gameover()
	if t < lockout then return end
	
	if not btn(4) and not btn(5) then
		btn_released = true
	end

	if btn_released then
		if btnp(4) or btnp(5) then
			start_screen()
			btn_released = false
		end
	end
end

-->8
-- draw

function draw_game()
	draw_starfield()

	if lives > 0 then
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
	end

	for e in all(enemies) do
		if e.flash > 0 then
			e.flash -= 1
			for i = 1, 15 do
				pal(i, 7)
			end
		end

		draw_spr(e)

		pal()
	end

	draw_list(bullets)

	if muzzle > 0 then
		circfill(player.x + 3, player.y - 2, muzzle, 7)
		circfill(player.x + 4, player.y - 2, muzzle, 7)
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
	draw_game()
	rect(0, 0, 127, 127, 11)
	print_center("you win!", 48, 11)
	print_center("score "..score, 64, 12)
	print_center("press any key to continue", 80, blink())
end

function draw_gameover()
	draw_game()
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

function spawn_wave()
	if wave == 1 then
		place_enemies({
			{0,1,1,1,1,1,1,1,1,0},
			{0,1,1,1,1,1,1,1,1,0},
			{0,1,1,1,1,1,1,1,1,0},
			{0,1,1,1,1,1,1,1,1,0}
		})
	elseif wave == 2 then
		place_enemies({
			{1,1,2,2,1,1,1,2,2,1},
			{1,1,2,2,1,1,1,2,2,1},
			{1,1,2,2,1,1,1,2,2,1},
			{2,2,2,2,2,2,2,2,2,2}
		})
	elseif wave == 3 then
		place_enemies({
			{3,3,1,1,1,1,1,1,3,3},
			{3,3,0,0,1,1,0,0,3,3},
			{3,3,0,0,2,2,0,0,3,3},
			{3,3,2,2,2,2,2,2,3,3}
		})
	elseif wave == 4 then
		place_enemies({
			{3,1,1,3,1,1,3,1,1,3},
			{3,1,1,3,1,1,3,1,1,3},
			{3,2,2,3,3,3,3,2,2,3},
			{4,4,4,4,0,0,4,4,4,4}
		})
	elseif wave == 5 then
		place_enemies({
			{0,0,0,0,0,0,0,0,0,0},
			{0,0,0,0,5,0,0,0,0,0},
			{0,0,0,0,0,0,0,0,0,0},
			{0,0,0,0,0,0,0,0,0,0}
		})
	end
end

function next_wave()
	wave += 1

	if wave > 5 then
		music(4)
		mode = "win"
		lockout = t + 30
	else
		if wave == 1 then
			music(0)
		else
			music(3)
		end
		mode = "wavetext"
		wavetext_t = 60
	end
end

function spawn_enemy(etype, ex, ey)
	local e = create_entity(ex, ey)
	e.flash = 0
	e.spd = 0
	e.type = etype
	e.frame = 1
	 
	if etype == nil or etype == 1 then
		-- green alien
		e.spr = 128
		e.anim = {128, 129, 130, 131}
		e.scr = 50
		e.hp = 3
	elseif etype == 2 then
		-- hell bat
		e.spr = 136
		e.anim = {136, 137}
		e.scr = 30
		e.hp = 2
	elseif etype == 3 then
		-- rotator
		e.spr = 132
		e.anim = {132, 133, 134, 135}
		e.scr = 50
		e.hp = 3
	elseif etype == 4 then
		-- drill
		e.spr = 138
		e.anim = {138, 139}
		e.scr = 40
		e.hp = 2
	elseif etype == 5 then
		-- boss
		e.spr = 144
		e.anim = {144, 146}
		e.scr = 100
		e.hp = 5
		e.w = 16
		e.h = 16
	end

	add(enemies, e)
end

function place_enemies(wave_list)
	for y = 1, 4 do
		for x = 1, 10 do
			if wave_list[y][x] != 0 then
				spawn_enemy(wave_list[y][x], x * 12 - 6, 4 + y * 12)
			end
		end
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
09999000009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9977990009aaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a77a9009aa77aa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a77a9009a7777a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a77a9009a7777a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aa90009aa77aa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09aa900009aaaa900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00990000009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0330033000000000000000000330033000d89d00001891000018910000198100200000020200002000ff880000ff880000000000000000000000000000000000
33b33b3303b00b3003b00b3033b33b330d5115d000d515000011110000515d002200002222000022088888800888888000000000000000000000000000000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb3d51aa15d0151a11000155100011a15102222222222222222065555600766655000000000000000000000000000000000
3b7717b33b7717b33b7717b33b7717b3d51aa15d0d51a15000d55d00051a15d02822228228222282656666557655556500000000000000000000000000000000
0b7117b03b7117b33b7117b30b7117b06d5005d6065005d0006dd6000d5005602888888228888882576555765557765500000000000000000000000000000000
0037730000377300003773000037730066d00d60006d0d600066660006d0d6002878878228788782065576600576555000000000000000000000000000000000
03033030030330300303303003033030076006700066060000066000006066000888888008000080005765000065570000000000000000000000000000000000
03000030033003303000000330000003007007000007070000077000007070000800008000000000000650000005700000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000149aa94100000000012222100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00019777aa921000000029aaaa920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d09a77a949920d00d0497777aa920d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0619aaa9422441600619a77944294160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07149a922249417006149a9442244160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07d249aaa9942d7006d249aa99442d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
067d22444422d760077d22244222d770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d666224422666d00d776249942677d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
066d51499415d66001d1529749251d10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0041519749151400066151944a151660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a001944a100a0000400149a4100400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000049a400090000a0000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003455032550305502e5502b550285502555022550205501b55018550165501355011550010000f5500c5500a5500855006550055500455003550015500055000000000000000000000000000100000000
000100002b650366402d65025650206301d6201762015620116200f6100d6100a6100761005610046100361002610026000160000600006000060000600006000000000000000000000000000000000000000000
00010000377500865032550206300d620085200862007620056100465004610026000260001600006200070000700006300060001600016200160001600016200070000700007000070000700007000070000700
000100000961025620006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00060000010501605019050160501905001050160501905016050190601b0611b0611b061290001d000170002600001050160501905016050190500105016050190501b0611b0611b0501b0501b0401b0301b025
00060000205401d540205401d540205401d540205401d54022540225502255022550225500000000000000000000025534225302553022530255301d530255302253019531275322753027530275322753027530
000600001972020720227201b730207301973020740227401b74020740227402274022740000000000000000000001672020720257201b730257301973025740227401b740277402274027740277402774027740
011000001f5501f5501b5501d5501d550205501f5501f5501b5501a5501b5501d5501f5501f5501b5501d5501d550205501f5501b5501a5501b5501d5501f5502755027550255502355023550225502055020550
011000000f5500f5500a5500f5501b530165501b5501b550165500f5500f5500a5500f5500f5500a550055500a5500e5500f5500f550165501b5501b550165501755017550125500f5500f550125501055010550
011000001e5501c5501c550175501e5501b550205501d550225501e55023550205501c55026550265500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000017550145501455010550175500b550195500d5501b5500f5501c550105500455016550165500000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090d00001b0001b0001b0001d0001b0301b0001b0201d0201e0302003020040200401e0002000020000200001b7001d7001b7001b7001b7001d700227001a7001b7001b700167001b7001b7001b7001c7001c700
050d00001f5001f0001f500215001f5301f0001f52021520225302453024530245302250024500245002450000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d00002200022000220002400022030220002203024030250302703027030270302500027000270002700000000000000000000000000000000000000000000000000000000000000000000000000000000000
4d1000002b0202b0202b0202b0202b0202b0202b0202b0202b020290202b0202c0202b0202b0202b0202602026020260202702027020270202b0202b0202b0202a0302a0302a0302703027030270302003020030
4d1000002003028030280302c0302a0302a0302a0302703027030270302c0302a030290302e0302e0300000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010f00001e050000001e0501d0501b0501a0601a0621a062000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
050f00001b540070001b5401a54018540175501755217562075000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000
010c0000290502c0002a00029055290552a000270502900024000290002705024000240002400027050240002a05024000240002a0552a055240002905024000240002400029050240002a000290002405026200
510c00001431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432519325203151431519325203251431519315203251432519315203151432518325
010c00000175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750017500175001750
010c0000195502c5002a50019555195552a500185502950024500295001855024500245002450018550245001b55024500245001b5551b555245001955024500245002450019550245002a500295001855026500
010c0000290502c0002a00029055290552a000270502900024000290002000024000240352504527050240002a050240002f0052d0552c0552400029050240002400024000240002400024030250422905026200
010c0000195502c5002a50019555195552a500185502950024500295002050024500145351654518550245001b550245002f5051e5551d5552450019550245002450024500245002450014530165401955026500
010c00002c05024000240002a05529055240002e050240002400029000270502400024000240002e050240003005024000240002e0552d05524000300502400024000290002905024000270002a0002900028000
510c0000143151931520325143251931520315163251932516315183151932516325183151931516325183251b3151e315183251b3251e315183151b3251e325183151b3151d325183251b3151d315183251b325
010c00000175001750017500175001750017500175001750037500375003750037500375003750037500375006750067500675006750067500675006750067500575005750057500575005750057500575005750
010c00001d55024500245001b55519555245001e550245002450029500165502450024500245001e550245001e55024500245001d5551b555245001d5502450024500295001855024500275002a5002950028500
__music__
04 04050644
00 07084749
04 090a484a
04 0b0c0d44
00 0e084344
04 0f0a4344
04 10114e44
01 12131415
00 16131417
02 18191a1b

