canvas = atom.canvas
canvas.width = 800
canvas.height = 600
ctx = atom.context
v = cp.v

atom.input.bind atom.key.A, 'a'
atom.input.bind atom.key.S, 's'

class Game extends atom.Game
	constructor: ->
		@nodes = [{x:100,y:100, polarity:-1}, {x:200, y:110, polarity:-1}, {x:150, y:200, polarity:1}]

		@space = new cp.Space
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
		

		@player = new cp.Body 1, cp.momentForCircle 1, 0, 10, v(0,0)
		@player.setPos v(200, 200)
		@space.addBody @player
		shape = @space.addShape new cp.CircleShape @player, 10, v(0,0)
		shape.setElasticity 0.5
		shape.setFriction 0.8

	update: (dt) ->
		if atom.input.down 'a'
			player_polarity = 1
		else if atom.input.down 's'
			player_polarity = -1

		force = {x:0, y:0}

		if player_polarity
			for n in @nodes
				dx = (n.x - @player.p.x) * player_polarity * n.polarity
				dy = (n.y - @player.p.y) * player_polarity * n.polarity
				norm = Math.sqrt(dx*dx+dy*dy)
				nx = dx/norm
				ny = dy/norm
				# F = qQ/r^2
				# take qQ = k for now
				k = 120
				norm /= 100
				if norm < 1 then norm = 1
				norm2 = norm * norm
				f_x = k / norm2 * nx
				f_y = k / norm2 * ny
				force.x += f_x
				force.y += f_y

		@player.applyForce v(force.x, force.y), v(0,0)
		@space.step 1/30
		@player.resetForces()

	draw: ->
		ctx.fillStyle = 'white'
		ctx.fillRect 0, 0, canvas.width, canvas.height
		ctx.save()
		# 0,0 at bottom left
		ctx.translate 0, canvas.height
		ctx.scale 1, -1

		for n in @nodes
			ctx.fillStyle = if n.polarity > 0 then 'red' else 'green'
			ctx.fillRect n.x, n.y, 10, 10

		ctx.fillStyle = if atom.input.down 'a' then 'red' else if atom.input.down 's' then 'green' else 'blue'
		ctx.beginPath()
		ctx.arc @player.p.x, @player.p.y, 10, 0, Math.PI*2
		ctx.fill()
		ctx.restore()

g = new Game
g.run()

window.onblur = -> g.stop()
window.onfocus = -> g.run()
