==============================================================
Level 1: アプリケーションをコンテナ化する
==============================================================

今回はコンテナに適したアーキテクチャへ変更するまえの段階として、
オンプレミスで仮想マシンで動いているアプリケーションについてコンテナ化をしていきます。

このレベルで習得できるもの
=============================================================

* 一般的なコンテナイメージの作成の手法
* 基本操作を習得する
* デプロイメント方法の習得

コンテナ化の準備
=============================================================

本ラボでは以下のイメージはキャッシュされているのでイメージのpullが高速になります。

Web/AP レイヤー

* nginx
* apache
* tomcat

Databaseレイヤー

* mySQL
* Postgress
* Oracle
* MongoDB

コンテナイメージの作成
=============================================================

想定するアプリケーションのコンテナイメージを作成します。

留意点としては以下の通りです。

.. todo:: 文章がまとまっていないので個々で言いたいことを、伝えたいことをはっきりさせ記載、コンテナイメージ作成時の注意点はtips的に別セクションへ。

* アプリケーションの配置をDockerfile内に配置
* 基本となるコンテナイメージについてはDockerHubで探してベースイメージとする
* 静的な構成となっていないか(IPパスワードのべた書きなど)
* ステートフルなものについてはコンテナに適したものにする

    * データ永続化についてはLevel2にて実施

* コンテナ側でIPを指定する際には基本的には 0.0.0.0 とする

    * 例: ENTRYPOINT ["rails", "server", "-b", "0.0.0.0"]

Dockerfile のリファレンス `Dockerfile Reference ファイル <https://docs.docker.com/engine/reference/builder/>`_

.. hint::
    どうしても進まない場合は こちら :doc:`resources/level1_sampledockerfile`  をクリックしてください。

コンテナイメージのビルド
=============================================================

作成した Dockerfileをビルドしてイメージを作成します。

バージョニングを意識してコンテナイメージを作成します、コンテナイメージに明示的にバージョンを指定します。 ::

    $ docker built -t 生成するコンテナイメージ名:バージョン Dockerファイルのパス

Dockerイメージの生成方法は複数の手法があります。
例えば、普通のOSイメージを起動して、ログインしパッケージなどのインストールを行っていく手法があります。
メリットとしてはオペレーションで作成したものをイメージとして登録できるため、Dockerfileを作成しなくても良いといメリットがある一方で、
コンテナイメージの作成方法が不透明となる可能性もあります。

イメージレポジトリに登録
=============================================================

プライベートレジストリ、DockerHubは選択いただけます。
このラボで作成たイメージを自社などで作成したい場合はDockerHubにpushすることもできます。

DockerHub を使う場合
-------------------------------------------------------------

DockerHubにアカウントがあることが前提です。 ::

    $ docker login
    $ docker image push accountname/container_image_name:tag

private registry を使う場合
-------------------------------------------------------------


プライベートレジストリのIPは以下の通りです。

* registry ip: 192.168.10.10

レジストリは共通に準備しているので、Docker imageをpushする際にレジストリのIPを指定してください。 ::

    $ docker push registry_ip:port/accoutname/container_image_name:tag


kubernetesにデプロイ
=============================================================

kubernetes基本操作
-------------------------------------------------------------

.. todo:: 出力を実際のイベント時の環境に併せて変更

必要となるコマンドラインツールがインストールされていることを確認します。 ::

    $ kubectl version
    Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.0", GitCommit:"6e937839ac04a38cac63e6a7a306c5d035fe7b0a", GitTreeState:"clean", BuildDate:"2017-09-28T22:57:57Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"5", GitVersion:"v1.5.2", GitCommit:"08e099554f3c31f6e6f07b448ab3ed78d0520507", GitTreeState:"clean", BuildDate:"1970-01-01T00:00:00Z", GoVersion:"go1.7.1", Compiler:"gc", Platform:"linux/amd64

次にクラスタを形成するノードを確認します。 ::

    $ kubectl get nodes
    NAME      STATUS    ROLES     AGE       VERSION
    host01    Ready     <none>    2m        v1.5.2

デプロイメント
-------------------------------------------------------------

kubernetesクラスタに作成したコンテナアプリケーションをデプロイするためには 「Deployment」を作成します。
kubectlを使用して、アプリケーションをデプロイします。

以下では ``kubectl run`` を実行すると「Deployment」が作成されます。 ::

    $ kubectl run deployment_name --image=上記で作成したイメージ --port=公開ポート


デプロイが完了したら以下のコマンドで状況を確認します。 ::

    $ kubectl get deployments
    NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    kubernetes-bootcamp   1         1         1            1           15m


デプロイしたアプリケーションのサービスを確認します。 ::

    $ kubectl get services
    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8s


外部向けに公開
-------------------------------------------------------------

外部向けにサービスを公開します。
公開後、再度サービスを確認します。 ::

    $ kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080
    service "kubernetes-bootcamp" exposed
    $ kubectl get services
    NAME                  TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)          AGE
    kubernetes            ClusterIP   10.96.0.1     <none>        443/TCP          28s
    kubernetes-bootcamp   NodePort    10.110.33.1   <none>        8080:30128/TCP   11s
    $


状態を確認します。 ::

    $ kubectl describe services/kubernetes-bootcamp
    Name:                     kubernetes-bootcamp
    Namespace:                default
    Labels:                   run=kubernetes-bootcamp
    Annotations:              <none>
    Selector:                 run=kubernetes-bootcamp
    Type:                     NodePort
    IP:                       10.110.33.1
    Port:                     <unset>  8080/TCP
    TargetPort:               8080/TCP
    NodePort:                 <unset>  30128/TCP
    Endpoints:                172.18.0.4:8080
    Session Affinity:         None
    External Traffic Policy:  Cluster
    Events:                   <none>

クリーンアップ
-------------------------------------------------------------

.. todo:: ジェネラルに使える内容とする。

ここまでで一旦コマンドラインの操作は完了です。
一旦デプロイを削除します。 ::

    $ kubectl delete deployment deployment_name
    $ kubectl delete svc service_name
    $ kubectl delete pv pv_name



kubectl delete pvc -l app=wordpress
.. tip:: kubectlの操作を容易にする

    kubectlのオペレーションの簡易化のためlabelをつけることをおすすめします。
    `k8s label <https://kubernetes.io/docs/concepts/configuration/overview/#using-labels>`_
    ``kubectl get pods -l app=nginx`` などのようにlabelがついているPod一覧を取得といったことが簡単にできます。
    ほかにも、
    ``kubectl delete deployment -l app=app_label``
    ``kubectl delete service -l app=app_label``


作成したアプリケーションをyamlで定義してデプロイ
=============================================================


ここまではコマンドラインで作成してきましたが yaml ファイルで１サービスをまとめてデプロイ出来るようにします。

ファイル全体の流れとしては以下の通りです。

* Service
* PersistentVolumeClaim
* Deployment

サンプルファイルは以下の通りです。

.. literalinclude:: resources/mysql-deployment.yaml
    :language: yaml
    :linenos:
    :caption: mysqlをデプロイする定義ファイル


.. cauntion:: 本番運用に関して
    Level4 運用編にてシングルではなく本番運用する際の考慮点等をまとめました。
    Workload APIを使う方法で可用性を高めることができます。


アプリケーションの稼働確認
=============================================================

デプロイしたアプリケーションにアクセスし正常稼働しているか確認します。

アクセスするIPについてはサービスを取得して確認します。

kubectlやyamlを使ってk8sへのデプロイが体感できたかと思います。
実運用になるとこのyamlをたくさん書くことは負荷になることもあるかもしれません
その解決のためにパッケージマネージャーHelm 等を使ってデプロイすることが多いかと思います。
このラボでは仕組みを理解していただき、応用出来ることを目的としています。

ここまでで Level1 は終了です。