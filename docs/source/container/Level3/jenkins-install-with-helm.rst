Helmの初期化
-----------------------------------------

Helmを使用する事前の設定をします。
Helmの初期化、RBACの設定を実施します。

.. code-block:: console

    $ helm init
    $ kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

Helmの基本
-----------------------------------------

基本的なHelmの使い方は以下の通りです。

.. code-block:: console

    $ helm install stable/helm-chart名

Helmチャートのインストール・Jenkinsのカスタマイズ
-------------------------------------------------------

今回はJenkinsを導入するにあたり環境に併せてカスタマイズを行います。
Helmは以下のURLに様々なものが公開されています。パラメータを与えることである程度カスタマイズし使用することができます。
Helm chartと同等のディレクトリにvalues.yamlというファイルが存在し、これを環境に併せて変更することでカスタマイズしデプロイできます。

* https://github.com/kubernetes/charts

今回のJenkinsのデプロイでは2つの公開方法が選択できます。


1つ目が、今回の環境では ``Service`` の ``type`` を ``LoadBalancer`` としてしてデプロイすると external-ipが付与される環境となっています。(MetalLBをデプロイ済みです。)

2つ目が ``Ingress`` を使った公開です。IngressをJenkinsのHelmチャートを使ってデプロイするためには「Master.Ingress.Annotations」、「Master.ServiceType」を変更しデプロイします。

簡易的にデプロイをためしてみたい方は1つ目の ``LoadBalancer`` を使ったやり方を実施、新しい概念であるIngressを使った方法を実施したい方は2つ目を選択しましょう。

どちらの方法の場合も、以下のvalues.yamlをカスタマイズしてデプロイします。
このレベルではJenkinsをデプロイするのが目的ではなくCI/CDパイプラインを作成するのが目的であるため、デプロイ用のyamlファイルを準備しました。

また、このvalues.yamlでは永続化ストレージが定義されていないため、Level2で作成したStorageClassを使用し動的にプロビジョニングをするように変更しましょう。

StorageClassには環境に作成したStorageClassを設定します。このサンプルでは "ontap-gold"を設定してあります。

また、Kubernetes上でCI/CDパイプラインを作成するため ``Kubernetes-plugin`` もyamlファイルに追記済みです。

.. literalinclude:: resources/helm-values/jenkins-default-values.yaml
        :language: yaml
        :caption: Helm設定用のvalues.yaml


実行イメージとしては以下の通りです。

.. code-block:: console

    $ helm --namespace jenkins --name jenkins -f ./jenkins-values.yaml install stable/jenkins --debug
    [debug] Created tunnel using local port: '44511'

    [debug] SERVER: "127.0.0.1:44511"

    [debug] Original chart version: ""
    [debug] Fetched stable/jenkins to /home/localadmin/.helm/cache/archive/jenkins-0.16.20.tgz

    [debug] CHART PATH: /home/localadmin/.helm/cache/archive/jenkins-0.16.20.tgz

    NAME:   jenkins
    REVISION: 1
    RELEASED: Mon Aug 27 23:54:09 2018
    CHART: jenkins-0.16.20
    USER-SUPPLIED VALUES:
    Agent:
      AlwaysPullImage: false
      Component: jenkins-slave
      Enabled: true
      Image: jenkins/jnlp-slave
      ImageTag: 3.10-1
      NodeSelector: {}
      PodRetention: Never
      Privileged: false
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 200m
          memory: 256Mi
      volumes: null
    Master:
      AdminUser: admin
      CLI: false
      CSRF:
        DefaultCrumbIssuer:
          Enabled: true
          ProxyCompatability: true
      Component: jenkins-master
      CustomConfigMap: false
      DisabledAgentProtocols:
      - JNLP-connect
      - JNLP2-connect
      HealthProbeLivenessFailureThreshold: 12
      HealthProbes: true
      HealthProbesLivenessTimeout: 90
      HealthProbesReadinessTimeout: 60
      Image: jenkins/jenkins
      ImagePullPolicy: Always
      ImageTag: lts
      Ingress:
        Annotations: null
        ApiVersion: extensions/v1beta1
        TLS: null
      InitScripts: null
      InstallPlugins:
      - kubernetes:1.12.3
      - workflow-job:2.24
      - workflow-aggregator:2.5
      - credentials-binding:1.16
      - git:3.9.1
      - blueocean:1.4.1
      - ghprb:1.40.0
      LoadBalancerSourceRanges:
      - 0.0.0.0/0
      Name: jenkins-master
      NodeSelector: {}
      PodAnnotations: {}
      ServiceAnnotations: {}
      ServicePort: 8080
      ServiceType: LoadBalancer
      SlaveListenerPort: 50000
      SlaveListenerServiceAnnotations: {}
      SlaveListenerServiceType: ClusterIP
      Tolerations: {}
      UsePodSecurityContext: true
      UseSecurity: true
      resources:
        limits:
          cpu: 2000m
          memory: 2048Mi
        requests:
          cpu: 50m
          memory: 256Mi
    NetworkPolicy:
      ApiVersion: extensions/v1beta1
      Enabled: false
    Persistence:
      AccessMode: ReadWriteOnce
      Annotations: {}
      Enabled: true
      Size: 8Gi
      StorageClass: ontap-gold
      mounts: null
      volumes: null
    rbac:
      apiVersion: v1
      install: false
      roleBindingKind: ClusterRoleBinding
      roleRef: cluster-admin
      serviceAccountName: default

    COMPUTED VALUES:
    Agent:
      AlwaysPullImage: false
      Component: jenkins-slave
      Enabled: true
      Image: jenkins/jnlp-slave
      ImageTag: 3.10-1
      NodeSelector: {}
      PodRetention: Never
      Privileged: false
      resources:
        limits:
          cpu: 200m
          memory: 256Mi
        requests:
          cpu: 200m
          memory: 256Mi
      volumes: null
    Master:
      AdminUser: admin
      CLI: false
      CSRF:
        DefaultCrumbIssuer:
          Enabled: true
          ProxyCompatability: true
      Component: jenkins-master
      CustomConfigMap: false
      DisabledAgentProtocols:
      - JNLP-connect
      - JNLP2-connect
      HealthProbeLivenessFailureThreshold: 12
      HealthProbes: true
      HealthProbesLivenessTimeout: 90
      HealthProbesReadinessTimeout: 60
      Image: jenkins/jenkins
      ImagePullPolicy: Always
      ImageTag: lts
      Ingress:
        Annotations: null
        ApiVersion: extensions/v1beta1
        TLS: null
      InitScripts: null
      InstallPlugins:
      - kubernetes:1.12.3
      - workflow-job:2.24
      - workflow-aggregator:2.5
      - credentials-binding:1.16
      - git:3.9.1
      - blueocean:1.4.1
      - ghprb:1.40.0
      LoadBalancerSourceRanges:
      - 0.0.0.0/0
      Name: jenkins-master
      NodeSelector: {}
      PodAnnotations: {}
      ServiceAnnotations: {}
      ServicePort: 8080
      ServiceType: LoadBalancer
      SlaveListenerPort: 50000
      SlaveListenerServiceAnnotations: {}
      SlaveListenerServiceType: ClusterIP
      Tolerations: {}
      UsePodSecurityContext: true
      UseSecurity: true
      resources:
        limits:
          cpu: 2000m
          memory: 2048Mi
        requests:
          cpu: 50m
          memory: 256Mi
    NetworkPolicy:
      ApiVersion: extensions/v1beta1
      Enabled: false
    Persistence:
      AccessMode: ReadWriteOnce
      Annotations: {}
      Enabled: true
      Size: 8Gi
      StorageClass: ontap-gold
      mounts: null
      volumes: null
    rbac:
      apiVersion: v1
      install: false
      roleBindingKind: ClusterRoleBinding
      roleRef: cluster-admin
      serviceAccountName: default

    HOOKS:
    ---
    # jenkins-ui-test-1g5nb
    apiVersion: v1
    kind: Pod
    metadata:
      name: "jenkins-ui-test-1g5nb"
      annotations:
        "helm.sh/hook": test-success
    spec:
      initContainers:
        - name: "test-framework"
          image: "dduportal/bats:0.4.0"
          command:
          - "bash"
          - "-c"
          - |
            set -ex
            # copy bats to tools dir
            cp -R /usr/local/libexec/ /tools/bats/
          volumeMounts:
          - mountPath: /tools
            name: tools
      containers:
        - name: jenkins-ui-test
          image: jenkins/jenkins:lts
          command: ["/tools/bats/bats", "-t", "/tests/run.sh"]
          volumeMounts:
          - mountPath: /tests
            name: tests
            readOnly: true
          - mountPath: /tools
            name: tools
      volumes:
      - name: tests
        configMap:
          name: jenkins-tests
      - name: tools
        emptyDir: {}
      restartPolicy: Never
    MANIFEST:

    ---
    # Source: jenkins/templates/secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: jenkins
      labels:
        app: jenkins
        chart: "jenkins-0.16.20"
        release: "jenkins"
        heritage: "Tiller"
    type: Opaque
    data:

      jenkins-admin-password: "N3EwZWtydDAyQg=="

      jenkins-admin-user: "YWRtaW4="
    ---
    # Source: jenkins/templates/config.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: jenkins
    data:
      config.xml: |-
        <?xml version='1.0' encoding='UTF-8'?>
        <hudson>
          <disabledAdministrativeMonitors/>
          <version>lts</version>
          <numExecutors>0</numExecutors>
          <mode>NORMAL</mode>
          <useSecurity>true</useSecurity>
          <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
            <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
          </authorizationStrategy>
          <securityRealm class="hudson.security.LegacySecurityRealm"/>
          <disableRememberMe>false</disableRememberMe>
          <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
          <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
          <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
          <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
          <jdks/>
          <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
          <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
          <clouds>
            <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@1.12.3">
              <name>kubernetes</name>
              <templates>
                <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
                  <inheritFrom></inheritFrom>
                  <name>default</name>
                  <instanceCap>2147483647</instanceCap>
                  <idleMinutes>0</idleMinutes>
                  <label>jenkins-jenkins-slave</label>
                  <nodeSelector></nodeSelector>
                    <nodeUsageMode>NORMAL</nodeUsageMode>
                  <volumes>
                  </volumes>
                  <containers>
                    <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
                      <name>jnlp</name>
                      <image>jenkins/jnlp-slave:3.10-1</image>
                      <privileged>false</privileged>
                      <alwaysPullImage>false</alwaysPullImage>
                      <workingDir>/home/jenkins</workingDir>
                      <command></command>
                      <args>${computer.jnlpmac} ${computer.name}</args>
                      <ttyEnabled>false</ttyEnabled>
                      # Resources configuration is a little hacky. This was to prevent breaking
                      # changes, and should be cleanned up in the future once everybody had
                      # enough time to migrate.
                      <resourceRequestCpu>200m</resourceRequestCpu>
                      <resourceRequestMemory>256Mi</resourceRequestMemory>
                      <resourceLimitCpu>200m</resourceLimitCpu>
                      <resourceLimitMemory>256Mi</resourceLimitMemory>
                      <envVars>
                        <org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                          <key>JENKINS_URL</key>
                          <value>http://jenkins:8080</value>
                        </org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                      </envVars>
                    </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
                  </containers>
                  <envVars/>
                  <annotations/>
                  <imagePullSecrets/>
                  <nodeProperties/>
                  <podRetention class="org.csanchez.jenkins.plugins.kubernetes.pod.retention.Default"/>
                </org.csanchez.jenkins.plugins.kubernetes.PodTemplate></templates>
              <serverUrl>https://kubernetes.default</serverUrl>
              <skipTlsVerify>false</skipTlsVerify>
              <namespace>jenkins</namespace>
              <jenkinsUrl>http://jenkins:8080</jenkinsUrl>
              <jenkinsTunnel>jenkins-agent:50000</jenkinsTunnel>
              <containerCap>10</containerCap>
              <retentionTimeout>5</retentionTimeout>
              <connectTimeout>0</connectTimeout>
              <readTimeout>0</readTimeout>
              <podRetention class="org.csanchez.jenkins.plugins.kubernetes.pod.retention.Never"/>
            </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
          </clouds>
          <quietPeriod>5</quietPeriod>
          <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
          <views>
            <hudson.model.AllView>
              <owner class="hudson" reference="../../.."/>
              <name>All</name>
              <filterExecutors>false</filterExecutors>
              <filterQueue>false</filterQueue>
              <properties class="hudson.model.View$PropertyList"/>
            </hudson.model.AllView>
          </views>
          <primaryView>All</primaryView>
          <slaveAgentPort>50000</slaveAgentPort>
          <disabledAgentProtocols>
            <string>JNLP-connect</string>
            <string>JNLP2-connect</string>
          </disabledAgentProtocols>
          <label></label>
          <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
            <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
          </crumbIssuer>
          <nodeProperties/>
          <globalNodeProperties/>
          <noUsageStatistics>true</noUsageStatistics>
        </hudson>
      jenkins.model.JenkinsLocationConfiguration.xml: |-
        <?xml version='1.1' encoding='UTF-8'?>
        <jenkins.model.JenkinsLocationConfiguration>
          <adminAddress></adminAddress>
          <jenkinsUrl>http://jenkins:8080</jenkinsUrl>
        </jenkins.model.JenkinsLocationConfiguration>
      jenkins.CLI.xml: |-
        <?xml version='1.1' encoding='UTF-8'?>
        <jenkins.CLI>
          <enabled>false</enabled>
        </jenkins.CLI>
      apply_config.sh: |-
        mkdir -p /usr/share/jenkins/ref/secrets/;
        echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
        cp -n /var/jenkins_config/config.xml /var/jenkins_home;
        cp -n /var/jenkins_config/jenkins.CLI.xml /var/jenkins_home;
        cp -n /var/jenkins_config/jenkins.model.JenkinsLocationConfiguration.xml /var/jenkins_home;
        # Install missing plugins
        cp /var/jenkins_config/plugins.txt /var/jenkins_home;
        rm -rf /usr/share/jenkins/ref/plugins/*.lock
        /usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
        # Copy plugins to shared volume
        cp -n /usr/share/jenkins/ref/plugins/* /var/jenkins_plugins;
      plugins.txt: |-
        kubernetes:1.12.3
        workflow-job:2.24
        workflow-aggregator:2.5
        credentials-binding:1.16
        git:3.9.1
        blueocean:1.4.1
        ghprb:1.40.0
    ---
    # Source: jenkins/templates/test-config.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: jenkins-tests
    data:
      run.sh: |-
        @test "Testing Jenkins UI is accessible" {
          curl --retry 48 --retry-delay 10 jenkins:8080/login
        }
    ---
    # Source: jenkins/templates/home-pvc.yaml
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: jenkins
      labels:
        app: jenkins
        chart: "jenkins-0.16.20"
        release: "jenkins"
        heritage: "Tiller"
    spec:
      accessModes:
        - "ReadWriteOnce"
      resources:
        requests:
          storage: "8Gi"
      storageClassName: "ontap-gold"
    ---
    # Source: jenkins/templates/jenkins-agent-svc.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: jenkins-agent
      labels:
        app: jenkins
        chart: "jenkins-0.16.20"
        component: "jenkins-jenkins-master"
    spec:
      ports:
        - port: 50000
          targetPort: 50000

          name: slavelistener
      selector:
        component: "jenkins-jenkins-master"
      type: ClusterIP
    ---
    # Source: jenkins/templates/jenkins-master-svc.yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: jenkins
      labels:
        app: jenkins
        heritage: "Tiller"
        release: "jenkins"
        chart: "jenkins-0.16.20"
        component: "jenkins-jenkins-master"
    spec:
      ports:
        - port: 8080
          name: http
          targetPort: 8080

      selector:
        component: "jenkins-jenkins-master"
      type: LoadBalancer

      loadBalancerSourceRanges:
        - 0.0.0.0/0
    ---
    # Source: jenkins/templates/jenkins-master-deployment.yaml
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: jenkins
      labels:
        heritage: "Tiller"
        release: "jenkins"
        chart: "jenkins-0.16.20"
        component: "jenkins-jenkins-master"
    spec:
      replicas: 1
      strategy:
        type: RollingUpdate
      selector:
        matchLabels:
          component: "jenkins-jenkins-master"
      template:
        metadata:
          labels:
            app: jenkins
            heritage: "Tiller"
            release: "jenkins"
            chart: "jenkins-0.16.20"
            component: "jenkins-jenkins-master"
          annotations:
            checksum/config: f1949fdff0e0d3db7c6180357f63c007db61b13e5c107e5980a5eac982863c21
        spec:
          securityContext:
            runAsUser: 0
          serviceAccountName: "default"
          initContainers:
            - name: "copy-default-config"
              image: "jenkins/jenkins:lts"
              imagePullPolicy: "Always"
              command: [ "sh", "/var/jenkins_config/apply_config.sh" ]
              resources:
                limits:
                  cpu: 2000m
                  memory: 2048Mi
                requests:
                  cpu: 50m
                  memory: 256Mi

              volumeMounts:
                -
                  mountPath: /var/jenkins_home
                  name: jenkins-home
                -
                  mountPath: /var/jenkins_config
                  name: jenkins-config
                -
                  mountPath: /var/jenkins_plugins
                  name: plugin-dir
                -
                  mountPath: /usr/share/jenkins/ref/secrets/
                  name: secrets-dir
          containers:
            - name: jenkins
              image: "jenkins/jenkins:lts"
              imagePullPolicy: "Always"
              args: [ "--argumentsRealm.passwd.$(ADMIN_USER)=$(ADMIN_PASSWORD)",  "--argumentsRealm.roles.$(ADMIN_USER)=admin"]
              env:
                - name: JAVA_TOOL_OPTIONS
                  value: ""
                - name: JENKINS_OPTS
                  value: ""
                - name: ADMIN_PASSWORD
                  valueFrom:
                    secretKeyRef:
                      name: jenkins
                      key: jenkins-admin-password
                - name: ADMIN_USER
                  valueFrom:
                    secretKeyRef:
                      name: jenkins
                      key: jenkins-admin-user
              ports:
                - containerPort: 8080
                  name: http
                - containerPort: 50000
                  name: slavelistener
              livenessProbe:
                httpGet:
                  path: "/login"
                  port: http
                initialDelaySeconds: 90
                timeoutSeconds: 5
                failureThreshold: 12
              readinessProbe:
                httpGet:
                  path: "/login"
                  port: http
                initialDelaySeconds: 60
              # Resources configuration is a little hacky. This was to prevent breaking
              # changes, and should be cleanned up in the future once everybody had
              # enough time to migrate.
              resources:

                limits:
                  cpu: 2000m
                  memory: 2048Mi
                requests:
                  cpu: 50m
                  memory: 256Mi


              volumeMounts:
                -
                  mountPath: /var/jenkins_home
                  name: jenkins-home
                  readOnly: false
                -
                  mountPath: /var/jenkins_config
                  name: jenkins-config
                  readOnly: true
                -
                  mountPath: /usr/share/jenkins/ref/plugins/
                  name: plugin-dir
                  readOnly: false
                -
                  mountPath: /usr/share/jenkins/ref/secrets/
                  name: secrets-dir
                  readOnly: false
          volumes:
          - name: jenkins-config
            configMap:
              name: jenkins
          - name: plugin-dir
            emptyDir: {}
          - name: secrets-dir
            emptyDir: {}
          - name: jenkins-home
            persistentVolumeClaim:
              claimName: jenkins
    LAST DEPLOYED: Mon Aug 27 23:54:09 2018
    NAMESPACE: jenkins
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1/Secret
    NAME     TYPE    DATA  AGE
    jenkins  Opaque  2     0s

    ==> v1/ConfigMap
    NAME           DATA  AGE
    jenkins        5     0s
    jenkins-tests  1     0s

    ==> v1/PersistentVolumeClaim
    NAME     STATUS   VOLUME      CAPACITY  ACCESS MODES  STORAGECLASS  AGE
    jenkins  Pending  ontap-gold  0s

    ==> v1/Service
    NAME           TYPE          CLUSTER-IP     EXTERNAL-IP     PORT(S)         AGE
    jenkins-agent  ClusterIP     10.109.172.86  <none>          50000/TCP       0s
    jenkins        LoadBalancer  10.97.161.136  192.168.10.210  8080:30376/TCP  0s

    ==> v1beta1/Deployment
    NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
    jenkins  1        1        1           0          0s

    ==> v1/Pod(related)
    NAME                     READY  STATUS   RESTARTS  AGE
    jenkins-965668c95-7tzmc  0/1    Pending  0         0s


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

「NOTES」欄に記載の通りadminパスワードを取得します。

.. code-block:: console

    $ printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

        sShJg2gig9

以上で、Jenkinsのデプロイが完了しました。

Helmが生成するマニフェストファイル
-----------------------------------------------------------------

Helmを使いvalues.yamlを定義するとどのようなマニフェストファイルが生成されるかが予測しづらいこともあります。

その場合には ``--dry-run`` と ``--debug`` を付与することでデプロイメントされるYAMLファイルが出力されます。

.. code-block:: console

   $ helm --namespace jenkins --name jenkins -f ./values.yaml install stable/jenkins --dry-run --debug


values.yamlのTry & Error: インストールが上手くいかない場合は？
-----------------------------------------------------------------

values.yamlを試行錯誤しながら設定していくことになると思います。
一度デプロイメントしたHelmチャートは以下のコマンドで削除することができます。

.. code-block:: console

    $ helm del --purge チャート名



