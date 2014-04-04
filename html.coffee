#!/usr/bin/env coffee

Html = 
	render: (ip, result = 0, time = 0) ->
		if !result
			# Show initial password form
			body = "
							<div class='ip'>Your current IP is <span id='ip'>#{ip}</span></div>
							<form method='post'>
								Password: <input type='password' name='password'>
								<input type='submit' value='Submit'>
							</form> 
					"
		else if result == 1
			# Success
			body = "
							<div class='success'>Success! IP [<span id='ip'>#{ip}</span>] is allowed for #{time} minutes.</div>
					"
		else if result == -1
			# Reject
			body = "
							<div class='error'>Error! Access denied.</div>
					"

		html = "<html>
					<head>
						<title>fw hole poker</title>
						<style type='text/css'>
							body { position: relative; }
							body .content {
								position: absolute;	margin: auto;
								top: 0; left: 0; bottom: 0; right: 0;
								width: 30%; height: 20%;
								text-align: center;
							}
							div.ip { margin: 2% 0; }
							div.success { color: green; }
							div.error { color: red; }
							span#ip { font-weight: bold; }
						</style>
					</head>
					<body>
						<div class='content'>
							#{body}
						</div>
					</body>
					</html>
				"

module.exports = Html