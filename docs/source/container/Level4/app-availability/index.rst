=============================================================
アプリケーションの可用性を向上させる
=============================================================

アプリケーションの可用性を挙げるためWorkload APIを使用する
=============================================================

すでに ``Deployment`` で使われているかもしれませんが、replica数などを定義できます。一般的なアプリケーションデプロイに使用します。

各ノードでコンテナを稼働させる ``DaemonSet`` があります。ログ収集用のデーモンやメトリクス収集などのユースケースがあります。

レプリカ生成時の順序制御、各ポッドにPVを割り当てることができる ``StatefulSet`` があります。主にクラスタ、分散環境におけるユースケースで使用するものです。

kubernetes上のオブジェクト名は以下の通りです。

* ReplicaSet
* DaemonSet
* StatefulSet

ローリングアップデート
=============================================================

``Deployment`` の ``Pod template`` 部分に変更があった場合に自動でアップデートできます。

.. code-block:: console

    $ kubectl set image deployment/DEPLOYMENT CONTAINER=IMAGE_NAME:TAG

``--record`` オプションをつけるとアノテーションが付与されます。

参考: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/


リリース後に問題発生、アプリケーションを戻す
=============================================================

アプリケーションは ``Deployment`` でリビジョン管理しています。

``rollout history`` でリビジョンを確認できます。


.. code-block:: console

    $ kubectl rollout history deployment/デプロイメント名
    deployments "nginx-deployment"
    REVISION  CHANGE-CAUSE
    1         <none>
    2         <none>


各リビジョンの詳細については ``--revision=N`` を付与することで詳細を確認できます。

.. code-block:: console

    $ kubectl rollout history deployment/nginx-deployment --revision=2
    deployments "nginx-deployment" with revision #2
    Pod Template:
      Labels:       app=nginx
            pod-template-hash=1520898311
      Containers:
       nginx:
        Image:      nginx:1.9.1
        Port:       80/TCP
        Environment:        <none>
        Mounts:     <none>
      Volumes:      <none>

アプリケーションは ``Deployment`` でリビジョン管理しており、ロールバック機能も提供しています。
``rollout undo`` で直前のリビジョンに戻ります。``--to-revision`` を指定することで任意のリビジョンに戻すことも可能です。

.. code-block:: console

    $ kubectl rollout undo deployment/nginx-deployment [--to-revision=N]

保存されるリビジョンは ``revisionHistoryLimit`` で定義できるため、運用に合わせた数にしましょう。

Helmを使った場合にも同様のことが実現可能です。

アプリケーション負荷に応じたスケールアウト・イン
=============================================================

``Horizontal Pod Autoscaler`` を使用してアプリケーションの負荷に応じてスケールアウトすることができます。

事前定義としてアプリケーションの負荷情報をheapsterで収集しておく必要があります。
以下の例はすべてのポッドのCPU使用率の平均が50％を超えた場合にレプリカを最大10まで増やす動作をします。

.. code-block:: console

    $ kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10


上記の例では、CPU使用率をメトリクスとしていますが複数のメトリクスを使用したり、カスタマイズすることも可能です。

参考: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/

アプリケーション負荷に応じたスケールアップ
=============================================================

``Horizontal Pod AutoScaler`` に対して ``Vertical Pod AutoScaler`` があります。

完全互換ではありませんが、Vertical Pod AutoScalerというものが k8s 1.9でalpha versionとして提供されています。
従来型のアプリケーションではスケールアウトより、スケールアップのほうが行いやすいのが一般的です。

https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler

アプリケーションの監視
=============================================================

kubernetsで監視すべき項目としてはクラスタ全体の監視とアプリケーションごとの監視になります。

- クラスタ全体の監視については後述します。
- 稼働しているアプリケーションの監視(Pod の監視)