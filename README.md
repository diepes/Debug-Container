# Debug-Container

Container based on Debian with debug tools added. (--platform=linux/amd64)
Its big :( 4.6GB

- aws-cli
- az azure cli (Using pip --break-system-packages)
- rust + cargo
- nodejs(v20) nvm
- ansible (Using pip --break-system-packages)
- terraform -> [tfswitch + aztfexport(2024-04-16 v0.14.1) + shell scripts]
- network tools: ssh, tcpdump, ngrep, dnsutils(dig), etc.

## Usage example: To attach the container to running k8s pod to debug

- Requires k8s > 2.24 (2021)

 1. Get the name of the pod and the container in the pod to attach to
 2. POD_NAME="debug"
 3. NS="vigor"
 4. Create NS if it does not exist. kubectl create namespace ${NS}
 5. Run container in k8s
    1. run full debug container:
     ```kubectl run  -n ${NS} ${POD_NAME} -it --image=docker.io/diepes/debug:latest -- bash```
    1. attache debug container to existing container e.g. ingress
    ```kubectl debug -n ${NS} ${POD_NAME} -it --image=docker.io/diepes/debug:latest [ --target <ContainerNameInPod> ] -- sh```
    ```` kubectl debug -n tm-infra -it tm-infra-shared-ingress-nginx-controller-797ccc698d-4hmgb --image=debian:stable --target=controller -- bash```
    1. run local debug container
    ```docker run --rm -it docker.io/diepes/debug:latest bash```
    1. run aws container
    ```docker run --rm -it amazon/aws-cli --version```

## Software in container

- ansible
- aws cli
- azure cli
- git
- rust
- ssh
- nvm (nodejs)
- terraform (tfswitch + aztfexport)
