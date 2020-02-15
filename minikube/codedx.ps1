. (join-path $PSScriptRoot minikube.ps1)

function New-CodeDxDeployment([string] $codeDxDnsName,
    [string]   $workDir, 
	[int]      $waitSeconds,
	[string]   $namespace,
	[string]   $releaseName,
	[string]   $adminPwd,
	[string]   $tomcatImage,
	[string]   $tomcatImagePullSecretName,
	[string]   $dockerConfigJson,
	[string]   $mariadbRootPwd,
	[string]   $mariadbReplicatorPwd,
	[int]      $dbVolumeSizeGiB,
	[int]      $dbSlaveReplicaCount,
	[int]      $dbSlaveVolumeSizeGiB,
	[int]      $codeDxVolumeSizeGiB,	
	[string[]] $extraValuesPaths,
	[switch]   $enablePSPs,
	[switch]   $enableNetworkPolicies,
	[switch]   $configureTls,
	[switch]   $configureIngress) {
 
	if (-not (Test-Namespace $namespace)) {
		New-Namespace  $namespace
	}
	Set-NamespaceLabel $namespace 'name' $namespace

	$imagePullSecretYaml = 'codedxTomcatImagePullSecrets: []'
	if (-not ([string]::IsNullOrWhiteSpace($tomcatImagePullSecretName))) {

		$imagePullSecretYaml = @'
codedxTomcatImagePullSecrets:
- name: {0}
'@ -f $tomcatImagePullSecretName

		New-ImagePullSecret $namespace $tomcatImagePullSecretName $dockerConfigJson
	}

	$psp = 'false'
	if ($enablePSPs) {
		$psp = 'true'
	}
	$networkPolicy = 'false'
	if ($enableNetworkPolicies) {
		$networkPolicy = 'true'
	}

	$tlsEnabled = 'false'
	$tlsSecretName = 'cdx-codedx-app-codedx-tls'
	$tlsCertFile = 'codedx-app-codedx.pem'
	$tlsKeyFile = 'codedx-app-codedx.key'
	if ($configureTls) {
		$tlsEnabled = 'true'

		New-Certificate 'codedx-app-codedx' 'codedx-app-codedx' 'cdx-app' @($codeDxDnsName)
		New-CertificateSecret 'cdx-app' $tlsSecretName $tlsCertFile $tlsKeyFile
	}

	$ingress = 'false'
	if ($configureIngress) {
		$ingress = 'true'
	}

	$values = @'
codedxAdminPassword: '{0}'
persistence:
  size: {12}Gi
codedxTls:
  enabled: {5}
  secret: {6}
  certFile: {7}
  keyFile: {8}
ingress:
  enabled: {14}
  annotations:
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    kubernetes.io/tls-acme: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
  hosts:
  - name: {13}
    tls: true
    tlsSecret: ingress-tls-secret
podSecurityPolicy:
  codedx:
    create: {3}
  mariadb:
    create: {3}
networkPolicy:
  codedx:
    create: {4}
  mariadb:
    master:
      create: {4}
    slave:
      create: {4}
codedxTomcatImage: {1}
{2}
mariadb:
  rootUser:
    password: '{9}'
  replication:
    password: '{10}'
  master:
    persistence:
      size: {11}Gi
  slave:
    replicas: {16}
    persistence:
      size: {15}Gi

'@ -f $adminPwd, $tomcatImage, $imagePullSecretYaml, `
$psp, $networkPolicy, `
$tlsEnabled, $tlsSecretName, $tlsCertFile, $tlsKeyFile, `
$mariadbRootPwd, $mariadbReplicatorPwd, `
$dbVolumeSizeGiB, $codeDxVolumeSizeGiB, $codeDxDnsName, $ingress, `
$dbSlaveVolumeSizeGiB, $dbSlaveReplicaCount

	$valuesFile = 'codedx-values.yaml'
	$values | out-file $valuesFile -Encoding ascii -Force

	$chartFolder = (join-path $workDir codedx-kubernetes/codedx)
	Invoke-HelmSingleDeployment 'Code Dx' $waitSeconds $namespace $releaseName $chartFolder $valuesFile 'codedx-app-codedx' 1 $extraValuesPaths
}

function New-ToolOrchestrationDeployment([string] $workDir, 
	[int]    $waitSeconds,
	[string] $namespace,
	[string] $codedxNamespace,
	[string] $codedxReleaseName,
	[int]    $numReplicas,
	[string] $minioUsername,
	[string] $minioPwd,
	[string] $apiKey,
	[string] $toolsImage,
	[string] $toolsMonoImage,
	[string] $newAnalysisImage,
	[string] $sendResultsImage,
	[string] $sendErrorResultsImage,
	[string] $toolServiceImage,
	[string] $imagePullSecretName,
	[string] $dockerConfigJson,
	[int]    $minioVolumeSizeGiB,
	[switch] $enablePSPs,
	[switch] $enableNetworkPolicies,
	[switch] $configureTls) {

	if (-not (Test-Namespace $namespace)) {
		New-Namespace  $namespace
	}
	Set-NamespaceLabel $namespace 'name' $namespace

	$protocol = 'http'
	$codedxPort = '9090'
	$tlsConfig = 'false'
	$tlsMinioCertSecret = ''
	$tlsToolServiceCertSecret = ''
	$codedxCaConfigMap = ''

	if ($configureTls) {
		$protocol = 'https'
		$codedxPort = '9443'
		$tlsConfig = 'true'
		$tlsMinioCertSecret = 'cdx-toolsvc-minio-tls'
		$tlsToolServiceCertSecret = 'cdx-toolsvc-codedx-tool-orchestration-tls'
		$codedxCaConfigMap = 'cdx-codedx-ca-cert'

		New-Certificate 'toolsvc-codedx-tool-orchestration' 'toolsvc-codedx-tool-orchestration' $namespace @()
		New-Certificate 'toolsvc-minio' 'toolsvc-minio' $namespace @()

		New-CertificateSecret $namespace $tlsMinioCertSecret 'toolsvc-minio.pem' 'toolsvc-minio.key'
		New-CertificateConfigMap $namespace 'cdx-toolsvc-minio-cert' 'toolsvc-minio.pem'
		New-CertificateSecret $namespace $tlsToolServiceCertSecret 'toolsvc-codedx-tool-orchestration.pem' 'toolsvc-codedx-tool-orchestration.key'

		New-CertificateConfigMap $namespace $codedxCaConfigMap (Get-MinikubeCaCertPath)
	}
	$codedxBaseUrl = '{0}://{1}-codedx.{2}:{3}/codedx' -f $protocol,$codedxReleaseName,$codedxNamespace,$codedxPort

	$imagePullSecretYaml = 'toolServiceImagePullSecrets: []'
	if (-not ([string]::IsNullOrWhiteSpace($imagePullSecretName))) {

		$imagePullSecretYaml = @'
toolServiceImagePullSecrets:
- name: {0}
'@ -f $imagePullSecretName

		New-ImagePullSecret $namespace $imagePullSecretName $dockerConfigJson
	}

	$psp = 'false'
	if ($enablePSPs) {
		$psp = 'true'
	}
	$networkPolicy = 'false'
	if ($enableNetworkPolicies) {
		$networkPolicy = 'true'
	}

	$values = @'
argo:
  installCRD: false

minio:
  global:
    minio:
      accessKeyGlobal: '{0}'
      secretKeyGlobal: '{1}'
    tls:
      enabled: {13}
      certSecret: {14}
      publicCrt: 'toolsvc-minio.pem'
      privateKey: 'toolsvc-minio.key'
  persistence:
    size: {21}Gi

minioTlsTrust:
  configMapName: 'cdx-toolsvc-minio-cert'
  configMapPublicCertKeyName: 'toolsvc-minio.pem'

podSecurityPolicy:
  tws:
    create: {16}
  twsWorkflows:	
    create: {16}
  argo:
    create: {16}
  minio:
    create: {16}

numReplicas: {12}

networkPolicy:
  toolServiceEnabled: {17}
  twsWorkflowsEnabled: {17}
  argoEnabled: {17}
  minioEnabled: {17}      
  kubeApiTargetPort: 8443
  codedxSelectors:
  - namespaceSelector:
      matchLabels:
        name: '{2}'
  
codedxBaseUrl: '{18}'
codedxTls:
  enabled: {19}
  caConfigMap: {20}
  
toolServiceApiKey: '{4}'
toolServiceTls:
  secret: {15}
  certFile: 'toolsvc-codedx-tool-orchestration.pem'
  keyFile: 'toolsvc-codedx-tool-orchestration.key'
  
imagePullSecretKey: '{5}'
imageNameCodeDxTools: '{6}'
imageNameCodeDxToolsMono: '{7}' 
imageNameNewAnalysis: '{8}' 
imageNameSendResults: '{9}' 
imageNameSendErrorResults: '{10}' 
toolServiceImageName: '{11}' 
{22}
'@ -f $minioUsername,`
$minioPwd,$codedxNamespace,$codedxReleaseName,$apiKey,`
$imagePullSecretName,$toolsImage,$toolsMonoImage,$newAnalysisImage,$sendResultsImage,$sendErrorResultsImage,$toolServiceImage,$numReplicas,
$tlsConfig,$tlsMinioCertSecret,$tlsToolServiceCertSecret,
$psp,$networkPolicy,$codedxBaseUrl,`
$tlsConfig,$codedxCaConfigMap,$minioVolumeSizeGiB,$imagePullSecretYaml

	$valuesFile = 'toolsvc-values.yaml'
	$values | out-file $valuesFile -Encoding ascii -Force

	$chartFolder = (join-path $workDir codedx-kubernetes/codedx-tool-orchestration)
	Invoke-HelmSingleDeployment 'Tool Orchestration' $waitSeconds $namespace 'toolsvc' $chartFolder $valuesFile 'toolsvc-codedx-tool-orchestration' $numReplicas @()
}

function Set-UseToolOrchestration([string] $workDir, 
	[string] $waitSeconds,
	[string] $namespace, [string] $codedxNamespace,
	[string] $toolServiceUrl, [string] $toolServiceApiKey,
	[string] $codedxReleaseName,
	[switch] $enableNetworkPolicies,
	[switch] $configureTls) {

	# access cacerts file
	$podName = kubectl -n $codedxNamespace get pod -l app=codedx --field-selector=status.phase=Running -o name
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to get for name of Code Dx pod, kubectl exited with code $LASTEXITCODE."
	}

	$podFile = "$($podName.Replace('pod/', ''))`:/etc/ssl/certs/java/cacerts"
	kubectl -n $codedxNamespace cp $podFile './cacerts'
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to copy out cacerts file, kubectl exited with code $LASTEXITCODE."
	}

	# update cacerts file
	keytool -import -trustcacerts -keystore cacerts -file (Get-MinikubeCaCertPath) -noprompt -storepass changeit
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to import CA certificate into cacerts file, keytool exited with code $LASTEXITCODE."
	}

	$chartFolder = (join-path $workDir codedx-kubernetes/codedx)
	copy-item cacerts $chartFolder -Force

	$networkPolicy = 'false'
	if ($enableNetworkPolicies) {
		$networkPolicy = 'true'
	}

	$cacertsFile = ''
	if ($configureTls) {
		$cacertsFile = 'cacerts'
	}

	$values = @'
codedxProps:
  extra:
  - type: values
    key: cdx-tool-orchestration
    values:
    - "tws.enabled = true"
    - "tws.service-url = {0}"
    - "tws.api-key = {1}"

networkPolicy:
  codedx:
    toolService: {3}
    toolServiceSelectors:
    - namespaceSelector:
        matchLabels:
          name: {2}

cacertsFile: {4}
'@ -f $toolServiceUrl, $toolServiceApiKey, $namespace, $networkPolicy, $cacertsFile

	$valuesFile = 'codedx-orchestration-values.yaml'
	$values | out-file $valuesFile -Encoding ascii -Force

	helm -n $codedxNamespace upgrade --values $valuesFile --reuse-values $codedxReleaseName $chartFolder
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to upgrade Code Dx release for tool orchestration, helm exited with code $LASTEXITCODE."
	}

	Wait-Deployment 'Helm Upgrade' $waitSeconds $codedxNamespace "$codedxReleaseName-codedx" 1
}

function Add-CertManager([string] $namespace, [string] $registrationEmailAddress, [string] $stagingIssuerFile, [string] $productionIssuerFile, [string] $waitSeconds) {

	kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.13.0/deploy/manifests/00-crds.yaml
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to add cert-manager CRDs, helm exited with code $LASTEXITCODE."
	}

	if (-not (Test-Namespace $namespace)) {
		New-Namespace  $namespace
	}

	helm repo add jetstack https://charts.jetstack.io
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to add jetstack repo, helm exited with code $LASTEXITCODE."
	}

	helm repo update
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to run helm repo update, helm exited with code $LASTEXITCODE."
	}

	helm install cert-manager --namespace $namespace jetstack/cert-manager --version v0.13.0
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to install cert-manager, helm exited with code $LASTEXITCODE."
	}

	Wait-Deployment 'Add cert-manager' $waitSeconds $namespace 'cert-manager' 1
	Wait-Deployment 'Add cert-manager (cert-manager-cainjector)' $waitSeconds $namespace 'cert-manager-cainjector' 1
	Wait-Deployment 'Add cert-manager (cert-manager-webhook)' $waitSeconds $namespace 'cert-manager-webhook' 1

	$issuerTemplate = @'
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-{1}
spec:
  acme:
    server: {2}
    email: {0}
    privateKeySecretRef:
      name: letsencrypt-{1}
    solvers:
    - http01:
        ingress:
          class: nginx
'@

	$issuerTemplate -f $registrationEmailAddress,'staging','https://acme-staging-v02.api.letsencrypt.org/directory' | out-file $stagingIssuerFile -Encoding ascii -Force
	kubectl -n $namespace create -f $stagingIssuerFile
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create staging ClusterIssuer. kubectl exited with code $LASTEXITCODE."
	}

	$issuerTemplate -f $registrationEmailAddress,'prod','https://acme-v02.api.letsencrypt.org/directory' | out-file $productionIssuerFile -Encoding ascii -Force
	kubectl -n $namespace create -f $productionIssuerFile
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create production ClusterIssuer. kubectl exited with code $LASTEXITCODE."
	}

	$certManagerFile = 'cert-manager-rbac.yaml'
	@'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cert-manager-psp-role
rules:
- apiGroups:
  - extensions
  resourceNames:
  - privileged
  resources:
  - podsecuritypolicies
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cert-manager-psp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cert-manager-psp-role
subjects:
- kind: ServiceAccount
  name: cert-manager
  namespace: cert-manager
- kind: ServiceAccount
  name: cert-manager-cainjector
  namespace: cert-manager
- kind: ServiceAccount
  name: cert-manager-webhook
  namespace: cert-manager
'@ | out-file $certManagerFile -Encoding ascii -Force

	kubectl -n $namespace create -f $certManagerFile
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create cert-manager RBAC resources. kubectl exited with code $LASTEXITCODE."
	}
}
