.PHONY: serve
serve:
	docker run --rm --init -itv ${PWD}:/src/site -p 80:4000 naoigcat/github-pages || :
