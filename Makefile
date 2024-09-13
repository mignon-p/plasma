
PLASMA_INSTALL ?= /opt/plasma

install: build ${PLASMA_INSTALL}/lib/pkgconfig
	cd build && ninja install

build:
	mkdir -p build && cd build \
		&& cmake -GNinja \
			-D CMAKE_INSTALL_PREFIX=${PLASMA_INSTALL} \
			-D CMAKE_INSTALL_LIBDIR=${PLASMA_INSTALL}/lib \
			.. \
		&& ninja

${PLASMA_INSTALL}/lib/pkgconfig:
	sudo mkdir -p ${PLASMA_INSTALL}
	sudo chown -R `id -u`:`id -g` ${PLASMA_INSTALL}

clean:
	xargs rm < build/install_manifest.txt || true
	rm -rf build

.phony: docker-build docker shell

ENV_BUILDER_IDS := -e BUILDER_UID=$(shell id -u) -e BUILDER_GID=$(shell id -g)
VOL_WORK := -v $$PWD:/work -w /work

docker-build: docker
	docker rm -f plasma-build
	docker run --name plasma-build ${VOL_WORK} ${ENV_BUILDER_IDS} \
		-e PLASMA_INSTALL=${PLASMA_INSTALL} \
		plasma-build \
		/bin/bash -c 'make clean; make install'
	docker container commit -p plasma-build plasma

docker: docker/Dockerfile
	docker build -f docker/Dockerfile docker/ -t plasma-build

shell:
	docker run --name plasma-shell -ti --rm ${VOL_WORK} ${ENV_BUILDER_IDS} plasma /bin/bash

shell-build: docker
	docker run --name plasma-shell-build -ti --rm ${VOL_WORK} ${ENV_BUILDER_IDS} plasma-build /bin/bash

docker-clean:
	docker rm -f plasma-build
	docker rmi -f plasma-build plasma
