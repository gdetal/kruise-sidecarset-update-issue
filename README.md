# kruise-sidecarset-update-issue

This repository contains code to ease the reproduction of issue https://github.com/openkruise/kruise/issues/242

## How to run the validation

1. install minikube
2. run `make check`

You can also setup the environment via `make setup` then run the steps manually (see target `check` in `Makefile`)

## Troubleshooting

It seems that the issue arise when the SidecarSet tries to update a Pod that previously had multiple containers.
To run the test with and without the multi-container Pods respectivelly use `make check` and `make check_sc`.
