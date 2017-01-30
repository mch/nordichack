dev: controller.js deploy
.PHONY: dev

prod: controller.min.js deploy-prod
.PHONY: prod

controller.js: Main.elm
	elm-make $^ --output $@

controller.min.js: controller.js
	yarn run google-closure-compiler-js --assume_function_wrapper --compilationLevel SIMPLE $^ > $@

.PHONY: deploy
deploy: controller.js
	cp controller.js ../server/static/controller.js

.PHONY: deploy-prod
deploy-prod: controller.min.js
	cp controller.min.js ../server/static/controller.js
