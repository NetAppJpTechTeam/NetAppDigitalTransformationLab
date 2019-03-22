=============================================================
ハンズオンのための環境構築と確認
=============================================================

目的・ゴール: Kubeflowのインストールと環境の確認
==================================================================================

最初に今回の環境の確認とハンズオンを行うために使う``Kubeflow``のインストールを行います。

- https://github.com/kubeflow/kubeflow

このセクションのゴールはハンズオンの環境が問題ないことの確認とKubeflowのインストールを完了させることです。

今回の環境の全体概要
==================================================================================

.. todo:: 図示したものを貼る

環境
---------------------------------------------------

- Kubernetes 1.13 オンプレミス（構築済み）
- Kubernetes 1.13 GPU クラスタ（構築済み）: 主にトレーング時にクラスタを切り替えて利用
- **Kubeflow オンプレミス: ハンズオンでインストール**
- Kubernetes 1.12 Google Cloud Platform : Kubeflowをインストール済み、GPU 枯渇時にクラスタを切り替えて使用、アプリケーションのサーブ時に使用

Kubeflow のインストール
==================================================================================

自身に与えられた環境にログインできるかを確認します。

以下のログイン先は今回使用するKubernetesクラスタのマスタノードです。

- xxx: 自身の番号

.. code-block:: console

    $ ssh localadmin@192.168.xxx.10
    $ kubectl get node

上記の ``kubectl get node`` で複数のノードが出力されることを確認してください。

Kubeflowのインストールを続けます。

Kubeflowを導入するために使う ``ksonnet`` のバージョンを確認します。

..
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


.. code-block:: console

    $ ks version

``ks version`` の結果が　``0.13.1``　であることを確認してください。

Kubeflowのインストールを開始します。

Kubeflowのインストールユーティリティである``kfctl.sh``をダウンロードします。

``kubeflow_src`` を作成し作業ディレクトリとします。

.. code-block:: console

    $ mkdir kubeflow_src
    $ cd kubeflow_src
    $ export KUBEFLOW_TAG=v0.4.1
    $ curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash

kubeflowがダウンロードできたことを確認します。

.. code-block:: console

    $ ls -F

    deployment/	kubeflow/	scripts/


``kfctl.sh init　デプロイメント名`` でセットアップ、デプロイを実施します。

デプロイメント名は以下のサンプルでは``kubeflow-deploy``としますが任意の名称です。

kubeflow-deploy フォルダが作成され、その配下にデプロイメント用のファイル郡が作成されます。

.. code-block:: console

    $ scripts/kfctl.sh init kubeflow-deploy --platform none
    $ ls -F

        deployment/	kubeflow/	kubeflow-deploy/	scripts/

kubeflow-deployディレクトリが作成されました。

インストールを続けます。以下の作業を実施します。

.. code-block:: console

    $ cd kubeflow-exe/
    $ ../scripts/kfctl.sh generate k8s
    $ ../scripts/kfctl.sh apply k8s

ここまででデプロイが完了です。

どのようなコンポーネントがデプロイされたかを確認しましょう。

.. code-block:: console

    $ kubectl get deploy -n kubeflow

    NAME                                     DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    ambassador                               3         3         3            3           49m
    argo-ui                                  1         1         1            1           48m
    centraldashboard                         1         1         1            1           49m
    katib-ui                                 1         1         1            1           26m
    minio                                    1         1         1            1           27m
    ml-pipeline                              1         1         1            1           27m
    ml-pipeline-persistenceagent             1         1         1            1           27m
    ml-pipeline-scheduledworkflow            1         1         1            1           27m
    ml-pipeline-ui                           1         1         1            1           27m
    mysql                                    1         1         1            1           27m
    pytorch-operator                         1         1         1            1           48m
    spartakus-volunteer                      1         1         1            1           48m
    studyjob-controller                      1         1         1            1           26m
    tf-job-dashboard                         1         1         1            1           49m
    tf-job-operator-v1beta1                  1         1         1            1           49m
    vizier-core                              1         1         1            1           26m
    vizier-core-rest                         1         1         1            1           26m
    vizier-db                                1         1         1            1           26m
    vizier-suggestion-bayesianoptimization   1         1         1            1           26m
    vizier-suggestion-grid                   1         1         1            1           26m
    vizier-suggestion-hyperband              1         1         1            1           26m
    vizier-suggestion-random                 1         1         1            1           26m
    workflow-controller                      1         1         1            1           48m


ここからは実際にKubeflowを使った一連の流れを実施していきます。
