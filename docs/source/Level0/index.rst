==============================================================
Level 0: 環境の確認・基本操作
==============================================================


目的・ゴール: ラボを実施する環境の確認
=============================================================

本ラボではkubernetesクラスタへの接続確認と稼働確認を行うことが目的です。

ガイドの中では以下を確認しています。

* ラボを実施する環境の構成理解
* 環境への接続確認
* kubernetesの基本操作を確認

流れ
=============================================================

#. ユーザIDの確認
#. 環境へログイン
#. 基本コマンド確認、k8s へアプリケーションデプロイ

kubernetes環境へのログイン
=============================================================

各自配布されている接続先情報にログイン出来るかを確認してください。

kubernetesにデプロイ
=============================================================

kubernetes基本操作
-------------------------------------------------------------

必要となるコマンドラインツールがインストールされていることを確認します。

.. code-block:: console

    $ kubectl version

    Client Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.6", GitCommit:"9f8ebd171479bec0ada837d7ee641dec2f8c6dd1", GitTreeState:"clean", BuildDate:"2018-03-21T15:21:50Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.6", GitCommit:"9f8ebd171479bec0ada837d7ee641dec2f8c6dd1", GitTreeState:"clean", BuildDate:"2018-03-21T15:13:31Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}

次にクラスタを形成するノードを確認します。

.. code-block:: console

    $ kubectl get nodes

    NAME      STATUS    ROLES     AGE       VERSION
    master    Ready     master    6d        v1.9.6
    node0     Ready     <none>    6d        v1.9.6
    node1     Ready     <none>    6d        v1.9.6
    node2     Ready     <none>    6d        v1.9.6

デプロイメント
-------------------------------------------------------------

kubernetesクラスタに作成したコンテナアプリケーションをデプロイするためには 「Deployment」を作成します。
kubectlを使用して、アプリケーションをデプロイします。

以下では ``kubectl run`` を実行すると「Deployment」が作成されます。

.. code-block:: console

    $ kubectl run 任意のデプロイメント名 --image=nginx --port=80

    deployment "nginxweb" created

デプロイが完了したら以下のコマンドで状況を確認します。

.. code-block:: console

    $ kubectl get deployments

    NAME                                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    nginxweb                              1         1         1            1           53s

デプロイしたアプリケーションのサービスを確認します。
まだこの状態ではデプロイしたアプリケーションのサービスは存在しない状況です。

.. code-block:: console

    $ kubectl get services

    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8s


外部向けに公開
-------------------------------------------------------------

外部向けにサービスを公開します。
公開後、再度サービスを確認します。

.. code-block:: console

    $ kubectl expose deployment/上記のデプロイメント名 --type="NodePort" --port 80

    service "nginxweb" exposed

``kubectl expose`` コマンドで外部へ公開しました。

サービス一覧から公開されたポートを確認します。

.. code-block:: console

    $ kubectl get services

    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        5d
    nginxweb     NodePort    10.103.136.206   <none>        80:30606/TCP   1m

PORT 列を確認します。上の実行例でいうと「30606」ポートの部分を確認します。
`--type="NodePort"` を指定すると各ノード上にアプリケーションにアクセスするポート（標準で30000–32767）を作成します。
ノードにアクセスしポッドが動いていれば、そのままアクセスします。ノードにポッドがなければ適切なノード転送される仕組みを持っています。
そのためマスターノードにアクセスすればk8sが適切に転送するという動作をします。

ホストのIPを確認します。

.. code-block:: console

    $ ifconfig -a | grep 192.168.*

      inet addr:192.168.10.10  Bcast:192.168.10.255  Mask:255.255.255.0

上記の情報を元にIPを生成してアクセスします。

- http://確認したIP:確認したポート番号/

アクセス時に以下の画面が表示されれば稼働確認完了です。

.. image:: resources/nginx.png


状態を確認します。

.. code-block:: console

    $ kubectl describe deployment nginxweb

    Name:                   nginxweb
    Namespace:              default
    CreationTimestamp:      Tue, 20 Mar 2018 13:44:08 +0900
    Labels:                 run=nginxweb
    Annotations:            deployment.kubernetes.io/revision=1
    Selector:               run=nginxweb
    Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  1 max unavailable, 1 max surge
    Pod Template:
      Labels:  run=nginxweb
      Containers:
       nginxweb:
        Image:        nginx
        Port:         80/TCP
        Environment:  <none>
        Mounts:       <none>
      Volumes:        <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
    OldReplicaSets:  <none>
    NewReplicaSet:   nginxweb-78547ccd78 (1/1 replicas created)
    Events:
      Type    Reason             Age   From                   Message
      ----    ------             ----  ----                   -------
      Normal  ScalingReplicaSet  15m   deployment-controller  Scaled up replica set nginxweb-78547ccd78 to 1

Replicas の項目で ``1 available`` となっていればデプロイメント成功です。




問題発生時のログの確認方法
-------------------------------------------------------------

デプロイに失敗するようであれば以下のコマンドで状態を確認します。

ポッドの状態を確認するコマンド

.. code-block:: console

    $ kubectl logs ポッド名


デプロイメントの状態を確認するコマンド

.. code-block:: console

    $ kubectl describe deployments デプロイメント名


他にも以下のようなコマンドで状態を確認することができます。
デプロイ時のYAMLファイル単位や、定義しているラベル単位でも情報を確認できます。


.. code-block:: console

    $ kubectl describe -f YAML定義ファイル
    $ kubectl describe -l ラベル名


よく使うコマンドや問題発生時の確認方法については次のページにまとめました。
今後のラボでうまくいかない場合いはぜひ参考にしてください。

:doc:`../others/cmdreferences`

クリーンアップ
-------------------------------------------------------------

コマンドラインの操作は完了です。
今までデプロイしたアプリケーションを削除します。

.. code-block:: console

    $ kubectl delete deployments デプロイメント名
    $ kubectl delete services サービス名

まとめ
=============================================================

このラボではこの先のラボを行うための基本となる操作及び環境の確認を実施しました。

この先は各自ガイドを見ながら進めてください。

ここまでで Level0 は終了です。