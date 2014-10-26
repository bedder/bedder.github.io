class @Board
	constructor: (@width, @height, @radius) ->
		@cells         = []
		@cellWidth     = @radius * 2
		@cellHeight    = 2 * Math.round(Math.sqrt(0.75 * @radius * @radius))
		@subcellWidth  = @radius * (6 / 4)
		@subcellHeight = @cellHeight / 2;
		@aspect        = @subcellHeight / (@radius / 2)
		@selected      = null
		@unitTypes     = []
		@units         = []
		for i in [0...@width]
			@cells.push([])
			for j in [0...@height]
				@cells[i].push(new Cell(this, i, j))

	each: (fn) ->
		for i in [0...@width]
			for j in [0...@height] by 2
				fn @at(i, j)
			for j in [1...@height] by 2
				fn @at(i, j)

	toggle: (i, j) ->
		@selected = @at(i, j)
		@selected.toggle() if @selected?
		this

	toggleAtPoint: (x, y) ->
		@selected = @atPoint(x, y)
		@selected.toggle() if @selected?
		this

	at: (i, j) ->
		return if (i >= @cells.length) or (j >= @cells[0].length) or (i < 0) or (j < 0)
		@cells[i][j]

	enableAtPoint: (x, y) ->
		@selected = this.atPoint(x, y)

	atPoint: (x, y) ->
		subcellX   = Math.floor(x / @subcellWidth)
		remainderX = x - (subcellX * @subcellWidth)
		subcellY   = Math.floor(y / @subcellHeight)
		remainderY = y - (subcellY * @subcellHeight)
		i = subcellX
		j = Math.floor((subcellY - (i % 2)) / 2)
		if remainderX < (@subcellWidth / 3)
			if ((subcellX + subcellY) % 2) == 0
				if remainderX * @aspect + remainderY < @subcellHeight
					i -= - 1
					j -= - (i % 2)
			else
				if remainderX * @aspect < remainderY
					j += + (i % 2)
					i -= - 1
		this.at(i, j)

class @Cell
	constructor: (@board, @i, @j) ->
		@enabled    = true
		@x          = @i * @board.subcellWidth
		@y          = @board.cellHeight * (2 * @j + (@i % 2)) / 2
		@numCorners = 6
		@centerX    = @x + (@board.cellWidth / 2)
		@centerY    = @y + @board.subcellHeight
		@cornersX   = [ @board.cellWidth / 4, @board.subcellWidth, @board.cellWidth, @board.subcellWidth, @board.cellWidth / 4, 0 ]
		@cornersX   = for value in @cornersX
			value + @x
		@cornersY   = [ 0, 0, @board.subcellHeight, @board.cellHeight, @board.cellHeight, @board.subcellHeight]
		@cornersY   = for value in @cornersY
			value + @y
		@occupied   = false

	toggle: ->
		@enabled = !@enabled
		@occupied = !@occupied

	visible: (iTarget, jTarget) ->
		@iDelta = @i - iTarget
		@jDelta = @j - jTarget
		if (@i % 2) == 0
			@sign = +1
		else
			@sign = -1
		(@i == iTarget) or (@iDelta-2*@jDelta == 0) or (@iDelta-2*@jDelta == -@sign) or (@iDelta+2*@jDelta == 0) or (@iDelta+2*@jDelta == @sign)

	distance: (iTarget, jTarget) ->
		Math.max(Math.abs(@i - iTarget), Math.abs(@j - jTarget))

	draw: (context) ->
		if @enabled
			context.moveTo @cornersX[0], @cornersY[0]
		for index in [1...@numCorners]
			context.lineTo @cornersX[index],  @cornersY[index]
			context.lineTo @cornersX[0], @cornersY[0]

class @UnitType
	constructor: (spriteLocation, @offsetX, @offsetY, altSpriteLocation=null) ->
		@sprite = new Image()
		@sprite.src = spriteLocation
		@altSprite = new Image()
		if altSpriteLocation?
			@altSprite.src = altSpriteLocation

class @Unit
	constructor: (@board, @i, @j, @type, @killable=true) ->
		@alive    = true
		@stunned  = false
		if @board.cells[@i][@j].occupied
			console.log("Error: Trying to put new unit in an occupied tile")
			return
		@board.cells[@i][@j].occupied = true
		currentType = @board.unitTypes[@type]
		@x = @board.cells[@i][@j].x + currentType.offsetX
		@y = @board.cells[@i][@j].y + currentType.offsetY
		@targetX = @x
		@targetY = @y

	makeMove: ->
		for cellArr in @board.cells
			for cell in cellArr
				if (cell.visible(@i, @j)) and (cell.distance(@i, @j) == 1)
					if cell == @board.cells[@board.units[0].i][@board.units[0].j] and @board.units[0].alive
						return @move(cell.i, cell.j)
					if (not cell.occupied)
						return @move(cell.i, cell.j)

	move: (iTarget, jTarget) ->
		if @board.cells[iTarget][jTarget].occupied
			for unit in @board.units
				if iTarget == unit.i and jTarget == unit.j
					unit.kill()
			return if @board.cells[iTarget][jTarget].occupied
		@board.cells[iTarget][jTarget].occupied = true
		@board.cells[@i][@j].occupied = false
		@i = iTarget
		@j = jTarget
		@targetX = @board.cells[@i][@j].x
		@targetY = @board.cells[@i][@j].y
		this

	atTarget: () ->
		return (@x == @targetX) and (@y == @targetY)

	tick: (maxDistance) ->
		deltaX = @targetX - @x
		deltaY = @targetY - @y
		delta  = Math.sqrt(deltaX * deltaX + deltaY * deltaY)
		if delta > maxDistance
			proportion = maxDistance / delta
			@x += (proportion * deltaX)
			@y += (proportion * deltaY)
		else
			@x = @targetX
			@y = @targetY

	kill: () ->
		if @killable == true
			@alive = false
			@board.cells[@i][@j].occupied = false
		else
			@stunned = true

class @Sprite
	constructor: (spriteSheet, @frameWidth, @frameHeight, @nFrames) ->
		@image = new Image()
		@image.src = spriteSheet
		@frameNumber = 0

	draw: (context, x, y) ->
		context.drawImage(@image, @frameNumber * @frameWidth, 0, @frameWidth, @frameHeight, x, y, @frameWidth, @frameHeight)

	nextFrame: () ->
		@frameNumber++
		@frameNumber = 0 if @frameNumber >= @nFrames
		this