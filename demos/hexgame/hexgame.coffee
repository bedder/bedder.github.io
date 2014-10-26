@sprites = new Object()
@damageMarkers = []

window.inLevel = false
window.updateLock = false

initialize = ->
	@canvas	= $("#canvas")[0]
	@context = canvas.getContext("2d")
	@levelNumber = 0

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
			if selected? and (selected.distanceUnit(board.units[0]) == 1)
				board.units[0].move(selected.i, selected.j)
				unitsMove()
			else
				window.updateLock = false;
	loadLevel()
	redrawCanvas()

redrawCanvas = ->
	@context.clearRect(0, 0, @canvas.width, @canvas.height)
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

loadLevel = ->
	window.updateLock = true
	delete @board

	@board = new Board(9, 7, 60)
	@board.toggle(0,0).toggle(8,0)
	@board.unitTypes.push(new UnitType("main_char_large.png", 31, 6))
	@board.unitTypes.push(new UnitType("light_knight_large.png", 33, 6))
	@board.unitTypes.push(new UnitType("heavy_knight_large.png", 26, 3, "heavy_knight_stunned_large.png"))
	@board.unitTypes.push(new UnitType("light_archer_large.png", 20, 6))
	for unit in @board.unitTypes
		unit.sprite.onload = ->
			redrawCanvas()
		unit.altSprite.onload = ->
			redrawCanvas()

	switch levelNumber
		when 0
			console.log("Starting spawn for L0")
			@board.units.push(new Unit(@board, 4, 0, 0, true, "Lunge/Swipe"))
			#@board.units.push(new Unit(@board, 3, 3, 3, true, "Range"))
			#@board.units.push(new Unit(@board, 4, 3, 3, true, "Range"))
			#@board.units.push(new Unit(@board, 5, 3, 3, true, "Range"))
			#@board.units.push(new Unit(@board, 4, 4, 2, false))
			@board.units.push(new Unit(@board, 3, 4, 1))
			@board.units.push(new Unit(@board, 4, 4, 1))
			@board.units.push(new Unit(@board, 5, 4, 1))
		when 1
			console.log("Starting spawn for L1")
			@board.units.push(new Unit(@board, 4, 0, 0, true, "Lunge/Swipe"))
			@board.units.push(new Unit(@board, 4, 4, 2, false))
			@board.units.push(new Unit(@board, 3, 5, 1))
			@board.units.push(new Unit(@board, 4, 5, 1))
			@board.units.push(new Unit(@board, 5, 5, 1))
			@board.units.push(new Unit(@board, 3, 6, 3, true, "Range"))
			@board.units.push(new Unit(@board, 4, 6, 3, true, "Range"))
			@board.units.push(new Unit(@board, 5, 6, 3, true, "Range"))
		else
			@board.units.push(new Unit(@board, 4, 0, 0, true, "Lunge/Swipe"))
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
			unit.makeMove().tick(10)
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
		alert("You died!")
		return loadLevel()
	for unit in @board.units
		if unit.type != 0 and unit.alive and not unit.stunned
			window.updateLock = false
			for unit in @board.units
				unit.stunDuration-- if unit.stunned
				unit.stunned = false if unit.stunDuration==0
			return
	alert("You killed everyone. Well done?")
	@levelNumber++
	loadLevel()

testCompletionCallback = ->
	window.updateLock = false
	testCompletion()

$(document).ready ->
	setTimeout(initialize, 500)