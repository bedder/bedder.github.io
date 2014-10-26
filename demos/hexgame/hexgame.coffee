@tile = new Image()
@tile.src = "tile_small.png"
@tile_light = new Image()
@tile_light.src = "tile_small_light.png"
@tile_red = new Image()
@tile_red.src = "tile_small_red.png"
window.inLevel = false
window.updateLock = false

initialize = ->
	@canvas	= $("#canvas")[0]
	@context = canvas.getContext("2d")
	@levelNumber = 0

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
					@context.drawImage(tile_red, cell.x, cell.y)
				else
					@context.drawImage(tile_light, cell.x, cell.y)
			else
				@context.drawImage(tile, cell.x, cell.y)
		@context.closePath()
	for unit in @board.units
		if unit.type == 0 or unit.alive
			currentType = @board.unitTypes[unit.type]
			unit.tick(5)
			if not unit.stunned
				@context.drawImage(currentType.sprite, unit.x, unit.y)
			else
				@context.drawImage(currentType.altSprite, unit.x, unit.y)

loadLevel = ->
	window.updateLock = true
	delete @board

	@board = new Board(9, 7, 60)
	@board.toggle(0,0).toggle(8,0)
	@board.unitTypes.push(new UnitType("main_char_100.png", 7, 1))
	@board.unitTypes.push(new UnitType("light_knight_100.png", 3, 1))
	@board.unitTypes.push(new UnitType("heavy_knight_100.png", 14, 1, "heavy_knight_stunned_100.png"))
	@board.unitTypes.push(new UnitType("light_archer_100.png", 5, 1))
	for unit in @board.unitTypes
		unit.sprite.onload = ->
			redrawCanvas()
		unit.altSprite.onload = ->
			redrawCanvas()

	switch levelNumber
		when 0
			console.log("Starting spawn for L0")
			@board.units.push(new Unit(@board, 4, 0, 0))
			@board.units.push(new Unit(@board, 3, 5, 1))
			@board.units.push(new Unit(@board, 4, 5, 1))
			@board.units.push(new Unit(@board, 5, 5, 1))
			@board.units.push(new Unit(@board, 3, 6, 3))
			@board.units.push(new Unit(@board, 4, 6, 3))
			@board.units.push(new Unit(@board, 5, 6, 3))
		when 1
			console.log("Starting spawn for L1")
			@board.units.push(new Unit(@board, 4, 0, 0))
			@board.units.push(new Unit(@board, 4, 4, 2, false))
			@board.units.push(new Unit(@board, 3, 5, 1))
			@board.units.push(new Unit(@board, 4, 5, 1))
			@board.units.push(new Unit(@board, 5, 5, 1))
			@board.units.push(new Unit(@board, 3, 6, 3))
			@board.units.push(new Unit(@board, 4, 6, 3))
			@board.units.push(new Unit(@board, 5, 6, 3))
		else
			console.log("Trying to spawn for unknown level" + levelNumber)
	window.inLevel = true
	window.updateLock = false
	redrawCanvas()

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
	if unit.atTarget()
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
		if unit.type != 0 and unit.alive
			window.updateLock = false
			return
	alert("You killed everyone. Well done?")
	@levelNumber++
	loadLevel()

testCompletionCallback = ->
	window.updateLock = false
	testCompletion()

$(document).ready ->
	setTimeout(initialize, 500)