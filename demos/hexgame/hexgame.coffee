@sprites = new Object()
@damageMarkers = []
@personified = true

window.inLevel = false
window.updateLock = false

initialize = ->
	@canvas	= $("#canvas")[0]
	@context = canvas.getContext("2d")
	@levelNumber = 0

	@personified = not (window.location.hash == '#tile')

	#Load resources
	@sprites.tile = new Image()
	@sprites.tile.src = "tile_small.png"
	@sprites.tile_light = new Image()
	@sprites.tile_light.src = "tile_small_light.png"
	@sprites.tile_red = new Image()
	@sprites.tile_red.src = "tile_small_red.png"
	@sprites.arrow = new Image()
	@sprites.arrow.src = "arrows.png"
	@sprites.attack = new Image()
	@sprites.attack.src = "attack_large.png"

	$("#canvas").mousemove (event) ->
		board.selectAtPels(event.offsetX, event.offsetY)
		redrawCanvas()

	$("#canvas").click (event) ->
		if window.inLevel and not window.updateLock
			window.updateLock = true;
			selected = board.atPels(event.offsetX, event.offsetY)
			if selected? and (selected.distanceUnit(board.units[0]) == 1) and not selected.occupied
				board.units[0].move(selected.i, selected.j)
				unitsMove()
			else
				window.updateLock = false;

	window.addEventListener "keypress", (event) ->
		switch event.which
			when 43
				# +   : Increment level, reload
				console.log("Skipping forward")
				levelNumber++
			when 45
				# -   : Decrement level, reload
				console.log("Skipping back")
				levelNumber--
			when 82, 114
				# r, R: Do nothing
				console.log("Reseting level")
			else
				return
		loadLevel()
		redrawCanvas()

	loadLevel()
	redrawCanvas()

redrawCanvas = ->
	@context.fillStyle = "rgba(0,0,0,1)"
	@context.fillRect(0, 0, @canvas.width, @canvas.height)
	@context.lineWidth=3;
	@context.strokeStyle="#0000ff";
	@board.each (cell) ->
		@context.beginPath()
		if cell.enabled
			if (cell == board.selected) and (cell.distanceUnit(board.units[0]) == 1)
				if cell.occupied
					@context.drawImage(sprites.tile_red, cell.x, cell.y)
				else
					@context.drawImage(sprites.tile_light, cell.x, cell.y)
			else
				@context.drawImage(sprites.tile, cell.x, cell.y)
		@context.closePath()
	for marker in @damageMarkers
		switch marker.direction
			when 0
				@context.drawImage(sprites.attack,  0,  0, 12, 82, marker.tile.x+54, marker.tile.y-41, 12, 82)
			when 1
				@context.drawImage(sprites.attack, 24,  0, 54, 44, marker.tile.x+48, marker.tile.y+ 4, 54, 44)
			when 2
				@context.drawImage(sprites.attack, 24, 42, 54, 44, marker.tile.x+48, marker.tile.y+56, 54, 44)
			when 3
				@context.drawImage(sprites.attack, 12,  0, 12, 82, marker.tile.x+54, marker.tile.y+63, 12, 82)
			when 4
				@context.drawImage(sprites.attack, 76, 42, 54, 44, marker.tile.x- 8, marker.tile.y+56, 54, 44)
			when 5
				@context.drawImage(sprites.attack, 76,  0, 54, 44, marker.tile.x- 8, marker.tile.y+ 4, 54, 44)
			else
				console.log("Unsupported attack direction", unit.attackDirection)
	setTimeout(disableDamageMarkers, 500)
	for unit in @board.units
		if unit.type == 0 or unit.alive
			currentType = @board.unitTypes[unit.type]

			# Draw projectiles
			if unit.projectileX? and unit.projectileY?
				switch unit.attackDirection
					when 0, 3
						@context.drawImage(sprites.arrow, 36,  0,  2, 36, unit.projectileX- 1+60, unit.projectileY-18+52,  2, 36)
					when 1, 4
						@context.drawImage(sprites.arrow,  0, 20, 32, 18, unit.projectileX-16+60, unit.projectileY- 9+52, 32, 18)
					when 2, 5
						@context.drawImage(sprites.arrow,  0,  0, 32, 18, unit.projectileX-16+60, unit.projectileY- 9+52, 32, 18)
					else
						console.log("Unsupported attack direction", unit.attackDirection)

			# Draw unit
			if not unit.stunned
				@context.drawImage(currentType.sprite, unit.x, unit.y)
			else
				@context.drawImage(currentType.altSprite, unit.x, unit.y)
				@context.font = "bold 15pt sans-serif"
				@context.textAlign = "center"
				@context.fillStyle = "rgb(255, 255, 255)"
				@context.fillText("#{unit.stunDuration}", unit.x + 30, unit.y + 50)
			tile = @board.atPels(unit.x, unit.y)
			@context.font = "bold 10pt sans-serif"
			@context.textAlign = "center"
			@context.fillStyle = "rgba(255, 255, 255, 0.8)"
			@context.fillText("#{unit.name}", unit.x + 30, unit.y)
	if @hint?
		@context.font = "40pt sans-serif"
		@context.textAlign = "right"
		@context.fillStyle = "rgba(255, 255, 255, 0.5)"
		lineOffset = 0
		for hintLine in @hint
			@context.fillText("#{hintLine}", @hintX, @hintY + lineOffset)
			lineOffset += 50
loadLevel = ->
	window.updateLock = true
	delete @board

	@board = new Board(10, 7, 60)
	@hint = null
	names = []
	if @personified
		@board.unitTypes.push(new UnitType("main_char_large.png", 31, 6))
		@board.unitTypes.push(new UnitType("light_knight_large.png", 33, 6))
		@board.unitTypes.push(new UnitType("heavy_knight_large.png", 26, 3, "heavy_knight_stunned_large.png"))
		@board.unitTypes.push(new UnitType("light_archer_large.png", 20, 6))
		names = [["Brynjar"], ["Payton", "Winfried", "Algar", "Swithin"], ["Godric", "Dudda"], ["Edmund", "Leofric", "Oswin", "Eadwig"]]
		types = ["You", "Light soldiers", "Heavy knights", "Archers"]
	else
		@board.unitTypes.push(new UnitType("tile_blue.png", 30, 22))
		@board.unitTypes.push(new UnitType("tile_red.png", 30, 22))
		@board.unitTypes.push(new UnitType("tile_red_square.png", 30, 22, "tile_red_square.png"))
		@board.unitTypes.push(new UnitType("tile_red_star.png", 30, 22))
		names = [["you"], ["basic", "basic", "basic", "basic"], ["heavy", "heavy"], ["ranged", "ranged", "ranged", "ranged"]]
		types = ["You", "basic units", "heavy units", "ranged units"]
	for unit in @board.unitTypes
		unit.sprite.onload = ->
			redrawCanvas()
		unit.altSprite.onload = ->
			redrawCanvas()

	console.log("Starting level #{levelNumber}")
	switch levelNumber
		when -2
			@board.each (cell) ->
				cell.toggle()
			@board.units.push(new Unit(@board, 4, 2, 0, true, "Lunge/Swipe", names[0][0]))

		when 0
			@board.toggleSet([2,2, 2,3])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@hint = ["Click on a tile", "to move there"]
			@hintX = 920
			@hintY = 330

		when 1
			@board.toggleSet([2,2, 2,3, 2,4])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 2, 4, 1, true, "Stab", names[1][0]))
			@hint = ["Move towards an enemy", "to perform an", "attack"]
			@hintX = 920
			@hintY = 330

		when 2
			@board.toggleSet([2,2, 2,3, 3,2])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 2, 3, 1, true, "Stab", names[1][0]))
			@hint = ["Moving to strafe", "enemies also works"]

		when 3
			@board.toggleSet([1,2, 1,3, 1,4, 2,2, 2,3, 2,4, 3,1, 3,2, 3,3])
			@board.units.push(new Unit(@board, 1, 2, 0, true, "Lunge/Swipe", names[0]))
			@board.units.push(new Unit(@board, 1, 4, 1, true, "Stab", names[1][0]))
			@board.units.push(new Unit(@board, 2, 4, 1, true, "Stab", names[1][1]))
			@board.units.push(new Unit(@board, 3, 1, 1, true, "Stab", names[1][2]))
			@hint = ["Try using", "both types", "of attacks"]
			@hintY = 290

		when 4
			@board.toggleSet([2,1, 2,2, 2,3, 2,4, 2,5, 3,1, 3,2, 3,3, 3,4, 3,5])
			@board.units.push(new Unit(@board, 2, 1, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 3, 5, 3, true, "Range", names[3][0]))
			@hint = [types[3] + " can only", "shoot in straight", "lines"]
			@hintY = 290

		when 5
			@board.toggleSet([2,2, 3,2, 4,2, 4,3])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 4, 2, 3, true, "Range", names[3][0]))
			@hint = [types[3] + " can't", "attack if you're", " too close"]

		when 6
			@board.toggleSet([2,2, 2,3, 2,4, 2,5, 2,6, 3,3, 3,4])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 2, 5, 1, true, "Stab", names[1][0]))
			@board.units.push(new Unit(@board, 2, 6, 3, true, "Range", names[3][0]))
			@hint = [types[3] + " can be", "blocked by other", "enemies"]

		when 7
			@board.toggleSet([1,2, 1,3, 2,2, 2,3, 3,1, 3,2, 3,3, 4,2, 4,3, 4,4])
			@board.units.push(new Unit(@board, 3, 1, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 1, 3, 3, true, "Range", names[3][0]))
			@board.units.push(new Unit(@board, 4, 4, 3, true, "Range", names[3][1]))
			@hint = ["Think before", "you move"]
			@hintY = 260

		when 8
			@board.toggleSet([2,2, 2,3, 2,4, 3,2, 4,3])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 2, 4, 2, false, "Stab", names[2][0]))
			@board.units.push(new Unit(@board, 4, 3, 2, false, "Stab", names[2][1]))
			@hint = [types[2] + " don't", "stay dead"]
			@hintY = 320

		when 9
			@board.toggleSet([2,5, 3,4, 4,2, 4,3, 4,4, 5,1, 5,2, 5,3, 6,1, 7,0])
			@board.units.push(new Unit(@board, 4, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 2, 5, 2, false, "Stab", names[2][0]))
			@board.units.push(new Unit(@board, 6, 1, 2, false, "Stab", names[2][1]))
			@hint = ["...only", "for three", "turns"]
			@hintY = 260

		when 10
			@board.toggleSet([1,2, 1,3, 1,4, 2,3, 2,4, 3,2, 3,3, 3,4, 4,3, 4,4, 5,2, 5,3, 5,4])
			@board.units.push(new Unit(@board, 3, 3, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 1, 2, 1, true, "Stab", names[1][0]))
			@board.units.push(new Unit(@board, 1, 4, 1, true, "Stab", names[1][1]))
			@board.units.push(new Unit(@board, 5, 2, 1, true, "Stab", names[1][2]))
			@board.units.push(new Unit(@board, 5, 4, 1, true, "Stab", names[1][3]))
			@hint = (["Good luck"])
			@hintY = 440

		when 11
			@board.toggleSet([1,2, 1,3, 1,4, 2,3, 2,4, 3,2, 3,3, 3,4, 4,3, 4,4, 5,2, 5,3, 5,4])
			@board.units.push(new Unit(@board, 3, 3, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 1, 2, 3, true, "Range", names[3][0]))
			@board.units.push(new Unit(@board, 1, 4, 3, true, "Range", names[3][1]))
			@board.units.push(new Unit(@board, 5, 2, 3, true, "Range", names[3][2]))
			@board.units.push(new Unit(@board, 5, 4, 3, true, "Range", names[3][3]))

		when 12
			@board.toggleSet([0,2, 0,5, 1,2, 1,3, 1,4, 2,2, 2,3, 2,4, 3,1, 3,2, 3,3, 3,4, 4,2, 4,3, 4,4, 5,2, 5,3, 5,4, 6,2, 6,5])
			@board.units.push(new Unit(@board, 3, 3, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 0, 2, 3, true, "Range", names[3][0]))
			@board.units.push(new Unit(@board, 0, 5, 3, true, "Range", names[3][1]))
			@board.units.push(new Unit(@board, 6, 2, 3, true, "Range", names[3][2]))
			@board.units.push(new Unit(@board, 6, 5, 3, true, "Range", names[3][3]))
			@board.units.push(new Unit(@board, 1, 2, 1, true, "Stab", names[1][0]))
			@board.units.push(new Unit(@board, 1, 4, 1, true, "Stab", names[1][1]))
			@board.units.push(new Unit(@board, 5, 2, 1, true, "Stab", names[1][2]))
			@board.units.push(new Unit(@board, 5, 4, 1, true, "Stab", names[1][3]))

		when 13
			@board.toggleSet([1,2, 1,3, 1,4, 1,5, 2,2, 2,3, 2,4, 2,5, 3,2, 3,3, 3,4, 3,5])
			@board.units.push(new Unit(@board, 2, 2, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 1, 5, 3, true, "Range", names[3][0]))
			@board.units.push(new Unit(@board, 3, 5, 3, true, "Range", names[3][1]))
			@board.units.push(new Unit(@board, 1, 4, 1, true, "Stab", names[1][0]))
			@board.units.push(new Unit(@board, 2, 5, 1, true, "Stab", names[1][1]))
			@board.units.push(new Unit(@board, 3, 4, 1, true, "Stab", names[1][2]))
			@board.units.push(new Unit(@board, 2, 4, 2, false, "Stab", names[2][0]))

		when 14
			@board.toggleSet([0,3, 0,4, 1,2, 1,4, 2,2, 2,3, 2,5, 3,1, 3,2, 3,3, 3,5, 4,1, 4,2, 4,3, 4,4, 4,5, 4,6, 5,1, 5,2, 5,3, 5,5, 6,2, 6,3, 6,5, 7,2, 7,4, 8,3, 8,4])
			@board.units.push(new Unit(@board, 4, 1, 0, true, "Lunge/Swipe", names[0][0]))
			@board.units.push(new Unit(@board, 1, 4, 3, true, "Range", names[3][0]))
			@board.units.push(new Unit(@board, 7, 4, 3, true, "Range", names[3][1]))
			@board.units.push(new Unit(@board, 4, 6, 2, false, "Stab", names[2][0]))
			@hintY = 100
			@hint = ["A final test"]

		else
			@board.toggle(4,3)
			@board.units.push(new Unit(@board, 4, 3, 0, true, "Lunge/Swipe", names[0][0]))
			@hint = ["Congratulations, you beat", "          all the levels!", "", "Please get the attention", "          of Matthew."]
			@hintY = 100
			console.log("Trying to spawn for unknown level" + levelNumber)
	window.inLevel = true
	window.updateLock = false
	redrawCanvas()

disableDamageMarkers = ->
	@damageMarkers = []

unitsMove = ->
	@nextUnitIndex = 0
	unitAnimateCallback()

unitsMoveCallback = ->
	while @nextUnitIndex < @board.units.length
		unit = @board.units[@nextUnitIndex]
		if unit.alive and not unit.stunned
			move = unit.makeMove()
			if move?
				move.tick(10)
				redrawCanvas()
			setTimeout(unitAnimateCallback, 25)
			return
		@nextUnitIndex++
	setTimeout(testCompletionCallback, 250)

unitAnimateCallback = ->
	unit = @board.units[@nextUnitIndex]
	if unit.atTarget() and not unit.projectileX?
		@nextUnitIndex++
		unitsMoveCallback()
		return
	else
		unit.tick(10)
		redrawCanvas()
		setTimeout(unitAnimateCallback, 25)
		return


testCompletion = ->
	if not @board.units[0].alive
		console.log("Player died.")
		alert("You died!")
		return loadLevel()
	for unit in @board.units
		if unit.type != 0 and unit.alive and not unit.stunned
			window.updateLock = false
			for unit in @board.units
				unit.stunDuration-- if unit.stunned
				unit.stunned = false if unit.stunDuration==0
			return
	alert("Well done!")
	@levelNumber++
	loadLevel()

testCompletionCallback = ->
	window.updateLock = false
	testCompletion()

$(document).ready ->
	setTimeout(initialize, 500)
