all: controller.js controller.min.js deploy
.PHONY: all 

controller.js: Main.elm
	elm-make $^ --output $@

controller.min.js: controller.js
	yarn run google-closure-compiler-js --assume_function_wrapper --compilationLevel SIMPLE $^ > $@

.PHONY: deploy
deploy: controller.js
	cp controller.js ../server/static/controller.js
