.PHONY: build clean-latest push-to-gcr test

src_files = preseed.sh
image_name = sftp-docker
gcr_location = eu.gcr.io/prefab-galaxy-202620
build_tag = build-${BUILD_NUMBER}

clean-local-builds:
	$(eval image_ids := $(shell docker images | egrep '^$(gcr_location)/$(image_name)\s+|^$(image_name)\s+' | awk '{print $$3}' | sort -u))
	$(if $(image_ids), docker rmi -f $(image_ids), $(info Nothing to clean up))

test:
	shellcheck -e SC1091 $(src_files)

build: test
	$(eval commit_id := $(shell git rev-parse HEAD))
	$(eval tag_name := $(shell git show-ref --dereference --tags | sed -n 's#^$(commit_id)\s\+refs/tags/\(.*\)\^{}$$#\1#p' | uniq))
	$(eval unstable_version := $(if $(tag_name), $(shell grep -v -- '^[0-9]\+\.[0-9]\+\.[0-9]\+$$' <<<"$(tag_name)"), ""))
	docker build -t $(image_name):$(commit_id) . --no-cache
	docker tag $(image_name):$(commit_id) $(image_name):$(build_tag)
	docker tag $(image_name):$(commit_id) $(gcr_location)/$(image_name):$(commit_id)
	$(if $(tag_name), docker tag $(image_name):$(commit_id) $(gcr_location)/$(image_name):$(tag_name))
	$(if $(tag_name), $(if $(unstable_version), $(info Seems to be a non production image. Not tagging as latest.), docker tag $(image_name):$(commit_id) $(gcr_location)/$(image_name):latest))

push-to-gcr:
	$(eval commit_id := $(shell git rev-parse HEAD))
	$(eval tag_name := $(shell git show-ref --dereference --tags | sed -n 's#^$(commit_id)\s\+refs/tags/\(.*\)\^{}$$#\1#p' | uniq))
	$(eval unstable_version := $(if $(tag_name), $(shell grep -v -- '^[0-9]\+\.[0-9]\+\.[0-9]\+$$' <<<"$(tag_name)"), ""))
	docker push $(gcr_location)/$(image_name):$(commit_id)
	$(if $(tag_name), docker push $(gcr_location)/$(image_name):$(tag_name))
	$(if $(unstable_version), , docker push $(gcr_location)/$(image_name):latest)
