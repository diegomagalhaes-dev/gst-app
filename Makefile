# ==============================================================================
# Define dependencies

GOLANG          := golang:1.22.2
ALPINE          := alpine:3.18
KIND            := kindest/node:v1.27.3
POSTGRES        := postgres:15.4

KIND_CLUSTER    := sgt-kind-cluster
NAMESPACE       := simple-go-todo
APP             := todo
SERVICE_NAME    := todo-api
VERSION         := 0.0.1
SERVICE_IMAGE   := $(SERVICE_NAME):$(VERSION)

BASE_URL := http://localhost:8000

# ==============================================================================
# Install dependencies
dev-brew:
	brew update
	brew list kind || brew install kind
	brew list kubectl || brew install kubectl
	brew list kustomize || brew install kustomize
	brew list pgcli || brew install pgcli

dev-docker:
	docker pull $(GOLANG)
	docker pull $(ALPINE)
	docker pull $(KIND)
	docker pull $(POSTGRES)

# ==============================================================================
# Building containers

all: service

service:
	docker build \
		-f infra/docker/dockerfile.todo \
		-t $(SERVICE_IMAGE) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind

dev-up:
	kind create cluster \
		--image $(KIND) \
		--name $(KIND_CLUSTER) \
		--config infra/k8s/dev/kind/kind.config.yaml

	kubectl config use-context kind-$(KIND_CLUSTER)
	kubectl wait --timeout=120s --namespace=local-path-storage --for=condition=Available deployment/local-path-provisioner
	kind load docker-image $(POSTGRES) --name $(KIND_CLUSTER)

dev-down:
	kind delete cluster --name $(KIND_CLUSTER)

# ------------------------------------------------------------------------------

dev-load:
	cd infra/k8s/dev/service; kustomize edit set image service-image=$(SERVICE_IMAGE)
	kind load docker-image $(SERVICE_IMAGE) --name $(KIND_CLUSTER)

dev-apply:
	kustomize build infra/k8s/dev/database | kubectl apply -f -
	kubectl rollout status --namespace=$(NAMESPACE) --watch --timeout=120s sts/database
	
	kustomize build infra/k8s/dev/service | kubectl apply -f -
	kubectl wait pods --namespace=$(NAMESPACE) --selector app=$(APP) --timeout=120s --for=condition=Ready

dev-restart:
	kubectl rollout restart deployment --namespace=$(NAMESPACE) $(APP)

dev-update: all dev-load dev-restart

dev-update-apply: service dev-load dev-apply

# ==============================================================================
# Todo CRUD endpoints

create:
	@echo "Criando uma nova tarefa..."
	curl -X POST $(BASE_URL)/todos -H "Content-Type: application/json" -d '{"title":"4Dummies","completed":false}'

get_all:
	@echo "Obtendo todas as tarefas..."
	curl -X GET $(BASE_URL)/todos 

get_one:
	@echo "Obtendo uma tarefa específica..."
	curl -X GET $(BASE_URL)/todos/1

update:
	@echo "Atualizando a tarefa..."
	curl -X PUT $(BASE_URL)/todos/1 -H "Content-Type: application/json" -d '{"title":"Learn Docker and Kubernetes","completed":true}'

delete:
	@echo "Deletando a tarefa..."
	curl -X DELETE $(BASE_URL)/todos/1

test_all: create get_all get_one update delete
