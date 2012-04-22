fs = require 'fs'
express = require 'express'
app = express.createServer()

app.use express.static __dirname
app.use express.bodyParser()

app.post '/save', (req, res) ->
  fs.writeFile 'levels.coffee', """
  level_data = [
    #{(req.body.map (l) -> JSON.stringify l).join("\n  ")}
  ]
  """

app.listen 3000
