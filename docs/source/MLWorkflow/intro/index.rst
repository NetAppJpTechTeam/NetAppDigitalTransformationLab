=============================================================
ハンズオンのための環境構築と確認
=============================================================

目的・ゴール: Kubeflowのインストールと環境の確認
==================================================================================

最初に今回の環境の確認とハンズオンを行うために使う ``Kubeflow`` のインストールを行います。

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

環境の確認
==================================================================================

自身に与えられた環境にログインできるかを確認します。

以下のログイン先は今回使用するKubernetesクラスタのマスタノードです。

- xxx: 自身の番号

.. code-block:: console

    $ ssh localadmin@192.168.xxx.10
    $ kubectl get node

上記の ``kubectl get node`` で複数のノードが出力されることを確認してください。

Tridentのインストール
==================================================================================

ここでは基礎編を参照しTridentの導入をしましょう。

:doc:`../../container/Level2/index` を参照してダイナミックストレージプロビジョニングを設定しましょう。

以下の項目を設定し、 ``ontap-gold`` を作成します。

- NetApp Tridentのインストール
- StorageClassの定義
- NFSバックエンドのONTAPでのStorageClass

ハンズオン簡易化のため作成したストレージクラスをデフォルトとします。

.. code-block:: console

    $ kubectl patch storageclass ontap-gold -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

実行後以下の表記となっていたら完了です。

.. code-block:: console

    $ kubectl get storageclass

    NAME                 PROVISIONER            AGE
    ontap-gold (default) netapp.io/trident      3d15h


Kubeflow のインストール
==================================================================================

Kubeflowのインストールを続けます。

Kubeflowを導入するために使う ``ksonnet`` のバージョンを確認します。

.. code-block:: console

    $ ks version

``ks version`` の結果が ``0.13.1`` であることを確認してください。

Kubeflowのインストールを開始します。

Kubeflowのインストールユーティリティである ``kfctl.sh`` をダウンロードします。

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


``kfctl.sh init デプロイメント名`` でセットアップ、デプロイを実施します。

デプロイメント名は以下のサンプルでは ``kubeflow-deploy`` としますが任意の名称です。

kubeflow-deploy フォルダが作成され、その配下にデプロイメント用のファイルが作成されます。

.. code-block:: console

    $ scripts/kfctl.sh init kubeflow-deploy --platform none
    $ ls -F

        deployment/	kubeflow/	kubeflow-deploy/	scripts/

kubeflow-deployディレクトリが作成されました。

インストールを続けます。以下の作業を実施します。

.. code-block:: console

    $ cd kubeflow-deploy/
    $ ../scripts/kfctl.sh generate k8s

生成された設定をそのままapplyするとambassador等UIを提供するサービスはClusterIPで公開されます。
外部からはアクセス出来ませんのでサービスのタイプを変更します。

.. note::

    下記ではNodePortに変更していますが、ラボの環境ではLoadBalancerを使う事も可能です。
    また、公開は必須ではなくkubectlを動作させている端末上のポートにフォワードして
    uiを使う事も可能です。
    また、JupyterについてはAmbassador上からアクセスする事が可能ですので必須ではありません。

.. code-block:: console

    $ cd ks_app/
    $ ks param set ambassador ambassadorServiceType NodePort
    $ ks param set jupyter serviceType NodePort
    $ cd ..

設定が出来たら適用してKubernetesに投入します。

.. code-block:: console

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

minio/mysql/vizier-dbはDB等の永続化ボリューム(Persistent Volume)を必要とします。
ボリュームの状態を確認します。

.. code-block:: console

    $ kubectl get pvc -n kubeflow

    NAME             STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    katib-mysql      Bound    vol3     10Gi       RWO                           73s
    minio-pv-claim   Bound    vol1     10Gi       RWO                           89s
    mysql-pv-claim   Bound    vol2     10Gi       RWO                           89s

    $ kubectl get pv

    NAME   CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS   REASON   AGE
    vol1   10Gi       RWO            Retain           Bound    kubeflow/minio-pv-claim                           3m17s
    vol2   10Gi       RWO            Retain           Bound    kubeflow/mysql-pv-claim                           3m17s
    vol3   10Gi       RWO            Retain           Bound    kubeflow/katib-mysql                              3m17s

.. todo:: tridentのlog貼り付ける

.. note::

    Tridentの設定が終わっていない場合、永続化ボリュームがプロビジョニングされず
    コンテナが起動できません。Tridentの導入と、デフォルトストレージクラスの設定まで
    を完了させてください。

ここからは実際にKubeflowを使った一連の流れを実施していきます。


なお、本ガイドではシェル内で変数を定義していきます。
もし何らかの原因でシェルのセッションが切れるようなことがあった場合にはいかに一覧がありますので
ここを参照してください。

利用変数一覧
----------------------------

.. code-block:: bash

    ENV=default
    PVC="pets-pvc"
    MOUNT_PATH="/pets_data"
    DATASET_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz"
    ANNOTATIONS_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz"
    MODEL_URL="http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"
    PIPELINE_CONFIG_URL="https://raw.githubusercontent.com/kubeflow/examples/master/object_detection/conf/faster_rcnn_resnet101_pets.config"
    ANNOTATIONS_PATH="${MOUNT_PATH}/annotations.tar.gz"
    DATASET_PATH="${MOUNT_PATH}/images.tar.gz"
    PRE_TRAINED_MODEL_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"
    OBJ_DETECTION_IMAGE="makotow/pets_object_detection:1.1-tensorflow1.13"
    PIPELINE_CONFIG_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_pets.config"
    TRAINING_DIR="${MOUNT_PATH}/train"
    CHECKPOINT="${TRAINING_DIR}/model.ckpt-687" #replace with your checkpoint number
    INPUT_TYPE="image_tensor"
    EXPORT_OUTPUT_DIR="${MOUNT_PATH}/exported_graphs"
    DATA_DIR_PATH="${MOUNT_PATH}"
    OUTPUT_DIR_PATH="${MOUNT_PATH}"
    MODEL_COMPONENT=pets-model
    MODEL_PATH=/mnt/exported_graphs/saved_model
    MODEL_STORAGE_TYPE=nfs
    NFS_PVC_NAME=pets-pvc
