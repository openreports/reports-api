PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

#########
# TOOLS #
#########

LOCALBIN                           := $(PWD)/bin
CODEGEN_VERSION                    := v0.30.0-rc.2
CODEGEN                             = $(shell pwd)/bin/code-generator
CODEGEN_ROOT                        = $(shell go env GOMODCACHE)/k8s.io/code-generator@$(CODEGEN_VERSION)
CONTROLLER_TOOLS_VERSION           ?= v0.18.0
CONTROLLER_GEN                     ?= $(LOCALBIN)/controller-gen
GEN_CRD_API_REFERENCE_DOCS         ?= $(LOCALBIN)/crd-ref-docs
GEN_CRD_API_REFERENCE_DOCS_VERSION ?= latest
HELM                               ?= $(LOCALBIN)/helm
HELM_VERSION                       ?= v3.17.3
GOIMPORTS                          ?= $(LOCALBIN)/goimports
GOIMPORTS_VERSION                  ?= latest
REGISTER_GEN                       ?= $(LOCALBIN)/register-gen
REGISTER_GEN_VERSION               := v0.33.1
SED                                := $(shell if [ "$(GOOS)" = "darwin" ]; then echo "gsed"; else echo "sed"; fi)

$(HELM):
	@echo Install helm... >&2
	@GOBIN=$(LOCALBIN) go install helm.sh/helm/v3/cmd/helm@$(HELM_VERSION)

$(GOIMPORTS):
	@echo Install goimports... >&2
	@GOBIN=$(LOCALBIN) go install golang.org/x/tools/cmd/goimports@$(GOIMPORTS_VERSION)

$(GEN_CRD_API_REFERENCE_DOCS): $(LOCALBIN)
	test -s $(LOCALBIN)/crd-ref-docs && $(LOCALBIN)/crd-ref-docs --version | grep -q $(GEN_CRD_API_REFERENCE_DOCS_VERSION) || \
	GOBIN=$(LOCALBIN) go install github.com/elastic/crd-ref-docs@$(GEN_CRD_API_REFERENCE_DOCS_VERSION)

$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen && $(LOCALBIN)/controller-gen --version | grep -q $(CONTROLLER_TOOLS_VERSION) || \
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

$(REGISTER_GEN):
	@GOBIN=$(LOCALBIN) go install k8s.io/code-generator/cmd/register-gen@$(REGISTER_GEN_VERSION)

.PHONY: install-tools
install-tools: ## Install tools
install-tools: $(HELM)
install-tools: $(GEN_CRD_API_REFERENCE_DOCS)
install-tools: $(CONTROLLER_GEN)
install-tools: $(GOIMPORTS)
install-tools: $(REGISTER_GEN)

.PHONY: clean-tools
clean-tools: ## Remove installed tools
	@echo Clean tools... >&2
	@rm -rf $(LOCALBIN)

###########
# CODEGEN #
###########

codegen-crds: ## Generate CRDs
codegen-crds: $(CONTROLLER_GEN)
	@echo Generate CRDs... >&2
	@$(CONTROLLER_GEN) paths=./apis/... crd:crdVersions=v1,ignoreUnexportedFields=true,generateEmbeddedObjectMeta=false

codegen-deepcopy: ## Generate deep copy functions
codegen-deepcopy: $(CONTROLLER_GEN)
	@echo Generate deep copy functions... >&2
	@$(CONTROLLER_GEN) paths=./apis/... object

codegen-rbac: ## Generate rbac
codegen-rbac: $(CONTROLLER_GEN)
	@echo Generate rbac... >&2
	@$(CONTROLLER_GEN) paths=./apis/... rbac:roleName=manager-role

.PHONY: codegen-api-docs
codegen-api-docs: ## Generate API docs
codegen-api-docs: $(GEN_CRD_API_REFERENCE_DOCS)
codegen-api-docs: $(GENREF)
	@echo Generate api docs... >&2
	$(GEN_CRD_API_REFERENCE_DOCS) --source-path=./apis --config=./docs/config.yaml --renderer=markdown --output-path=./docs/api-docs.md

codegen: ## Build all generated code
codegen: codegen-crds
codegen: codegen-deepcopy
codegen: codegen-rbac
codegen: codegen-api-docs

#########
# BUILD #
#########

fmt: ## Run go fmt against code
fmt: codegen
	@echo Format code... >&2
	@go fmt ./...

imports: ## Run go imports against code
imports: $(GOIMPORTS)
	@echo Go imports... >&2
	@$(GOIMPORTS) -w .

vet: ## Run go vet against code
vet: fmt
vet: imports
	@echo Vet code... >&2
	go vet ./...

build: ## Run go build against code
build: vet
	@echo Build code... >&2
	@go build ./...


.PHONY: generate-client
generate-client:
	./hack/update-codegen.sh

.PHONY: fmt-check
fmt-check:
	@echo "Checking go fmt..." >&2
	@git --no-pager diff .
	@echo 'If this test fails, it is because the git diff is non-empty after running "make fmt".' >&2
	@echo 'To correct this, locally run "make fmt" and commit the changes.' >&2
	@git diff --quiet --exit-code .


.PHONY: imports-check
imports-check: imports
	@echo Checking go imports... >&2
	@git --no-pager diff .
	@echo 'If this test fails, it is because the git diff is non-empty after running "make imports-check".' >&2
	@echo 'To correct this, locally run "make imports" and commit the changes.' >&2
	@git diff --quiet --exit-code .

.PHONY: code-generator
code-generator:
	@GOBIN=$(PROJECT_DIR)/bin GO111MODULE=on go install k8s.io/code-generator/cmd/client-gen@$(CODEGEN_VERSION)
	cp -f $(CODEGEN_ROOT)/generate-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/generate-internal-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/kube_codegen.sh $(PROJECT_DIR)/bin/


.PHONY: codegen-manifest-release
codegen-manifest-release: ## Create CRD release manifest
codegen-manifest-release: $(HELM)
codegen-manifest-release: manifests
	@echo Generating manifests for release... >&2
	@mkdir -p ./.manifest
	@$(HELM) template openreports chart/ \
	| $(SED) -e '/^#.*/d' > ./.manifest/release.yaml

.PHONY: verify-codegen
verify-codegen: ## Verify all generated code are up to date
verify-codegen: generate-all copy-crd-to-helm
	@echo Checking git diff... >&2
	@echo 'If this test fails, it is because the git diff is non-empty after running "make codegen-all".' >&2
	@echo 'To correct this, locally run "make codegen-all" and commit the changes.' >&2
	@git diff --exit-code .

.PHONY: copy-crd-to-helm
copy-crd-to-helm: manifests ## Generate CRD YAMLs and copy them to the Helm chart templates directory
	cp crd/openreports.io/v1alpha1/*.yaml chart/templates/

.PHONY: unused-package-check
unused-package-check:
	@tidy=$$(go mod tidy); \
	if [ -n "$${tidy}" ]; then \
		echo "go mod tidy checking failed!"; echo "$${tidy}"; echo; \
	fi

########
# HELP #
########

.PHONY: help
help: ## Shows the available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-40s\033[0m %s\n", $$1, $$2}'
