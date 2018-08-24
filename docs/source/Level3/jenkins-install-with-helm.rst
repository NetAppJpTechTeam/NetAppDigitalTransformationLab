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
-----------------------------------------

今回はJenkinsを導入するにあたり環境に併せてカスタマイズを行います。
Helmは以下のURLに様々なものが公開されています。パラメータを与えることである程度カスタマイズし使用することができます。
Helm chartと同等のディレクトリにvalues.yamlというファイルが存在し、これを環境に併せて変更することでカスタマイズしデプロイできます。

* https://github.com/kubernetes/charts

今回のJenkinsのデプロイでは3つの公開方法が選択できます。


1つ目が、今回の環境では ``Service`` の ``type`` を ``LoadBalancer`` としてしてデプロイすると external-ipが付与される環境を設定しています。(MetalLBをデプロイ済みです。)

2つ目が ``Ingress`` を使った公開です。IngressをJenkinsのHelmチャートを使ってデプロイするためには「Master.Ingress.Annotations」、「Master.ServiceType」を変更しデプロイします。
また、このvalues.yamlでは永続化ストレージが定義されていないため、Level2で作成したStorageClassを使用し動的にプロビジョニングをするように変更しましょう。

簡易的にデプロイをためしてみたい方は1つ目の ``LoadBalancer`` を使ったやり方を実施、新しい概念であるIngressを使った方法を実施したい方は2つ目を選択しましょう。

どちらの方法の場合も、以下のvalues.yamlをカスタマイズしてデプロイします。
このレベルではJenkinsをデプロイするのが目的ではなくCI/CDパイプラインを作成するのが目的であるため、デプロイ用のyamlファイルを準備しました。

StorageClassには環境に作成したStorageClassを設定します。このサンプルでは暫定で "ontap-gold"を設定してあります。

また、Kubernetes上でCI/CDパイプラインを作成するため ``Kubernetes-plugin`` もyamlファイルに追記済みです。

.. literalinclude:: resources/helm-values/jenkins-default-values.yaml
        :language: yaml
        :caption: Helm設定用のvalues.yaml


実行イメージとしては以下の通りです。

.. todo:: ユーザアドレス変更

.. code-block:: console

    $ helm --namespace jenkins --name jenkins -f ./jenkins-values.yaml install stable/jenkins --debug
        LAST DEPLOYED: Tue Apr 24 12:47:12 2018
        NAMESPACE: jenkins
        STATUS: DEPLOYED

        RESOURCES:
        ==> v1/Secret
        NAME     TYPE    DATA  AGE
        jenkins  Opaque  2     8m

        ==> v1/ConfigMap
        NAME           DATA  AGE
        jenkins        3     8m
        jenkins-tests  1     8m

        ==> v1/PersistentVolumeClaim
        NAME     STATUS  VOLUME                 CAPACITY  ACCESS MODES  STORAGECLASS  AGE
        jenkins  Bound   jenkins-jenkins-2c478  8Gi       RWO           ontap-gold    8m

        ==> v1/ServiceAccount
        NAME     SECRETS  AGE
        jenkins  1        8m

        ==> v1/Service
        NAME           TYPE       CLUSTER-IP   EXTERNAL-IP  PORT(S)         AGE
        jenkins-agent  ClusterIP  10.98.21.68  <none>       50000/TCP       8m
        jenkins        NodePort   10.96.24.25  <none>       8080:31050/TCP  8m

        ==> v1beta1/Deployment
        NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
        jenkins  1        1        1           1          8m

        ==> v1beta1/Ingress
        NAME     HOSTS                              ADDRESS  PORTS  AGE
        jenkins  jenkins.user21.web.service.consul  80       8m

        ==> v1/Pod(related)
        NAME                      READY  STATUS   RESTARTS  AGE
        jenkins-578686f98d-6pbx9  1/1    Running  0         8m

        ==> v1beta1/ClusterRoleBinding
        NAME                  AGE
        jenkins-role-binding  8m


        NOTES:
        1. Get your 'admin' user password by running:
          printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

        2. Visit http://jenkins.user21.web.service.consul

        3. Login with the password from step 1 and the username: admin

        For more information on running Jenkins on Kubernetes, visit:
        https://cloud.google.com/solutions/jenkins-on-container-engine
        Configure the Kubernetes plugin in Jenkins to use the following Service Account name jenkins using the following steps:
          Create a Jenkins credential of type Kubernetes service account with service account name jenkins
          Under configure Jenkins -- Update the credentials config in the cloud section to use the service account credential you created in the step above.


「NOTES」欄に記載の通りadminパスワードを取得します。


.. code-block:: console

    $ printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

        sShJg2gig9

以上で、Jenkinsのデプロイが完了しました。

Helmが生成するマニフェストファイル
-----------------------------------------------------------------

Helmを使いvalues.yamlを定義するとどのようなマニフェストファイルが生成されるかが予測しづらいこともあります。

その場合には ``--dry-run`` と ``--debug`` を付与することでデプロイメントされるYAMLファイルが出力されます。

helm --namespace jenkins --name jenkins -f ./values.yaml install stable/jenkins --dry-run --debug


インストールが上手くいかない場合は？
-----------------------------------------------------------------

values.yamlを試行錯誤しながら設定していくことになると思います。
一度デプロイメントしたHelmチャートは以下のコマンドで削除することができます。

.. code-block:: console

    $ helm del --purge チャート名



