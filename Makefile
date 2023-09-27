SHELL = /bin/zsh

.PHONY: serve
serve:
	for port in $$(jot -r 100 $$(sysctl net.inet.ip.portrange.first | awk '{print $$2}') $$(sysctl net.inet.ip.portrange.last | awk '{print $$2}')) ; \
	do \
		netstat -a -n | grep "\*\.$$port.*LISTEN" > /dev/null || break ; \
	done ; \
	exec {fd}< <(sleep 5 && open http://localhost:$$port) ; \
	docker run --rm --init -itv $$(pwd):/src/site -p $$port:4000 naoigcat/github-pages || :
