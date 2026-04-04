SHELL = /bin/zsh

.SILENT:

.PHONY: serve
serve:
	container_id="$$(docker run --rm --init -d -v $$(pwd):/src/site -p 127.0.0.1::4000 naoigcat/github-pages jekyll serve -w --force_polling -H 0.0.0.0 -P 4000)" || { echo 'Failed to start container' >&2 ; exit 1 ; } ; \
	[[ -n $$container_id ]] || { echo 'Failed to get container ID' >&2 ; exit 1 ; } ; \
	trap 'docker stop '$$container_id' >/dev/null 2>&1 || :' EXIT INT TERM ; \
	timeout=300 ; elapsed=0 ; \
	while true ; do \
		logs="$$(docker logs "$$container_id" 2>&1)" ; \
		echo "$$logs" | grep -q 'Error response from daemon' && { echo "$$logs" >&2 ; echo 'Docker daemon error while waiting for server' >&2 ; exit 1 ; } ; \
		echo "$$logs" | grep -q 'Server running' && break ; \
		sleep 1 ; \
		elapsed=$$((elapsed + 1)) ; \
		[[ $$elapsed -lt $$timeout ]] || { docker logs "$$container_id" ; echo 'Timeout waiting for server' >&2 ; exit 1 ; } ; \
	done ; \
	port="$$(docker port "$$container_id" 4000/tcp | awk -F: 'NR == 1 { print $$NF }')" ; \
	[[ -n $$port ]] || { echo 'Failed to resolve host port' >&2 ; exit 1 ; } ; \
	open http://localhost:$$port ; \
	docker attach "$$container_id" || :
