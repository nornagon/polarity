canvas = atom.canvas
canvas.width = 400
canvas.height = 200
ctx = atom.context
v = cp.v

atom.input.bind atom.key.A, 'a'
atom.input.bind atom.key.S, 's'

atom.input.bind atom.key.P, 'edit'
atom.input.bind atom.button.LEFT, 'click'
atom.input.bind atom.key.SPACE, 'select'
atom.input.bind atom.key.V, 'save'
atom.input.bind atom.key.R, 'reset'
atom.input.bind atom.key.N, 'skip'
atom.input.bind atom.key.B, 'back'
atom.input.bind atom.key.M, 'name'

rnd = (n=1) -> n * Math.random()
mrnd = (n=1) -> n * (2*Math.random()-1)
irnd = (n) -> Math.floor n * Math.random()

parseXY = (k) ->
  [x,y] = k.split /,/
  {x:parseInt(x), y:parseInt(y)}

TILE_SIZE = 10

tileset = new Image
tileset.src = 'ld.gif'

tileAt = (x,y,w=TILE_SIZE/2,h=TILE_SIZE/2) ->
	{x:x*2,y:y*2,w:w*2,h:h*2}
animAt = (frames,x,y,w=TILE_SIZE/2,h=TILE_SIZE/2) ->
	{x:x*2,y:y*2,w:w*2,h:h*2,frames}
drawTile = (tile, x, y) ->
	ctx.save()
	ctx.translate Math.round(x), Math.round(y)+tile.h
	ctx.scale 1, -1
	ctx.drawImage tileset, tile.x, tile.y, tile.w, tile.h, 0, 0, tile.w, tile.h
	ctx.restore()
drawFrame = (anim, frame, x, y) ->
	ctx.save()
	ctx.translate Math.round(x), Math.round(y)+anim.h
	ctx.scale 1, -1
	ctx.drawImage tileset, anim.x + frame*anim.w, anim.y, anim.w, anim.h, 0, 0, anim.w, anim.h
	ctx.restore()

screenToWorld = (x, y) ->
	{x: x, y: (canvas.height-y)}

Tiles =
	block:
		tile: tileAt 20, 5
		draw: (x, y) ->
			drawTile @tile, x, y
	positive:
		tile: tileAt 10, 0
		draw: (x, y) -> drawTile @tile, x, y
		ethereal: true
	negative:
		tile: tileAt 5, 5
		draw: (x, y) -> drawTile @tile, x, y
		ethereal: true
	antimatter:
		tile: tileAt 35, 15
		draw: (x, y) -> drawTile @tile, x, y
		sensor: true
	goal:
		tile: tileAt 55, 5
		draw: (x, y) -> drawTile @tile, x, y
		sensor: true

	player_start:
		ethereal: true
		draw: (x, y) ->
			ctx.strokeStyle = 'black'
			ctx.lineWidth = 1
			ctx.beginPath()
			ctx.moveTo x,y
			ctx.lineTo x+TILE_SIZE, y+TILE_SIZE
			ctx.moveTo x+TILE_SIZE, y
			ctx.lineTo x, y+TILE_SIZE
			ctx.stroke()

	player:
		tile: animAt 1, 25, 45
		draw: (f,x,y) -> drawFrame @tile, f, x, y
	player_positive:
		tile: animAt 5, 32, 37, 11, 11
		draw: (f,x,y) -> drawFrame @tile, f, x, y
	player_negative:
		tile: animAt 5, 32, 48, 11, 11
		draw: (f,x,y) -> drawFrame @tile, f, x, y


Shrapnel =
	[
		tile: tileAt 76, 21, 3, 3
		draw: (x, y) -> drawTile @tile, x-@tile.w/2, y-@tile.h/2
	,
		tile: tileAt 81, 22, 2, 2
		draw: (x, y) -> drawTile @tile, x-@tile.w/2, y-@tile.h/2
	,
		tile: tileAt 81, 16, 3, 3
		draw: (x, y) -> drawTile @tile, x-@tile.w/2, y-@tile.h/2
	]


empty_level = {"tiles":{"5,6":"block","8,6":"block","6,6":"block","7,6":"block"}, "player_start":{x:7,y:8}}

attract_level =
  {"name":"","tiles":{"8,8":"antimatter","6,8":"block","9,8":"block","35,-1":"block","6,7":"block","2,16":"block","2,15":"block","2,14":"block","2,13":"block","2,12":"block","2,11":"block","2,10":"block","2,9":"block","2,8":"block","3,8":"block","4,8":"block","5,8":"block","35,3":"antimatter","39,9":"positive","2,17":"block","2,18":"block","2,19":"block","36,2":"block","35,2":"block","34,2":"block","4,12":"block","4,13":"block","4,14":"block","4,15":"block","4,16":"block","4,17":"block","4,18":"block","4,19":"block","37,2":"block","38,2":"block","2,-1":"block","4,-1":"block","9,9":"block","10,9":"positive","38,-1":"block","36,3":"antimatter","37,3":"antimatter","38,3":"block","9,10":"block","9,11":"block","38,19":"block","38,18":"block","38,17":"block","38,16":"block","38,15":"block","38,14":"block","38,13":"block","38,12":"block","38,11":"block","38,10":"block","38,9":"block","35,19":"block","35,18":"block","35,17":"block","35,16":"block","35,15":"block","35,14":"block","35,13":"block","35,12":"block","35,11":"block","35,10":"block","34,10":"block","38,8":"block","37,8":"block","36,8":"block","35,8":"block","34,8":"block","33,10":"block","32,10":"block","31,10":"block","31,9":"block","31,8":"block","7,8":"antimatter","31,7":"block","31,6":"block","31,5":"block","31,4":"block","34,7":"block","34,6":"block","35,6":"block","36,6":"block","37,6":"block","38,6":"block","38,4":"block","38,5":"block","31,3":"block","32,3":"block","33,3":"block","34,3":"block","8,11":"block","7,11":"block","6,11":"block","5,11":"block","4,11":"block","9,7":"block","8,7":"block","7,7":"block","31,12":"player_negative","39,4":"negative"}}

class Level
	constructor: (json) ->
		@tiles = []
		@nodes = {}
		for xy,type of json.tiles
			{x,y} = parseXY xy
			@tiles.push {x, y, type}
			@nodes[[x,y]] = {x, y, type} if type in ['positive','negative']
		@name = json.name
		@player_start = json.player_start


	occupy: (@space) ->
		@occupyTile t for t in @tiles
	occupyTile: (t) ->
		{x, y, type} = t
		return if Tiles[type].ethereal
		t.shape = new cp.BoxShape2 @space.staticBody,
			{l:x*TILE_SIZE, b:y*TILE_SIZE, r:(x+1)*TILE_SIZE, t:(y+1)*TILE_SIZE}
		t.shape.setElasticity 0.4
		t.shape.setFriction 0.8
		t.shape.collision_type = type
		if Tiles[type].sensor
			t.shape.sensor = true
		@space.addShape t.shape

	export: ->
		json = {name:@name, tiles:{}, player_start:@player_start}
		for t in @tiles
			json.tiles[[t.x,t.y]] = t.type
		json

	setTile: (x, y, type) ->
		if type is 'player_start'
			@player_start = {x, y}
			return
		delete @nodes[[x,y]]
		for t,i in @tiles
			if t.x == x and t.y == y
				if t.shape
					@space.removeShape t.shape
				break
		if i < @tiles.length
			@tiles[i] = @tiles[@tiles.length-1]
			@tiles.length--
		if type?
			@tiles.push t = {x, y, type}
			@occupyTile t
		if type in ['positive','negative']
			@nodes[[x,y]] = {x,y,type}

	draw: (edit_mode) ->
		for {x, y, type} in @tiles
			if type of Tiles
				Tiles[type].draw(x*TILE_SIZE,y*TILE_SIZE)
		if edit_mode and @player_start
			Tiles.player_start.draw @player_start.x*TILE_SIZE, @player_start.y*TILE_SIZE
		return


class Game extends atom.Game
	constructor: ->
		@levels = (new Level l for l in level_data)
		@levelNum = -1

		@state = 'title'
		States[@state].init?.call this

	reset: ->
		@frameNo = 0
		@player_anim_start = 0
		@timers = {}
		@space = new cp.Space
		@playerDead = false
		@finishedLevel = false

		@space.addCollisionHandler 'player', 'antimatter', (arb) =>
			if not @playerDead
				@playerDead = true
				@space.addPostStepCallback @playerDied
			return false
		@space.addCollisionHandler 'player', 'goal', (arb) =>
			if not @finishedLevel
				@finishedLevel = true
				@space.addPostStepCallback @reachedGoal
			return false

		@space.addCollisionHandler 'ball', 'shrapnel', -> false

		@space.addCollisionHandler 'ball', 'antimatter', (arb) =>
			if arb.body_a in @balls
				@balls = (b for b in @balls when b != arb.body_a)
				b = arb.body_a
				p = v(arb.body_a.p.x, arb.body_a.p.y)
				@space.addPostStepCallback =>
					@space.removeShape b.shapeList[0]
					@space.removeBody b
					@shrapnel p

		@level.occupy @space

		@space.gravity = v(0,-50)
		floor = @space.addShape new cp.SegmentShape @space.staticBody, v(0,0), v(800,0), 0
		floor.setElasticity 1
		floor.setFriction 1

		wall1 = @space.addShape(new cp.SegmentShape(@space.staticBody, v(0, 0), v(0, 600), 0))
		wall1.setElasticity(1)
		wall1.setFriction(1)

		wall2 = @space.addShape(new cp.SegmentShape(@space.staticBody, v(800, 0), v(800, 600), 0))
		wall2.setElasticity(1)
		wall2.setFriction(1)
		

		if @level.player_start?
			@player = new cp.Body 1, cp.momentForCircle 1, 0, 5, v(0,0)
			@player.setPos v((@level.player_start.x+0.5) * TILE_SIZE, (@level.player_start.y+0.5) * TILE_SIZE)
			@space.addBody @player
			shape = @space.addShape new cp.CircleShape @player, 5, v(0,0)
			shape.setElasticity 0.5
			shape.setFriction 0.8
			shape.collision_type = 'player'
			that = this
			shape.draw = ->
				style = if atom.input.down 'a' then '_positive' else if atom.input.down 's' then '_negative' else ''
				tile = "player#{style}"
				frame = Math.floor((that.frameNo - that.player_anim_start) / 3)
				if frame >= Tiles[tile].tile.frames then frame = 0
				Tiles[tile].draw frame, @tc.x-Tiles[tile].tile.w/2, @tc.y-Tiles[tile].tile.w/2


	makeBall: (polarity, x, y) ->
		@balls ?= []
		ball = new cp.Body 1, cp.momentForCircle 1, 0, 5, v(0,0)
		ball.polarity = polarity
		@balls.push ball
		ball.setPos v((x+0.5) * TILE_SIZE, (y+0.5) * TILE_SIZE)
		@space.addBody ball
		shape = @space.addShape new cp.CircleShape ball, 5, v(0,0)
		shape.setElasticity 0.5
		shape.setFriction 0.8
		shape.collision_type = 'ball'
		that = this
		shape.draw = ->
			style = if polarity > 0 then '_positive' else if polarity < 0 then '_negative' else ''
			tile = "player#{style}"
			Tiles[tile].draw 0, @tc.x-Tiles[tile].tile.w/2, @tc.y-Tiles[tile].tile.w/2

	reachedGoal: =>
		@forward()
		@state = 'levelTransition'
		States[@state].init.call this
	forward: =>
		if @levelNum >= @levels.length-1
			@levels.push new Level empty_level
		@level = @levels[++@levelNum]
		@reset()
	back: =>
		if @levelNum > 0
			@levelNum--
		@level = @levels[@levelNum]
		@reset()

	playerDied: =>
		@space.removeShape s for s in @player.shapeList
		@space.removeBody @player
		@shrapnel @player.p
		@player = null
		@in 65, => @reset()

	shrapnel: (p) ->
		for [0..10]
			body = new cp.Body 1, cp.momentForCircle 1, 0, 2, v(0,0)
			shape = new cp.CircleShape body, 2, v(0,0)
			shape.group = 'shrapnel'
			shape.collision_type = 'shrapnel'
			body.setPos v(p.x, p.y)
			body.setVelocity v(mrnd(50), 50+mrnd(20))
			body.w = mrnd(5)
			@space.addBody body
			@space.addShape shape
			do (shape, body) =>
				i = irnd Shrapnel.length
				shape.draw = ->
					ctx.save()
					ctx.translate @body.p.x, @body.p.y
					ctx.rotate @body.a
					Shrapnel[i].draw 0, 0
					ctx.restore()
				@in 30+irnd(60), =>
					@space.removeShape shape
					@space.removeBody body

	in: (frames, cb) ->
		(@timers[@frameNo+frames] ?= []).push cb
	runTimers: ->
		todo = @timers[@frameNo]
		if todo
			delete @timers[@frameNo]
			t() for t in todo

	update: (dt) ->
		States[@state].update.call this, dt

	draw: ->
		ctx.fillStyle = 'rgb(36,49,61)'
		ctx.fillRect 0, 0, canvas.width, canvas.height
		States[@state].draw.call this

States =
	title:
		init: ->
			@level = new Level attract_level
			@reset()
		update: (dt) ->
			States.playing.update.call(this, dt)
			if rnd() < 0.005
				@makeBall 1,3,20
			if rnd() < 0.005
				@makeBall -1,37-irnd(2),20

			if atom.input.pressed 'a'
				@reachedGoal()
		draw: ->
			States.playing.draw.call(this)
			ctx.fillStyle = 'rgba(29,37,46,0.6)'
			ctx.fillRect 0, 0, canvas.width, canvas.height
			ctx.textBaseline = 'top'
			ctx.font = '56px "04b19Regular"'
			ctx.textAlign = 'center'
			ctx.fillStyle = 'white'
			ctx.fillText 'POLARITY', canvas.width/2, 20
			ctx.font = '28px "04b19Regular"'
			ctx.fillText 'PRESS A TO START!', canvas.width/2, 120
			ctx.font = '14px "04b19Regular"'
			#ctx.fillStyle = 'rgb(60, 142, 231)'
			ctx.fillStyle = 'rgb(143,182,214)'
			ctx.fillText 'A game by Jeremy Apthorp', canvas.width/2, 80
			ctx.fillText 'Made in 48 hours', canvas.width/2, 160
			ctx.fillText 'for Ludum Dare #23', canvas.width/2, 176

	playing:
		update: (dt) ->
			if atom.input.pressed 'edit'
				@state = 'editing'
				return

			if @player?
				if atom.input.down 'a'
					player_polarity = 1
				else if atom.input.down 's'
					player_polarity = -1

				if atom.input.pressed('a') or atom.input.pressed('s')
					@player_anim_start = @frameNo

			force_between = (b,p, n) ->
				polarity = if n.type is 'positive' then 1 else -1
				dx = ((n.x+0.5)*TILE_SIZE - b.x) * p * polarity
				dy = ((n.y+0.5)*TILE_SIZE - b.y) * p * polarity
				norm = Math.sqrt(dx*dx+dy*dy)
				nx = dx/norm
				ny = dy/norm
				# F = qQ/r^2
				# take qQ = k for now
				k = 80
				norm /= 50
				if norm < 1 then norm = 1
				norm2 = norm * norm
				f_x = k / norm2 * nx
				f_y = k / norm2 * ny
				{x:f_x, y:f_y}

			force = {x:0, y:0}
			if player_polarity
				for _,n of @level.nodes
					f = force_between @player.p, player_polarity, n
					force.x += f.x
					force.y += f.y

			@player?.applyForce v(force.x, force.y), v(0,0)

			if @balls
				for b in @balls
					force = {x:0, y:0}
					for _,n of @level.nodes
						f = force_between b.p, b.polarity, n
						force.x += f.x
						force.y += f.y
					b.resetForces()
					b.applyForce v(force.x, force.y), v(0,0)
					

			@space.step 1/30
			@player?.resetForces()
			@frameNo++
			@runTimers()

		draw: ->
			ctx.save()
			# 0,0 at bottom left
			ctx.translate 0, canvas.height
			ctx.scale 1, -1

			@level.draw(@state is 'editing')
			@space.activeShapes.each (s) ->
				s.draw()

			ctx.restore()
			ctx.font = '14px "04b19Regular"'
			ctx.fillStyle = 'white'
			ctx.textAlign = 'left'
			ctx.textBaseline = 'top'
			ctx.fillText (@level.name ? 'Unnamed').toUpperCase(), 3, 3

			if @levelNum is 0
				if @player.p.y > 10*TILE_SIZE
					ctx.fillText 'Be positive: press A', 21*TILE_SIZE, 4*TILE_SIZE
				else
					ctx.fillText 'Be negative: press S', 24*TILE_SIZE, 11*TILE_SIZE

	levelTransition:
		init: ->
			@level_num_x = -300
			@level_name_x = canvas.width + 50
			@level_anim_t = 0
		update: (dt) ->
			pos = (t) ->
				if t < 0.4
					900*t
				else if t < 1.9
					900*0.4 + 30*(t-0.4)
				else
					900*0.4 + 30*1.5 + 900*(t-1.9)
			@level_num_x = -300 + pos(@level_anim_t)
			@level_name_x = canvas.width + 50 - pos(@level_anim_t)
			@level_anim_t += dt

			if @level_anim_t > 2.4
				@state = 'playing'
		draw: ->
			ctx.fillStyle = 'white'
			ctx.font = '14px "04b19Regular"'
			ctx.textAlign = 'left'
			ctx.textBaseline = 'bottom'
			ctx.fillText "Level #{@levelNum + 1}", @level_num_x, 50
			ctx.textBaseline = 'top'
			ctx.font = '28px "04b19Regular"'
			ctx.fillText (@level.name ? 'Unnamed').toUpperCase(), @level_name_x, 60

	editing:
		update: ->
			if atom.input.pressed 'select'
				@laying = false
				@state = 'pickingTile'
				return

			if atom.input.pressed 'edit'
				@laying = false
				@state = 'playing'
				return

			# edit mode
			if not atom.input.down 'click'
				@laying = false
			if @laying or atom.input.pressed 'click'
				@laying = true
				{x, y} = screenToWorld atom.input.mouse.x, atom.input.mouse.y
				tx = Math.floor x/TILE_SIZE
				ty = Math.floor y/TILE_SIZE
				@level.setTile tx, ty, @tileToPlace

			if atom.input.pressed 'save'
				req = new XMLHttpRequest
				req.open 'POST', window.location.origin + '/save', true
				req.setRequestHeader 'Content-Type', 'application/json;charset=UTF-8'
				req.send JSON.stringify (l.export() for l in @levels)

			if atom.input.pressed 'skip'
				@forward()
			if atom.input.pressed 'back'
				@back()

			if atom.input.pressed 'name'
				@level.name = prompt 'Level name:', @level.name ? ''

			if atom.input.pressed 'reset'
				@reset()

		draw: ->
			States.playing.draw.call @
			ctx.fillStyle = 'red'
			ctx.beginPath()
			ctx.arc 8, 8, 5, 0, Math.PI*2
			ctx.fill()

	pickingTile:
		update: ->
			if atom.input.pressed 'select'
				@state = 'editing'
			if atom.input.pressed 'click'
				console.log atom.input.mouse.x, atom.input.mouse.y
				if 0 <= atom.input.mouse.x-100 < Object.keys(Tiles).length*TILE_SIZE and 0 <= atom.input.mouse.y-100 < TILE_SIZE
					tile_type = Object.keys(Tiles)[Math.floor (atom.input.mouse.x - 100)/TILE_SIZE]
				else
					tile_type = undefined
				@tileToPlace = tile_type # TODO pick the tile type
				@state = 'editing'
		draw: ->
			States.editing.draw.call @
			ctx.fillStyle = 'rgba(128,128,128,0.4)'
			ctx.fillRect 0, 0, canvas.width, canvas.height
			x = 100
			for name,t of Tiles
				t.draw x, 100
				x += TILE_SIZE


g = new Game
g.run()

window.onblur = -> g.stop()
window.onfocus = -> g.run()

cp.PolyShape::draw = ->
  ctx.beginPath()

  verts = this.tVerts
  len = verts.length
  lastPoint = new cp.Vect(verts[len - 2], verts[len - 1])
  ctx.moveTo(lastPoint.x, lastPoint.y)

  i = 0
  while i < len
    p = new cp.Vect(verts[i], verts[i+1])
    ctx.lineTo(p.x, p.y)
    i += 2
  #ctx.fill()
  ctx.stroke()

cp.SegmentShape::draw = ->
  oldLineWidth = ctx.lineWidth
  ctx.lineWidth = Math.max 1, this.r * 2
  ctx.beginPath()
  ctx.moveTo @ta.x, @ta.y
  ctx.lineTo @tb.x, @tb.y
  ctx.stroke()
  ctx.lineWidth = oldLineWidth

cp.CircleShape::draw = ->
  ctx.lineWidth = 3
  ctx.lineCap = 'round'
  ctx.beginPath()
  ctx.arc @tc.x, @tc.y, @r, 0, 2*Math.PI, false

  # And draw a little radius so you can see the circle roll.
  ctx.moveTo @tc.x, @tc.y
  r = cp.v.mult(@body.rot, @r).add @tc
  ctx.lineTo r.x, r.y
  ctx.stroke()
