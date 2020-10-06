pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--a table containing all game entities
entities = {}

function canwalk(x, y)
	return not fget(mget(x/8, y/8), 7)
end

--returns true or false based on if two entities are touching or not
function touching(x1, y1, w1, h1, x2, y2, w2, h2)
	return
	x1 + w1 > x2 and
	x1 < x2 + w2 and
	y1 + h1 > y2 and
	y1 < y2 + h2
end

--creates and returns a new position component
function newposition(x, y, w, h)
	local p = {}

	p.x = x
	p.y = y
	p.w = w
	p.h = h

	return p
end

--takes the x, y coordinates of the sprite's position within the sprite sheet
--each sprite is 8x8, so grabbing 2nd sprite on sprite sheet would be 8, 0
function newsprite(x, y)
	local s = {}

	s.x = x
	s.y = y

	return s
end

--creates and returns a new control component
function newcontrol(left, right, up, down, input)
	local c = {}

	c.left = left
	c.right = right
	c.up = up
	c.down = down
	c.input = input

	return c
end

--creates and returns a new intention component
function newintention()
	i = {}

	i.left = false
	i.right = false
	i.up = false
	i.down = false

	return i
end

--creates and returns a new entity component
function newentity(position, sprite, control, intention)
	local e = {}

	e.position = position
	e.sprite = sprite
	e.control = control
	e.intention = intention

	return e
end

--player input is based on the current button being pressed
--anytime a button is being pressed, updates ent's intention property to true and then false when button is released
function playerinput(ent)
	ent.intention.left = btn(ent.control.left)
	ent.intention.right = btn(ent.control.right)
	ent.intention.up = btn(ent.control.up)
	ent.intention.down = btn(ent.control.down)
end

controlsystem = {}
controlsystem.update = function()
	for ent in all(entities) do
		--every frame, the control system is checking the entities table for entities that have non-nil control/intention properties
		--updates the entity's control.input property with the current entity being controlled
		if ent.control ~= nil and ent.intention ~= nil then
			ent.control.input(ent)
		end
	end
end

physicssystem = {}
physicssystem.update = function ()
	for ent in all(entities) do

		local newx = ent.position.x
		local newy = ent.position.y

		--every frame, the physics system is checking the entities table for entities that have non-nil intention properties and updating the entity's position based on the (movement) intention direction
		if ent.position ~= nil and ent.intention ~= nil then
			if ent.intention.left then newx -= 1 end
			if ent.intention.right then newx += 1 end
			if ent.intention.up then newy -= 1 end
			if ent.intention.down then newy += 1 end
		end

		local canmovex = true
		local canmovey = true

		--
		--map collisions
		--

		--subtracting 1 from the sprite width & height is because the w/h values start at 0
		--update x position if allowed to move
		if not canwalk(newx, ent.position.y) or
			not canwalk(newx, ent.position.y + ent.position.h - 1) or
			not canwalk(newx + ent.position.w - 1, ent.position.y) or
			not canwalk(newx + ent.position.w - 1, ent.position.y + ent.position.h - 1) then
			canmovex = false
		end

		--update y position if allowed to move
		if not canwalk(ent.position.x, newy) or
			not canwalk(ent.position.x, newy + ent.position.h - 1) or
			not canwalk(ent.position.x + ent.position.w - 1, newy) or
			not canwalk(ent.position.x + ent.position.w - 1, newy + ent.position.h - 1) then
			canmovey = false
		end

		--
		--entity collisions
		--

		--check x
		for otherentity in all(entities) do
			--x1, y1, w1, h1, x2, y2, w2, h2
			if otherentity ~= ent and touching(newx, ent.position.y, ent.position.w, ent.position.h, otherentity.position.x, otherentity.position.y, otherentity.position.w, otherentity.position.h) then
				canmovex = false
			end
		end

		--check y
		for otherentity in all(entities) do
			--x1, y1, w1, h1, x2, y2, w2, h2
			if otherentity ~= ent and touching(ent.position.x, newy, ent.position.w, ent.position.h, otherentity.position.x, otherentity.position.y, otherentity.position.w, otherentity.position.h) then
				canmovey = false
			end
		end

		if canmovex then ent.position.x = newx end
		if canmovey then ent.position.y = newy end
	end
end

graphicsystem = {}
graphicsystem.update = function()
	cls()
	--every frame, center camera on player sprite
	camera(
		-64 + player.position.x + (player.position.w / 2),
		-64 + player.position.y + (player.position.h / 2)
	)
	--every frame, draw the map
	map()

	--every frame, draw all sprite entities at their specified position coordinates
	for ent in all(entities) do
		if ent.sprite ~= nil and ent.position ~= nil then
			sspr(
				ent.sprite.x, ent.sprite.y,
				ent.position.w, ent.position.h,
				ent.position.x, ent.position.y
			)
		end
	end

	camera()

	--(for testing purposes) crosshair sprite
	--spr(16, 64-4, 64-4)
end

--(for testing purposes) converts anything to string, even nested tables
function tostring(any)
	if (type(any)~="table") return tostr(any)
	
	local str = "{"

	for k,v in pairs(any) do
		if (str~="{") str=str..","
		str="\n"..str..tostring(k).."="..tostring(v)
	end

  return str.."}"
end

function _init()
	--creates a player entity
	player = newentity(
		--creates a position component and adds sprite to the coordinates on the map
		newposition(56, 56, 8, 8),
		--create a sprite component
		newsprite(8, 0),
		--creates a control component
		newcontrol(0, 1, 2, 3, playerinput),
		--creates a intention component
		newintention()
	)

	--add player to entities list
	add(entities, player)

	--creates a tree entity
	add(entities,
		newentity(
			--creates a position component and adds sprite to the coordinates on the map
			newposition(40, 40, 8, 8),
			--create a sprite component
			newsprite(120, 8),
			--creates a control component
			nil,
			--creates a intention component
			nil
		)
	)
end

function _update60()
	--checks player input
	controlsystem.update()
	--moves entities
	physicssystem.update()
end

function _draw()
	--every frame, draws all graphics to the screen
	graphicsystem.update()
end
__gfx__
00000000007000600000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
00000000007777700000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
000000000071ff100000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
00000000bb7ffff00000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
00000000bcbcccc00000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
00000000fbccccc40000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
00000000001111100000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
0000000000f000400000000000000000000000000000000000000000000000000000000000000000000000000000000066666666cccccccc3333333355555555
000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00bb000
000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00bb000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbb000
880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb0b0
880000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0bb000
0008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbb000
000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb000
__gff__
0000000000000000000000008080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0e0e0e0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0d0d0d0d0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0d0d0d0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0e0d0d0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0e0e0d0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0e0e0d0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0e0e0e0e0e0e0e0e0e0e0e0e0e0e0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000000000000000e0500e0500f0500f050110501405015050190501a0501d05021050240501e0501e05018050160501505014050140501305013050130501205017050170501505012050000000000000000
00100000000000000000000127001700016000130001a7001a7001a7000b0000e0001100011000110001200012000110001100015000190001b0001c0001b000140001100010000100000f000100000000000000
0010000022f0029f0012f0010f000ef000ef000df000df000cf000cf000cf000cf000cf000cf000df000df000ef000ff0010f0011f0012f0013f0015f0016f0018f001af001bf001df001ff0020f000000000000
