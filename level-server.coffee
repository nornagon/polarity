fs = require 'fs'
express = require 'express'
app = express.createServer()

app.use express.static __dirname
app.use express.bodyParser()

app.post '/save', (req, res) ->
	fs.writeFile 'levels.coffee', """
	level_data = #{JSON.stringify req.body}
	"""

app.listen 3000
