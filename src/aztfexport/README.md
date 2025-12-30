# Information

Shell scripts to run aztfexport tool to create terraform main.tf and imports from actual Azure RG

## How to import

1. (Optional) Create tfimport dir, and add remotestate.tf to point to TF cloud.
1. run the debug container ```docker run -it --rm -v ${PWD}:/root/tf:ro -v ${PWD}/aztf_out:/root/tf/aztf_out diepes/debug```
   - this will mount the local git volume/dir to ./tf in container.
   - NOTE: Container env with TF etc.
1. In container update  ```pes-aztfexport.sh``` to repo with correct Subscription and RG
   - ```vim.tiny /usr/local/bin/pes-aztfexport.sh```

1. In container login
   - ```tfswitch```` to install terraform in container
   - ```az login --use-device-code```
     - web auth - https://microsoft.com/devicelogin copy code and pick subscription.
   - ```cd tf```
1. In container do import into ./aztf_out
   1. aztfexport create Map with names to import
      ```~/tf $  pes-aztfexport.sh query / rg```
      - "s" save aztf_out/aztfexportResourceMapping.json
   2. rename names from gen-123 to resource names
      ```~/tf $ rust_aztfexport_rename```
      - remove unused
   3. ```~/tf $  cp ~/tf/aztf_out/aztfexportResourceMapping.json.out ~/azTfExpResMapIn.json```  (out of aztf_out into /root/)
   4. run aztfexport to use the new map and do the actual export, creating import.tf and main.tf
      ```~/tf:  pes-aztfexport.sh map```
1. Result: main.tf
1. Copy main.tf and import.tf into normal terraform folder, and split main.
1. Done
