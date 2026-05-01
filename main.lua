-- globals
PLATFORM_HEIGHT = 20
SCORE = 0
LEVEL = 1
STATE = "menu"

-- player
local player = {}

-- keyboard(hammer)
local keyboards = { {}, {} }
local keyboardTimer = 0

-- platforms
local platforms = { {}, {}, {}, {}, {}, {} }

-- ladders
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

-- barriers
local barriers = { {}, {} }

-- enemy
local enemies = {}
-- local enemyCount = 0
local randomEnemySpawnInterval = 2
local randomEnemySpawnIntervalLowerBounds = 2
local randomEnemySpawnIntervalUpperBounds = 7
local spawnEnemyTimer = 0

-- ui
local font = love.graphics.newFont(24)

-- catagorys look up
-- 1 = default
-- 2 = standard enemy state
-- 4 = enemy climb down ladder sensor
-- 5 = enemy ladder state
-- 7 = ladders
-- 8 = player keyboard state(star state from mario)
-- 16 I just use this one when reseting a mask

function love.load()
	-- window setup
	love.window.setMode(800, 1000)
	love.window.setTitle("Code Kong")
	love.graphics.setBackgroundColor(0, 0, 0)

	-- physics setup
	love.physics.setMeter(64)
	World = love.physics.newWorld(0, 9.81 * 64, true)
	World:setCallbacks(beginCollision, endCollision, preSolve, postSolve)

	math.randomseed(os.time())

	BarrierSetup()
	PlatformSetup()
	LadderSetup()
	PlayerSetup()
	KeyboardItemSetup()
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
	p.height = 40
	p.width = 20
	p.starting_x = 30
	p.starting_y = groundLevel.y - PLATFORM_HEIGHT / 2 - p.height / 2
	p.radius = p.width / 2

	-- movement
	p.speed = 150
	p.jumpHeight = -40
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
	p.tookDamage = false
	p.holdingKeyboard = false
	p.canUseLadder = true
	p.keyboardTimerInterval = 5

	-- physics setup
	p.body = love.physics.newBody(World, p.starting_x, p.starting_y, "dynamic")
	p.body:setFixedRotation(true)
	p.bodyCollider = love.physics.newRectangleShape(p.width, p.height / 2)
	p.feetCollider = love.physics.newCircleShape(0, p.height / 2 - p.radius, p.radius)
	p.bodyFixture = love.physics.newFixture(p.body, p.bodyCollider)
	p.feetFixture = love.physics.newFixture(p.body, p.feetCollider)
	p.bodyFixture:setUserData(p)
	p.feetFixture:setUserData(p)
	p.bodyFixture:setMask(4)
	p.feetFixture:setMask(4)

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
				l.fixture:setCategory(7)
				l.fixture:setMask(2, 5)

				l.climbDownShape =
					love.physics.newRectangleShape(0, -l.height / 2 - PLATFORM_HEIGHT / 2 - 20, l.width, 20)
				l.climbDownFixture = love.physics.newFixture(l.body, l.climbDownShape)
				l.climbDownFixture:setCategory(4)
				l.climbDownFixture:setUserData(l)
				l.climbDownFixture:setSensor(true)
			end
		end
	end
end

function KeyboardItemSetup()
	for _, k in ipairs(keyboards) do
		k.name = "keyboard"
		k.height = 40
		k.width = 20
	end
	local k = keyboards
	local pl = platforms
	k[1].x = love.graphics.getWidth() - 220
	k[1].y = pl[2].body:getY() - PLATFORM_HEIGHT / 2 - k[1].height / 2 - 60

	k[2].x = 220
	k[2].y = pl[5].body:getY() - PLATFORM_HEIGHT / 2 - k[2].height / 2 - 60

	for _, key in ipairs(keyboards) do
		key.body = love.physics.newBody(World, key.x, key.y, "static")
		key.shape = love.physics.newRectangleShape(key.width, key.height)
		key.fixture = love.physics.newFixture(key.body, key.shape)
		key.fixture:setUserData(key)
		key.fixture:setCategory(6)
		key.fixture:setSensor(true)
		key.fixture:setMask(2, 4, 5)
	end
end

-- enemy setup
function SpawnEnemy()
	local e = {}
	-- enemyCount = enemyCount + 1
	e.name = "enemy"

	-- transform
	e.width = 30
	e.height = 20
	e.starting_x = 100
	e.starting_y = platforms[#platforms].y - PLATFORM_HEIGHT / 2 - e.height / 2

	-- logic
	e.speed = 150
	e.isRight = true
	e.climbLadderChance = 8
	e.canMove = true
	e.onLadder = false
	e.currentLadder = 0

	e.body = love.physics.newBody(World, e.starting_x, e.starting_y, "dynamic")
	e.body:setFixedRotation(true)
	e.shape = love.physics.newRectangleShape(e.width, e.height)
	e.scoringShape = love.physics.newRectangleShape(0, -e.height / 2 - 10, 10, 20)
	e.fixture = love.physics.newFixture(e.body, e.shape)
	e.fixture:setUserData(e)
	e.fixture:setCategory(2)
	e.fixture:setMask(2, 5)
	e.fixture:setFriction(0)

	-- Scoring Sensor logic
	-- claude helped found I had a typo here saying scoringFixture where I had in the damage check scoringSensor
	e.scoringSensor = love.physics.newFixture(e.body, e.scoringShape)
	e.scoringSensor:setUserData(e)
	e.scoringSensor:setSensor(true)
	e.scoringSensor:setMask(8)

	table.insert(enemies, e)
	spawnEnemyTimer = 0
end

function ResetLocationsOnDamage()
	local p = player
	local e = enemies
	local py = platforms[1].y - PLATFORM_HEIGHT / 2 - p.height / 2
	p.body:setPosition(30, py)
	p.body:setLinearVelocity(0, 0)
	p.tookDamage = false
	for i in pairs(e) do
		e[i].body:destroy()
		e[i] = nil
	end

	randomEnemySpawnInterval = 3
	randomEnemySpawnIntervalLowerBounds = 2
	randomEnemySpawnIntervalUpperBounds = 6
	p.currentLadder = 0
	p.onLadder = false
	p.isGrounded = true
	p.canUseLadder = true
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

	if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
		if p.canMove then
			local _, vy = p.body:getLinearVelocity()
			p.body:setLinearVelocity(p.speed * -1, vy)
		end
	elseif love.keyboard.isDown("d") or love.keyboard.isDown("right") then
		if p.canMove then
			local _, vy = p.body:getLinearVelocity()
			p.body:setLinearVelocity(p.speed, vy)
		end
	end
	if love.keyboard.isDown("space") or love.keyboard.isDown("w") or love.keyboard.isDown("up") then
		if p.isGrounded and p.onLadder == false then
			p.isGrounded = false
			p.body:applyLinearImpulse(0, p.jumpHeight)
		end

		-- ladder movement logic
		LadderMovement("up")
	elseif love.keyboard.isDown("s") or love.keyboard.isDown("down") then
		LadderMovement("down")
	end
end

function LadderMovement(direction)
	local p = player
	if p.onLadder and p.canUseLadder then
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

function EnemyMovement(e)
	local _, vy = e.body:getLinearVelocity()
	if e.isRight then
		e.body:setLinearVelocity(e.speed, vy)
	else
		e.body:setLinearVelocity(e.speed * -1, vy)
	end
end

function love.keyreleased(key)
	if STATE == "game" then
		if key == "d" or key == "a" or key == "left" or key == "right" then
			local _, py = player.body:getLinearVelocity()
			player.body:setLinearVelocity(0, py)
		-- this fixes a issue with ladders of the player not stoping on the ladder when you aren't holding any movement keys
		elseif key == "w" or key == "space" or key == "s" or key == "up" or key == "down" then
			if player.onLadder then
				local px, _ = player.body:getLinearVelocity()
				player.body:setLinearVelocity(px, 0)
			end
		end
	end
end

function love.keypressed(key)
	-- global binds
	if key == "escape" then
		love.event.quit()
	end
	-- debug binds
	if key == "m" then
		STATE = "menu"
	elseif key == "g" then
		STATE = "game"
	elseif key == "o" then
		STATE = "gameOver"
	elseif key == "9" then
		SCORE = 999999
	end

	if STATE == "menu" then
		if key == "space" then
			STATE = "game"
		end
	elseif STATE == "gameOver" then
		if key == "space" then
			RestartGame()
		elseif key == "m" then
			STATE = "menu"
		end
	end
end

-- TODO
function RestartGame()
	SCORE = 0
	-- reset player
	local p = player
	local py = platforms[1].y - PLATFORM_HEIGHT / 2 - p.height / 2
	p.body:setPosition(30, py)
	p.body:setLinearVelocity(0, 0)
	p.tookDamage = false
	p.isGrounded = true
	p.onLadder = false
	p.currentLadder = 0
	p.canUseLadder = true
	p.holdingKeyboard = false
	p.lives = 3
	p.speed = 150

	-- reset enemies
	randomEnemySpawnInterval = 2
	randomEnemySpawnIntervalLowerBounds = 2
	randomEnemySpawnIntervalUpperBounds = 7
	spawnEnemyTimer = 0

	if #enemies > 0 then
		for i, e in ipairs(enemies) do
			enemies[i] = nil
			e.body:destroy()
		end
	end

	-- reset keyboards
	for i, k in ipairs(keyboards) do
		keyboards[i] = nil
		k.body:destroy()
	end
	keyboards = { {}, {} }
	KeyboardItemSetup()

	-- set state
	STATE = "game"
end

function love.update(dt)
	World:update(dt)

	if STATE == "game" then
		if player.lives <= 0 then
			STATE = "gameOver"
		end

		PlayerMovement()
		if player.currentLadder ~= 0 and player.onLadder then
			inPlatformCheck(player, player.currentLadder)
		end

		if player.holdingKeyboard then
			local timerInterval = player.keyboardTimerInterval

			keyboardTimer = keyboardTimer + dt
			if keyboardTimer >= timerInterval then
				keyboardTimer = 0
				player.holdingKeyboard = false
				player.canUseLadder = true
				player.bodyFixture:setCategory(1)
				player.feetFixture:setCategory(1)
				player.bodyFixture:setMask(4)
				player.feetFixture:setMask(4)
				player.speed = 150
			end
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

		spawnEnemyTimer = spawnEnemyTimer + dt
		if spawnEnemyTimer >= randomEnemySpawnInterval then
			spawnEnemyTimer = 0
			if #enemies % 5 == 0 then
				if randomEnemySpawnIntervalUpperBounds >= 3 then
					randomEnemySpawnIntervalUpperBounds = randomEnemySpawnIntervalUpperBounds - 1
				else
					if randomEnemySpawnIntervalLowerBounds >= 2 then
						randomEnemySpawnIntervalLowerBounds = randomEnemySpawnIntervalLowerBounds - 1
					end
				end
			end
			randomEnemySpawnInterval =
				math.random(randomEnemySpawnIntervalLowerBounds, randomEnemySpawnIntervalUpperBounds)
			SpawnEnemy()
		end

		-- enemy movement
		if #enemies >= 1 then
			for _, e in ipairs(enemies) do
				if e.canMove then
					EnemyMovement(e)
				end
			end
		end

		-- center enemy on ladders
		if #enemies >= 1 then
			for _, e in ipairs(enemies) do
				if e.currentLadder ~= 0 then
					local l = e.currentLadder
					local x = l.body:getX()
					local y = e.body:getY()
					e.body:setPosition(x, y)
				end
			end
		end

		if player.tookDamage then
			ResetLocationsOnDamage()
		end
	end
end

function love.draw()
	if STATE == "menu" then
		love.graphics.setColor(1, 1, 1)
		local startMessage = "Press SPACE to Start"
		local quitMessage = "Press ESC to Quit"
		love.graphics.print(startMessage, font, love.graphics.getWidth() / 2 - font:getWidth(startMessage) / 2, 150)
		love.graphics.print(quitMessage, font, love.graphics.getWidth() / 2 - font:getWidth(quitMessage) / 2, 300)
	elseif STATE == "game" then
		local px = player.body:getX() - player.width / 2
		local py = player.body:getY() - player.height / 2
		if player.holdingKeyboard then
			love.graphics.setColor(0, 1, 0)
		else
			love.graphics.setColor(1, 0, 0)
		end
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
					-- used claude to help me find a aqua color and how to convert 255 rgb values to how lua does color
					love.graphics.setColor(0, 200 / 255, 220 / 255)
					love.graphics.polygon("fill", l.body:getWorldPoints(l.shape:getPoints()))
				end
			end
		end

		-- enemys
		for _, e in ipairs(enemies) do
			if e then
				love.graphics.setColor(1, 0, 0)
				love.graphics.polygon("fill", e.body:getWorldPoints(e.shape:getPoints()))
			end
		end
		-- keyboards
		for _, k in ipairs(keyboards) do
			if k then
				love.graphics.setColor(1, 1, 1)
				love.graphics.polygon("fill", k.body:getWorldPoints(k.shape:getPoints()))
			end
		end
		-- ui
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Score: " .. tostring(SCORE), font, 10, 0)
		love.graphics.print("Lives: " .. tostring(player.lives), font, 10, 40)
	elseif STATE == "gameOver" then
		love.graphics.setColor(1, 0, 0)
		local gameOverText = "GAME OVER!"
		local finalScore = "Score: " .. tostring(SCORE)
		local restartText = "Press Space to restart"
		local goMainMenuText = "Press m to Return to the Main Menu"
		local quitText = "Press ESC to Quit"

		love.graphics.print(gameOverText, font, love.graphics.getWidth() / 2 - font:getWidth(gameOverText) / 2, 150)
		love.graphics.print(finalScore, font, love.graphics.getWidth() / 2 - font:getWidth(finalScore) / 2, 300)
		love.graphics.print(restartText, font, love.graphics.getWidth() / 2 - font:getWidth(restartText) / 2, 450)
		love.graphics.print(goMainMenuText, font, love.graphics.getWidth() / 2 - font:getWidth(goMainMenuText) / 2, 600)
		love.graphics.print(quitText, font, love.graphics.getWidth() / 2 - font:getWidth(quitText) / 2, 750)
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

		if objA.name == "player" and objB.name == "keyboard" then
			PickupKeyboard(objA, objB)
		elseif objA.name == "keyboard" and objB.name == "player" then
			PickupKeyboard(objB, objA)
		end

		if objA.name == "enemy" and objB.name == "barrier" then
			objA.isRight = not objA.isRight
		elseif objA.name == "barrier" and objB.name == "enemy" then
			objB.isRight = not objB.isRight
		end

		-- enemy ladder logic
		if objA.name == "enemy" and objB.name == "ladder" then
			if b == objB.climbDownFixture then
				EnemyLadderLogic(objA, objB)
			end
		elseif objA.name == "ladder" and objB.name == "enemy" then
			if a == objA.climbDownFixture then
				EnemyLadderLogic(objB, objA)
			end
		end

		-- enemy stop moving on ladder logic
		if objA.name == "enemy" and objB.name == "platform" then
			EnemyStopLadderMovement(objA)
		elseif objB.name == "enemy" and objA.name == "platform" then
			EnemyStopLadderMovement(objB)
		end

		-- damage check
		if objA.name == "player" and objB.name == "enemy" then
			if b == objB.scoringSensor then
				if not objA.onLadder then
					SCORE = SCORE + 100
				end
			else
				if objA.bodyFixture:getCategory() ~= 8 and objA.feetFixture:getCategory() ~= 8 then
					objA.lives = objA.lives - 1
					objA.tookDamage = true
				else
					objB.body:destroy()
					for i, e in ipairs(enemies) do
						if e == objB then
							table.remove(enemies, i)
							break
						end
					end
					SCORE = SCORE + 200
				end
			end
		elseif objA.name == "enemy" and objB.name == "player" then
			if a == objA.scoringSensor then
				if not objB.onLadder then
					SCORE = SCORE + 100
				end
			else
				if objB.bodyFixture:getCategory() ~= 8 and objB.feetFixture:getCategory() ~= 8 then
					objB.lives = objB.lives - 1
					objB.tookDamage = true
				else
					objA.body:destroy()
					for i, e in ipairs(enemies) do
						if e == objA then
							table.remove(enemies, i)
							break
						end
					end
					SCORE = SCORE + 200
				end
			end
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

function EnemyLadderLogic(e, l)
	local randNum = math.random(1, e.climbLadderChance)
	if randNum == 1 then
		local p = l.abovePlatform
		e.canMove = false
		e.isRight = not e.isRight
		e.fixture:setCategory(5)
		p.fixture:setMask(5)
		e.climbLadderChance = 8
		e.body:setGravityScale(0)
		e.body:setLinearVelocity(0, 50)
		e.currentLadder = l
	else
		if math.random(1, 2) == 1 then
			e.climbLadderChance = e.climbLadderChance - 1
		end
	end
end

function EnemyStopLadderMovement(enemy)
	local e = enemy
	local l = e.currentLadder
	if l ~= 0 then
		local pl = l.abovePlatform
		if e.body:getY() + e.height / 2 >= l.body:getY() + l.height / 2 - 5 then
			e.body:setGravityScale(1)
			e.canMove = true
			-- logic for making it so enemies don't freeze when another enemy is at the end of a ladder
			local resetMask = true
			for _, en in ipairs(enemies) do
				if en.currentLadder == e.currentLadder and en ~= e then
					resetMask = false
				end
			end
			if resetMask then
				pl.fixture:setMask(16)
			end
			e.fixture:setCategory(2)
			e.currentLadder = 0
		end
	end
end

function PickupKeyboard(p, k)
	for i, key in ipairs(keyboards) do
		if key == k then
			table.remove(keyboards, i)
			k.body:destroy()
			break
		end
	end

	p.holdingKeyboard = true
	p.canUseLadder = false
	p.bodyFixture:setMask(4, 7)
	p.feetFixture:setMask(4, 7)
	p.bodyFixture:setCategory(8)
	p.feetFixture:setCategory(8)
	p.speed = 250
end
