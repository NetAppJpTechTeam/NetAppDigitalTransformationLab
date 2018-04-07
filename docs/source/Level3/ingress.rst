
.. ngress用にネームスペースを準備します。 ::

..  $ kubectl create namespace ingress



.. 以下、ingress 作成時のコマンド::
..
..     localadmin@master:~$ kubectl get nodes
..     NAME      STATUS    ROLES     AGE       VERSION
..     master    Ready     master    13d       v1.9.4
..     node0     Ready     <none>    13d       v1.9.4
..     node1     Ready     <none>    13d       v1.9.4
..     localadmin@master:~$ kubectl label node "role=router" -l "kubernetes.io/hostname=node0"
..     node "node0" labeled
..     localadmin@master:~$ kubectl get nodes
..     NAME      STATUS    ROLES     AGE       VERSION
..     master    Ready     master    13d       v1.9.4
..     node0     Ready     <none>    13d       v1.9.4
..     node1     Ready     <none>    13d       v1.9.4
..     localadmin@master:~$ kubectl get label
..     the server doesn't have a resource type "label"
..     localadmin@master:~$ kubectl get labels
..     the server doesn't have a resource type "labels"
..     localadmin@master:~$ kubectl get label node
..     the server doesn't have a resource type "label"
..     localadmin@master:~$
..       namespace: ingress
..     localadmin@master:~$ ls
..     dockerfile  helm
..     localadmin@master:~$ ls
..     dockerfile  helm
..     localadmin@master:~$ mkdir ingress
..     localadmin@master:~$ cd ingress/
..     localadmin@master:~/ingress$ ls
..     localadmin@master:~/ingress$ touch default_http_backend.yaml
..     localadmin@master:~/ingress$ vim default_http_backend.yaml
..     localadmin@master:~/ingress$
..       namespace: ingress
..     localadmin@master:~/ingress$ ls
..     default_http_backend.yaml
..     localadmin@master:~/ingress$ less default_http_backend.yaml
..     localadmin@master:~/ingress$ kubectl create -f default_http_backend.yaml
..     Error from server (NotFound): error when creating "default_http_backend.yaml": namespaces "ingress" not found
..     Error from server (NotFound): error when creating "default_http_backend.yaml": namespaces "ingress" not found
..     localadmin@master:~/ingress$ kubectl create ns ingress
..     namespace "ingress" created
..     localadmin@master:~/ingress$ kubectl create -f default_http_backend.yaml
..     deployment "default-http-backend" created
..     service "default-http-backend" created
..     localadmin@master:~/ingress$ touch nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ vim nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ kubectl create -f nginx-ingress-controller.yaml
..     daemonset "nginx-ingress-controller-v1" created
..     localadmin@master:~/ingress$ kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.4 --replicas=1 --port=8080
..     Error from server (NotFound): namespaces "jx" not found
..     localadmin@master:~/ingress$ kubectl get namespace
..     NAME          STATUS    AGE
..     default       Active    13d
..     ingress       Active    1m
..     jenkins       Active    13d
..     kube-public   Active    13d
..     kube-system   Active    13d
..     localadmin@master:~/ingress$ kubectl set namespace
..     default_http_backend.yaml      nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ kubectl set namespace
..     default_http_backend.yaml      nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ kubectl set namespace --help
..     Configure application resources
..
..     These commands help you make changes to existing application resources.
..
..     Available Commands:
..       env            Update environment variables on a pod template
..       image          Update image of a pod template
..       resources      Update resource requests/limits on objects with pod templates
..       selector       Set the selector on a resource
..       serviceaccount Update ServiceAccount of a resource
..       subject        Update User, Group or ServiceAccount in a RoleBinding/ClusterRoleBinding
..
..     Usage:
..       kubectl set SUBCOMMAND [options]
..
..     Use "kubectl <command> --help" for more information about a given command.
..     Use "kubectl options" for a list of global command-line options (applies to all commands).
..     localadmin@master:~/ingress$ kubectl config view
..     apiVersion: v1
..     clusters:
..     - cluster:
..         certificate-authority-data: REDACTED
..         server: https://192.168.10.10:6443
..       name: kubernetes
..     contexts:
..     - context:
..         cluster: kubernetes
..         namespace: jx
..         user: kubernetes-admin
..       name: kubernetes-admin@kubernetes
..     current-context: kubernetes-admin@kubernetes
..     kind: Config
..     preferences: {}
..     users:
..     - name: kubernetes-admin
..       user:
..         client-certificate-data: REDACTED
..         client-key-data: REDACTED
..     localadmin@master:~/ingress$ kubectl config current-context
..     kubernetes-admin@kubernetes
..     localadmin@master:~/ingress$ kubectl set-context > kubectl config set-context $(kubectl config current-context) --namespace=chiroito
..     Error: unknown command "set-context" for "kubectl"
..     Run 'kubectl --help' for usage.
..     error: unknown command "set-context" for "kubectl"
..     localadmin@master:~/ingress$ kubectl set-context > kubectl config set-context $(kubectl config current-context) --namespace=default
..     Error: unknown command "set-context" for "kubectl"
..     Run 'kubectl --help' for usage.
..     error: unknown command "set-context" for "kubectl"
..     localadmin@master:~/ingress$ kubectl config set-context $(kubectl config current-context) --namespace=default
..     error: open /home/localadmin/.kube/config.lock: permission denied
..     localadmin@master:~/ingress$ sudo kubectl config set-context $(kubectl config current-context) --namespace=default
..     Context "kubernetes-admin@kubernetes" modified.
..     localadmin@master:~/ingress$
..     apiVersion: extensions/v1beta1
..     localadmin@master:~/ingress$ ls
..     default_http_backend.yaml  kubectl  nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ cat kubectl
..     localadmin@master:~/ingress$ rm kubectl
..     localadmin@master:~/ingress$ ls
..     default_http_backend.yaml  nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ kubectl create -f nginx-ingress-controller.yaml
..     Error from server (AlreadyExists): error when creating "nginx-ingress-controller.yaml": daemonsets.extensions "nginx-ingress-controller-v1" already exists
..     localadmin@master:~/ingress$ kubectl run echoheaders --image=gcr.io/google_containers/echoserver:1.4 --replicas=1 --port=8080
..     deployment "echoheaders" created
..     localadmin@master:~/ingress$ kubectl expose deployment echoheaders --port=80 --target-port=8080 --name=echoheaders
..     service "echoheaders" exposed
..     localadmin@master:~/ingress$ touch ingress.yaml
..     localadmin@master:~/ingress$ vim ingress.yaml
..     localadmin@master:~/ingress$ kubectl create -f ingress.yaml
..     The Ingress "echomap" is invalid: spec.rules[0].host: Invalid value: "192.168.10.10": must be a DNS name, not an IP address
..     localadmin@master:~/ingress$ hostname
..     master
..     localadmin@master:~/ingress$
..     apiVersion: extensions/v1beta1
..     localadmin@master:~/ingress$ ls
..     default_http_backend.yaml  ingress.yaml  nginx-ingress-controller.yaml
..     localadmin@master:~/ingress$ vi ingress.yaml
..     localadmin@master:~/ingress$ kubectl create -f ingress.yaml
..     ingress "echomap" created
..     localadmin@master:~/ingress$ kubectl get pods
..     NAME                           READY     STATUS    RESTARTS   AGE
..     echoheaders-6bcb685b8f-kzt88   1/1       Running   0          2m
..     localadmin@master:~/ingress$ kubectl get svc
..     NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
..     echoheaders   ClusterIP   10.108.26.99   <none>        80/TCP    2m
..     kubernetes    ClusterIP   10.96.0.1      <none>        443/TCP   13d
..     localadmin@master:~/ingress$ kubectl get ing
..     NAME      HOSTS            ADDRESS   PORTS     AGE
..     echomap   k8s.netapp.com             80        22s
..     localadmin@master:~/ingress$ kubectl get ing -n ingress
..     No resources found.
..     localadmin@master:~/ingress$ kubectl get service -n ingress
..     NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
..     default-http-backend   ClusterIP   10.97.213.115   <none>        80/TCP    7m
..     localadmin@master:~/ingress$
..     localadmin@master:~/ingress$ ls
..     default_http_backend.yaml  ingress.yaml  nginx-ingress-controller.yaml
..
..

helm chartを使ったNginx Ingressのデプロイメントです。::

    localadmin@master:~/helm/jenkins$ helm install --namespace kube-system --name nginx-ingress stable/nginx-ingress --set rbac.create=true
    NAME:   nginx-ingress
    LAST DEPLOYED: Thu Apr  5 20:51:16 2018
    NAMESPACE: kube-system
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1/ConfigMap
    NAME                      DATA  AGE
    nginx-ingress-controller  1     0s

    ==> v1/ServiceAccount
    NAME           SECRETS  AGE
    nginx-ingress  1        0s

    ==> v1beta1/ClusterRoleBinding
    NAME           AGE
    nginx-ingress  0s

    ==> v1beta1/Role
    NAME           AGE
    nginx-ingress  0s

    ==> v1beta1/PodDisruptionBudget
    NAME                           MIN AVAILABLE  MAX UNAVAILABLE  ALLOWED DISRUPTIONS  AGE
    nginx-ingress-controller       1              N/A              0                    0s
    nginx-ingress-default-backend  1              N/A              0                    0s

    ==> v1/Pod(related)
    NAME                                            READY  STATUS             RESTARTS  AGE
    nginx-ingress-controller-76b594fc47-2hdrv       0/1    ContainerCreating  0         0s
    nginx-ingress-default-backend-6664bc64c9-qpz95  0/1    ContainerCreating  0         0s

    ==> v1beta1/ClusterRole
    NAME           AGE
    nginx-ingress  0s

    ==> v1beta1/RoleBinding
    NAME           AGE
    nginx-ingress  0s

    ==> v1/Service
    NAME                           TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                     AGE
    nginx-ingress-controller       LoadBalancer  10.103.250.231  <pending>    80:31464/TCP,443:30998/TCP  0s
    nginx-ingress-default-backend  ClusterIP     10.99.3.184     <none>       80/TCP                      0s

    ==> v1beta1/Deployment
    NAME                           DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
    nginx-ingress-controller       1        1        1           0          0s
    nginx-ingress-default-backend  1        1        1           0          0s


    NOTES:
    The nginx-ingress controller has been installed.
    It may take a few minutes for the LoadBalancer IP to be available.
    You can watch the status by running 'kubectl --namespace kube-system get services -o wide -w nginx-ingress-controller'

    An example Ingress that makes use of the controller:

      apiVersion: extensions/v1beta1
      kind: Ingress
      metadata:
        annotations:
          kubernetes.io/ingress.class: nginx
        name: example
        namespace: foo
      spec:
        rules:
          - host: www.example.com
            http:
              paths:
                - backend:
                    serviceName: exampleService
                    servicePort: 80
                  path: /
        # This section is only required if TLS is to be enabled for the Ingress
        tls:
            - hosts:
                - www.example.com
              secretName: example-tls

    If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

      apiVersion: v1
      kind: Secret
      metadata:
        name: example-tls
        namespace: foo
      data:
        tls.crt: <base64 encoded cert>
        tls.key: <base64 encoded key>
      type: kubernetes.io/tls