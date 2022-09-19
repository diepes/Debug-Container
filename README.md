# Debug-Container
Container based on Debian with debug tools added.


## To attach the container to running k8s pod to debug
 * Requires k8s > 2.24 (2021)

 1. Get the name of the pod and the container in the pod to attach to
 2. POD="<pod-name>"
 3. NS="<name-space>"
 4. kubectl debug -n $NS -it $POD --image=docker.io/diepes/debug:latest [ --target <ContainerNameInPod> ] -- sh

 e.g. for ingress
 
     kubectl debug -n tm-infra -it tm-infra-shared-ingress-nginx-controller-797ccc698d-4hmgb --image=debian:stable --target=controller -- bash
     
