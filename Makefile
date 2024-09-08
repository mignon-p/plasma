
.phony: docker-build docker shell

PLASMA_INSTALL ?= /opt/plasma
ENV_BUILDER_IDS := -e BUILDER_UID=$(shell id -u) -e BUILDER_GID=$(shell id -g)
VOL_WORK := -v $$PWD:/work -w /work

docker-build: docker
	docker rm -f plasma-build
	docker run --name plasma-build ${VOL_WORK} ${ENV_BUILDER_IDS} \
		-e PLASMA_INSTALL=${PLASMA_INSTALL} \
		plasma \
		/bin/bash -c 'make clean; make install'
	docker container commit -p plasma-build plasma

${PLASMA_INSTALL}/lib/pkgconfig:
	sudo mkdir -p ${PLASMA_INSTALL}/lib/pkgconfig
	sudo chown -R `id -u`:`id -g` ${PLASMA_INSTALL}

build:
	mkdir -p build && cd build \
		&& cmake -GNinja \
			-D CMAKE_INSTALL_PREFIX=${PLASMA_INSTALL} \
			-D CMAKE_INSTALL_LIBDIR=${PLASMA_INSTALL}/lib \
			.. \
		&& ninja

install: build ${PLASMA_INSTALL}/lib/pkgconfig
	cd build && ninja install

clean:
	xargs rm < build/install_manifest.txt
	rm -rf build

shell:
	docker run --name plasma-shell -ti --rm ${VOL_WORK} ${ENV_BUILDER_IDS} plasma /bin/bash

docker: docker/Dockerfile
	docker build -f docker/Dockerfile docker/ -t plasma

