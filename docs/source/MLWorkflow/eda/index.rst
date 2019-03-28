=============================================================
データの探索: データを扱ってみる
=============================================================

目的・ゴール: まずは取り扱うデータを準備する
==================================================================================

まずはトレーニングを実行するために必要なデータを準備します。

データを置く場所であるPersistentVolumeClaimを作成しデータをダウンロード解凍を実施します。

概要
==============================================

ここでは以下のフローで進んでいきます。
一覧としては以下の通りです。一つ一つの用語がわからない場合があるかもしれませんがまずは動かし体験することを目標としています。

#. テスト、トレニングデータ、トレーニング結果（モデル）を保管するPersistentVolumeClaimをデプロイする
#. データセットのダウンロード、データセットのアノテーション、事前トレーニング済みモデルチェックポイント、トレーニングパイプラインの構成ファイルをダウンロード
#. ダウンロードしたデータ・セット、事前トレーニング済みデータ・セット、データ・セットアノテーションの解凍
#. ペット検知器モデルをトレーニングするので、TensorFlowペットレコードを作成

ハンズオンではこのksonnetアプリを使用し進めます。

この例で使用する一連のコンポーネントを含むksonnetアプリks-appが存在します。
コンポーネントはks-app/componentsディレクトリにあります、カスタマイズしたい場合はここを編集します。

前章から続けている場合はKubeflowのディレクトリに移動しているため、一旦ホームに戻り、今回のお題の画像解析AI用のディレクトリに移動します。
なお、このサンプルアプリケーションはベースとしてKubeflowのExampleを使用しております。

- https://github.com/kubeflow/examples

.. code-block:: console

    $ cd
    $ git clone https://github.com/kubeflow/examples.git


.. code-block:: console

    $ cd examples/object_detection/ks-app
    $ export ENV=default
    $ ks env add ${ENV} --context=`kubectl config current-context`
    $ ks upgrade
    $ ks env set ${ENV} --namespace kubeflow

トレーニングデータの準備
====================================================================================

作業ディレクトリ pwd を実行し以下のディレクトリであることを確認しましょう。

.. code-block:: console

    $ pwd

    /home/localadmin/exmaples/object_detection/ks-app

データ保管用の領域を作成
--------------------------------------------------------------------------------------

データを保管するPersistentVolumeClaim(PVC)を作成します。

ハンズオンではダイナミックストレージプロビジョニングが必要となります。
前章でインストール、設定したTridentを使用します。

ksonnet のコンポーネントを編集します。

.. code-block:: console

    $ ks param set pets-pvc accessMode "ReadWriteMany"
    $ ks param set pets-pvc storage "20Gi"
    $ ks param set pets-pvc storageClassName "ontap-gold"



.. todo::  ks param set pets-pvc cloneFromPVC "pets-org"

ここまでで上記でセットしたパラメータを確認しましょう。

.. code-block:: console

    $ ks param list pets-pvc

    COMPONENT PARAM            VALUE
    ========= =====            =====
    pets-pvc  accessMode       'ReadWriteMany'
    pets-pvc  name             'pets-pvc'
    pets-pvc  storage          '20Gi'
    pets-pvc  storageClassName 'ontap-gold'

展開したファイルだと、StorageClassを定義する項目がないため追加します。

.. code-block:: console

    $ vim components/pets-pvc.jsonnet


``storageClassName: params.storageClassName`` を追記しましょう。

追記後は以下のファイルとなっていれば完了です。

.. code-block:: js

    local env = std.extVar("__ksonnet/environments");
    local params = std.extVar("__ksonnet/params").components["pets-pvc"];

    local k = import "k.libsonnet";

    local pvc = {
      apiVersion: "v1",
      kind: "PersistentVolumeClaim",
      metadata:{
        name: params.name,
        namespace: env.namespace,
      },
      spec:{
        accessModes: [params.accessMode],
        volumeMode: "Block",
        resources: {
          requests: {
            storage: params.storage,
          },
        },
        storageClassName: params.storageClassName
      },
    };


以下のコマンドを実行するとデータ保管用の領域であるPVCが作成されます。

.. code-block:: console

    $ ks apply ${ENV} -c pets-pvc

    INFO Applying persistentvolumeclaims kubeflow.pets-pvc
    INFO Creating non-existent persistentvolumeclaims kubeflow.pets-pvc

以下のコマンドを実行し、Statusが「Bound」となっていれば完了です。

.. code-block:: console

    $ kubectl get pvc pets-pvc -n kubeflow

    NAME       STATUS   VOLUME                    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    pets-pvc   Bound    kubeflow-pets-pvc-e2be6   20Gi       RWX            ontap-gold     6m55s

ここまででデータを保管するPVCが作成できたため、次はPVCに必要なデータをダウンロードします。


AI作成に必要なデータをダウンロード
--------------------------------------------------------------------------------------

ここまでに作成した ``pets-pvc`` へデータをダウンロードし保管します。

変数定義を実施します。

.. code-block:: console

    $ PVC="pets-pvc"
    $ MOUNT_PATH="/pets_data"
    $ DATASET_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz"
    $ ANNOTATIONS_URL="http://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz"
    $ MODEL_URL="http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"
    $ PIPELINE_CONFIG_URL="https://raw.githubusercontent.com/kubeflow/examples/master/object_detection/conf/faster_rcnn_resnet101_pets.config"


ksonnetにパラメータを指定します。

.. code-block:: console

    $ ks param set get-data-job mountPath ${MOUNT_PATH}
    $ ks param set get-data-job pvc ${PVC}
    $ ks param set get-data-job urlData ${DATASET_URL}
    $ ks param set get-data-job urlAnnotations ${ANNOTATIONS_URL}
    $ ks param set get-data-job urlModel ${MODEL_URL}
    $ ks param set get-data-job urlPipelineConfig ${PIPELINE_CONFIG_URL}


指定したパラメータを確認します。

.. code-block:: console

    $ ks param list get-data-job

    COMPONENT    PARAM             VALUE
    =========    =====             =====
    get-data-job mountPath         '/pets_data'
    get-data-job name              'get-data-job'
    get-data-job pvc               'pets-pvc'
    get-data-job urlAnnotations    'http://www.robots.ox.ac.uk/~vgg/data/pets/data/annotations.tar.gz'
    get-data-job urlData           'http://www.robots.ox.ac.uk/~vgg/data/pets/data/images.tar.gz'
    get-data-job urlModel          'http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_2018_01_28.tar.gz'
    get-data-job urlPipelineConfig 'https://raw.githubusercontent.com/kubeflow/examples/master/object_detection/conf/faster_rcnn_resnet101_pets.config'

ここで使用しているサンプルの一部ではkubernetesクラスタ内から外部への名前解決が失敗する状態になっています。
同じ動作をするコンテナイメージを作成しましたので以下のファイルの ``image`` の部分を変更してください。

image: "inutano/wget" から image: "makotow/wget:dns-fix-0.1.2"へ変更してください。

.. code-block:: console

    $ vim components/get-data-job.jsonnet

最終的にファイル全体が以下のようになっていれば完了です。

.. code-block:: js

    local env = std.extVar("__ksonnet/environments");
    local params = std.extVar("__ksonnet/params").components["get-data-job"];

    local k = import "k.libsonnet";

    local getDataJob(namespace, name, pvc, url, mountPath) = {
          apiVersion: "batch/v1",
          kind: "Job",
          metadata: {
            name: name,
            namespace: namespace,
          },
          spec: {
            template: {
              spec: {
                containers: [{
                  name: "get-data",
                  image: "makotow/wget:dns-fix-0.1.2", <- このように変更します。
                  imagePullPolicy: "IfNotPresent",
                  command: ["wget",  url, "-P", mountPath, "--no-check-certificate"],
                  volumeMounts: [{
                      mountPath: mountPath,
                      name: "pets-data",
                  },],
                  },],
                volumes: [{
                    name: "pets-data",
                    persistentVolumeClaim: {
                      claimName: pvc,
                    },
                },],
                restartPolicy: "Never",
              },
            },
            backoffLimit: 4,
          },
        };

    std.prune(k.core.v1.list.new([
      getDataJob(env.namespace, params.name + "-dataset", params.pvc, params.urlData, params.mountPath),
      getDataJob(env.namespace, params.name + "-annotations", params.pvc, params.urlAnnotations, params.mountPath),
      getDataJob(env.namespace, params.name + "-model", params.pvc, params.urlModel, params.mountPath),
      getDataJob(env.namespace, params.name + "-config", params.pvc, params.urlPipelineConfig, params.mountPath)]))



.. note::

    なぜ名前解決が失敗しているかについて詳しく知りたい方は以下のGitHub Issues のやりとりが参考になります。

    https://github.com/kubernetes/kubernetes/issues/64924

kubernetesクラスタに適応します。

.. code-block:: console

    $ ks apply ${ENV} -c get-data-job

    INFO Applying jobs kubeflow.get-data-job-dataset
    INFO Creating non-existent jobs kubeflow.get-data-job-dataset
    INFO Applying jobs kubeflow.get-data-job-annotations
    INFO Creating non-existent jobs kubeflow.get-data-job-annotations
    INFO Applying jobs kubeflow.get-data-job-model
    INFO Creating non-existent jobs kubeflow.get-data-job-model
    INFO Applying jobs kubeflow.get-data-job-config
    INFO Creating non-existent jobs kubeflow.get-data-job-config


ダウンロード完了しているかを確認します。

「COMPLETIONS」がすべて「1/1」となれば完了です。

.. code-block:: console

    $ kubectl get jobs -n kubeflow

    NAME                       COMPLETIONS   DURATION   AGE
    get-data-job-annotations   1/1           10s        95s
    get-data-job-config        1/1           8s         93s
    get-data-job-dataset       1/1           74s        96s
    get-data-job-model         1/1           20s        95s

ダウンロードしたデータを解凍
--------------------------------------------------------------------------------------

ダウンロードしたデータを解凍します。

.. code-block:: console

    $ ANNOTATIONS_PATH="${MOUNT_PATH}/annotations.tar.gz"
    $ DATASET_PATH="${MOUNT_PATH}/images.tar.gz"
    $ PRE_TRAINED_MODEL_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_coco_2018_01_28.tar.gz"

ksonnetにパラメータを指定します。

.. code-block:: console

    $ ks param set decompress-data-job mountPath ${MOUNT_PATH}
    $ ks param set decompress-data-job pvc ${PVC}
    $ ks param set decompress-data-job pathToAnnotations ${ANNOTATIONS_PATH}
    $ ks param set decompress-data-job pathToDataset ${DATASET_PATH}
    $ ks param set decompress-data-job pathToModel ${PRE_TRAINED_MODEL_PATH}

パラメータの定義を確認します。

.. code-block:: console

    $ ks param list decompress-data-job

    COMPONENT           PARAM             VALUE
    =========           =====             =====
    decompress-data-job mountPath         '/pets_data'
    decompress-data-job name              'decompress-data-job'
    decompress-data-job pathToAnnotations '/pets_data/annotations.tar.gz'
    decompress-data-job pathToDataset     '/pets_data/images.tar.gz'
    decompress-data-job pathToModel       '/pets_data/faster_rcnn_resnet101_coco_2018_01_28.tar.gz'
    decompress-data-job pvc               'pets-pvc'

kubernetesクラスタに適応します。

.. code-block:: console

    $ ks apply ${ENV} -c decompress-data-job

    INFO Applying jobs kubeflow.decompress-data-job-dataset
    INFO Creating non-existent jobs kubeflow.decompress-data-job-dataset
    INFO Applying jobs kubeflow.decompress-data-job-annotations
    INFO Creating non-existent jobs kubeflow.decompress-data-job-annotations
    INFO Applying jobs kubeflow.decompress-data-job-model
    INFO Creating non-existent jobs kubeflow.decompress-data-job-model

.. code-block:: console

    $ kubectl get job -n kubeflow

    NAME                              COMPLETIONS   DURATION   AGE
    decompress-data-job-annotations   0/1           25s        25s
    decompress-data-job-dataset       0/1           25s        25s
    decompress-data-job-model         0/1           24s        24s
    get-data-job-annotations          1/1           10s        12m
    get-data-job-config               1/1           8s         12m
    get-data-job-dataset              1/1           74s        12m
    get-data-job-model                1/1           20s        12m

最終的に以下のように ``decompress-data-job`` のCOMPLETIONSが「1/1」と表示されれば、解凍完了です。

.. code-block:: console

    decompress-data-job-annotations   1/1           3m37s      16m
    decompress-data-job-dataset       1/1           108s       16m
    decompress-data-job-model         1/1           27s        16m


トレーニングに利用するTensorFlowペットレコードを作成
--------------------------------------------------------------------------------------

今回は ``TensorFlow Detection API`` を使用します、そこで使えるTFRecordフォーマットに変換する必要があります。

そのための ``create-pet-record-job`` を準備しています。このジョブを構成し、適応していきましょう。

変数定義を行います。

.. code-block:: console

    $ OBJ_DETECTION_IMAGE="lcastell/pets_object_detection"
    $ DATA_DIR_PATH="${MOUNT_PATH}"
    $ OUTPUT_DIR_PATH="${MOUNT_PATH}"

ksonnetにパラメータを指定します。

.. code-block:: console

    $ ks param set create-pet-record-job image ${OBJ_DETECTION_IMAGE}
    $ ks param set create-pet-record-job dataDirPath ${DATA_DIR_PATH}
    $ ks param set create-pet-record-job outputDirPath ${OUTPUT_DIR_PATH}
    $ ks param set create-pet-record-job mountPath ${MOUNT_PATH}
    $ ks param set create-pet-record-job pvc ${PVC}

kubernetesクラスタに適応します。

.. code-block:: console

    $ ks apply ${ENV} -c create-pet-record-job

    INFO Applying jobs kubeflow.create-pet-record-job
    INFO Creating non-existent jobs kubeflow.create-pet-record-job

稼働状況を確認します。

.. code-block:: console

    $ kubectl get jobs -n kubeflow

    NAME                              COMPLETIONS   DURATION   AGE
    create-pet-record-job             0/1           47s        47s
    decompress-data-job-annotations   1/1           3m37s      22m
    decompress-data-job-dataset       1/1           108s       22m
    decompress-data-job-model         1/1           27s        22m
    get-data-job-annotations          1/1           10s        34m
    get-data-job-config               1/1           8s         34m
    get-data-job-dataset              1/1           74s        34m
    get-data-job-model                1/1           20s        34m

COMPLETIONSが「1/1」となれば完了です。

.. code-block:: console

    create-pet-record-job   1/1   4m15s   4m15s

ここまででデータの準備ができました。

次からはトレーニングの実施をしていきます。
