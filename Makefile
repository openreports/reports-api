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

CODEGEN_VERSION := v0.30.0-rc.2
CODEGEN = $(shell pwd)/bin/code-generator
CODEGEN_ROOT = $(shell $(GO_CMD) env GOMODCACHE)/k8s.io/code-generator@$(CODEGEN_VERSION)
CONTROLLER_TOOLS_VERSION           ?= v0.18.0
CONTROLLER_GEN                     ?= $(LOCALBIN)/controller-gen
GEN_CRD_API_REFERENCE_DOCS         ?= $(LOCALBIN)/crd-ref-docs
GEN_CRD_API_REFERENCE_DOCS_VERSION ?= latest
HELM                               ?= $(LOCALBIN)/helm
HELM_VERSION                       ?= v3.17.3
GOIMPORTS                          ?= $(LOCALBIN)/goimports
GOIMPORTS_VERSION                  ?= latest
TOOLS := $(HELM)
SED     := $(shell if [ "$(GOOS)" = "darwin" ]; then echo "gsed"; else echo "sed"; fi)

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
	GOBIN=$(LOCALBIN) $(GO_CMD) install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

.PHONY: install-tools
install-tools: ## Install tools
install-tools: $(TOOLS) $(GEN_CRD_API_REFERENCE_DOCS) $(CONTROLLER_GEN) $(GOIMPORTS)

.PHONY: clean-tools
clean-tools: ## Remove installed tools
	@echo Clean tools... >&2
	@rm -rf $(LOCALBIN)

all: code-generator manifests generate generate-api-docs generate-client build fmt vet

generate-all: code-generator manifests generate generate-api-docs generate-client

.PHONY: manifests
manifests: ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
manifests: $(CONTROLLER_GEN)
	$(CONTROLLER_GEN) rbac:roleName=manager-role crd webhook paths="./apis/openreports.io/v1alpha1" output:crd:artifacts:config=crd/openreports.io/v1alpha1

.PHONY: generate
generate: ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
generate: $(CONTROLLER_GEN) 
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./apis/..."

.PHONY: generate-client
generate-client:
	./hack/update-codegen.sh


# Run go build against code
build:
	go build ./...

# Run go fmt against code
fmt:
	go fmt ./...

.PHONY: fmt-check
fmt-check:
	@echo "Checking go fmt..." >&2
	@git --no-pager diff .
	@echo 'If this test fails, it is because the git diff is non-empty after running "make fmt".' >&2
	@echo 'To correct this, locally run "make fmt" and commit the changes.' >&2
	@git diff --quiet --exit-code .

# Run go vet against code
vet:
	go vet ./...

.PHONY: imports
imports: $(GOIMPORTS)
	@echo Go imports... >&2
	@$(GOIMPORTS) -w .

.PHONY: imports-check
imports-check: imports
	@echo Checking go imports... >&2
	@git --no-pager diff .
	@echo 'If this test fails, it is because the git diff is non-empty after running "make imports-check".' >&2
	@echo 'To correct this, locally run "make imports" and commit the changes.' >&2
	@git diff --quiet --exit-code .

.PHONY: code-generator
code-generator:
	@GOBIN=$(PROJECT_DIR)/bin GO111MODULE=on $(GO_CMD) install k8s.io/code-generator/cmd/client-gen@$(CODEGEN_VERSION)
	cp -f $(CODEGEN_ROOT)/generate-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/generate-internal-groups.sh $(PROJECT_DIR)/bin/
	cp -f $(CODEGEN_ROOT)/kube_codegen.sh $(PROJECT_DIR)/bin/

# generate-api-docs will create api docs
generate-api-docs: $(GEN_CRD_API_REFERENCE_DOCS)
	$(GEN_CRD_API_REFERENCE_DOCS) --source-path=./apis/openreports.io/v1alpha1 --config=./docs/config.yaml --renderer=markdown --output-path=./docs/api-docs.md

.PHONY: codegen-api-docs
codegen-api-docs: $(PACKAGE_SHIM) $(GEN_CRD_API_REFERENCE_DOCS) $(GENREF) ## Generate API docs
	@echo Generate api docs... >&2
	$(GEN_CRD_API_REFERENCE_DOCS) -v=4 \
		-api-dir pkg/api \
		-config docs/config.json \
		-template-dir docs/template \
		-out-file docs/index.html

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
verify-codegen: generate-all
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