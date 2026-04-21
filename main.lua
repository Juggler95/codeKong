local player = {}
local platforms = { {}, {}, {}, {}, {}, {} }
local edgeLadders = {
	{ abovePlatform = 2 },
	{ abovePlatform = 3 },
	{ abovePlatform = 4 },
	{ abovePlatform = 5 },
	{ abovePlatform = 6 },
}
local variedLadders = {}
local ladderTypes = { edgeLadders, variedLadders }

-- globals
PLATFORM_HEIGHT = 20

function love.load()
	-- window setup
	love.window.setMode(800, 900)
	love.window.setTitle("Code Kong")
	love.graphics.setBackgroundColor(0, 0, 1)

	-- physics setup
	love.physics.setMeter(64)
	World = love.physics.newWorld(0, 9.81 * 64, true)
	World:setCallbacks(beginCollision, endCollision, preSolve, postSolve)

	PlatformSetup()
	LadderSetup()
	PlayerSetup()
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
	p.height = 80
	p.width = 20
	p.starting_x = 30
	p.starting_y = groundLevel.y - PLATFORM_HEIGHT / 2 - p.height / 2
	p.radius = p.width / 2

	-- movement
	p.speed = 200
	p.jumpHeight = -60
	p.climbSpeed = -70

	-- logic
	p.name = "player"
	p.isGrounded = true
	p.onLadder = false
	p.currentLadder = 0
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
end

function PlayerMovement()
	local p = player

	-- Ladder gravity logic
	if player.onLadder == true then
		player.body:setGravityScale(0)
	else
		player.body:setGravityScale(1)
	end

	if love.keyboard.isDown("a") then
		local _, vy = p.body:getLinearVelocity()
		p.body:setLinearVelocity(-200, vy)
	elseif love.keyboard.isDown("d") then
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
		p.isGrouned = false
		if direction == "up" then
			p.body:setLinearVelocity(px, p.climbSpeed)
		elseif direction == "down" then
			p.body:setLinearVelocity(px, p.climbSpeed * -1)
		end
	elseif p.onLadder and p.isGrounded == false then
		local px, _ = p.body:getLinearVelocity()
		p.body:setLinearVelocity(px, 0)
	end
end

-- LADDERS

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

function love.update(dt)
	World:update(dt)

	PlayerMovement()
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

function love.keyreleased(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "d" or key == "a" then
		local _, py = player.body:getLinearVelocity()
		player.body:setLinearVelocity(0, py)
	-- this fixes a issue with ladder of you not stoping on the ladder when you aren't holding one of the keys
	elseif key == "w" or key == "space" or key == "s" then
		if player.onLadder then
			local px, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(px, 0)
		end
	end
end

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
			objA.onLadder = false
		elseif objA.name == "ladder" and objB.name == "player" then
			objB.onLadder = false
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
	end
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse) end
