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

	toggleAtPels: (x, y) ->
		@selected = @atPels(x, y)
		@selected.toggle() if @selected?
		this

	at: (i, j) ->
		return if (i >= @cells.length) or (j >= @cells[0].length) or (i < 0) or (j < 0)
		@cells[i][j]

	atUnit: (unit) ->
		@at(unit.i, unit.j)

	atPels: (x, y) ->
		subcellX   = Math.floor(x / @subcellWidth)
		remainderX = x - (subcellX * @subcellWidth)
		subcellY   = Math.floor(y / @subcellHeight)
		remainderY = y - (subcellY * @subcellHeight)
		i = subcellX
		j = Math.floor((subcellY - (i % 2)) / 2)
		if remainderX < (@subcellWidth / 3)
			if ((subcellX + subcellY) % 2) == 0
				if remainderX * @aspect + remainderY < @subcellHeight
					i--
					j -= (i % 2)
			else
				if remainderX * @aspect < remainderY
					i--
					j += ((i + 1) % 2)
		this.at(i, j)

	selectAtPels: (x, y) ->
		@selected = this.atPels(x, y)

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

	visibleUnit: (unit) ->
		@visible(unit.i, unit.j)

	distance: (iTarget, jTarget) ->
		if @visible(iTarget, jTarget)
			Math.max(Math.abs(@i - iTarget), Math.abs(@j - jTarget))
		else
			NaN

	distanceUnit: (unit) ->
		@distance(unit.i, unit.j)

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
	constructor: (@board, @i, @j, @type, @killable=true, @attackType="Stab") ->
		@alive    = true
		@stunned  = false
		if @board.at(@i, @j).occupied
			console.log("Error: Trying to put new unit in an occupied tile")
			return
		@board.at(@i, @j).occupied = true
		currentType = @board.unitTypes[@type]
		@x = @board.at(@i, @j).x + currentType.offsetX
		@y = @board.at(@i, @j).y + currentType.offsetY
		@targetX = @x
		@targetY = @y

	makeMove: ->
		for cellArr in @board.cells
			for cell in cellArr
				if (cell.distance(@i, @j) == 1)
					if cell == @board.atUnit(@board.units[0]) and @board.units[0].alive
						return @move(cell.i, cell.j)
					if (not cell.occupied)
						return @move(cell.i, cell.j)

	move: (iTarget, jTarget) ->
		# Detect if the move is valid
		if @board.at(iTarget, jTarget).occupied and @attackType!="Stab"
			console.log("Cannot move into that cell")
			return this

		# Detect if any units are going to be killed
		if @attackType=="Lunge" or @attackType=="Lunge/Swipe"
			console.log("Testing lunge")
			for cellArr in @board.cells
				for cell in cellArr
					if cell.occupied and cell.distance(@i, @j)==2 and cell.distance(iTarget, jTarget)==1
						for unit in @board.units
							unit.kill() if (unit.i==cell.i) and (unit.j==cell.j)
		if @attackType=="Swipe" or @attackType=="Lunge/Swipe"
			for cellArr in @board.cells
				for cell in cellArr
					if cell.occupied and cell.distance(@i, @j)==1 and cell.distance(iTarget, jTarget)==1
						for unit in @board.units
							unit.kill() if (unit.i==cell.i) and (unit.j==cell.j)
		if @attackType=="Stab"
			if @board.at(iTarget, jTarget).occupied
				for unit in @board.units
					unit.kill() if (iTarget == unit.i) and (jTarget == unit.j)
			# Detect stabbing kills
		#if @attackType=="Range"
			# Not applicable

		return if @board.at(iTarget, jTarget).occupied
		@board.at(iTarget, jTarget).occupied = true
		@board.at(@i, @j).occupied = false
		@i = iTarget
		@j = jTarget
		currentType = @board.unitTypes[@type]
		@targetX = @board.at(@i, @j).x + currentType.offsetX
		@targetY = @board.at(@i, @j).y + currentType.offsetY
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
			@board.at(@i, @j).occupied = false
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