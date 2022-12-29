.PHONY: serve
serve:
	docker run --rm -v ${PWD}:/src/site -p 4000:4000 naoigcat/github-pages
