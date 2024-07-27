
.phony: docker shell

docker-build: docker
	docker rm -f plasma-build
	docker run --name plasma-build -v $$PWD:/work -e BUILDER_UID=`id -u` -e BUILDER_GID=`id -g` -w /work plasma /bin/bash -c 'make -B build'
	docker container commit -p plasma-build plasma

build:
	rm -rf build && mkdir build && cd build && cmake -GNinja .. && ninja && sudo ninja install

shell: docker
	docker run --name plasma-shell -ti --rm -v $$PWD:/work -e BUILDER_UID=`id -u` -e BUILDER_GID=`id -g` -w /work plasma /bin/bash

docker: docker/Dockerfile
	docker build -f docker/Dockerfile docker/ -t plasma

