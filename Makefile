KRUISE_VERSION ?= 0.4.0
KUBERNETES_VERSION ?= 1.14.3

.PHONY: minikube kruise setup

# 1- validate that the sidecar container is setup
# 2- patch the SidecarSet image
# 3- validate that the sidecar container has been updated
check: setup
	minikube kubectl -- get pods --selector=app=nginx -o json | \
		jq -er '.items[].spec.containers[1].image == "busybox:latest"'
	minikube kubectl -- patch sidecarsets sidecarset-test --type merge \
		-p '{"spec":{"containers":[{"name":"busybox","image":"ubuntu:latest"}]}}'
	minikube kubectl --  wait --for=condition=Ready --all pod --timeout 1m
	minikube kubectl -- get pods --selector=app=nginx -o json | \
		jq -er '.items[].spec.containers[1].image == "ubuntu:latest"'

# The following targets setup a minikube cluster with kruise installed and a sidecarset defined to add a sidecar to nginx pods.
setup: kruise
	minikube kubectl -- apply -f ./sidecarset-test.yaml
	minikube kubectl -- apply -f ./nginx.yaml
	minikube kubectl --  wait --for=condition=Ready --all pod --timeout 1m

kruise: minikube
	helm install --wait kruise https://github.com/openkruise/kruise/releases/download/v$(KRUISE_VERSION)/kruise-chart.tgz --set manager.log.level=5

minikube:
	-minikube delete
	minikube start --kubernetes-version=$(KUBERNETES_VERSION)
