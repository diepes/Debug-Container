# Debug-Container

## Version v0.4.0 (2025-04-24)

Container based on Debian with debug tools added. (--platform=linux/amd64)
Its big :( 4.6GB

- aws-cli
- az azure cli (Using pip --break-system-packages)
- rust + cargo
- nodejs(v20) nvm
- ansible (Using pip --break-system-packages)
- terraform -> [tfswitch + aztfexport(2025-03-25 v0.17.1) + shell scripts]
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

    1. Okta retrieve AWS EKS k8s credentials.
       1. Create setup ~/.okta/config.properties e.g.

              OKTA_ORG=CORP.okta.com
              OKTA_AWS_APP_URL=https://CORP.okta.com/home/amazon_aws/0xxxxxxxx000xx0/171
              OKTA_USERNAME=123456
              OKTA_BROWSER_AUTH=false

       1. Run Debug container mounting aws and okta folders

              docker run -v ~/.okta/config.properties:/root/.okta/config.properties -v ~/.aws:/root/.aws -v ~/.kube:/root/.kube -it diepes/debug 

       1. Run extractions script in container, intall okta package.


              okta-get-aws-eks-credentials.sh

## Software in container

- ansible
- aws cli
- azure cli
- git
- rust
- ssh
- nvm (nodejs)
- terraform (tfswitch + aztfexport)
- okta-get-aws-eks-credentials.sh (Script to use okta java client EKS credential retrieving see e.g. above.)
