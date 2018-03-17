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

本ラボでは以下のイメージをキャッシュしているのでイメージのpullが高速になります。

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

Dockerfile のリファレンス `Dockerfile Reference ファイル <https://docs.docker.com/engine/reference/builder/>`_

留意点としては以下の通りです。

* アプリケーションの配置をDockerfile内に配置
* 基本となるコンテナイメージについてはDockerHubで探してベースイメージとする
* 静的な構成となっていないか(IPパスワードのべた書きなど)

    * 環境変数で設定出来るよう設計する。のちほどk8sのSecretなどでパスワードを保存

* 冪等性はコンテナイメージ側で対応する。責任範囲を明確にしてイメージを作成
* ステートフルなものについてはコンテナに適したものにする

    * データ永続化については :doc:`../Level2/index` にて実施

.. hint::

    どうしても進まない場合は :doc:`resources/level1_sampledockerfile`  をクリックしてください。


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

.. todo:: IPアドレス確認。そもそもここに記載するかは検討が必要。

* registry ip: 192.168.10.10

レジストリは共通に準備しているので、Docker imageをpushする際にレジストリのIPを指定してください。 ::

    $ docker push registry_ip:port/accoutname/container_image_name:tag



作成したアプリケーションをyamlで定義してデプロイ
=============================================================


Level0ではコマンドラインで作成してきましたがyamlファイルで１サービスをまとめてデプロイ出来るようにします。

ファイル全体の流れとしては以下の通りです。

* Service
* PersistentVolumeClaim
* Deployment

サンプルファイルは以下の通りです。
(https://kubernetes.io/docs/tutorials/stateful-application/mysql-wordpress-persistent-volume/ を参考としています。）

.. literalinclude:: resources/sample-deployment.yaml
    :language: yaml
    :caption: アプリケーションをデプロイする定義ファイルの例 deployment.yaml


.. caution:: 本番運用に関して
    Level4 運用編にてシングル構成ではなく本番運用する際の考慮点等をまとめました。
    Workload APIを使う方法で可用性を高めることができます。

kubectlの操作を容易にする
-------------------------------------------------------------

kubectlのオペレーションの簡易化のためlabelをつけることをおすすめします。

* 参考URL: `k8s label <https://kubernetes.io/docs/concepts/configuration/overview/#using-labels>`_

``kubectl get pods -l app=nginx`` などのようにlabelがついているPod一覧を取得といったことが簡単にできます。
ほかにも以下の様なことが可能となります。

* ``kubectl delete deployment -l app=app_label``
* ``kubectl delete service -l app=app_label``
* ``kubectl delete pvc -l app=wordpress``

以下のコマンドを実行してデプロイしましょう。 ::

    $ kubectl create -f deployment.yaml


アプリケーションの稼働確認
=============================================================

デプロイしたアプリケーションにアクセスし正常稼働しているか確認します。

アクセスするIPについてはサービスを取得して確認します。 ::

    $ kubectl get svc

結果として以下のような出力が得られます。EXTERNAL-IPの項目に表示されているIPにアクセスしてみましょう。 ::

    NAME              TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
    kubernetes        ClusterIP      10.51.240.1    <none>        443/TCP          4d
    wordpress         LoadBalancer   10.51.244.29   <pending>     8080:31658/TCP   41s
    wordpress-mysql   ClusterIP      None           <none>        3306/TCP         52s

まとめ
=============================================================

kubectlやyamlを使ってk8sへのデプロイが体感できたかと思います。
実運用になるとこのyamlをたくさん書くことは負荷になることもあるかもしれません
その解決のためにパッケージマネージャーHelm 等を使ってデプロイすることが多いかと思います。
このラボでは仕組みを理解していただき、応用出来ることを目的としています。

ここまでで Level1 は終了です。