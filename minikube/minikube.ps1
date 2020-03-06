. (join-path $PSScriptRoot k8s.ps1)

function Test-MinikubeProfile([string] $profileName, [string] $vmDriver, [string] $k8sVersion) {

	$profileList = minikube profile list
	$result = $profileList | select-string ('\s{0}\s+\|\s+{1}\s+.+\s+{2}\s+\|' -f [regex]::escape($profileName),[regex]::escape($vmDriver),[regex]::escape($k8sVersion))
	$null -ne $result
}

function Test-MinikubeStatus([string] $profileName) {

	minikube -p $profileName status | out-null
	0 -eq $LASTEXITCODE
}

function New-MinikubeCluster([string] $profileName, [string] $k8sVersion, [string] $vmDriver, [int] $cpus, [string] $memory, [string] $diskSize, [string[]] $extraConfig) {

	Write-Verbose "Creating new minikube instance ($profileName) with the following parameters:`n  driver=$vmDriver`n  k8s=$k8sversion`n  cpus=$cpus`n  memory=$memory`n  disk=$diskSize"
	minikube start --vm-driver=$vmDriver -p $profileName --kubernetes-version $k8sVersion --cpus $cpus --memory $memory --disk-size $diskSize @($extraConfig)
	
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create k8s cluster. Minikube exited with code $LASTEXITCODE."
	}
}

function Add-CalicoNetworkPolicyProvider([string] $waitSeconds) {

	kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to add Calico. kubectl exited with code $LASTEXITCODE."
	}

	Wait-AllRunningPods 'Add Network Policy' $waitSeconds
}

function Add-IngressAddon([string] $profileName, [int] $waitSeconds) {

	minikube -p $profileName addons enable ingress
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to add ingress addon. Minikube exited with code $LASTEXITCODE."
	}

	Wait-Deployment 'Ingress Addon' $waitSeconds 'kube-system' 'nginx-ingress-controller' 1
}

function Add-DefaultPodSecurityPolicy([string] $pspFile, [string] $roleFile, [string] $roleBindingFile) {

	$psp = @'
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
spec:
  privileged: true
  allowPrivilegeEscalation: true
  allowedCapabilities:
  - '*'
  volumes:
  - '*'
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  hostIPC: true
  hostPID: true
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
'@

	$psp | out-file $pspFile -Encoding ascii -Force
	kubectl create -f $pspFile
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create PodSecurityPolicy. kubectl exited with code $LASTEXITCODE."
	}

	$role = @'
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp:privileged
rules:
- apiGroups: ['policy']
  resources: ['podsecuritypolicies']
  verbs:     ['use']
  resourceNames:
  - privileged
'@

	$role | out-file $roleFile -Encoding ascii -Force
	kubectl create -f $roleFile
    	if ($LASTEXITCODE -ne 0) {
    		throw "Unable to create PodSecurityPolicy ClusterRole. kubectl exited with code $LASTEXITCODE."
    	}

	$roleBinding = @'
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp:privileged-rolebinding
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: psp:privileged
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: Group
  apiGroup: rbac.authorization.k8s.io
  name: system:serviceaccounts
- kind: Group
  apiGroup: rbac.authorization.k8s.io
  name: system:nodes
'@

	$roleBinding | out-file $roleBindingFile -Encoding ascii -Force
	kubectl create -f $roleBindingFile
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to create default PodSecurityPolicy RoleBinding. kubectl exited with code $LASTEXITCODE."
	}
}

function Start-MinikubeCluster([string] $profileName, [string] $k8sVersion, [string] $vmDriver, [int] $waitSeconds, [switch] $usePsp, [switch] $useNetworkPolicy, [string[]] $extraConfig) {

	$pspConfig = ''
	if ($usePsp) {
		$pspConfig = '--extra-config=apiserver.enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota,PodSecurityPolicy'
	}

	$cniConfig = ''
	if ($useNetworkPolicy) {
		$cniConfig = '--network-plugin=cni'
	}

	minikube start -p $profileName --kubernetes-version $k8sVersion --vm-driver $vmDriver $cniConfig $pspConfig @($extraConfig)

	if ($LASTEXITCODE -ne 0) {
		throw "Unable to start minikube cluster, minikube exited with code $LASTEXITCODE."
	}

	Wait-MinikubeNodeReady 'Start Minikube Cluster' $waitSeconds
}

function Wait-MinikubeNodeReady([string] $message, [int] $waitSeconds) {

	$sleepSeconds = [math]::min(60, ($waitSeconds * .05))
	$timeoutTime = [datetime]::Now.AddSeconds($waitSeconds)
	while ($true) {

		Write-Verbose "Waiting for ready node ($message)..."
		$results = kubectl get node
		if ($null -ne ($results | select-string 'minikube\s+Ready')) {
			Write-Verbose "Node is ready ($message)"
			break
		}

		if ([datetime]::now -gt $timeoutTime) {
			throw "Unable to continue because a timeout occurred while waiting for the minikube node to be in a Ready state ($message)"
		}
		Write-Verbose "The node is not ready. Another check will occur in $sleepSeconds seconds ($message)."
		start-sleep -seconds $sleepSeconds
	}
}

function New-Certificate([string] $resourceName, [string] $dnsName, [string] $namespace, [string[]] $alternativeNames){

	$altNames = @()
	$altNames = $altNames + "$dnsName.$namespace" + "$dnsName.$namespace.svc.cluster.local" + $alternativeNames

	New-Csr $dnsName `
		$altNames `
		"$dnsName.conf" `
		"$dnsName.csr" `
		"$dnsName.key"

	New-CsrResource $resourceName "$dnsName.csr" "$dnsName.csrr"
	New-CsrApproval $resourceName

	$certText = Get-Certificate $resourceName
	$caCertText = Get-MinikubeCaCert
	"$certText`n$caCertText" | out-file "$resourceName.pem" -Encoding ascii -Force
}

function Get-MinikubeCaCertPath {
	join-path $HOME '.minikube/ca.crt'
}

function Get-MinikubeCaCert {

	$caCertFile = Get-MinikubeCaCertPath
	[io.file]::ReadAllText($caCertFile)
}

function Stop-MinikubeCluster([string] $profileName) {

	minikube stop -p $profileName
	if ($LASTEXITCODE -ne 0) {
		throw "Unable to stop minikube cluster. Minikube exited with code $LASTEXITCODE."
	}
}