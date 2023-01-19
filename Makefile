.PHONY: serve
serve:
	docker run --rm -v ${PWD}:/src/site -p 80:4000 naoigcat/github-pages
