KRUISE_VERSION ?= 0.4.0
KUBERNETES_VERSION ?= 1.16.4

TEST_NAMESPACE ?= testns
KUBECTL := minikube kubectl --
KUBECTL_NS := $(KUBECTL) -n "$(TEST_NAMESPACE)"

MULTICONTAINER ?= 1

.PHONY: minikube kruise setup run check

.NOTPARALLEL:
check: kruise setup run

check_sc: MULTICONTAINER=0
check_sc: check

# 1- validate that the sidecar container is setup
# 2- patch the SidecarSet image
# 3- validate that the sidecar container has been updated
run:
	$(KUBECTL_NS) get pods --selector=app=nginx -o json | \
		jq -er '.items[].spec.containers[1].image == "busybox:latest"'
	$(KUBECTL_NS) apply -f ./sidecarset-test-update.yaml
	sleep 120 # wait for sidecar to be updated
	$(KUBECTL_NS) get pods --selector=app=nginx -o json | \
		jq -er '.items[].spec.containers[1].image == "ubuntu:latest"'

# The following targets setup a minikube cluster with kruise installed and a sidecarset defined to add a sidecar to nginx pods.
setup:
	$(KUBECTL) create namespace "$(TEST_NAMESPACE)"
	$(KUBECTL_NS) apply -f ./sidecarset-test.yaml
	if test "$(MULTICONTAINER)" -eq "0"; then \
		$(KUBECTL_NS) apply -f ./nginx.yaml; \
	else \
		$(KUBECTL_NS) apply -f ./nginx-mc.yaml; \
	fi
	$(KUBECTL_NS)  wait --for=condition=Ready --all pod --timeout 1m

kruise: minikube
	helm install --wait kruise https://github.com/openkruise/kruise/releases/download/v$(KRUISE_VERSION)/kruise-chart.tgz --set manager.log.level=5

minikube:
	-minikube delete
	minikube start --kubernetes-version=$(KUBERNETES_VERSION)
