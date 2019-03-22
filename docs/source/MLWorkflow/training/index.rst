=============================================================
トレーニング: トレーングを行い推論モデルを作成する
=============================================================

目的・ゴール: 推論モデルを作成、作成する一般的な手法を体験する
===================================================================


トレーングを実施
===================================================================

トレーニング用のコンテナイメージを作成します。

.. code-block:: console

    $ cd ~/examples/object_detection/docker
    $ docker build --pull -t pets_object_detection -f ./Dockerfile.training .　

コンテナイメージのビルドは割と時間がかかります。
このタイミングで休憩をとったり、今までの流れで疑問点がないかを確認しましょう。

ビルドが終わったら生成されたイメージの確認をします。

.. code-block:: console

    $ docker images

    pets_object_detection              latest                         25728e8ade9a        2 minutes ago       2.11GB


docker imageへタグ付けし、コンテナレジストリへpushします。

- XX: ユーザ番号

.. code-block:: console
    $ docker login https://registry.ndxlab.net
    $ docker tag  pets_object_detection  registry.ndxlab.net/user[XX]/pets_object_detection:1.0
    $ docker push registry.ndxlab.net/user[XX]/pets_object_detection:1.0

ここもアップロードまでしばらく時間がかかるため、別コンソールを立ち上げて別の作業を進めます。
トレーニングするためのワークフローを作成します

.. code-block:: console

    $ cd ../ks-app/
    $ cd ~/examples/object_detection/ks-app
    $ PIPELINE_CONFIG_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_pets.config"
    $ TRAINING_DIR="${MOUNT_PATH}/train"
    $ ks param set tf-training-job image ${OBJ_DETECTION_IMAGE}
    $ ks param set tf-training-job mountPath ${MOUNT_PATH}
    $ ks param set tf-training-job pvc ${PVC}
    $ ks param set tf-training-job numPs 1
    $ ks param set tf-training-job numWorkers 1
    $ ks param set tf-training-job pipelineConfigPath ${PIPELINE_CONFIG_PATH}
    $ ks param set tf-training-job trainDir ${TRAINING_DIR}

トレーニング用のコンポーネントを導入します。

.. code-block:: console

    $ ks pkg install kubeflow/tf-training

    INFO Retrieved 4 files

プロトタイプのリストを表示、tf-job-operator  が存在することを確認します。

.. code-block:: console

    $ ks prototype list

    NAME                                  DESCRIPTION
    ====                                  ===========
    io.ksonnet.pkg.configMap              A simple config map with optional user-specified data
    io.ksonnet.pkg.deployed-service       A deployment exposed with a service
    io.ksonnet.pkg.namespace              Namespace with labels automatically populated from the name
    io.ksonnet.pkg.single-port-deployment Replicates a container n times, exposes a single port
    io.ksonnet.pkg.single-port-service    Service that exposes a single port
    io.ksonnet.pkg.tf-job-operator        A TensorFlow job operator.
    io.ksonnet.pkg.tf-serving             A TensorFlow serving deployment


オペレーターコンポーネントをプロトタイプから生成します。

.. code-block:: console

    $ ks generate tf-job-operator tf-job-operator

    INFO Writing component at 'examples/object_detection/ks-app/components/tf-job-operator.jsonnet'

Exampleフォルダへ依存ライブラリをコピーします。

.. code-block:: console

    $ cp -r ../../../kubeflow-exe/ks_app/vendor/ ./vendor/

Jobを実行するために必要な環境変数を定義します。

.. code-block:: console

     $ ks param set tf-job-operator deploymentNamespace kubeflow
     $ ks param list tf-job-operator

Jobを実行します。

.. code-block:: console


     $ ks apply $ENV -c tf-job-operator

        INFO Applying customresourcedefinitions tfjobs.kubeflow.org
        INFO Applying serviceaccounts kubeflow.tf-job-dashboard
        INFO Applying configmaps kubeflow.tf-job-operator-config
        INFO Applying serviceaccounts kubeflow.tf-job-operator
        INFO Applying clusterroles tf-job-operator
        INFO Applying clusterrolebindings tf-job-operator
        INFO Applying services kubeflow.tf-job-dashboard
        INFO Applying clusterroles tf-job-dashboard
        INFO Applying clusterrolebindings tf-job-dashboard
        INFO Applying deployments kubeflow.tf-job-operator
        INFO Creating non-existent deployments kubeflow.tf-job-operator
        INFO Applying deployments kubeflow.tf-job-dashboard
        INFO Applying deployments kubeflow.tf-job-dashboard
        INFO Applying deployments kubeflow.tf-job-dashboard

