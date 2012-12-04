#!/usr/bin/env coffee
npm = require("npm")
_ = require("underscore")
path = require("path")
inspect = require("util").inspect
wrench = require("wrench")

showUsageAndExit = (k, v, t) ->
	if k
		console.log("Unknown option #{k}")
	console.log("""#{path.basename(require.main.filename)} OPTIONS
		\t--userId, -u: target user id or username
		\t--appDir, -d: target application path
		\t--help, -h: you're looking at it
	""")
	process.exit(0)

parseCommandLine = () ->
	nopt = require("nopt")
	nopt.invalidHandler = showUsageAndExit

	knownOpts =
		"userId": [String, Number]
		"appDir": path
		"help": String

	shortHands =
		"u" : ["--userId"]
		"d" : ["--appDir"]
		"h" : ["--help"]

	parsed = nopt(knownOpts, shortHands, process.argv, 2)

	if parsed.argv.original.length == 0 or parsed.help or parsed.argv.remain.length != 0
		return showUsageAndExit()

	if !parsed.userId || !parsed.appDir
		return showUsageAndExit()

	return _.pick(parsed, ["userId", "appDir"])

setEnv = (userId, appDir) ->
	process.chdir(appDir)
	process.cwd()
	process.setuid(userId) if process.getuid() != userId

runNpm = (appDir) ->
	tmpDir = path.resolve(appDir,"npm_tmp")

	npm.load({ tmp: tmpDir }, (er) ->
		if er
			console.log("npm load error: #{inspect(er)}")
			return

		npm.on('log', (msg) ->
			console.log(msg)
		)

		console.log("Running npm install...")

		npm.commands.install( (er, data) ->

			wrench.rmdirSyncRecursive(tmpDir,(rmdirErr) ->
				if(rmdirErr)
					console.log("Error removing #{tmpDir}:\n#{inspect(rmdirErr)}")
					return

			)

			if er
				console.log("npm install error: #{inspect(er)}")
				return
			console.log("npm install complete.")
		)
	)

main = () ->
	[userId, appDir ] = _.values(parseCommandLine())
	setEnv(userId, appDir)
	runNpm(appDir)

main()