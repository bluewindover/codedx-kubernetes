
# Setup Script

The setup.ps1 PowerShell Core script uses Helm to install and configure Code Dx and Tool Orchestration on a Kubernetes cluster. The setup.ps1 script located here gets called indirectly by the setup.ps1 scripts in the provider-specific folders. See the README files under aws, azure, and minikube for more details.

## Script Parameters

This section describes the setup.ps1 script parameters.

>Note: Refer to the README files under aws, azure, and minikube for instructions on how to configure Code Dx for those environments.

| Parameter                                          | Description                                                | Default or (Example)                              |
|----------------------------------------------------|------------------------------------------------------------|---------------------------------------------------|
| `workDir`                                          | directory to store script-generated files                  | `$HOME/.k8s-codedx`                               |
| `kubeContextName`                                  | kubeconfig context entry to select at start up             | `eks` (example)                                   |
|                                                    |                                                            |                                                   |
| `clusterCertificateAuthorityCertPath`              | cert path for CA issuing certs via certificates.k8s.io API | `./aws-eks.pem` (example)                         |
| `codeDxDnsName`                                    | domain name for the Code Dx web application                | `www.codedx.io` (example)                         |
| `codeDxServicePortNumber`                          | HTTP port number for Code Dx k8s service                   | `9090`                                            |
| `codeDxTlsServicePortNumber`                       | HTTPS port number for Code Dx k8s service                  | `9443`                                            |
| `waitTimeSeconds`                                  | seconds to wait for install commands to complete           | `900`                                             |
|                                                    |                                                            |                                                   |
| `dbVolumeSizeGiB`                                  | volume size of the MariaDB master database                 | `32`                                              |
| `dbSlaveReplicaCount`                              | number of MariaDB slave instances                          | `1`                                               |
| `dbSlaveVolumeSizeGiB`                             | volume size of the MariaDB slave database                  | `32`                                              |
| `minioVolumeSizeGiB`                               | volume size for the MinIO storage application              | `32`                                              |
| `codeDxVolumeSizeGiB`                              | volume size for the Code Dx web application                | `32`                                              |
| `storageClassName`                                 | storage class name for persistance volumes                 | `gp2` (example)                                   |
|                                                    |                                                            |                                                   |
| `codeDxMemoryReservation`                          | memory request and limit for Code Dx                       | `16Gi` (example)                                  |
| `dbMasterMemoryReservation`                        | memory request and limit for the master database           | `16Gi` (example)                                  |
| `dbSlaveMemoryReservation`                         | memory request and limit for slave databases               | `16Gi` (example)                                  |
| `toolServiceMemoryReservation`                     | memory request and limit for the tool service              | `16Gi` (example)                                  |
| `minioMemoryReservation`                           | memory request and limit for MinIO                         | `16Gi` (example)                                  |
| `workflowMemoryReservation`                        | memory request and limit for workflow controller           | `16Gi` (example)                                  |
| `nginxMemoryReservation`                           | memory request and limit for nginx                         |                                                   |
|                                                    |                                                            |                                                   |
| `codeDxCPUReservation`                             | CPU request and limit for Code Dx                          | `2` (example)                                     |
| `dbMasterCPUReservation`                           | CPU request and limit for the master database              | `2` (example)                                     |
| `dbSlaveCPUReservation`                            | CPU request and limit for slave databases                  | `2` (example)                                     |
| `toolServiceCPUReservation`                        | CPU request and limit for the tool service                 | `2` (example)                                     |
| `minioCPUReservation`                              | CPU request and limit for MinIO                            | `2` (example)                                     |
| `workflowCPUReservation`                           | CPU request and limit for workflow controller              | `2` (example)                                     |
| `nginxCPUReservation`                              | CPU request and limit for nginx                            | `2` (example)                                     |
|                                                    |                                                            |                                                   |
| `codeDxEphemeralStorageReservation`                | storage request and limit for Code Dx                      | `2Gi`                                             |
| `dbMasterEphemeralStorageReservation`              | storage request and limit for the master database          | `2Gi` (example)                                   |
| `dbSlaveEphemeralStorageReservation`               | storage request and limit for slave databases              | `2Gi` (example)                                   |
| `toolServiceEphemeralStorageReservation`           | storage request and limit for the tool service             | `2Gi` (example)                                   |
| `minioEphemeralStorageReservation`                 | storage request and limit for MinIO                        | `2Gi` (example)                                   |
| `workflowEphemeralStorageReservation`              | storage request and limit for workflow controller          | `2Gi` (example)                                   |
| `nginxEphemeralStorageReservation`                 | storage request and limit for nginx                        | `2Gi` (example)                                   |
|                                                    |                                                            |                                                   |
| `imageCodeDxTomcat`                                | Code Dx Tomcat Docker image name                           | `latest version`                                  |
| `imageCodeDxTools`                                 | Code Dx Tools Docker image name                            | `latest version`                                  |
| `imageCodeDxToolsMono`                             | Code Dx Tools Mono Docker image name                       | `latest version`                                  |
| `imageNewAnalysis`                                 | Code Dx New Analysis Docker image name                     | `latest version`                                  |
| `imageSendResults`                                 | Code Dx Send Results Docker image name                     | `latest version`                                  |
| `imageSendErrorResults`                            | Code Dx Send Result Errors Docker image name               | `latest version`                                  |
| `imageToolService`                                 | Code Dx Tool Service Docker image name                     | `latest version`                                  |
| `imagePreDelete`                                   | Code Dx Tool Service pre-delete Docker image name          | `latest version`                                  |
|                                                    |                                                            |                                                   |
| `toolServiceReplicas`                              | number of tool service copies to run concurrently          | `3`                                               |
|                                                    |                                                            |                                                   |
| `useTLS`                                           | whether Code Dx endpoints use TLS                          | `$true`                                           |
| `usePSPs`                                          | whether to create pod security policies                    | `$true`                                           |
|                                                    |                                                            |                                                   |
| `skipNetworkPolicies`                              | whether to skip creating network policies                  | `$false`                                          |
|                                                    |                                                            |                                                   |
| `nginxIngressControllerInstall`                    | whether to install the NGINX ingress controller            | `$true`                                           |
| `nginxIngressControllerLoadBalancerIP`             | optional static IP for the NGINX ingress service           | `10.0.0.5` (example)                              |
|                                                    |                                                            |                                                   |
| `letsEncryptCertManagerInstall`                    | whether to install a Let's Encrypt Cert Manager            | `$true`                                           |
| `letsEncryptCertManagerRegistrationEmailAddress`   | email address for Let's Encrypt registration               | `me@codedx.com` (example)                         |
| `letsEncryptCertManagerClusterIssuer`              | cluster issuer (letsencrypt-staging or letsencrypt-prod)   | `letsencrypt-staging`                             |
| `letsEncryptCertManagerNamespace`                  | namespace for Cert Manager components                      | `cert-manager`                                    |
|                                                    |                                                            |                                                   |
| `serviceTypeCodeDx`                                | service type for the Code Dx service                       | `LoadBalancer`    (example)                       |
| `serviceAnnotationsCodeDx`                         | annotations for the Code Dx service                        | `@('key: value')` (example)                       |
|                                                    |                                                            |                                                   |
| `ingressEnabled`                                   | whether to create the Code Dx ingress resource             | `$true`                                           |
| `ingressAssumesNginx`                              | whether the Code Dx ingress has an NGINX annotation        | `$true`                                           |
| `ingressAnnotationsCodeDx`                         | annotations for the Code Dx ingress                        | `@('key: value')` (example)                       |
|                                                    |                                                            |                                                   |
| `namespaceToolOrchestration`                       | namespace for Code Dx Tool Orchestration components        | `cdx-svc`                                         |
| `namespaceCodeDx`                                  | namespace for Code Dx application                          | `cdx-app`                                         |
| `namespaceIngressController`                       | namespace for the NGINX Helm chart installation            | `nginx`                                           |
|                                                    |                                                            |                                                   |
| `releaseNameCodeDx`                                | name for the Code Dx Helm release                          | `codedx`                                          |
| `releaseNameToolOrchestration`                     | name for the Code Dx Tool Orchestration Helm release       | `codedx-tool-orchestration`                       |
|                                                    |                                                            |                                                   |
| `toolServiceApiKey`                                | the API key for the Code Dx Tool Orchestration service     | `[guid]::newguid()`                               |
|                                                    |                                                            |                                                   |
| `codedxAdminPwd`                                   | password for the Code Dx admin account                     | `HEPKmbRC4ANcd!` (example)                        |
| `minioAdminUsername`                               | username for the MinIO admin account                       | `admin`                                           |
| `minioAdminPwd`                                    | password for the MinIO admin account                       | `JGpS2t8UXj80o!` (example)                        |
| `mariadbRootPwd`                                   | password for the MariaDB root account                      | `ZjQLEg07BMNEf!` (example)                        |
| `mariadbReplicatorPwd`                             | password for the MariaDB replicator account                | `760nP8i6ZFzVS!` (example)                        |
|                                                    |                                                            |                                                   |
| `caCertsFilePwd`                                   | current password for the Code Dx cacerts file              | `changeit`                                        |
| `caCertsFileNewPwd`                                | new password to protect the Code Dx cacerts file           | `jcqBYa68G1usO!` (example)                        |
|                                                    |                                                            |                                                   |
| `extraCodeDxChartFilesPaths`                       | files to copy to the Code Dx chart folder at install time  | `@('/cacerts')`  (example)                        |
| `extraCodeDxTrustedCaCertPaths`                    | trusted cert files to add to the Code Dx cacerts file      | `@('/cert.pem')` (example)                        |
|                                                    |                                                            |                                                   |
| `dockerImagePullSecretName`                        | k8s image pull secret name for a private Docker registry   | `my-registry`    (example)                        |
| `dockerRegistry`                                   | server name of private Docker registry                     | `myregistry.io`  (example)                        |
| `dockerRegistryUser`                               | username for private Docker registry                       | `myregistryuser` (example)                        |
| `dockerRegistryPwd`                                | password for private Docker registry username              | `R4dLYCfuda9ej!` (example)                        |
|                                                    |                                                            |                                                   |
| `codedxHelmRepo`                                   | Code Dx Helm repository                                    | `https://codedx.github.io/codedx-kubernetes`      |
|                                                    |                                                            |                                                   |
| `codedxGitRepo`                                    | Code Dx Kubernetes git repository                          | `https://github.com/codedx/codedx-kubernetes.git` |
| `codedxGitRepoBranch`                              | Code Dx Kubernetes git repository branch                   | `master`                                          |
|                                                    |                                                            |                                                   |
| `kubeApiTargetPort`                                | port number of the Kubernetes API                          | `443`                                             |
|                                                    |                                                            |                                                   |
| `extraCodeDxValuesPaths`                           | extra values.yaml file(s) for the Code Dx Helm chart       | `@('/file.yaml')` (example)                       |
| `extraToolOrchestrationValuesPaths`                | extra values.yaml file(s) for Tool Orchestration chart     | `@('/file.yaml')` (example)                       |
|                                                    |                                                            |                                                   |
| `externalDatabaseUrl`                              | connection string for an external database                 | `jdbc:mysql://mariadb/codedx` (example)           |
| `externalDatabaseUser`                             | existing username of external database user                | `codedx` (example)                                |
| `externalDatabasePwd`                              | password for external database user                        | `5Ed3&#Rutcdw` (example)                          |
|                                                    |                                                            |                                                   |
| `skipDatabase`                                     | whether to skip installing MariaDB (use external database) | `$false`                                          |
| `skipToolOrchestration`                            | whether to skip installing the Tool Orchestration feature  | `$false`                                          |
|                                                    |                                                            |                                                   |
| `provisionNetworkPolicy`                           | script block for optional network policy provisioning      |                                                   |
| `provisionIngressController`                       | script block for optional ingress controller provisioning  |                                                   |