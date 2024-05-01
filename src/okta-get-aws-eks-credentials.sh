#!/usr/bin/env bash
backup_kube_config="~/.kube/config.bak"

echo; echo "## Validate kube config before we start..."; sleep 1
kubectl config view
if [ $? -ne 0 ]; then
    echo "## kubectl config view failed, exiting ..."; exit 1
fi
# Make a backup of kube config if it exists
cp ~/.kube/config $backup_kube_config 2>/dev/null

# Catch all non-zero exit codes
set -e

echo; echo "## Install openjdk-jre ..."; sleep 1
apt update
apt install -y default-jre

echo; echo "## Install okta-awscli-java ..."; sleep 1
curl 'https://raw.githubusercontent.com/oktadeveloper/okta-aws-cli-assume-role/master/bin/install.sh' -o install.sh ; bash install.sh -i

export PATH=$PATH:/root/.okta/bin
ln -s /root/.okta/bin/awscli /usr/local/bin/okta-aws

echo
echo "## Verify okta-aws credentials or create [oktaprofile] ..."; 
echo "## - you will be prompted for okta password ..."
sleep 1
#okta-aws oktaprofile sts get-caller-identity --region ap-southeast-2
#~/.okta/bin/withokta aws --profile  oktaprofile sts get-caller-identity --region ap-southeast-2
. "$HOME/.okta/bash_functions"
PATH="$HOME/.okta/bin:$PATH"
okta-aws oktaprofile sts get-caller-identity

echo; echo "## List EKS k8s clusters ..."; sleep 1
aws eks list-clusters --profile oktaprofile --region ap-southeast-2

echo; echo "## Loop through clusters and add to kube config ..."; sleep 1
echo "   # Get list of EKS clusters ..."
clusters=$( aws eks list-clusters --profile oktaprofile --region ap-southeast-2 | python3 -c "import sys, json; print(' '.join(json.load(sys.stdin)['clusters']))" )

echo "   # Loop through and add each EKScluster ..."; echo

for c in $clusters; do
    echo "c=$c"
    aws eks update-kubeconfig --name $c --region ap-southeast-2 --profile oktaprofile
done

echo; echo "## Validate kube config after initial update ..."; sleep 1
kubectl config view
if [ $? -ne 0 ]; then
    echo "## kubectl config broken after initial update ? check error above and compare to backup $backup_kube_config ..."; exit 1
fi 

sleep 2
echo
echo "## Updated kube config for $clusters"

echo "## Update .kube/config names, simplify"
## user: arn:aws:eks:ap-southeast-2:397193723729:cluster/wso2-eks-dev-fM54yODz
sed -i.bak 's/\(name: \)




//\1/' ~/.kube/config
diff ~/.kube/config ~/.kube/config.bak

# Install kubectl
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl ; mv kubectl /usr/local/bin/

echo; echo "## Validate kube config after changes ..."; sleep 1
kubectl config view
if [ $? -ne 0 ]; then
    echo "## kubectl config broken ? check error above and compare to backup $backup_kube_config ..."; exit 1
fi 
echo "## DONE"

