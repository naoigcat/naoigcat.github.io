SHELL = /bin/zsh

.PHONY: serve
serve:
	container_id="$$(docker run --rm --init -d -v $$(pwd):/src/site -p 127.0.0.1::4000 naoigcat/github-pages)" || { echo 'Failed to start container' >&2 ; exit 1 ; } ; \
	[[ -n $$container_id ]] || { echo 'Failed to get container ID' >&2 ; exit 1 ; } ; \
	trap 'docker stop '$$container_id' >/dev/null 2>&1 || :' EXIT INT TERM ; \
	timeout=30 ; elapsed=0 ; \
	until docker logs "$$container_id" 2>&1 | grep -q 'Server running' ; do \
		sleep 1 ; \
		elapsed=$$((elapsed + 1)) ; \
		[[ $$elapsed -lt $$timeout ]] || { docker logs "$$container_id" ; echo 'Timeout waiting for server' >&2 ; exit 1 ; } ; \
	done ; \
	port="$$(docker port "$$container_id" 4000/tcp | awk -F: 'NR == 1 { print $$NF }')" ; \
	[[ -n $$port ]] || { echo 'Failed to resolve host port' >&2 ; exit 1 ; } ; \
	open http://localhost:$$port ; \
	docker attach "$$container_id"
