##############################################################################################
#  Copyright Accenture. All Rights Reserved.
#
#  SPDX-License-Identifier: Apache-2.0
##############################################################################################

---
network:
  # Network level configuration specifies the attributes required for each organization
  # to join an existing network.
  type: fabric
  version: 2.2.2       # currently tested 1.4.4, 1.4.8 and 2.2.2
  # upgrade: "yes"

  #Environment section for Kubernetes setup
  env:
    type: "local"             # tag for the environment. Important to run multiple flux on single cluster
    proxy: none              # 'none' can be used in single-cluster networks to don´t use a proxy
    ambassadorPorts:          # Any additional Ambassador ports can be given here, this is valid only if proxy='ambassador'
      portRange:              # For a range of ports 
        from: 15010 
        to: 15020
    # ports: 15020,15021      # For specific ports
    retry_count: 50                 # Retry count for the checks
    external_dns: enabled          # Should be enabled if using external-dns for automatic route configuration
    # annotations:              # Additional annotations that can be used for some pods (ca, ca-tools, orderer and peer nodes)
    #   service: 
    #    - example1: example2
    #   deployment: {} 
    #   pvc: {}

  # configtx:
  #   custom: false               # true : when custom tpls are to be provided | false : when the default tpls are to be used
  #   folder_path: /home/bevel/build/configtx_tpl/               # path to folder where all 4 tpls are placed e.g. /home/bevel/build/configtx_tpl/ 

  # Docker registry details where images are stored. This will be used to create k8s secrets
  # Please ensure all required images are built and stored in this registry.
  # Do not check-in docker_password.
  docker:
    url: "index.docker.io/hyperledgerlabs"
    username: ""
    password: ""

  # Remote connection information for orderer (will be blank or removed for orderer hosting organization)
  # For RAFT consensus, have odd number (2n+1) of orderers for consensus agreement to have a majority.
  consensus:
    name: raft
    type: broker        #This field is not consumed for raft consensus
    replicas: 4         #This field is not consumed for raft consensus
    grpc:
      port: 9092        #This field is not consumed for raft consensus
  orderers:
    - orderer:
      type: orderer
      name: orderer1
      org_name: {{ ordererOrg1 | lower }}            # org_name should match one organization definition below in organizations: key            
      orderer_org: {{ ordererOrg1 | lower }}
      uri: orderer1.{{ ordererOrg1 | lower }}:7050    # Internal URI for orderer which should be reachable by all peers
      certificate: /home/bevel/build/orderer1.crt   # the directory should be writable

  # The channels defined for a network with participating peers in each channel
  channels:
  - channel:
    consortium: {{ ordererOrg1}}Consortium
    channel_name: AllChannel
    chaincodes:
      - "chaincode_name"
    orderers:
      - {{ ordererOrg1 |  lower }}
    participants:
    - organization:
      name: {{peerOrg1 | lower}}
      type: creator       # creator organization will create the channel and instantiate chaincode, in addition to joining the channel and install chaincode
      org_status: new
      peers:
      - peer:
        name: peer0
        gossipAddress: peer0.{{peerOrg1 | lower}}:7051         # Internal URI of the gossip peer
        peerAddress: peer0.{{peerOrg1 | lower}}:7051           # Internal URI of the peer
        # peerstatus: existing
      ordererAddress: orderer1.{{ ordererOrg1 |  lower }}:7050   # Internal URI of the orderer
    - organization:
      name: {{peerOrg2 | lower}}
      type: joiner
      org_status: new
      peers:
      - peer:
        name: peer0
        gossipAddress: peer0.{{peerOrg2 | lower}}:7051
        # peerstatus: existing
        peerAddress: peer0.{{peerOrg2 | lower}}:7051      # Internal URI of the peer
      ordererAddress: orderer1.{{ ordererOrg1 |  lower }}:7050
    - organization:
      name: {{ peerOrg3 |  lower }}
      type: joiner       # creator organization will create the channel and instantiate chaincode, in addition to joining the channel and install chaincode
      org_status: new
      peers:
      - peer:
        name: peer0
        gossipAddress: peer0.{{ peerOrg3 |  lower }}:7051         # Internal URI of the gossip peer
        peerAddress: peer0.{{ peerOrg3 |  lower }}:7051           # Internal URI of the peer
      ordererAddress: orderer1.{{ ordererOrg1 |  lower }}:7050
    endorsers:
    # Only one peer per org required for endorsement
    - organization:
      name: {{peerOrg1 | lower}}
      peers:
      - peer:
        name: peer0
        corepeerAddress: peer0.{{peerOrg1 | lower}}:7051
        certificate: "/home/bevel/build/{{peerOrg1 | lower}}/peer0.crt" # certificate path for peer
    - organization:
      name: {{ peerOrg2 |  lower }}
      peers:
      - peer:
        name: peer0
        corepeerAddress: peer0.{{ peerOrg2 |  lower }}:7051
        certificate: "/home/bevel/build/{{ peerOrg2 |  lower }}/peer0.crt" # certificate path for peer
    - organization:
      name: {{ peerOrg3 |  lower }}
      peers:
      - peer:
        name: peer0
        corepeerAddress: peer0.{{ peerOrg3 |  lower }}:7051
        certificate: "/home/bevel/build/{{ peerOrg3 |  lower }}/peer0.crt" # certificate path for peer
    genesis:
      name: OrdererGenesis

  # Allows specification of one or many organizations that will be connecting to a network.
  # If an organization is also hosting the root of the network (e.g. doorman, membership service, etc),
  # then these services should be listed in this section as well.
  organizations:

    # Specification for the 1st organization. Each organization maps to a VPC and a separate k8s cluster
    - organization:
      name: {{ ordererOrg1 |  lower }}
      country: UK
      state: London
      location: London
      subject: "O=Orderer,L=51.50/-0.13/London,C=GB"
      type: orderer
      external_url_suffix: bank.com  # Ignore for proxy none
      org_status: new
      fabric_console: enabled
      ca_data:
        url: ca.{{ ordererOrg1 |  lower }}:7054
        certificate: /home/bevel/build/orderer1.crt

      cloud_provider: z   # Options: aws, azure, minikube
      aws:
        access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
        secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws

      # Kubernetes cluster deployment variables. The config file path and name has to be provided in case
      # the cluster has already been created.
      k8s:
        # region: "us-central1-c"
        context: "minikube"
        config_file: "/home/bevel/build/config"

      # Hashicorp Vault server address and root-token. Vault should be unsealed.
      # Do not check-in root_token
      vault:
        url: "http://54.163.55.154:8200"
        root_token: "root"
        secret_path: "secretsv2"

      # Git Repo details which will be used by GitOps/Flux.
      # Do not check-in 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
      gitops:
        git_protocol: "https" # Option for git over https or ssh
        git_url: "https://github.com/ShettyDeepshika/bevel.git"  # Gitops https or ssh url for flux value files 
        branch: "upgrade"                                          # Git branch where release is being made
        release_dir: "platforms/hyperledger-fabric/releases/dev" # Relative Path in the Git repo for flux sync per environment.
        chart_source: "platforms/hyperledger-fabric/charts"      # Relative Path where the Helm charts are stored in Git repo
        git_repo: "github.com/ShettyDeepshika/bevel.git"              # Gitops git repository URL for git push  (without https://)
        username: "ShettyDeepshika"                              # Git user who has rights to check-in in all branches
        password: "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"                             # Git Server user password/token (Optional for ssh; Required for https)
        email: "mindtree09deepshika@gmail.com"                                   # Email to use in git config
        private_key: "/home/bevel/build/gitops"                  # Path to private key file which has write-access to the git repo (Optional for https; Required for ssh)

      # Services maps to the pods that will be deployed on the k8s cluster
      # This sample is an orderer service and includes a raft consensus
      services:
        ca:
          name: ca
          subject: "/C=GB/ST=London/L=London/O=Orderer/CN=ca.{{ ordererOrg1 |  lower }}"
          type: ca
          grpc:
            port: 7054

        consensus:
          name: raft
        
        orderers:
        - orderer:
          name: orderer1
          type: orderer
          consensus: raft
          grpc:
            port: 7050

    # Specification for the 2nd organization. Each organization maps to a VPC and a separate k8s cluster
    - organization:
      name: {{ peerOrg2 |  lower }}
      country: CH
      state: Zurich
      location: Zurich
      subject: "O={{ peerOrg2 }},OU={{ peerOrg2 }},L=47.38/8.54/Zurich,C=CH"
      type: peer
      org_status: new
      fabric_console: enabled
      external_url_suffix: # Ignore for proxy none
      orderer_org: {{ ordererOrg1 |  lower }} # Name of the organization that provides the ordering service
      ca_data:
        url: ca.{{ peerOrg2 |  lower }}:7054
        certificate: /home/bevel/build/{{ peerOrg2 |  lower }}/server.crt

      cloud_provider: minikube   # Options: aws, azure, minikube
      aws:
        access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
        secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws

      # Kubernetes cluster deployment variables. The config file path and name has to be provided in case
      # the cluster has already been created.
      k8s:
        # region: "us-central1-c"
        context: "minikube"
        config_file: "/home/bevel/build/config"

      # Hashicorp Vault server address and root-token. Vault should be unsealed.
      # Do not check-in root_token
      vault:
        url: "http://54.163.55.154:8200"
        root_token: "root"
        secret_path: "secretsv2"

      # Git Repo details which will be used by GitOps/Flux.
      # Do not check-in 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
      gitops:
        git_protocol: "https" # Option for git over https or ssh
        git_url: "https://github.com/ShettyDeepshika/bevel.git"  # Gitops https or ssh url for flux value files 
        branch: "upgrade"                                          # Git branch where release is being made
        release_dir: "platforms/hyperledger-fabric/releases/dev" # Relative Path in the Git repo for flux sync per environment.
        chart_source: "platforms/hyperledger-fabric/charts"      # Relative Path where the Helm charts are stored in Git repo
        git_repo: "github.com/ShettyDeepshika/bevel.git"              # Gitops git repository URL for git push  (without https://)
        username: "ShettyDeepshika"                              # Git user who has rights to check-in in all branches
        password: "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"                             # Git Server user password/token (Optional for ssh; Required for https)
        email: "mindtree09deepshika@gmail.com"                                   # Email to use in git config
        private_key: "/home/bevel/build/gitops"                  # Path to private key file which has write-access to the git repo (Optional for https; Required for ssh)

      # Generating User Certificates with custom attributes using Fabric CA in BAF for Peer Organizations
      users:
      - user:
        identity: user1
        attributes:
          - key: "hf.Revoker"
            value: "true"
      # The participating nodes are peers
      # This organization hosts it's own CA server
      services:
        ca:
          name: ca
          subject: "/C=CH/ST=Zurich/L=Zurich/O={{ peerOrg2 }}/CN=ca.{{ peerOrg2 |  lower }}"
          type: ca
          grpc:
            port: 7054
        peers:
        - peer:
          name: peer0          
          type: anchor                                          # This can be anchor/nonanchor. Atleast one peer should be anchor peer.         
          # peerstatus: existing
          gossippeeraddress: peer0.{{ peerOrg2 |  lower }}:7051        # Internal Address of the other peer in same Org for gossip, same peer if there is only one peer  
          peerAddress: peer0.{{ peerOrg2 |  lower }}:7051              # Internal URI of the peer
          certificate: /home/bevel/build/{{ peerOrg2 |  lower }}/peer0.crt # Path to peer Certificate
          cli: enabled                                          # Creates a peer cli pod depending upon the (enabled/disabled) tag. 
          grpc:
            port: 7051
          events:
            port: 7053
          couchdb:
            port: 5984
          restserver:           # This is for the rest-api server
            targetPort: 20001
            port: 20001
          expressapi:           # This is for the express api server
            targetPort: 3000
            port: 3000
          chaincodes:
            - name: "supplychain"    # This has to be replaced with the name of the chaincode
              version: "1"           # This has to be replaced with the version of the chaincode (do NOT use .)
              maindirectory: "cmd"   # The main directory where chaincode is needed to be placed
              lang: "golang"  # The language in which the chaincode is written ( golang/java/node )
              repository:
                username: "ShettyDeepshika"          # Git user with read rights to repo
                password: "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"         # Git token of above user
                url: "github.com/ShettyDeepshika/bevel.git"
                branch: upgrade
                path: "examples/supplychain-app/fabric/chaincode_rest_server/chaincode/"  #The path to the chaincode in the repo
              arguments: '\"init\",\"\"'                                                  #Arguments to be passed along with the chaincode parameters
              endorsements: ""                                                            #Endorsements (if any) provided along with the chaincode

    - organization:
      name: {{peerOrg1 | lower}}
      country: GB
      org_status: new
      state: London
      location: London
      fabric_console: enabled
      subject: "O={{peerOrg1}},OU={{peerOrg1}},L=51.50/-0.13/London,C=GB"
      type: peer
      external_url_suffix:  # Ignore for proxy none
      orderer_org: {{ ordererOrg1 |  lower }} # Name of the organization that provides the ordering service
      ca_data:
        url: ca.{{peerOrg1 | lower}}:7054
        certificate: /home/bevel/build/{{peerOrg1 | lower}}/server.crt

      cloud_provider: minikube   # Options: aws, azure, minikube
      aws:
        access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
        secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws

      # Kubernetes cluster deployment variables. The config file path and name has to be provided in case
      # the cluster has already been created.
      k8s:
        # region: "us-central1-c"
        context: "minikube"
        config_file: "/home/bevel/build/config"

      # Hashicorp Vault server address and root-token. Vault should be unsealed.
      # Do not check-in root_token
      vault:
        url: "http://54.163.55.154:8200"
        root_token: "root"
        secret_path: "secretsv2"

      # Git Repo details which will be used by GitOps/Flux.
      # Do not check-in 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
      gitops:
        git_protocol: "https" # Option for git over https or ssh
        git_url: "https://github.com/ShettyDeepshika/bevel.git"  # Gitops https or ssh url for flux value files 
        branch: "upgrade"                                          # Git branch where release is being made
        release_dir: "platforms/hyperledger-fabric/releases/dev" # Relative Path in the Git repo for flux sync per environment.
        chart_source: "platforms/hyperledger-fabric/charts"      # Relative Path where the Helm charts are stored in Git repo
        git_repo: "github.com/ShettyDeepshika/bevel.git"              # Gitops git repository URL for git push  (without https://)
        username: "ShettyDeepshika"                              # Git user who has rights to check-in in all branches
        password: "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"                             # Git Server user password/token (Optional for ssh; Required for https)
        email: "mindtree09deepshika@gmail.com"                                   # Email to use in git config
        private_key: "/home/bevel/build/gitops"                  # Path to private key file which has write-access to the git repo (Optional for https; Required for ssh)

      # Generating User Certificates with custom attributes using Fabric CA in BAF for Peer Organizations
      users:
      - user:
        identity: user1
        attributes:
          - key: "hf.Revoker"
            value: "true"
      services:
        ca:
          name: ca
          subject: "/C=GB/ST=London/L=London/O={{ peerOrg1 }}/CN=ca.{{ peerOrg1 |  lower }}"
          type: ca
          grpc:
            port: 7054
        peers:
        - peer:
          name: peer0          
          type: anchor                                      # This can be anchor/nonanchor. Atleast one peer should be anchor peer.    
          # peerstatus: existing
          gossippeeraddress: peer0.{{ peerOrg1 |  lower }}:7051         # Internal Address of the other peer in same Org for gossip, same peer if there is only one peer  
          peerAddress: peer0.{{ peerOrg1 |  lower }}:7051               # Internal URI of the peer
          certificate: /home/bevel/build/{{ peerOrg1 |  lower }}/peer0.crt  # Path to peer Certificate
          cli: enabled                                     # Creates a peer cli pod depending upon the (enabled/disabled) tag. 
          grpc:
            port: 7051
          events:
            port: 7053
          couchdb:
            port: 5984
          restserver:
            targetPort: 20001
            port: 20001
          expressapi:
            targetPort: 3000
            port: 3000
          chaincodes:
            - name: "supplychain"    # This has to be replaced with the name of the chaincode
              version: "1"           # This has to be replaced with the version of the chaincode (do NOT use .)
              maindirectory: "cmd"   # The main directory where chaincode is needed to be placed
              lang: "golang"  # The language in which the chaincode is written ( golang/java/node )
              repository:
                username: "ShettyDeepshika"          # Git user with read rights to repo
                password: "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"         # Git token of above user
                url: "github.com/ShettyDeepshika/bevel.git"
                branch: upgrade
                path: "examples/supplychain-app/fabric/chaincode_rest_server/chaincode/"  #The path to the chaincode in the repo
              arguments: '\"init\",\"\"'                                                  #Arguments to be passed along with the chaincode parameters
              endorsements: ""                                                            #Endorsements (if any) provided along with the chaincode
    - organization:
      name: {{ peerOrg3 |  lower }}
      country: CH
      state: Zurich
      location: Zurich
      subject: "O={{ peerOrg3}},OU={{ peerOrg3}},L=47.38/8.54/Zurich,C=CH"
      type: peer
      org_status: new
      fabric_console: enabled
      external_url_suffix: # Ignore for proxy none
      orderer_org: {{ ordererOrg1 |  lower }} # Name of the organization that provides the ordering service
      ca_data:
        url: ca.{{ peerOrg3 |  lower }}:7054
        certificate: /home/bevel/build/{{peerOrg3 |  lower }}/server.crt

      cloud_provider: minikube   # Options: aws, azure, minikube
      aws:
        access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
        secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws

      # Kubernetes cluster deployment variables. The config file path and name has to be provided in case
      # the cluster has already been created.
      k8s:
        # region: "us-central1-c"
        context: "minikube"
        config_file: "/home/bevel/build/config"

      # Hashicorp Vault server address and root-token. Vault should be unsealed.
      # Do not check-in root_token
      vault:
        url: "http://54.163.55.154:8200"
        root_token: "root"
        secret_path: "secretsv2"

      # Git Repo details which will be used by GitOps/Flux.
      # Do not check-in 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
      gitops:
        git_protocol: "https" # Option for git over https or ssh
        git_url: "https://github.com/ShettyDeepshika/bevel.git"  # Gitops https or ssh url for flux value files 
        branch: "upgrade"                                          # Git branch where release is being made
        release_dir: "platforms/hyperledger-fabric/releases/dev" # Relative Path in the Git repo for flux sync per environment.
        chart_source: "platforms/hyperledger-fabric/charts"      # Relative Path where the Helm charts are stored in Git repo
        git_repo: "github.com/ShettyDeepshika/bevel.git"              # Gitops git repository URL for git push  (without https://)
        username: "ShettyDeepshika"                              # Git user who has rights to check-in in all branches
        password: "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"                             # Git Server user password/token (Optional for ssh; Required for https)
        email: "mindtree09deepshika@gmail.com"                                   # Email to use in git config
        private_key: "/home/bevel/build/gitops"                  # Path to private key file which has write-access to the git repo (Optional for https; Required for ssh)

      # Generating User Certificates with custom attributes using Fabric CA in BAF for Peer Organizations
      users:
      - user:
        identity: user1
        attributes:
          - key: "hf.Revoker"
            value: "true"
      # The participating nodes are peers
      # This organization hosts it's own CA server
      services:
        ca:
          name: ca
          subject: "/C=CH/ST=Zurich/L=Zurich/O={{ peerOrg3 }}/CN=ca.{{ peerOrg3 |  lower }}"
          type: ca
          grpc:
            port: 7054
        peers:
        - peer:
          name: peer0          
          type: anchor                                          # This can be anchor/nonanchor. Atleast one peer should be anchor peer.         
          # peerstatus: existing
          gossippeeraddress: peer0.{{ peerOrg3 |  lower }}:7051        # Internal Address of the other peer in same Org for gossip, same peer if there is only one peer  
          peerAddress: peer0.{{ peerOrg3 |  lower }}:7051              # Internal URI of the peer
          certificate: /home/bevel/build/{{ peerOrg3 |  lower }}/peer0.crt # Path to peer Certificate
          cli: enabled                                          # Creates a peer cli pod depending upon the (enabled/disabled) tag. 
          grpc:
            port: 7051
          events:
            port: 7053
          couchdb:
            port: 5984
          restserver:           # This is for the rest-api server
            targetPort: 20001
            port: 20001
          expressapi:           # This is for the express api server
            targetPort: 3000
            port: 3000
          chaincodes:
            - name: "supplychain"    # This has to be replaced with the name of the chaincode
              version: "1"           # This has to be replaced with the version of the chaincode (do NOT use .)
              maindirectory: "cmd"   # The main directory where chaincode is needed to be placed
              lang: "golang"  # The language in which the chaincode is written ( golang/java/node )
              repository:
                username: "ShettyDeepshika"          # Git user with read rights to repo
                password: "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"         # Git token of above user
                url: "github.com/ShettyDeepshika/bevel.git"
                branch: upgrade
                path: "examples/supplychain-app/fabric/chaincode_rest_server/chaincode/"  #The path to the chaincode in the repo
              arguments: '\"init\",\"\"'                                                  #Arguments to be passed along with the chaincode parameters
              endorsements: ""                                                            #Endorsements (if any) provided along with the chaincode
  