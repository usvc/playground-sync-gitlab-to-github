# sample Makefile
IMAGE_REF=usvc/playground-sync-gitlab-to-github:latest

dep:
	@printf -- 'install dependencies\n'

lint:
	@printf -- 'standardise code\n'

test:
	@$(MAKE) test_unit
	@$(MAKE) test_integration

test_unit:
	@printf -- 'run unit tests\n'

test_integration:
	@printf -- 'run integration tests\n'

build:
	@printf -- 'build binaries/built package\n'
	mkdir -p ./bin
	echo 'placeholder for a binary' > ./bin/binary
	sha256sum ./bin/binary | cut -f 1 -d ' ' > ./bin/binary.sha256

image:
	@printf -- 'build container image\n'
	docker build -f ./build/Dockerfile -t $(IMAGE_REF) .

publish_image: image
	@printf -- 'publish container image\n'
	docker push $(IMAGE_REF)

# sample commands

ssl:
	mkdir ./.ssh
	ssh-keygen -t rsa -b 4096 -f ./.ssh/id_rsa -N ""
	cat ./.ssh/id_rsa | base64 -w 0 > ./.ssh/id_rsa.b64
