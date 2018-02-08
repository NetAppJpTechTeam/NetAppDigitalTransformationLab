==============================================================
Level1: アプリケーションをコンテナ化する
==============================================================

今回はコンテナに適したアーキテクチャに変更するまえの段階として、
オンプレミスで仮想マシンで動いているアプリケーションについてコンテナ化をしていきます。

.. todolist::

このレベルで習得するもの
    一般的なコンテナイメージの作成の手法
    基本操作を習得する
    デプロイメント方法の習得


コンテナ化の準備
=============================================================


本ラボでは以下のイメージを準備しています。

* nginx
* apache
* tomcat

Database レイヤー

* mySQL
* Postgress
* Oracle
* MongoDB

コンテナイメージの作成
=============================================================

想定するアプリケーションのコンテナイメージを作成します。

留意点としては以下の通り

* アプリケーションの配置
* 静的な構成となっていないか？ (IPパスワードのべた書きなど）
    * コンテナプラットフォームではIPは不定のため、k8s/OpenShiftでは `Service <https://kubernetes.io/docs/concepts/services-networking/service/>`_ を利用する
* ステートフルなものについてはコンテナに適したものにする
    * Hint: https://12factor.net/ja/
* 基本となるコンテナイメージについては DockerHub で探してベースイメージとする
* コンテナ側でIPを指定する際には基本的には 0.0.0.0 とする。そうしないとコネクションがリセットされる。
    * ENTRYPOINT ["rails", "server", "-b", "0.0.0.0"]


Dockerfile のリファレンス `Dockerfile Reference ファイル <https://docs.docker.com/engine/reference/builder/>`_

Hint: どうしても進まない場合は `こちら <docs/source/examples/level1_sampledockerfile.rst>`_ をクリック

コンテナイメージのビルド
=============================================================

作成した Dockerfileをビルドしてイメージを作成する。

バージョニングを意識して実施する。::

    $ docker built -t 生成するコンテナイメージ名:バージョン Dockerファイルのパス


.. TIP::
    Docker イメージの生成方法は複数の手法があります。
    例えば、普通のOSイメージを起動して、ログインしパッケージなどのインストールを行っていく手法があります。
    メリットとしてはオペレーションで作成したものをイメージとして登録できるため、Dockerfileを作成しなくても良いといメリットがある一方で、
    コンテナイメージの作成方法が不透明となる可能性もあります。


イメージレポジトリに登録
=============================================================

プライベートレジストリ、DockerHubは選択いただけます。
このラボで作成たイメージを自社などで作成したい場合は DockerHub に push することもできます。

DockerHub を使う場合
-------------------------------------------------------------

DockerHub にアカウントがあることが前提です。 ::

    $ docker login
    $ docker image push　accountname/container_image_name:tag

private registry を使う場合
-------------------------------------------------------------


プライベートレジストリのIPは以下の通りです。
registry ip: 192.168.0.10

レジストリは共通に準備しているので、Docker image を push する際にレジストリのIPを指定してください。　::

    $ docker push registry_ip:port/accoutname/container_image_name:tag


kubernetes にデプロイ
=============================================================

kubernetes 基本操作
-------------------------------------------------------------

.. todo:: 出力を実際のイベント時の環境に併せて変更

必要となるコマンドラインツールが入っていることを確認します::

    $ kubectl version
    Client Version: version.Info{Major:"1", Minor:"8", GitVersion:"v1.8.0", GitCommit:"6e937839ac04a38cac63e6a7a306c5d035fe7b0a", GitTreeState:"clean", BuildDate:"2017-09-28T22:57:57Z", GoVersion:"go1.8.3", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"5", GitVersion:"v1.5.2", GitCommit:"08e099554f3c31f6e6f07b448ab3ed78d0520507", GitTreeState:"clean", BuildDate:"1970-01-01T00:00:00Z", GoVersion:"go1.7.1", Compiler:"gc", Platform:"linux/amd64

次にクラスタを形成するノードを確認します。::

    $ kubectl get nodes
    NAME      STATUS    ROLES     AGE       VERSION
    host01    Ready     <none>    2m        v1.5.2

デプロイメント
-------------------------------------------------------------


.. todo:: コマンドライン、出力を実際のイベント時の環境に併せて変更

kubernetes クラスタに作成したコンテナアプリケーションをデプロイするためには 「Deployment」を作成します。
kubectlを使用して、アプリケーションをデプロイします。::

    $ kubectl run deployment_name --image=上記で作成したイメージ --port=公開ポート


デプロイが完了したらい以下のコマンドで状況を確認します。 ::

    $ kubectl get deployments
    NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    kubernetes-bootcamp   1         1         1            1           15m



定義ファイルを利用したデプロイメント
-------------------------------------------------------------

.. todo:: このタイミングでやるかの検討が必要

yaml ファイルを作成する。

サンプル::

    apiversion: 1.0

    サンプル提示


(Option) Workload API を使えるようであれば使いましょう。

例えば、Webサーバのコンテナは常に２つ立ち上がっている状態、等の定義ができます。


アプリケーションの稼働確認
=============================================================

デプロイしたアプリケーションにアクセスし、正常稼働しているか確認します。

アクセスするIPについては Serviceを定義します。




ここまでで Level1 は終了です。
