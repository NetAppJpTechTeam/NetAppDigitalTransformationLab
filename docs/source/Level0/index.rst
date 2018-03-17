==============================================================
Level 0: 環境の確認・基本操作
==============================================================

今回はコンテナに適したアーキテクチャへ変更するまえの段階として、
オンプレミスで仮想マシンで動いているアプリケーションについてコンテナ化をしていきます。

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

    $ kubectl run deployment_name --image=nginx --port=80


デプロイが完了したら以下のコマンドで状況を確認します。 ::

    $ kubectl get deployments
    NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    kubernetes-bootcamp   1         1         1            1           15m


デプロイしたアプリケーションのサービスを確認します。 ::

    $ kubectl get services
    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   8s


デプロイに失敗するようであれば以下のコマンドで状態を確認します。 ::

    $ kubectl describe deploy deploy_name
    $ kubectl describe -f deploy.yaml
    $ kubectl describe -l label

外部向けに公開
-------------------------------------------------------------

外部向けにサービスを公開します。
公開後、再度サービスを確認します。 ::

    $ kubectl expose deployment/nginx --type="NodePort" --port 8080
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

.. tip::

    ``kubectl create deploy`` の際に --expose オプションを指定すると自動的にServiceを作成することができます。

クリーンアップ
-------------------------------------------------------------

.. todo:: ジェネラルに使える内容とする。

ここまでで一旦コマンドラインの操作は完了です。
一旦デプロイを削除します。 ::

    $ kubectl delete deployment deployment_name
    $ kubectl delete svc service_name

まとめ
=============================================================

このラボではこの先のラボを行うため基本となる操作を学びました。

ここまでで Level0 は終了です。