local player = {}
local platforms = { {}, {} }
local starter_platform = {}
local latters = { {} }
-- need to fix a bug where you can't go up latter when you are standing on ground and it only lets you go up when you are already in air.
function love.load()
	-- window setup
	love.window.setMode(800, 800)
	love.window.setTitle("Code Kong")
	love.graphics.setBackgroundColor(0, 0, 1)

	-- physics setup
	love.physics.setMeter(64)
	World = love.physics.newWorld(0, 9.81 * 64, true)
	World:setCallbacks(beginCollision, endCollision, preSolve, postSolve)

	-- running functions for setups
	platformsSetup()
	latterSetup()
	playerSetup()
end

function love.update(dt)
	World:update(dt)
	playerMovement()
end

function love.draw()
	-- player
	local px = player.body:getX() - player.width / 2
	local py = player.body:getY() - player.height / 2

	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", px, py, player.width, player.height)

	-- starter_platform
	love.graphics.setColor(1, 0, 1)
	love.graphics.polygon("fill", starter_platform.body:getWorldPoints(starter_platform.shape:getPoints()))

	-- platforms
	for _, p in ipairs(platforms) do
		love.graphics.setColor(1, 0, 1)
		love.graphics.polygon("fill", p.body:getWorldPoints(p.shape:getPoints()))
		love.graphics.origin()
	end

	-- latters
	for _, l in ipairs(latters) do
		love.graphics.setColor(1, 1, 1)
		love.graphics.polygon("fill", l.body:getWorldPoints(l.shape:getPoints()))
	end
end

-- PLATFORMS

function platformsSetup()
	for i, p in ipairs(platforms) do
		if i % 2 ~= 0 then
			p.angle = -2
		else
			p.angle = 2
		end
		if i == 1 then
			p.width = love.graphics.getWidth() / 2
		else
			p.width = love.graphics.getWidth() - love.graphics.getWidth() / 15
		end
		p.height = 20
		p.groundLevel = false
		p.name = "platform"
	end
	platforms[1].x = love.graphics.getWidth() / 2 + platforms[1].width / 2
	platforms[1].y = love.graphics.getHeight() - platforms[1].height / 2 - 7
	platforms[1].groundLevel = true

	platforms[2].x = love.graphics.getWidth() / 2 - (love.graphics.getWidth() - platforms[2].width)
	platforms[2].y = platforms[1].y - 115 - platforms[2].height / 2 - platforms[1].height / 2

	for _, p in ipairs(platforms) do
		p.body = love.physics.newBody(World, p.x, p.y, "static")
		p.body:setAngle(math.rad(p.angle))
		p.shape = love.physics.newRectangleShape(p.width, p.height)
		p.fixture = love.physics.newFixture(p.body, p.shape)
		p.fixture:setUserData(p)
	end

	-- starting platform
	local sp = starter_platform
	sp.width = love.graphics.getWidth() / 2
	sp.height = 20
	sp.name = "platform"
	sp.x = love.graphics.getWidth() / 2 - love.graphics.getWidth() / 4
	sp.y = love.graphics.getHeight() - sp.height / 2

	sp.body = love.physics.newBody(World, sp.x, sp.y, "static")
	sp.shape = love.physics.newRectangleShape(sp.width, sp.height)
	sp.fixture = love.physics.newFixture(sp.body, sp.shape)
	sp.fixture:setUserData(sp)
end

-- PLAYER

function playerSetup()
	player.width = 20
	player.height = 60
	player.starting_x = 40
	-- player.starting_y = 500
	player.starting_y = love.graphics.getHeight() - starter_platform.height - player.height / 2
	player.speed = 200
	player.jumpHeight = -50
	player.isGrounded = false
	player.onLatter = false
	player.latterClimbSpeed = -70
	player.name = "player"
	player.feetRadius = player.width / 2
	player.inPlatform = false

	player.body = love.physics.newBody(World, player.starting_x, player.starting_y, "dynamic")
	player.body:setFixedRotation(true)
	player.bodyCollider = love.physics.newRectangleShape(player.width, player.height / 2)
	player.feetCollider = love.physics.newCircleShape(0, player.height / 2 - player.feetRadius, player.feetRadius)
	player.bodyFixture = love.physics.newFixture(player.body, player.bodyCollider)
	player.feetFixture = love.physics.newFixture(player.body, player.feetCollider)
	player.bodyFixture:setUserData(player)
	player.feetFixture:setUserData(player)
end

function playerMovement()
	-- Player Movement
	if love.keyboard.isDown("a") and not player.inPlatform then
		-- cluade helped fix a bug when this line
		local _, vy = player.body:getLinearVelocity()
		player.body:setLinearVelocity(-200, vy)
	elseif love.keyboard.isDown("d") and not player.inPlatform then
		local _, vy = player.body:getLinearVelocity()
		player.body:setLinearVelocity(player.speed, vy)
	else
		local _, vy = player.body:getLinearVelocity()
		player.body:setLinearVelocity(0, vy)
	end

	if player.onLatter == true then
		player.body:setGravityScale(0)
	else
		player.body:setGravityScale(1)
	end

	if love.keyboard.isDown("space") or love.keyboard.isDown("w") then
		if not player.onLatter then
			if player.isGrounded then
				player.body:applyLinearImpulse(0, player.jumpHeight)
				player.isGrounded = false
			end

		-- latter movement
		elseif player.onLatter then
			local vx, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(vx, player.latterClimbSpeed)
			if player.isGrounded then
				player.body:setLinearVelocity(vx, player.latterClimbSpeed)
			end
		end
	else
		if player.isGrounded == false and player.onLatter then
			local vx, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(vx, 0)
		end
	end

	if love.keyboard.isDown("s") then
		if player.onLatter then
			local vx, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(vx, player.latterClimbSpeed * -1)
		end
	else
		if
			player.isGrounded == false
			and player.onLatter
			and not love.keyboard.isDown("space")
			and not love.keyboard.isDown("w")
		then
			local vx, _ = player.body:getLinearVelocity()
			player.body:setLinearVelocity(vx, 0)
		end
	end
end

-- LATTERS
function latterSetup()
	local lat = latters

	lat[1].small = true

	for _, l in ipairs(lat) do
		l.width = 15
		l.name = "latter"
		if l.small == true then
			l.height = 100
		else
			l.height = 120
		end
	end

	lat[1].x = love.graphics.getWidth() - 100 - lat[1].width / 2
	lat[1].y = love.graphics.getHeight() - platforms[1].height / 2 - lat[1].height / 2 - platforms[1].height

	-- physics setup
	for _, l in ipairs(lat) do
		l.body = love.physics.newBody(World, l.x, l.y, "static")
		l.shape = love.physics.newRectangleShape(l.width, l.height)
		l.fixture = love.physics.newFixture(l.body, l.shape)
		l.fixture:setUserData(l)
	end
end

-- COLLISION
-- used claude to understand how this function works
function beginCollision(a, b, coll)
	local objA = a:getUserData()
	local objB = b:getUserData()
	if objA and objB then
		if objA.name == "player" and objB.name == "platform" then
			objB.isGrounded = true
		elseif objA.name == "platform" and objB.name == "player" then
			objB.isGrounded = true
		end

		if objA.name == "player" and objB.name == "latter" then
			objA.onLatter = true
		elseif objA.name == "latter" and objB.name == "player" then
			objB.onLatter = true
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

		if objA.name == "player" and objB.name == "latter" or objA.name == "latter" and objB.name == "player" then
			player.inPlatform = false
			for _, p in ipairs(platforms) do
				if objA.name == "player" or objB.name == "player" then
					if
						player.body:getY() < p.body:getY() + p.height / 2
						and player.body:getY() > p.body:getY() - p.height / 2
					then
						player.inPlatform = true
					end
				end
			end
			if player.inPlatform == false or player.isGrounded == false then
				player.onLatter = false
			end
		end
	end
end

function preSolve(a, b, coll)
	local objA = a:getUserData()
	local objB = b:getUserData()

	if objA and objB then
		-- latter check
		if objA.name == "player" and objB.name == "latter" or objA.name == "latter" and objB.name == "player" then
			coll:setEnabled(false)
		end
		-- platform checks
		if
			objA.name == "player" and objB.name == "platform" and objA.onLatter == true
			or objB.name == "player" and objA.name == "platform" and objB.onLatter == true
		then
			if
				objA.name == "player"
					and objB.body:getY() - objB.height / 2 <= player.body:getY() + player.height / 2
				or objB.name == "player"
					and objA.body:getY() - objA.height / 2 <= player.body:getY() + player.height / 2
			then
				coll:setEnabled(false)
			else
				coll:setEnabled(true)
			end
		end
	end
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse) end
