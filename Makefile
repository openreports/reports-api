GO_CMD ?= go

PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

CONTROLLER_TOOLS_VERSION           ?= v0.18.0
CONTROLLER_GEN                     ?= $(LOCALBIN)/controller-gen
GEN_CRD_API_REFERENCE_DOCS         ?= $(LOCALBIN)/crd-ref-docs
GEN_CRD_API_REFERENCE_DOCS_VERSION ?= latest

#########
# TOOLS #
#########
TOOLS_DIR                          ?= $(PWD)/.tools
HELM                               ?= $(TOOLS_DIR)/helm
HELM_VERSION                       ?= v3.17.3
TOOLS	:= $(HELM)
SED     := $(shell if [ "$(GOOS)" = "darwin" ]; then echo "gsed"; else echo "sed"; fi)

$(HELM):
	@echo Install helm... >&2
	@GOBIN=$(TOOLS_DIR) go install helm.sh/helm/v3/cmd/helm@$(HELM_VERSION)

.PHONY: install-tools
install-tools: ## Install tools
install-tools: $(TOOLS)

.PHONY: clean-tools
clean-tools: ## Remove installed tools
	@echo Clean tools... >&2
	@rm -rf $(TOOLS_DIR)

# Run go build against code
build:
	go build ./...

# Run go fmt against code
fmt:
	go fmt ./...

# Linting checks

.PHONY: fmt-check
fmt-check:
	@echo "Checking go fmt..." >&2
	@git --no-pager diff .
	@echo 'If this test fails, it is because the git diff is non-empty after running "make fmt".' >&2
	@echo 'To correct this, locally run "make fmt" and commit the changes.' >&2
	@git diff --quiet --exit-code .

.PHONY: unused-package-check
unused-package-check:
	@tidy=$$(go mod tidy); \
	if [ -n "$${tidy}" ]; then \
		echo "go mod tidy checking failed!"; echo "$${tidy}"; echo; \
	fi


# Run go vet against code
vet:
	go vet ./...

.PHONY: all
all: # Generate all code and build the project
all:
	codegen-all build fmt vet

###########
# CODEGEN #
###########

codegen-all: ## Generate all generated code
codegen-all: codegen-code codegen-manifests codegen-controller codegen-api-docs codegen-client

.PHONY: codegen-manifests
codegen-manifests: ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
codegen-manifests: codegen-controller
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd webhook paths="./apis/openreports.io/v1alpha1" output:crd:artifacts:config=crd/openreports.io/v1alpha1


.PHONY: codegen-controller
codegen-controller: ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
codegen-controller: $(CONTROLLER_GEN) ## Download controller-gen locally if necessary. If wrong version is installed, it will be overwritten.
$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen && $(LOCALBIN)/controller-gen --version | grep -q $(CONTROLLER_TOOLS_VERSION) || \
	GOBIN=$(LOCALBIN) $(GO_CMD) install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

.PHONY: codegen-client
codegen-client:
	./hack/update-codegen.sh

.PHONY: codegen-controller
codegen-controller: $(CONTROLLER_GEN) ## Download controller-gen locally if necessary. If wrong version is installed, it will be overwritten.
$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen && $(LOCALBIN)/controller-gen --version | grep -q $(CONTROLLER_TOOLS_VERSION) || \
	GOBIN=$(LOCALBIN) $(GO_CMD) install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

# Use same code-generator version as k8s.io/api
CODEGEN_VERSION := v0.30.0-rc.2
CODEGEN = $(shell pwd)/bin/code-generator
CODEGEN_ROOT = $(shell $(GO_CMD) env GOMODCACHE)/k8s.io/code-generator@$(CODEGEN_VERSION)
.PHONY: codegen-code
codegen-code:
	@GOBIN=$(PROJECT_DIR)/bin GO111MODULE=on $(GO_CMD) install k8s.io/code-generator/cmd/client-gen@$(CODEGEN_VERSION)
	cp -f $(CODEGEN_ROOT)/generate-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/generate-internal-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/kube_codegen.sh $(PROJECT_DIR)/bin/


.PHONY: codegen-api-docs
codegen-api-docs: ## Generate API docs
codegen-api-docs: $(GEN_CRD_API_REFERENCE_DOCS)
	$(GEN_CRD_API_REFERENCE_DOCS) --source-path=./apis/openreports.io/v1alpha1 --config=./docs/config.yaml --renderer=markdown --output-path=./docs/api-docs.md

$(GEN_CRD_API_REFERENCE_DOCS): $(LOCALBIN)
	$(call go-install-tool,$(GEN_CRD_API_REFERENCE_DOCS),github.com/elastic/crd-ref-docs,$(GEN_CRD_API_REFERENCE_DOCS_VERSION))


.PHONY: codegen-manifest-release
codegen-manifest-release: ## Create CRD release manifest
codegen-manifest-release: manifests
	@echo Generating manifests for release... >&2
	@mkdir -p ./.manifest
	@$(HELM) template openreports chart/ \
	| $(SED) -e '/^#.*/d' > ./.manifest/release.yaml

#################
# RELEASE NOTES #
#################

.PHONY: release-notes
release-notes: ## Generate release notes
	@echo Generating release notes... >&2
	@bash -c 'while IFS= read -r line ; do if [[ "$$line" == "## "* && "$$line" != "## $(VERSION)" ]]; then break ; fi; echo "$$line"; done < "CHANGELOG.md"' \
	true

#################
# VERIFY CODGEN #
#################

.PHONY: verify-codegen
verify-codegen: ## Verify all generated code are up to date
verify-codegen: codegen-all
	@echo Checking git diff... >&2
	@echo 'If this test fails, it is because the git diff is non-empty after running "make codegen-all".' >&2
	@echo 'To correct this, locally run "make codegen-all" and commit the changes.' >&2
	@git diff --exit-code .

#########
# UTILS #
#########

.PHONY: copy-crd-to-helm
copy-crd-to-helm: manifests ## Generate CRD YAMLs and copy them to the Helm chart templates directory
	cp crd/openreports.io/v1alpha1/*.yaml chart/templates/

# go-install-tool will 'go install' any package with custom target and name of binary, if it doesn't exist
# $1 - target path with name of binary (ideally with version)
# $2 - package url which can be installed
# $3 - specific version of package
define go-install-tool
@[ -f $(1) ] || { \
set -e; \
package=$(2)@$(3) ;\
echo "Downloading $${package}" ;\
GOBIN=$(LOCALBIN) go install $${package} ;\
mv "$$(echo "$(1)" | sed "s/-$(3)$$//")" $(1) ;\
}
endef


########
# HELP #
########
.PHONY: help
help: ## Shows the available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'