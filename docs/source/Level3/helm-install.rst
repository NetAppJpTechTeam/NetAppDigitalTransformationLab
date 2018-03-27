

基本的なhelmの使い方は以下の通りです。 ::

    $ helm install --name jenkins --namespace jenkins stable/jenkins
    NAME:   jenkins
    LAST DEPLOYED: Mon Mar 26 19:57:25 2018
    NAMESPACE: jenkins
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1/PersistentVolumeClaim
    NAME     STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
    jenkins  Pending  0s

    ==> v1/Service
    NAME           TYPE          CLUSTER-IP     EXTERNAL-IP  PORT(S)         AGE
    jenkins-agent  ClusterIP     10.100.198.44  <none>       50000/TCP       0s
    jenkins        LoadBalancer  10.101.141.43  <pending>    8080:31340/TCP  0s

    ==> v1beta1/Deployment
    NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
    jenkins  1        1        1           0          0s

    ==> v1/Pod(related)
    NAME                      READY  STATUS    RESTARTS  AGE
    jenkins-6cd96444b5-z9ctq  0/1    Init:0/1  0         0s

    ==> v1/Secret
    NAME     TYPE    DATA  AGE
    jenkins  Opaque  2     0s

    ==> v1/ConfigMap
    NAME           DATA  AGE
    jenkins        3     0s
    jenkins-tests  1     0s


    NOTES:
    1. Get your 'admin' user password by running:
      printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
    2. Get the Jenkins URL to visit by running these commands in the same shell:
      NOTE: It may take a few minutes for the LoadBalancer IP to be available.
            You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
      export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
      echo http://$SERVICE_IP:8080/login

    3. Login with the password from step 1 and the username: admin

    For more information on running Jenkins on Kubernetes, visit:
    https://cloud.google.com/solutions/jenkins-on-container-engine

「NOTES」欄にきさい　のある通りadminパスワードを取得します。::

    $ printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

JenkinsへのアクセスURLを取得します。 ::

    $ export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
    $ echo http://$SERVICE_IP:8080/login


.. tips::

    Helmは以下のURLに様々なものが公開されています。パラメータを与えることである程度カスタマイズし使用するうことができます。
    Helm chartの
