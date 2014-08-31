module.exports = (grunt) ->
	grunt.initConfig
		coffee:
			compile:
				files:
					'js/fwhp.js': ['coffee/fwhp.coffee']

	grunt.loadNpmTasks 'grunt-contrib-coffee'

	grunt.registerTask 'default', ['coffee']
