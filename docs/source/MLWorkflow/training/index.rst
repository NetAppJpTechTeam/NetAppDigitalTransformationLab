=============================================================
トレーニング: トレーングを行い推論モデルを作成する
=============================================================

目的・ゴール: 推論モデルを作成、作成する一般的な手法を体験する
===================================================================

データの準備ができたため実際にトレーニングを実施します。

#. これまでの構成を使用して分散TensorFlowオブジェクト検出トレーニングジョブを実行

トレーングを実施
===================================================================

トレーニング用のコンテナイメージを作成します。

作業ディレクトリへ移動します。

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

コンテナレジストへのpush時に認証が求められます。
その際には以下のID、パスワードを入力してください。


ユーザ名：user[XX]
パスワード: netapp123

XX: ユーザ番号

.. todo:: NDXオンプレで確認

.. code-block:: console

    $ docker login https://registry.ndxlab.net
    $ docker tag  pets_object_detection  registry.ndxlab.net/user[XX]/pets_object_detection:1.0
    $ docker push registry.ndxlab.net/user[XX]/pets_object_detection:1.0

.. code-block:: console

    $ cd ../ks-app/
    $ cd ~/examples/object_detection/ks-app

トレーニングに関連するパラメータを設定します。

.. todo:: private repositoryの場合の設定方法を確認。

.. code-block:: console

    $ PIPELINE_CONFIG_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_pets.config"
    $ TRAINING_DIR="${MOUNT_PATH}/train"
    $ OBJ_DETECTION_IMAGE="makotow/pets_object_detection:1.0"

.. code-block:: console

    $ ks param set tf-training-job image ${OBJ_DETECTION_IMAGE}
    $ ks param set tf-training-job mountPath ${MOUNT_PATH}
    $ ks param set tf-training-job pvc ${PVC}
    $ ks param set tf-training-job numPs 1
    $ ks param set tf-training-job numWorkers 1
    $ ks param set tf-training-job pipelineConfigPath ${PIPELINE_CONFIG_PATH}
    $ ks param set tf-training-job trainDir ${TRAINING_DIR}

トレーニングに使用するパラメータを確認します。

.. code-block:: console

    $ ks param list tf-training-job

    COMPONENT       PARAM              VALUE
    =========       =====              =====
    tf-training-job image              'makotow/pets_object_detection:1.0'
    tf-training-job mountPath          '/pets_data'
    tf-training-job name               'tf-training-job'
    tf-training-job numGpu             0
    tf-training-job numPs              1
    tf-training-job numWorkers         1
    tf-training-job pipelineConfigPath '/pets_data/faster_rcnn_resnet101_pets.config'
    tf-training-job pvc                'pets-pvc'
    tf-training-job trainDir           '/pets_data/train'

.. ここがほとんどいらなくなる。

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

.. 本来はkubeflowデプロイ時に実施すべき
    オペレーターコンポーネントをプロトタイプから生成します。

    .. code-block:: console

        $ ks generate tf-job-operator tf-job-operator

        INFO Writing component at 'examples/object_detection/ks-app/components/tf-job-operator.jsonnet'

Exampleフォルダへ依存ライブラリをコピーします。

.. code-block:: console

    $ cp -r ../../../kubeflow_src/kubeflow-deploy/ks_app/vendor/ ./vendor/

Jobを実行するために必要な環境変数を定義します。

tf-operatorをデプロイします。
デプロイする場所は ``kubeflow_src/kubeflow-deploy/ks_app`` となり、サンプルのディレクトリは異なるため注意してください。

.. code-block:: console

    $ cd ~/kubeflow_src/kubeflow-deploy/ks_app
    $ ks param set tf-job-operator deploymentNamespace kubeflow
    $ ks param list tf-job-operator

    COMPONENT       PARAM               VALUE
    =========       =====               =====
    tf-job-operator cloud               'null'
    tf-job-operator deploymentNamespace 'kubeflow'
    tf-job-operator deploymentScope     'cluster'
    tf-job-operator name                'tf-job-operator'
    tf-job-operator tfDefaultImage      'null'
    tf-job-operator tfJobImage          'gcr.io/kubeflow-images-public/tf_operator:v0.4.0'
    tf-job-operator tfJobUiServiceType  'ClusterIP'
    tf-job-operator tfJobVersion        'v1beta1'


tf-operator をデプロイします。

.. code-block:: console

    $ ks apply ${ENV} -c tf-job-operator

    INFO Applying customresourcedefinitions tfjobs.kubeflow.org
    INFO Creating non-existent customresourcedefinitions tfjobs.kubeflow.org
    INFO Applying serviceaccounts kubeflow.tf-job-dashboard
    INFO Creating non-existent serviceaccounts kubeflow.tf-job-dashboard
    INFO Applying configmaps kubeflow.tf-job-operator-config
    INFO Creating non-existent configmaps kubeflow.tf-job-operator-config
    INFO Applying serviceaccounts kubeflow.tf-job-operator
    INFO Creating non-existent serviceaccounts kubeflow.tf-job-operator
    INFO Applying clusterroles tf-job-operator
    INFO Creating non-existent clusterroles tf-job-operator
    INFO Applying clusterrolebindings tf-job-operator
    INFO Creating non-existent clusterrolebindings tf-job-operator
    INFO Applying services kubeflow.tf-job-dashboard
    INFO Creating non-existent services kubeflow.tf-job-dashboard
    INFO Applying clusterroles tf-job-dashboard
    INFO Creating non-existent clusterroles tf-job-dashboard
    INFO Applying clusterrolebindings tf-job-dashboard
    INFO Creating non-existent clusterrolebindings tf-job-dashboard
    INFO Applying deployments kubeflow.tf-job-operator-v1beta1
    INFO Applying deployments kubeflow.tf-job-dashboard
    INFO Creating non-existent deployments kubeflow.tf-job-dashboard

続いてTensorFlowのジョブを実行します。
一部分サンプルの内容だと動作しない箇所があるため、

ファイルを編集しv1alpha1からv1beta1ヘ変更しましょう。

.. code-block:: console

    $ vim components/tf-training-job.jsonnet

編集後に7行目のようになっていれば完了です。

.. code-block:: console

      1 local env = std.extVar("__ksonnet/environments");
      2 local params = std.extVar("__ksonnet/params").components["tf-training-job"];
      3
      4 local k = import "k.libsonnet";
      5
      6 local tfJobCpu = {
      7   apiVersion: "kubeflow.org/v1beta1",
      8   kind: "TFJob",
      9   metadata: {
     10     name: params.name,
     11     namespace: env.namespace,
     12   },


.. code-block:: console

    ks apply ${ENV} -c tf-training-job


モニタリングする
----------------------------------

適応後に稼働状況を確認しましょう。

KubeflowではTensorFlowのジョブをKubernetes上で稼働させるため、
tfjobsというCustomerResouceDefinition(CRD)で定義しています。

ここでは使われているイメージがなにか？
中でどのようなものが稼働しているかを確認しましょう。

.. code-block:: console

    kubectl -n kubeflow describe tfjobs tf-training-job
    Name:         tf-training-job
    Namespace:    kubeflow
    Labels:       app.kubernetes.io/deploy-manager=ksonnet
                  ksonnet.io/component=tf-training-job
    Annotations:  ksonnet.io/managed:
                    {"pristine":"H4sIAAAAAAAA/+xUwW7bMAy97zN4lpP6amCHYUMPA7oFa9EdisKgZcZRLZGCxDQwCv/7IHtriq37g9wIPj4+kXrgC2B095SyE4YGxmNHey+njaRh+1x3pFiDgdFxD...
    API Version:  kubeflow.org/v1beta1
    Kind:         TFJob
    Metadata:
      Creation Timestamp:  2019-03-24T13:40:28Z
      Generation:          1
      Resource Version:    459799
      Self Link:           /apis/kubeflow.org/v1beta1/namespaces/kubeflow/tfjobs/tf-training-job
      UID:                 62d56003-4e3a-11e9-8f7f-42010a9201d1
    Spec:
      Clean Pod Policy:  Running
      Tf Replica Specs:
        Master:
          Replicas:        1
          Restart Policy:  Never
          Template:
            Metadata:
              Creation Timestamp:  <nil>
            Spec:
              Containers:
                Args:
                  --alsologtostderr
                  --pipeline_config_path=/pets_data/faster_rcnn_resnet101_pets.config
                  --train_dir=/pets_data/train
                Command:
                  python
                  research/object_detection/legacy/train.py
                Image:              makotow/pets_object_detection:1.0
                Image Pull Policy:  Always
                Name:               tensorflow
                Ports:
                  Container Port:  2222
                  Name:            tfjob-port
                Resources:
                Volume Mounts:
                  Mount Path:  /pets_data
                  Name:        pets-data
                Working Dir:   /models
              Restart Policy:  OnFailure
              Volumes:
                Name:  pets-data
                Persistent Volume Claim:
                  Claim Name:  pets-pvc
        PS:
          Replicas:        1
          Restart Policy:  Never
          Template:
            Metadata:
              Creation Timestamp:  <nil>
            Spec:
              Containers:
                Args:
                  --alsologtostderr
                  --pipeline_config_path=/pets_data/faster_rcnn_resnet101_pets.config
                  --train_dir=/pets_data/train
                Command:
                  python
                  research/object_detection/legacy/train.py
                Image:              makotow/pets_object_detection:1.0
                Image Pull Policy:  Always
                Name:               tensorflow
                Ports:
                  Container Port:  2222
                  Name:            tfjob-port
                Resources:
                Volume Mounts:
                  Mount Path:  /pets_data
                  Name:        pets-data
                Working Dir:   /models
              Restart Policy:  OnFailure
              Volumes:
                Name:  pets-data
                Persistent Volume Claim:
                  Claim Name:  pets-pvc
        Worker:
          Replicas:        1
          Restart Policy:  Never
          Template:
            Metadata:
              Creation Timestamp:  <nil>
            Spec:
              Containers:
                Args:
                  --alsologtostderr
                  --pipeline_config_path=/pets_data/faster_rcnn_resnet101_pets.config
                  --train_dir=/pets_data/train
                Command:
                  python
                  research/object_detection/legacy/train.py
                Image:              makotow/pets_object_detection:1.0
                Image Pull Policy:  Always
                Name:               tensorflow
                Ports:
                  Container Port:  2222
                  Name:            tfjob-port
                Resources:
                Volume Mounts:
                  Mount Path:  /pets_data
                  Name:        pets-data
                Working Dir:   /models
              Restart Policy:  OnFailure
              Volumes:
                Name:  pets-data
                Persistent Volume Claim:
                  Claim Name:  pets-pvc
    Status:
      Conditions:
        Last Transition Time:  2019-03-24T13:40:28Z
        Last Update Time:      2019-03-24T13:40:28Z
        Message:               TFJob tf-training-job is created.
        Reason:                TFJobCreated
        Status:                True
        Type:                  Created
        Last Transition Time:  2019-03-24T13:41:20Z
        Last Update Time:      2019-03-24T13:41:20Z
        Message:               TFJob tf-training-job is running.
        Reason:                TFJobRunning
        Status:                True
        Type:                  Running
      Replica Statuses:
        Master:
          Active:  1
        PS:
          Active:  1
        Worker:
          Active:  1
      Start Time:  2019-03-24T13:41:20Z
    Events:
      Type     Reason                          Age                    From         Message
      ----     ------                          ----                   ----         -------
      Warning  SettedPodTemplateRestartPolicy  5m18s (x3 over 5m18s)  tf-operator  Restart policy in pod template will be overwritten by restart policy in replica spec
      Normal   SuccessfulCreatePod             5m18s                  tf-operator  Created pod: tf-training-job-ps-0
      Normal   SuccessfulCreateService         5m18s                  tf-operator  Created service: tf-training-job-ps-0
      Normal   SuccessfulCreatePod             5m18s                  tf-operator  Created pod: tf-training-job-worker-0
      Normal   SuccessfulCreateService         5m18s                  tf-operator  Created service: tf-training-job-worker-0
      Normal   SuccessfulCreatePod             5m18s                  tf-operator  Created pod: tf-training-job-master-0
      Normal   SuccessfulCreateService         5m18s                  tf-operator  Created service: tf-training-job-master-0


またはハンズオン環境に入っているsternというツールを使うことでPodのログを確認することができます。

.. code-block:: console

    $ stern tf-training -n kubeflow

ここまででトレーニングの実施が完了です。

CPUのみで実施していると非常に時間がかかってしまいます。
ここでは一旦CFJobsを削除し作成されているモデルを使いアプリケーションを作成しましょう。

.. code-block:: console

    $ ks delete ${ENV} -c tf-training-job



