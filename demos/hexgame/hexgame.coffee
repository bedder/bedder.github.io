@tile = new Image()
@tile.src = "tile_small.png"
window.inLevel = false
window.updateLock = false

initialize = ->
	@canvas	= $("#canvas")[0]
	@context = canvas.getContext("2d")
	@levelNumber = 0

	$("#canvas").mousemove (event) ->
		#

	$("#canvas").click (event) ->
		if window.inLevel and not window.updateLock
			window.updateLock = true;
			selected = board.atPoint(event.offsetX, event.offsetY)
			if selected? and selected.visible(board.units[0].i, board.units[0].j) and selected.distance(board.units[0].i, board.units[0].j) == 1
				board.units[0].move(selected.i, selected.j)
				redrawCanvas()
				unitsMove()
			else
				window.updateLock = false;
		else
			console.log("Be patient!", window.inLevel, window.updateLock)
	loadLevel()
	redrawCanvas()

redrawCanvas = ->
	@context.clearRect(0, 0, @canvas.width, @canvas.height)
	@context.lineWidth=3;
	@context.strokeStyle="#0000ff";
	@board.each (cell) ->
		@context.beginPath()
		@context.drawImage(tile, cell.x, cell.y) if cell.enabled
		if @board.selected == cell
			@context.font = "bold 25px sans-serif";
			@context.lineCap="round";
			@context.fillStyle="rgba(35,89,42,0.2)";
			@context.fill()
			@context.fillStyle="rgba(255,255,255,0.2)";
			@context.fillText("#{@board.selected.horizontalIndex},#{@board.selected.verticalIndex}", @board.selected.centerX - 20, @board.selected.centerY + 8)
		@context.closePath()
	for unit in @board.units
		if unit.alive
			currentType = @board.unitTypes[unit.type]
			x = @board.cells[unit.i][unit.j].x + currentType.offsetX
			y = @board.cells[unit.i][unit.j].y + currentType.offsetY
			if not unit.stunned
				@context.drawImage(currentType.sprite, x, y)
			else
				@context.drawImage(currentType.altSprite, x, y)

loadLevel = ->
	window.updateLock = true
	delete @board

	@board = new Board(9, 7, 60)
	@board.toggle(0,0).toggle(8,0)
	@board.unitTypes.push(new UnitType("main_char_100.png", 5, 1))
	@board.unitTypes.push(new UnitType("light_knight_100.png", 3, 1))
	@board.unitTypes.push(new UnitType("heavy_knight_100.png", 7, 1, "heavy_knight_stunned_100.png"))
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
	@nextUnitIndex = 1
	unitsMoveCallback()

unitsMoveCallback = ->
	while @nextUnitIndex < @board.units.length
		unit = @board.units[@nextUnitIndex]
		if unit.alive and not unit.stunned
			unit.makeMove()
			redrawCanvas()
			@nextUnitIndex++
			setTimeout(unitsMoveCallback, 250)
			return
		@nextUnitIndex++
	setTimeout(testCompletionCallback, 250)

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