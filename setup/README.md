
# Setup Script

The setup.ps1 PowerShell Core script uses Helm to install and configure Code Dx and Tool Orchestration on a Kubernetes cluster. The setup.ps1 script located here gets called indirectly by the setup.ps1 scripts in the provider-specific folders. See the README files under aws, azure, and minikube for more details.

## Script Parameters

This section describes the setup.ps1 script parameters.

>Note: Refer to the README files under aws, azure, and minikube for instructions on how to configure Code Dx for those environments.

| Parameter | Description | Default | Example |
|---|---|---|---|
| workDir | workDir specifies a directory to store script-generated files | $HOME/.k8s-codedx | |
| clusterCertificateAuthorityCertPath | clusterCertificateAuthorityCertPath specifies a path to your cluster's CA certificate file | | ./aws-eks.pem |
| codeDxDnsName | codeDxDnsName specifies the domain name for the Code Dx web application | | www.codedx.io |
| codeDxPortNumber | codeDxPortNumber specifies the port number bound to the Code Dx web application | 8443 | |
| waitTimeSeconds | waitTimeSeconds specifies the amount of time to wait for install commands to complete | 900 | |
| dbVolumeSizeGiB | dbVolumeSizeGiB specifies the size of the volume for the MariaDB database | 32 | |
| dbSlaveReplicaCount | dbSlaveReplicaCount specifies the number of MariaDB slave instances | 0 | |
| dbSlaveVolumeSizeGiB | dbSlaveVolumeSizeGiB specifies the size of the volume for each MariaDB slave instance | 32 | |
| minioVolumeSizeGiB | minioVolumeSizeGiB specifies the size of the volume for the MinIO storage application | 32 | |
| codeDxVolumeSizeGiB | codeDxVolumeSizeGiB specifies the size of the volume for the Code Dx web application | 32 | |
| storageClassName | storageClassName specifies the name of the storage class for persistance volume claims | | managed-premium |
| imageCodeDxTomcat | imageCodeDxTomcat specifies the name of the Code Dx Docker image | codedxregistry.azurecr.io/codedx/codedx-tomcat:latest |
| imageCodeDxTools | imageCodeDxTools specifies the name of the Code Dx Tools Docker image | codedxregistry.azurecr.io/codedx/codedx-tools:latest | |
| imageCodeDxToolsMono | imageCodeDxToolsMono specifies the name of the Code Dx Tools Mono Docker image | codedxregistry.azurecr.io/codedx/codedx-toolsmono:latest | |
| imageNewAnalysis | imageNewAnalysis specifies the name of the Code Dx New Analysis Docker image | codedxregistry.azurecr.io/codedx/codedx-newanalysis:latest | |
| imageSendResults | imageSendResults specifies the name of the Code Dx Send Results Docker image | codedxregistry.azurecr.io/codedx/codedx-results:latest | |
| imageSendErrorResults | imageSendErrorResults specifies the name of the Code Dx Send Result Errors Docker image | codedxregistry.azurecr.io/codedx/codedx-error-results:latest | |
| imageToolService | imageToolService specifies the name of the Code Dx Tool Service Docker image | codedxregistry.azurecr.io/codedx/codedx-tool-service:latest | |
| imagePreDelete | imagePreDelete specifies the name of the Code Dx Tool Service pre-delete Docker image | codedxregistry.azurecr.io/codedx/codedx-cleanup:latest | |
| toolServiceReplicas | toolServiceReplicas specifies the number of tool service copies to run concurrently | 3 | |
| useTLS | useTLS specifies whether Code Dx endpoints use TLS | $true | |
| usePSPs | usePSPs specifies whether to create Code Dx pod security policies | $true | |
| skipNetworkPolicies | skipNetworkPolicies specifies whether to skip creating Code Dx network policies | $false | |
| ingressRegistrationEmailAddress | ingressRegistrationEmailAddress specifies the email address for the Let's Encrypt configuration | | |
| ingressLoadBalancerIP | ingressLoadBalancerIP specifies the static IP address for the nginx ingress service | | |
| namespaceToolOrchestration | namespaceToolOrchestration specifies the namespace for the tool orchestration components | cdx-svc | |
| namespaceCodeDx | namespaceCodeDx specifies the namespace for the Code Dx application | cdx-app | |
| namespaceIngressController | namespaceIngressController specifies the namespace for the nginx ingress controller | nginx | |
| releaseNameCodeDx | releaseNameCodeDx specifies the name for the Code Dx Helm release | codedx-app | |
| releaseNameToolOrchestration | releaseNameToolOrchestration specifies the name for the Code Dx Tool Orchestration Helm release | toolsvc-codedx-tool-orchestration | |
| toolServiceApiKey | toolServiceApiKey specifies the API key for the Code Dx Tool Orchestration service | [guid]::newguid() | |
| codedxAdminPwd | codedxAdminPwd specifies the password for the Code Dx admin account | | |
| minioAdminUsername | minioAdminUsername specifies the username for the MinIO admin account | admin | |
| minioAdminPwd | minioAdminPwd specifies the password for the MinIO admin account | | |
| mariadbRootPwd | mariadbRootPwd specifies the password for the MariaDB root account | | |
| mariadbReplicatorPwd | mariadbReplicatorPwd specifies the password for the MariaDB replicator account | | |
| dockerImagePullSecretName | dockerImagePullSecretName specifies the name of the Kubernetes secret to store a Docker image pull secret | | |
| dockerConfigJson | dockerConfigJson specifies the .dockerconfigjson value allowing access to a private Docker registry | | See .dockerconfigjson at https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials |
| codedxRepo | codedxRepo specifies the Code Dx Kubernetes URL | https://codedx.github.io/codedx-kubernetes | |
| kubeApiTargetPort | kubeApiTargetPort specifies the port of the Kubernetes API | 443 | |
| extraCodeDxValuesPaths | extraCodeDxValuesPaths specifies one or more extra values.yaml files for the Code Dx Helm chart | | |
| provisionNetworkPolicy | provisionNetworkPolicy specifies a script block to call for any required network policy provisioning | | |
| provisionIngress | provisionIngress specifies a script block to call for any required ingress controller provisioning | | |