# Information

Shell scripts to run aztfexport tool to create terraform main.tf and imports from actual Azure RG

## How to import

1. Create tfimport dir, and add remotestate.tf to point to TF cloud.
1. Update pes-aztfexport.sh with correct Subscription and RG
1. Run ```./pes-docker-aztfexport.sh``` (Container env with TF etc.)
   - tfswitch to install terraform in container
1. In container login
   - az login --use-device-code
   - web auth
   - cd tf
1. In container do import into ./aztf_out
   1. aztfexport create Map with names to import
      ```./pes-aztfexport.sh 2```
   2. rename names from gen-123 to resource names
      ```./pes-search_and_replace.py```
   3. copy ./aztf_out/aztfexportResourceMapping.json to .. out of aztf_out
   4. run aztfexport to use the new map and do the actual export, creating import.tf and main.tf
      ```./pes-aztfexport.sh 3```
1. In "Microsoft Azure Export for Terraform"
   - "s" save aztf_out/aztfexportResourceMapping.json
