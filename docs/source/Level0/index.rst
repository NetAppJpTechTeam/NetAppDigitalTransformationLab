==============================================================
Level 0: 環境の確認・基本操作
==============================================================

本ラボではkubernetesクラスタへの接続確認と稼働確認を行います。

このレベルで習得できるもの
=============================================================

* 環境への接続確認
* kubernetesの基本操作確認

kubernetes環境へのログイン
=============================================================

各自配布されている接続先情報にログイン出来るかを確認してください。

kubernetesにデプロイ
=============================================================

kubernetes基本操作
-------------------------------------------------------------

必要となるコマンドラインツールがインストールされていることを確認します。 ::

    $ kubectl version
    Client Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.4", GitCommit:"bee2d1505c4fe820744d26d41ecd3fdd4a3d6546", GitTreeState:"clean", BuildDate:"2018-03-12T16:29:47Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"9", GitVersion:"v1.9.4", GitCommit:"bee2d1505c4fe820744d26d41ecd3fdd4a3d6546", GitTreeState:"clean", BuildDate:"2018-03-12T16:21:35Z", GoVersion:"go1.9.3", Compiler:"gc", Platform:"linux/amd64"}

次にクラスタを形成するノードを確認します。 ::

    $ kubectl get nodes
    NAME      STATUS    ROLES     AGE       VERSION
    master    Ready     master    5d        v1.9.4
    node0     Ready     <none>    5d        v1.9.4
    node1     Ready     <none>    5d        v1.9.4

デプロイメント
-------------------------------------------------------------

kubernetesクラスタに作成したコンテナアプリケーションをデプロイするためには 「Deployment」を作成します。
kubectlを使用して、アプリケーションをデプロイします。

以下では ``kubectl run`` を実行すると「Deployment」が作成されます。 ::

    $ kubectl run 任意のデプロイメント名 --image=nginx --port=80
    deployment "nginxweb" created

デプロイが完了したら以下のコマンドで状況を確認します。 ::

    $ kubectl get deployments
    NAME                                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    nginxweb                              1         1         1            1           53s

デプロイしたアプリケーションのサービスを確認します。
まだこの状態ではデプロイしたアプリケーションのサービスは存在しない状況です。 ::

    $ kubectl get services
    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8s


外部向けに公開
-------------------------------------------------------------

外部向けにサービスを公開します。
公開後、再度サービスを確認します。 ::

    $ kubectl expose deployment/任意のデプロイメント名 --type="NodePort" --port 80
    service "nginxweb" exposed
    $ kubectl get services
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP        5d
    nginxweb     NodePort    10.103.136.206   <none>        80:30606/TCP   1m

PORT 列を確認します。上の実行例でいうと「30606」ポートの部分を確認します。
この値は起動するたびに変更となります。
自身のホストのIPを確認します。 ::

    $ ifconfig -a | grep 192.168.*
      inet addr:192.168.10.10  Bcast:192.168.10.255  Mask:255.255.255.0

上記の情報を元にIPを生成してアクセスします。

- http://192.168.10.10:30606/

アクセス時に以下の画面が表示されれば稼働確認完了です。

.. image:: resources/nginx.png


状態を確認します。 ::

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



問題発生時のログの確認方法
-------------------------------------------------------------

デプロイに失敗するようであれば以下のコマンドで状態を確認します。

ポッドの状態を確認するコマンド ::

    $ kubectl logs ポッド名


デプロイメントの状態を確認するコマンド ::

    $ kubectl describe deployments デプロイメント名


他にも以下のようなコマンドで状態を確認することができます。
デプロイのyamlファイル単位や、定義しているラベル単位でも情報を確認できます。 ::

    $ kubectl describe -f deploy.yaml
    $ kubectl describe -l ラベル名


クリーンアップ
-------------------------------------------------------------

ここまでで一旦コマンドラインの操作は完了です。
一旦デプロイを削除します。 ::

    $ kubectl delete deployments デプロイメント名
    $ kubectl delete services サービス名

まとめ
=============================================================

このラボではこの先のラボを行うため基本となる操作を学びました。

ここまでで Level0 は終了です。