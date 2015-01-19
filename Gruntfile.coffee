module.exports = (grunt) ->

	src =
		main: "src/main/"
		test: "src/test/"
		libs: "dist/js/lib/"
		dist: "dist/"
		repo: "repo/"
		
	resSrc =
		main: "#{src.main}/resources/"
		test: "#{src.test}/resources/"
		dist: "#{src.dist}/resources/"

	jsSrc = 
		main: "#{src.main}js/"
		test: "#{src.test}js/"
		dist: "#{src.dist}js/"
		
	htmlSrc =
		main: "#{src.main}html/"
		dist: "#{src.dist}"
		
	cofSrc =
		main: "#{src.main}coffee/"
		dist: jsSrc.dist
		test: jsSrc.test

	# Initialize the configuration.
	grunt.initConfig

		# -- Common variables

		# Load configuration from JSON.
		pkg: grunt.file.readJSON "package.json"
		
		# Define the header for source files.
		banner: """/*
				  \ * <%= pkg.name %> - <%= pkg.version %> (<%= grunt.template.today(\"yyyy-mm-dd\") %>)
				  \ * Copyright <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.organization || pkg.author.name %>, <%= pkg.author.email %>. All rights reserved.
				  \ */
				  \ 
				  """
				  
		# -- Plugin configuration

		# Manage dependencies with bower.
		"bower-install-simple":
			options:
				directory: src.repo
			prod:
				options:
					production: true
					
		bower:
			completeRequireJs:
				rjsConfig: "#{jsSrc.dist}app.build.js"
				
				options:
					transitive: true
		
		# Specify directories to clean.
		clean:
			dist: [src.dist]
			repo: [src.repo]
			coffee: ["#{jsSrc.main}*-compiled.js"]
			
		# Compile CoffeeScripts to temporary JS File.
		coffee:				  
			compile:
				options:
					bare: true
					
				files: [
					{ src: [ "#{cofSrc.main}example.coffee" ], dest: "#{jsSrc.main}example-compiled.js" },
					{ src: [ "#{cofSrc.main}*.coffee",  "!#{cofSrc.main}example.coffee"], dest: "#{jsSrc.main}coffee-compiled.js" }
				]
		
		# Check code quality for CoffeeScripts
		coffeelint:
			sources: [ "#{cofSrc.main}*.coffee" ]
			
		# Files to be copied during build.
		copy:
			html: 
				expand: true
				cwd: htmlSrc.main
				src: ["**"]
				dest: htmlSrc.dist
		
			resources:
				expand: true
				cwd: resSrc.main
				src: ["**"]
				dest: resSrc.dist
		
			libs:
				dot: true
				expand: true
				cwd: src.repo
				src: ["**"]
				dest: src.libs
			
		# Configuration for concatunation: Put the file header to each file.
		concat:
			options:
				banner: "<%= banner %>"
				stripBanners: true
				
			# All JS Files are merged into one output file, except for app.build.js
			dist:
				src: ["#{jsSrc.main}**.js", "!#{jsSrc.main}app.build.js", "!#{jsSrc.main}example-compiled.js"]
				dest: "#{jsSrc.dist}<%= pkg.name %>.js"
				
			example:
				src: ["#{jsSrc.main}example-compiled.js"]
				dest: "#{jsSrc.dist}example.js"
				
			main:
				src: ["#{jsSrc.main}app.build.js"]
				dest: "#{jsSrc.dist}app.build.js"

		# Configuration for jshint.
		jshint:
			src:
				src: ["#{jsSrc.main}**/*.js"]
				
			test:
				src: ["#{jsSrc.test}**/*.js"]

			# Allow certain options.
			options:
				browser: true
				boss: true
				
		# Configurations for uglify.
		uglify:
			options:
				banner: "<%= banner %>"

			build:
				src: "<%= concat.dist.dest %>"
				dest: "#{jsSrc.dist}<%= pkg.name %>.min.js"
				
		# Inject CSS/ JS imports to HTML files.
		wiredep: 
			target:
				src: "#{src.dist}**/*.html",
				#ignorePath: src.dist


	# Load external Grunt task plugins.
	grunt.loadNpmTasks "grunt-bower-install-simple"
	grunt.loadNpmTasks "grunt-bower-requirejs"
	grunt.loadNpmTasks "grunt-coffeelint"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-clean"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-jshint"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-wiredep"

	# Default task.
	grunt.registerTask "build", ["clean:dist", "jshint", "coffeelint", "coffee", "concat", "clean:coffee", "uglify", "copy", "bower", "wiredep" ]
	grunt.registerTask "update", ["clean:repo", "bower-install-simple:prod"]
	grunt.registerTask "default", ["clean", "update", "build"]