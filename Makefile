
.phony: docker shell

PLASMA_INSTALL ?= /opt/plasma

docker-build: docker
	docker rm -f plasma-build
	docker run --name plasma-build -v $$PWD:/work -e BUILDER_UID=`id -u` -e BUILDER_GID=`id -g` -w /work plasma /bin/bash -c 'make clean; make -B build'
	docker container commit -p plasma-build plasma

${PLASMA_INSTALL}/lib/pkgconfig:
	sudo mkdir -p ${PLASMA_INSTALL}/lib/pkgconfig
	sudo chown -R `id -u`:`id -g` ${PLASMA_INSTALL}

build:
	mkdir -p build && cd build && cmake -GNinja -D CMAKE_INSTALL_PREFIX=${PLASMA_INSTALL} -D CMAKE_INSTALL_LIBDIR=${PLASMA_INSTALL}/lib .. && ninja

install: build ${PLASMA_INSTALL}/lib/pkgconfig
	cd build && ninja -v install

clean:
	xargs rm < build/install_manifest.txt
	rm -rf build

shell: docker
	docker run --name plasma-shell -ti --rm -v $$PWD:/work -e BUILDER_UID=`id -u` -e BUILDER_GID=`id -g` -w /work plasma /bin/bash

docker: docker/Dockerfile
	docker build -f docker/Dockerfile docker/ -t plasma

