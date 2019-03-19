=============================================================
ハンズオンのための環境構築と環境の確認
=============================================================

目的・ゴール: 環境の確認とKubeflowのインストール
==================================================================================

最初に今回の環境の確認とハンズオンを行うために使う``Kubeflow``のインストールを行います。

- https://github.com/kubeflow/kubeflow

このセクションのゴールはハンズオンの環境が問題ないことの確認とKubeflowのインストールを完了させることです。

今回の環境の全体概要
==================================================================================

.. todo:: 図示したものを貼る

オンプレミス
---------------------------------------------------

- Kubernetes 1.13 オンプレミス　（構築済み）
- Kubernnetes 1.13 GPU クラスタ（構築済み）
    - 主にトレーング時にクラスタを切り替えて利用
- Kubeflow オンプレミス　（ハンズオンでインストール）

クラウド(GCP)
---------------------------------------------------

- Google Cloud Platform
- Kubeflow オンプレミス　（構築済み）
    - GPU 枯渇時にクラスタを切り替えて使用
    - アプリケーションのサーブ時に使用

Kubeflow のインストール
==================================================================================

まずは自身に与えられた環境にログインできるかを確認します。
以下のログイン先は今回使用するKubernetesクラスタのマスタノードです。

- xxx: 自身の番号

.. code-block:: console

    $ ssh localadmin@192.168.xxx.10
    $ kubectl get node

上記の `` kubectl get node `` で複数のノードが出力されることを確認してください。

続いてKubeflowのインストールになります。
いくつかログは出力されますがワーニングやエラーになっていないことを確認してください。

まずはKubeflowを導入するためのksonnetをインストールします。

.. code-block:: console

    $ export KS_VER=0.13.1

    $ export KS_PKG=ks_${KS_VER}_linux_amd64

    $ wget -O /tmp/${KS_PKG}.tar.gz https://github.com/ksonnet/ksonnet/releases/download/v${KS_VER}/${KS_PKG}.tar.gz

    -- snip
    Saving to: ‘/tmp/ks_0.13.1_linux_amd64.tar.gz’

    /tmp/ks_0.13.1_linux_am 100%[============================>]  21.97M  8.79MB/s    in 2.5s

    2019-03-18 15:15:25 (8.79 MB/s) - ‘/tmp/ks_0.13.1_linux_amd64.tar.gz’ saved [23034111/23034111]

    $ mkdir -p ${HOME}/bin
    $ tar -xvf /tmp/$KS_PKG.tar.gz -C ${HOME}/bin
    $ export PATH=$PATH:${HOME}/bin/$KS_PKG
    $ ks version

``ks version`` の結果が``0.13.1``であることを確認してください。

Kubeflowのインストールを開始します。

Kubeflowのインストールユーティリティである``kfctl.sh``をダウンロードします。

``kubeflow_src``を作成し作業ディレクトリとします。

.. code-block:: console

    $ mkdir kubeflow_src
    $ cd kubeflow_src
    $ export KUBEFLOW_TAG=v0.4.1
    $ curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash

``kfctl.sh init　デプロイメント名`` でセットアップ、デプロイを実施します。

- デプロイメント名は以下のサンプルでは``ndxlab-kubeflow``としますが任意の名称です。

.. code-block:: console
　　　
    $ scripts/kfctl.sh init ndx-kubeflow --platform none
    $ cd ndx-kubeflow/
    $ ../scripts/kfctl.sh generate k8s
    $ ../scripts/kfctl.sh apply k8s
    $ kubectl get svc -n kubeflow
    $ kubectl patch storageclass fas6280 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
    $ kubectl -n kubeflow edit svc jupyter-lb

    ClusterIP ⇒　NodePort

    $ kubectl get svc -n kubeflow
    NAME                                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
    ambassador                               ClusterIP   10.101.244.54    <none>        80/TCP              55m
    ambassador-admin                         ClusterIP   10.102.84.170    <none>        8877/TCP            55m
    argo-ui                                  NodePort    10.111.190.212   <none>        80:31204/TCP        54m
    centraldashboard                         ClusterIP   10.102.191.52    <none>        80/TCP              55m
    jupyter-0                                ClusterIP   None             <none>        8000/TCP            55m
    jupyter-lb                               NodePort    10.98.230.37     <none>        80:32217/TCP        55m
    katib-ui                                 ClusterIP   10.105.233.197   <none>        80/TCP              54m
    minio-service                            ClusterIP   10.110.14.204    <none>        9000/TCP            54m
    ml-pipeline                              ClusterIP   10.98.92.28      <none>        8888/TCP,8887/TCP   54m
    ml-pipeline-tensorboard-ui               ClusterIP   10.109.68.236    <none>        80/TCP              54m
    ml-pipeline-ui                           ClusterIP   10.108.22.213    <none>        80/TCP              54m
    mysql                                    ClusterIP   10.98.57.158     <none>        3306/TCP            54m
    tf-job-dashboard                         ClusterIP   10.100.230.168   <none>        80/TCP              55m
    vizier-core                              NodePort    10.107.52.19     <none>        6789:31271/TCP      54m
    vizier-core-rest                         ClusterIP   10.102.37.196    <none>        80/TCP              54m
    vizier-db                                ClusterIP   10.105.55.85     <none>        3306/TCP            54m
    vizier-suggestion-bayesianoptimization   ClusterIP   10.108.81.225    <none>        6789/TCP            54m
    vizier-suggestion-grid                   ClusterIP   10.110.229.63    <none>        6789/TCP            54m
    vizier-suggestion-hyperband              ClusterIP   10.98.214.225    <none>        6789/TCP            54m
    vizier-suggestion-random                 ClusterIP   10.104.19.84     <none>        6789/TCP            54m

    Deploy and play!