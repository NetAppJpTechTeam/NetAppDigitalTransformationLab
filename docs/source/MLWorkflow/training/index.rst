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

ここでは ``Dockerfile.training`` を使用します。

TensorFlowのバージョンを以下のように変更します。

.. code-block:: console

    $ vim Docerfile.training

- 変更前:tensorflow==1.10.0
- 変更後:tensorflow==1.13.1

最終的なファイルは以下の通りです

.. code-block:: console

    # Copyright 2018 Intel Corporation.
    #
    # Licensed under the Apache License, Version 2.0 (the "License");
    # you may not use this file except in compliance with the License.
    # You may obtain a copy of the License at
    #
    #     https://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.

    FROM ubuntu:16.04

    LABEL maintainer="Soila Kavulya <soila.p.kavulya@intel.com>"

    # Pick up some TF dependencies
    RUN apt-get update && apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            libfreetype6-dev \
            libpng12-dev \
            libzmq3-dev \
            pkg-config \
            python \
            python-dev \
            python-pil \
            python-tk \
            python-lxml \
            rsync \
            git \
            software-properties-common \
            unzip \
            wget \
            && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

    RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
        python get-pip.py && \
        rm get-pip.py

    RUN pip --no-cache-dir install \
            tensorflow==1.13.1

    RUN pip --no-cache-dir install \
            Cython \
            contextlib2 \
            jupyter \
            matplotlib

    # Setup Universal Object Detection
    ENV MODELS_HOME "/models"
    RUN git clone https://github.com/tensorflow/models.git $MODELS_HOME

    RUN cd $MODELS_HOME/research && \
        wget -O protobuf.zip https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip && \
        unzip protobuf.zip && \
        ./bin/protoc object_detection/protos/*.proto --python_out=.

    RUN git clone https://github.com/cocodataset/cocoapi.git && \
        cd cocoapi/PythonAPI && \
        make && \
        cp -r pycocotools $MODELS_HOME/research

    ENV PYTHONPATH "$MODELS_HOME/research:$MODELS_HOME/research/slim:$PYTHONPATH"

    # TensorBoard
    EXPOSE 6006

    WORKDIR $MODELS_HOME

    # Run training job
    ARG pipeline_config_path
    ARG train_dir

    CMD ["python", "$MODELS_HOME/research/object_detection/legacy/train.py", "--pipeline_config_path=$pipeline_config_path"  "--train_dir=$train_dir"]

編集後、本ハンズオンで使用するコンテナイメージをビルドします。

.. code-block:: console

    $ docker build --pull -t pets_object_detection -f ./Dockerfile.training .

コンテナイメージのビルドは割と時間がかかります。
このタイミングで今までの流れで疑問点がないかを確認しましょう。

ビルドが終わったら生成されたイメージの確認をします。

.. code-block:: console

    $ docker images

    pets_object_detection              latest                         25728e8ade9a        2 minutes ago       2.11GB


docker imageへタグ付けし、コンテナレジストリへpushします。

コンテナレジストへのpush時に認証が求められます。
その際には以下のID、パスワードを入力してください。


- ユーザ名：user[XX]
- パスワード: Netapp1!

XX: ユーザ番号

.. code-block:: console

    $ docker login https://registry.ndxlab.net
    $ docker tag  pets_object_detection  registry.ndxlab.net/user[XX]/pets_object_detection:1.0
    $ docker push registry.ndxlab.net/user[XX]/pets_object_detection:1.0

.. code-block:: console

    $ cd ~/examples/object_detection/ks-app

トレーニングに関連するパラメータを設定します。

.. code-block:: console

    $ PIPELINE_CONFIG_PATH="${MOUNT_PATH}/faster_rcnn_resnet101_pets.config"
    $ TRAINING_DIR="${MOUNT_PATH}/train"
    $ OBJ_DETECTION_IMAGE="user[番号]/pets_object_detection:1.0"

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
    tf-training-job image              'user[番号]/pets_object_detection:1.0'
    tf-training-job mountPath          '/pets_data'
    tf-training-job name               'tf-training-job'
    tf-training-job numGpu             0
    tf-training-job numPs              1
    tf-training-job numWorkers         1
    tf-training-job pipelineConfigPath '/pets_data/faster_rcnn_resnet101_pets.config'
    tf-training-job pvc                'pets-pvc'
    tf-training-job trainDir           '/pets_data/train'

Exampleフォルダへ依存ライブラリをコピーします。

.. code-block:: console

    $ cp -r ../../../kubeflow_src/kubeflow-deploy/ks_app/vendor/ ./vendor/


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

ここまででトレーニングを開始することができました。


モニタリングする
----------------------------------

トレーニング開始後に稼働状況を確認しましょう。

KubeflowではTensorFlowのジョブをKubernetes上で稼働させるため、
tfjobsというCustomerResouceDefinition(CRD)で定義しています。

ここでは使われているイメージがなにか？中でどのようなものが稼働しているかを確認しましょう。

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


また、ハンズオン環境に入っているsternというツールを使うことでPodのログを確認することができます。

.. code-block:: console

    $ stern tf-training -n kubeflow

ここまででトレーニングの実施が完了です。

今回のサンプルは200000回ステップを実行します。

現在の実行数を確認してみましょう。

CPUだと非常に時間がかかってしまうためGPUが必要になります。
GPUの活用は今後実施します。

Checkpoint が生成されていることを確認して、一旦CFJobsを削除し作成されているモデルを使いアプリケーションを作成しましょう。

Checkpointのファイル生成状況を確認します。

.. code-block:: console

    $ kubectl -n kubeflow exec tf-training-job-master-0 -- ls ${MOUNT_PATH}/train

model.ckpt-X というファイルがあれば完了です。

CFJobsを削除します。


.. code-block:: console

    $ ks delete ${ENV} -c tf-training-job

ここまででトレーニングが終了しました。


