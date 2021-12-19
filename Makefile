.PHONY: serve
serve:
	docker run --rm --init -itv ${PWD}:/srv/jekyll -p 8080:4000 jekyll/jekyll:pages jekyll serve
