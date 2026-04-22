local player = {}
local platforms = { {}, {}, {}, {}, {}, {} }
local edgeLadders = {
	{ abovePlatform = platforms[2] },
	{ abovePlatform = platforms[3] },
	{ abovePlatform = platforms[4] },
	{ abovePlatform = platforms[5] },
	{ abovePlatform = platforms[6] },
}
local variedLadders =
	{ { abovePlatform = platforms[3] }, { abovePlatform = platforms[4] }, { abovePlatform = platforms[5] } }
local ladderTypes = { edgeLadders, variedLadders }
local barriers = { {}, {} }

-- globals
PLATFORM_HEIGHT = 20

function love.load()
	-- window setup
	love.window.setMode(800, 900)
	love.window.setTitle("Code Kong")
	love.graphics.setBackgroundColor(0, 0, 0)

	-- physics setup
	love.physics.setMeter(64)
	World = love.physics.newWorld(0, 9.81 * 64, true)
	World:setCallbacks(beginCollision, endCollision, preSolve, postSolve)

	BarrierSetup()
	PlatformSetup()
	LadderSetup()
	PlayerSetup()
end

-- Setup Functions
function BarrierSetup()
	for _, b in ipairs(barriers) do
		b.height = love.graphics.getHeight() - PLATFORM_HEIGHT / 2
		b.width = 15
		b.name = "barrier"
		b.y = love.graphics.getHeight() / 2 - PLATFORM_HEIGHT / 2
	end

	local b = barriers
	b[1].x = 0 - b[1].width / 2
	b[2].x = love.graphics.getWidth() + b[2].width / 2

	for _, b in ipairs(barriers) do
		b.body = love.physics.newBody(World, b.x, b.y, "static")
		b.shape = love.physics.newRectangleShape(b.width, b.height)
		b.fixture = love.physics.newFixture(b.body, b.shape)
		b.fixture:setUserData(b)
	end
end

function PlatformSetup()
	local plat = platforms
	local sp = platforms[1]

	-- globals for platforms
	local GAP = 125

	sp.x = love.graphics.getWidth() / 2
	sp.y = love.graphics.getHeight()
	sp.width = love.graphics.getWidth()
	sp.name = "platform"

	for i = 2, #plat do
		local p = plat
		p[i].y = p[i - 1].y - GAP - PLATFORM_HEIGHT
		p[i].width = love.graphics.getWidth() - 100
		p[i].name = "platform"
		if i % 2 == 0 then
			-- the - 50 is to align it on the left side
			p[i].x = love.graphics.getWidth() / 2 - 50
		else
			-- the + 50 is to align it on the right side
			p[i].x = love.graphics.getWidth() / 2 + 50
		end
	end

	for _, p in ipairs(platforms) do
		p.body = love.physics.newBody(World, p.x, p.y, "static")
		p.shape = love.physics.newRectangleShape(p.width, PLATFORM_HEIGHT)
		p.fixture = love.physics.newFixture(p.body, p.shape)
		p.fixture:setUserData(p)
	end
end

function PlayerSetup()
	local p = player
	local groundLevel = platforms[1]
	-- transform
	p.height = 60
	p.width = 20
	p.starting_x = 30
	p.starting_y = groundLevel.y - PLATFORM_HEIGHT / 2 - p.height / 2
	p.radius = p.width / 2

	-- movement
	p.speed = 200
	p.jumpHeight = -50
	p.climbSpeed = -70
	p.canJump = true
	p.canMove = true

	-- logic
	p.name = "player"
	p.isGrounded = true
	p.onLadder = false
	p.currentLadder = 0
	p.groundTimer = 0
	p.lives = 3

	-- physics setup
	p.body = love.physics.newBody(World, p.starting_x, p.starting_y, "dynamic")
	p.body:setFixedRotation(true)
	p.bodyCollider = love.physics.newRectangleShape(p.width, p.height / 2)
	p.feetCollider = love.physics.newCircleShape(0, p.height / 2 - p.radius, p.radius)
	p.bodyFixture = love.physics.newFixture(p.body, p.bodyCollider)
	p.feetFixture = love.physics.newFixture(p.body, p.feetCollider)
	p.bodyFixture:setUserData(p)
	p.feetFixture:setUserData(p)

	-- claude code told me about the setFriction function
	-- this is just preventing the player from sticking to the side of the platforms/barriers
	p.bodyFixture:setFriction(0)
	p.feetFixture:setFriction(0)
end

function LadderSetup()
	local el = edgeLadders
	local vl = variedLadders
	-- position edge ladders
	for i = 1, #el do
		local l = el
		l[i].height = 125
		l[i].width = 15
		l[i].name = "ladder"
		if i % 2 == 0 then
			-- left side
			-- + 150 to move it left a little so its not right at the edge
			l[i].x = l[i].width / 2 + 150
			l[i].y = platforms[i].y - PLATFORM_HEIGHT / 2 - l[i].height / 2
		else
			-- right side
			-- - 150 to move it left a little so its not right at the edge
			l[i].x = love.graphics.getWidth() - l[i].width / 2 - 150
			l[i].y = platforms[i].y - PLATFORM_HEIGHT / 2 - l[i].height / 2
		end
	end

	-- varied Ladders setup
	for i = 1, #vl do
		local l = vl
		l[i].width = 15
		l[i].height = 125
		l[i].name = "ladder"
	end

	-- the last arithmitic math at the end of the x values are just the offsets

	vl[1].x = love.graphics.getWidth() / 2 - vl[1].width / 2 - 30
	vl[1].y = platforms[2].y - PLATFORM_HEIGHT / 2 - vl[1].height / 2

	vl[2].x = love.graphics.getWidth() / 2 - vl[2].width / 2 + 30
	vl[2].y = platforms[3].y - PLATFORM_HEIGHT / 2 - vl[2].height / 2

	vl[3].x = love.graphics.getWidth() / 2 - vl[3].width / 2 - 100
	vl[3].y = platforms[4].y - PLATFORM_HEIGHT / 2 - vl[3].height / 2

	-- ladder physics
	for _, t in ipairs(ladderTypes) do
		for __, l in ipairs(t) do
			if l then
				l.body = love.physics.newBody(World, l.x, l.y, "static")
				l.shape = love.physics.newRectangleShape(l.width, l.height)
				l.fixture = love.physics.newFixture(l.body, l.shape)
				l.fixture:setUserData(l)
			end
		end
	end
end

-- MOVEMENT
function PlayerMovement()
	local p = player

	-- Ladder gravity logic
	if player.onLadder == true then
		player.body:setGravityScale(0)
	else
		player.body:setGravityScale(1)
	end

	if love.keyboard.isDown("a") and p.canMove then
		local _, vy = p.body:getLinearVelocity()
		p.body:setLinearVelocity(-200, vy)
	elseif love.keyboard.isDown("d") and p.canMove then
		local _, vy = p.body:getLinearVelocity()
		p.body:setLinearVelocity(200, vy)
	end
	if love.keyboard.isDown("space") or love.keyboard.isDown("w") then
		if p.isGrounded and p.onLadder == false then
			p.isGrounded = false
			p.body:applyLinearImpulse(0, p.jumpHeight)
		end

		-- ladder movement logic
		LadderMovement("up")
	elseif love.keyboard.isDown("s") then
		LadderMovement("down")
	end
end

function LadderMovement(direction)
	local p = player
	if p.onLadder then
		local px, _ = p.body:getLinearVelocity()
		p.isGrounded = false
		if direction == "up" then
			p.body:setLinearVelocity(px, p.climbSpeed)
		elseif direction == "down" then
			p.body:setLinearVelocity(px, p.climbSpeed * -1)
		end
		-- claude found I had a dead elseif branch here. I removed it
	end
end

function love.keyreleased(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "d" or key == "a" then
		local _, py = player.body:getLinearVelocity()
		player.body:setLinearVelocity(0, py)
	-- this fixes a issue with ladders of the player not stoping on the ladder when you aren't holding any movement keys
	elseif key == "w" or key == "space" or key == "s" then
		if player.onLadder then
			local px, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(px, 0)
		end
	end
end

function love.update(dt)
	World:update(dt)

	PlayerMovement()
	if player.currentLadder ~= 0 and player.onLadder then
		inPlatformCheck(player, player.currentLadder)
	end

	-- claude helped me figure out timer logic
	-- gives the player a delay after coming through a platform where they can't jump so they don't jump right when coming out of ladder and looking like they get launched
	if not player.canJump then
		player.canMove = true
		player.groundTimer = player.groundTimer + dt
		if player.groundTimer >= 0.1 then
			player.groundTimer = 0
			player.isGrounded = true
			player.canJump = true
		end
	end
end

function love.draw()
	local px = player.body:getX() - player.width / 2
	local py = player.body:getY() - player.height / 2
	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("fill", px, py, player.width, player.height)

	-- platforms
	for _, p in ipairs(platforms) do
		love.graphics.setColor(1, 0, 1)
		love.graphics.polygon("fill", p.body:getWorldPoints(p.shape:getPoints()))
		love.graphics.origin()
	end

	-- ladders
	for _, t in ipairs(ladderTypes) do
		for __, l in ipairs(t) do
			if l then
				love.graphics.setColor(0, 1, 0)
				love.graphics.polygon("fill", l.body:getWorldPoints(l.shape:getPoints()))
			end
		end
	end
end

-- collision

function beginCollision(a, b, coll)
	local objA = a:getUserData()
	local objB = b:getUserData()
	if objA and objB then
		-- platform checks
		if objA.name == "player" and objB.name == "platform" then
			objA.isGrounded = true
		elseif objA.name == "platform" and objB.name == "player" then
			objB.isGrounded = true
		end

		if objA.name == "player" and objB.name == "ladder" then
			objA.onLadder = true
		elseif objA.name == "ladder" and objB.name == "player" then
			objB.onLadder = true
		end
	end
end

function endCollision(a, b, coll)
	local objA = a:getUserData()
	local objB = b:getUserData()
	if objA and objB then
		if objA.name == "player" and objB.name == "platform" then
			objA.isGrounded = false
		elseif objA.name == "platform" and objB.name == "player" then
			objB.isGrounded = false
		end

		if objA.name == "player" and objB.name == "ladder" then
			inPlatformCheck(objA, objB)
		elseif objA.name == "ladder" and objB.name == "player" then
			inPlatformCheck(objB, objA)
		end
	end
end

function preSolve(a, b, coll)
	local objA = a:getUserData()
	local objB = b:getUserData()
	if objA and objB then
		if objA.name == "player" and objB.name == "ladder" or objA.name == "ladder" and objB.name == "player" then
			if objA.name == "player" then
				objA.currentLadder = objB
			elseif objB.name == "player" then
				objB.currentLadder = objA
			end
			coll:setEnabled(false)
		end
		-- platform checks
		if objA.name == "player" and objB.name == "platform" then
			PlatformAboveLogic(objA, objB, coll)
		elseif objA.name == "platform" and objB.name == "player" then
			PlatformAboveLogic(objB, objA, coll)
		end
	end
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse) end

-- logic / checks
function PlatformAboveLogic(player, platform, coll)
	local p = player
	local pl = platform
	local l = p.currentLadder

	if l == 0 then
		return
	elseif pl ~= l.abovePlatform then
		return
	elseif not p.onLadder then
		return
	end

	if p.body:getY() + p.height / 2 > pl.body:getY() - PLATFORM_HEIGHT / 2 then
		coll:setEnabled(false)
	else
		coll:setEnabled(true)
	end
end

function inPlatformCheck(p, l)
	local pl = l.abovePlatform
	p.inPlatform = false
	if
		p.body:getY() + p.height / 2 > pl.body:getY() - PLATFORM_HEIGHT / 2
		and p.body:getY() - p.height / 2 < pl.body:getY() + PLATFORM_HEIGHT / 2
		and p.onLadder
	then
		p.inPlatform = true
		p.canMove = false
	end
	-- checks if the players feet are above the platform to start the grounded timer and lets the player move
	if p.body:getY() + p.height / 2 < pl.body:getY() - PLATFORM_HEIGHT / 2 then
		p.isGrounded = false
		p.onLadder = false
		p.groundTimer = 0
		p.canJump = false
		p.canMove = true
		player.currentLadder = 0
		local px, _ = player.body:getLinearVelocity()
		player.body:setLinearVelocity(px, 0)
	-- checks if the player is past the right or left edge of the ladder to disable onLadder and makes the player fall back to the gruond
	elseif
		p.body:getX() - p.width / 2 > l.body:getX() + l.width / 2
		or p.body:getX() + p.width / 2 < l.body:getX() - l.width / 2
	then
		p.onLadder = false
		p.currentLadder = 0
		p.canMove = true
		local px, _ = player.body:getLinearVelocity()
		player.body:setLinearVelocity(px, 0)
		-- the - 10 in this line is just a little bit of a offset to make sure the player is at the bottom of the ladder before then can jump when climbing down the ladder before leaving
		if p.body:getY() + p.height / 2 > l.body:getY() + l.height / 2 - 10 then
			p.isGrounded = true
		end
	-- checks if the player top is below the platform to re-enabled player movement
	elseif p.body:getY() - p.height / 2 > pl.body:getY() + PLATFORM_HEIGHT / 2 then
		p.canMove = true
	end
end
