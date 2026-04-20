# Debug-Container

## Version v0.4.11 (2025-12-05)

Container based on Debian with debug tools added. (--platform=linux/amd64)
Its big :( 4.6GB

- aws-cli
- az azure cli (Using uv pip)
- rust + cargo
- nodejs(v22) nvm
- ansible (Using uv pip)
- terraform -> [tfswitch + aztfexport(2025-03-25 v0.17.1) + shell scripts]
- network tools: ssh, tcpdump, ngrep, dnsutils(dig), etc.

## Usage example: To attach the container to running k8s pod to debug

- Requires k8s > 2.24 (2021)

 1. Get the name of the pod and the container in the pod to attach to
 2. export POD_NAME="debug"
 3. export POD_NS="vigor"
 4. Create NS if it does not exist. kubectl create namespace ${NS}
 5. Run container in k8s
    1. run full debug container:
     ```kubectl run  -n ${POD_NS} ${POD_NAME} -it --rm --restart=Never --image=docker.io/diepes/debug:latest -- bash```
    1. attache debug container to existing container e.g. ingress
    ```kubectl debug -n ${POD_NS} ${POD_NAME} -it --rm --image=docker.io/diepes/debug:latest [ --target <ContainerNameInPod> ] -- sh```
    ```` kubectl debug -n tm-infra -it tm-infra-shared-ingress-nginx-controller-797ccc698d-4hmgb --image=debian:stable --target=controller -- bash```
    1. run local debug container
    ```docker run --rm -it docker.io/diepes/debug:latest bash```
    1. run aws container
    ```docker run --rm -it amazon/aws-cli --version```
    1. run debug container with ssh login
       - add --env root_password="xyzzz" --entrypoint="/entrypoint-sshd.sh"
    1. Use container for aztfexport to create terraform config

           export AZTFEXPORT_SUBSCRIPTION_ID="<< SUB >>"
           export AZTFEXPORT_RG="<< RG >>"

           docker run -it --rm --platform=linux/amd64 \
               --volume ${PWD}:/root/tf:ro \
               --volume ${PWD}/aztf_out:/root/tf/aztf_out \
               --env AZTFEXPORT_RG="${AZTFEXPORT_RG}" \
               --env AZTFEXPORT_SUBSCRIPTION_ID="${AZTFEXPORT_SUBSCRIPTION_ID}" \
               --name tfimport \
               diepes/debug

       1. Run Debug container mounting aws folder

              docker run -v ~/.aws:/root/.aws -v ~/.kube:/root/.kube -it diepes/debug 

## Software in container

- ansible
- aws cli
- azure cli
- git
- helm
- rust
- ssh
- nvm (nodejs)
- terraform (tfswitch + aztfexport)

# Local test

- build

      docker build . -t debug-local

- run

      docker run -it --rm --platform=linux/amd64 debug-local

- 2nd exec into container

      docker exec -it debug-local -- bash
