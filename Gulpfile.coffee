gulp = require 'gulp'
coffee = require 'gulp-coffee'
header = require 'gulp-header'

gulp.task 'build', ->
 	gulp.src 'coffee/*.coffee'
 		.pipe coffee bare: true
 		.pipe header "#!/usr/bin/env node\n\n"
 		.pipe gulp.dest 'js/'

gulp.task 'watch', ->
	gulp.watch 'coffee/*.coffee', ['build']

gulp.task 'default', ['build']