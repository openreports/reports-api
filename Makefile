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
CLIENT_GEN                         ?= $(LOCALBIN)/client-gen
LISTER_GEN                         ?= $(LOCALBIN)/lister-gen
INFORMER_GEN                       ?= $(LOCALBIN)/informer-gen
REGISTER_GEN                       ?= $(LOCALBIN)/register-gen
REGISTER_GEN                       ?= $(LOCALBIN)/register-gen
CODE_GEN_VERSION                   := v0.33.1
SED                                := $(shell if [ "$(GOOS)" = "darwin" ]; then echo "gsed"; else echo "sed"; fi)

$(HELM):
	@echo Install helm... >&2
	@GOBIN=$(LOCALBIN) go install helm.sh/helm/v3/cmd/helm@$(HELM_VERSION)

$(GOIMPORTS):
	@echo Install goimports... >&2
	@GOBIN=$(LOCALBIN) go install golang.org/x/tools/cmd/goimports@$(GOIMPORTS_VERSION)

$(GEN_CRD_API_REFERENCE_DOCS):
	test -s $(LOCALBIN)/crd-ref-docs && $(LOCALBIN)/crd-ref-docs --version | grep -q $(GEN_CRD_API_REFERENCE_DOCS_VERSION) || \
	GOBIN=$(LOCALBIN) go install github.com/elastic/crd-ref-docs@$(GEN_CRD_API_REFERENCE_DOCS_VERSION)

$(CONTROLLER_GEN):
	test -s $(LOCALBIN)/controller-gen && $(LOCALBIN)/controller-gen --version | grep -q $(CONTROLLER_TOOLS_VERSION) || \
	GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

$(CLIENT_GEN):
	@echo Install client-gen... >&2
	@GOBIN=$(LOCALBIN) go install k8s.io/code-generator/cmd/client-gen@$(CODE_GEN_VERSION)

$(LISTER_GEN):
	@echo Install lister-gen... >&2
	@GOBIN=$(LOCALBIN) go install k8s.io/code-generator/cmd/lister-gen@$(CODE_GEN_VERSION)

$(INFORMER_GEN):
	@echo Install informer-gen... >&2
	@GOBIN=$(LOCALBIN) go install k8s.io/code-generator/cmd/informer-gen@$(CODE_GEN_VERSION)

$(REGISTER_GEN):
	@echo Install register-gen... >&2
	@GOBIN=$(LOCALBIN) go install k8s.io/code-generator/cmd/register-gen@$(CODE_GEN_VERSION)

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

codegen-client-applyconfigurations: ## Generate apply configs
codegen-client-applyconfigurations: $(CONTROLLER_GEN)
	@echo Generate apply configs... >&2
	@$(CONTROLLER_GEN) paths=./apis/... applyconfiguration

codegen-client-clientset: ## Generate clientset
codegen-client-clientset: $(CLIENT_GEN)
	@echo Generate clientset... >&2
	@rm -rf ./pkg/client/clientset && mkdir -p ./pkg/client/clientset
	@$(CLIENT_GEN) \
		--go-header-file ./hack/boilerplate.go.txt \
		--clientset-name versioned \
		--apply-configuration-package github.com/openreports/reports-api/pkg/client/applyconfiguration \
		--output-dir ./pkg/client/clientset \
		--output-pkg github.com/openreports/reports-api/pkg/client/clientset \
		--input-base github.com/openreports/reports-api \
		--input ./apis/openreports.io/v1alpha1

codegen-client-listers: ## Generate listers
codegen-client-listers: $(LISTER_GEN)
	@echo Generate listers... >&2
	@rm -rf ./pkg/client/listers && mkdir -p ./pkg/client/listers
	@$(LISTER_GEN) \
		--go-header-file ./hack/boilerplate.go.txt \
		--output-dir ./pkg/client/listers \
		--output-pkg github.com/openreports/reports-api/pkg/client/listers \
		./apis/...

codegen-client-informers: ## Generate informers
codegen-client-informers: $(INFORMER_GEN)
	@echo Generate informers... >&2
	@rm -rf ./pkg/client/informers && mkdir -p ./pkg/client/informers
	@$(INFORMER_GEN) \
		--go-header-file ./hack/boilerplate.go.txt \
		--output-dir ./pkg/client/informers \
		--output-pkg github.com/openreports/reports-api/pkg/client/informers \
		--versioned-clientset-package github.com/openreports/reports-api/pkg/client/clientset/versioned \
		--listers-package github.com/openreports/reports-api/pkg/client/listers \
		./apis/...

codegen-client: ## Generate client
codegen-client: codegen-client-applyconfigurations
codegen-client: codegen-client-informers
codegen-client: codegen-client-listers
codegen-client: codegen-client-clientset

codegen-api-docs: ## Generate API docs
codegen-api-docs: $(GEN_CRD_API_REFERENCE_DOCS)
	@echo Generate api docs... >&2
	$(GEN_CRD_API_REFERENCE_DOCS) --source-path=./apis --config=./docs/config.yaml --renderer=markdown --output-path=./docs/api-docs.md

codegen: ## Build all generated code
codegen: codegen-crds
codegen: codegen-deepcopy
codegen: codegen-rbac
codegen: codegen-api-docs
codegen: codegen-client

#########
# BUILD #
#########

fmt: ## Run go fmt against code
fmt: codegen
	@echo Format code... >&2
	@go fmt ./...

imports: ## Run go imports against code
imports: $(GOIMPORTS)
imports: codegen
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
