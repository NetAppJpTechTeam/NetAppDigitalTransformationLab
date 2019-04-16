=============================================================
アプリケーションから使用する: アプリケーションに組み込む
=============================================================

目的・ゴール: アプリケーションから使用する方法を試す
=============================================================

#. チェックポイントファイルからTensorFlowのグラフを生成
#. トレーニングしたペット判定機のモデルをTF-Servingを使用してサーブ


アプリケーション適用の準備：グラフの生成
=============================================================

トレーニング中のチェックポイントの番号を確認しましょう。

.. code-block:: console

    $ kubectl -n kubeflow exec tf-training-job-master-0 -- ls ${MOUNT_PATH}/train

以下の形式のファイルを参照し変数にセットします。

model.ckpt-[番号] をCHECKPOINT変数にセットします。

ここで一旦CFJobsを削除します。

.. code-block:: console

    $ ks delete ${ENV} -c tf-training-job


.. code-block:: console

    $ CHECKPOINT="${TRAINING_DIR}/model.ckpt-[番号]"
    $ INPUT_TYPE="image_tensor"
    $ EXPORT_OUTPUT_DIR="${MOUNT_PATH}/exported_graphs"

ksonnetのパラメータに設定します。

.. code-block:: console

    $ ks param set export-tf-graph-job mountPath ${MOUNT_PATH}
    $ ks param set export-tf-graph-job pvc ${PVC}
    $ ks param set export-tf-graph-job image ${OBJ_DETECTION_IMAGE}
    $ ks param set export-tf-graph-job pipelineConfigPath ${PIPELINE_CONFIG_PATH}
    $ ks param set export-tf-graph-job trainedCheckpoint ${CHECKPOINT}
    $ ks param set export-tf-graph-job outputDir ${EXPORT_OUTPUT_DIR}
    $ ks param set export-tf-graph-job inputType ${INPUT_TYPE}

設定したパラメータを確認します。

.. code-block:: console

    $ ks param list export-tf-graph-job

    COMPONENT           PARAM              VALUE
    =========           =====              =====
    export-tf-graph-job image              'makotow/pets_object_detection:1.0'
    export-tf-graph-job inputType          'image_tensor'
    export-tf-graph-job mountPath          '/pets_data'
    export-tf-graph-job name               'export-tf-graph-job'
    export-tf-graph-job outputDir          '/pets_data/exported_graphs'
    export-tf-graph-job pipelineConfigPath '/pets_data/faster_rcnn_resnet101_pets.config'
    export-tf-graph-job pvc                'pets-pvc'
    export-tf-graph-job trainedCheckpoint  '/pets_data/train/model.ckpt-687'

kubernetesクラスタに適応します。

.. code-block:: console

    $ ks apply ${ENV} -c export-tf-graph-job

    INFO Applying jobs kubeflow.export-tf-graph-job
    INFO Creating non-existent jobs kubeflow.export-tf-graph-job


.. note::

    TensorFlowにおけるチェックポイントとは、その時点のパラメータやモデルを保管・読み込みができるようにしている機能です。

ジョブが完了したかは以下のコマンドで確認します。

.. code-block:: console

    $ kubectl get job -n kubeflow

    NAME                              COMPLETIONS   DURATION   AGE
    create-pet-record-job             1/1           3m5s       31h
    decompress-data-job-annotations   1/1           3m37s      31h
    decompress-data-job-dataset       1/1           2m1s       31h
    decompress-data-job-model         1/1           24s        31h
    export-tf-graph-job               1/1           45s        50m
    get-data-job-config               1/1           3s         31h
    get-data-job-model                1/1           13s        31h

export-tf-graph-job の Completionが ``1/1`` になっていれば完了です。


変換が完了したら、モデルが生成されたフォルダをマウントしサーブの準備をします。


アプリケーション適用の準備：モデルのサーブ
=============================================================

ストレージ上の実際のボリュームを確認するため、ストレージへ接続しボリューム名を取得します。

.. code-block:: console

    $ cd
    $ mkdir models
    $ ssh vsadmin@192.168.[ユーザ番号].200 vol show

    Password:
    Vserver   Volume       Aggregate    State      Type       Size  Available Used%
    --------- ------------ ------------ ---------- ---- ---------- ---------- -----
    ndxsvm    svm_root     aggr1_01     online     RW          1GB    972.4MB    0%
    ndxsvm    trident_kubeflow_pets_pvc_9373b aggr1_01 online RW 20GB 13.96GB   30%
    ndxsvm    trident_trident aggr1_01  online     RW          2GB     2.00GB    0%
    3 entries were displayed.

上記の例では ``pets_pvc`` というキーワードが入っているボリュームをマウントします。
ボリューム名は各自読み替えてください。
Jobが完了すると以下の通りファイルが作成されています。

.. code-block:: console

    $ sudo mount -t nfs 192.168.XX.200:/trident_kubeflow_pets_pvc_9373b ./models
    $ cd ~/models/exported_graphs
    $ ls

    checkpoint			model.ckpt.index  saved_model
    frozen_inference_graph.pb	model.ckpt.meta
    model.ckpt.data-00000-of-00001	pipeline.config

ここからはアプリケーションへのサーブの準備をします。

.. code-block:: console

    $ sudo mkdir saved_model/1
    $ sudo cp saved_model/* saved_model/1

ここまででモデルの準備ができました。

実際にモデルをサーブしてみましょう。

変数の定義をします。
上記で定義したモデルのパスを設定します。

今回はバックエンドのストレージはNFSを使用しているため、
``MODEL_STORAGE_TYPE`` はnfsを設定します。

.. code-block:: console

        MODEL_COMPONENT=pets-model
        MODEL_PATH=/mnt/exported_graphs/saved_model
        MODEL_STORAGE_TYPE=nfs
        NFS_PVC_NAME=pets-pvc

ksonnetに変数を反映します。

.. code-block:: console

    $ ks param set ${MODEL_COMPONENT} modelPath ${MODEL_PATH}
    $ ks param set ${MODEL_COMPONENT} modelStorageType ${MODEL_STORAGE_TYPE}
    $ ks param set ${MODEL_COMPONENT} nfsPVC ${NFS_PVC_NAME}
    $ ks param set ${MODEL_COMPONENT} defaultCpuImage tensorflow/serving:1.13.0
    $ ks param set ${MODEL_COMPONENT} defaultGpuImage tensorflow/serving:1.13.0-gpu

設定した値を確認します。

.. code-block:: console

    $ ks param list pets-model

    COMPONENT  PARAM            VALUE
    =========  =====            =====
    pets-model defaultCpuImage  'tensorflow/serving:1.13.0'
    pets-model defaultGpuImage  'tensorflow/serving:1.13.0-gpu'
    pets-model deployHttpProxy  true
    pets-model modelPath        '/mnt/exported_graphs/saved_model'
    pets-model modelStorageType 'nfs'
    pets-model name             'pets-model'
    pets-model nfsPVC           'pets-pvc'


本日時点(2019/3/28時点)ではこのままだとServe時にエラーが出てしまうため、
一部編集します。（TensorFlowのバージョンアップによりコマンドラインが一部変更による影響）

編集対象のファイルは以下のパスに存在するものです。

.. code-block:: console

    $ cd ~/examples/object_detection/ks-app/
    $ vim vendor/kubeflow/tf-serving[ランダム文字列]/tf-serving.libsonnet

行数としては123行目を一行削除します。内容としては以下の行を削除します。

.. code-block:: console

    "/usr/bin/tensorflow_model_server"


モデルをサーブします。

.. code-block:: console

    $ ks apply ${ENV} -c pets-model

    INFO Applying services kubeflow.pets-model
    INFO Creating non-existent services kubeflow.pets-model
    INFO Applying deployments kubeflow.pets-model-v1
    INFO Creating non-existent deployments kubeflow.pets-model-v1


実行されているかの確認はデプロイメントを確認しましょう。
DESIREDとAVAILABLEが同一の値になっており正常稼働していることが確認できました。

.. code-block:: console

    $ kubectl get deploy -n kubeflow pets-model-v1
    NAME            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    pets-model-v1   1         1         1            1           12m


ポッドのログを確認してみましょう。

まずはポッド名を確認します。
一番左の文字列がポッド名です。

.. code-block:: console

    $ kubectl get pod -n kubeflow | grep pets-model

    pets-model-v1-966f4bcd4-x4666                             2/2     Running            0          4m45s

ポッドのログを確認します。１つ前の手順で取得したポッド名を使って確認します。
エラーやワーニングが発生していないことを確認しましょう。

.. code-block:: console

    $ kubectl logs pets-model-v1-966f4bcd4-x4666 -n kubeflow -c pets-model

    2019-03-26 15:03:22.413505: I external/org_tensorflow/tensorflow/cc/saved_model/loader.cc:285] SavedModel load for tags { serve }; Status: success. Took 1984623 microseconds.
    2019-03-26 15:03:22.414523: I tensorflow_serving/servables/tensorflow/saved_model_warmup.cc:101] No warmup data file found at /mnt/exported_graphs/saved_model/1/assets.extra/tf_serving_warmup_requests
    2019-03-26 15:03:22.419865: I tensorflow_serving/core/loader_harness.cc:86] Successfully loaded servable version {name: pets-model version: 1}
    2019-03-26 15:03:22.423037: I tensorflow_serving/model_servers/server.cc:313] Running gRPC ModelServer at 0.0.0.0:9000 ...
    2019-03-26 15:03:22.424251: I tensorflow_serving/model_servers/server.cc:333] Exporting HTTP/REST API at:localhost:8501 ...
    [evhttp_server.cc : 237] RAW: Entering the event loop ...


ここまでで生成したモデルをサービングする手順が完了です。

.. note::

    kubectl logs 上記のコマンドで最後に ``-c`` を付与しています。これはPod内に複数のコンテナが起動している場合に特定のコンテナを指定しログを取得しています。
    Pod＝１つ以上のコンテナの集まりのためこのような構成をとることもできます。


アプリケーション適用：実際にAPI経由で推論してみる
=============================================================

今回の生成したモデルを使用し推論を実行するためにgRPCクライントを使用することができます。

今回はオペレーション簡易化のため ``grpc-client-tf-serving`` というgrpcクライアントを含んだコンテナイメージを作成してあります。

容量が大きいため事前に ``docker pull`` しましょう。

.. code-block:: console

    $ docker pull registry.ndxlab.net/library/grpc-client-tf-serving:1.0

別コンソールから以下のコマンドを実行しましょう。


Kubernetes外部からモデルサーバにアクセスできるようにポートフォワーディングを設定します。

.. code-block:: console

    $ kubectl -n kubeflow port-forward service/pets-model 9000:9000

サンプルフォルダにある画像を推論させます。

.. code-block:: console

    $ cd ~/examples/object_detection/serving_script
    $ OUT_DIR=.  <= カレントディレクトリとしましたが好きな場所に設定してください。
    $ INPUT_IMG="image1.jpg"
    $ sudo docker run --network=host \
        -v $(pwd):/examples/object_detection/serving_script --rm -it \
        registry.ndxlab.net/library/grpc-client-tf-serving:1.0 \
        --server=localhost:9000 \
        --model=pets-model \
        --input_image=${INPUT_IMG} \
        --output_directory=${OUT_DIR} \
        --label_map=${TF_MODELS}/models/research/object_detection/data/pet_label_map.pbtxt

実行が完了すると ``OUT_DIR`` で指定した箇所に ``image1-output.jpg`` というファイル名で保存されています。

ローカル環境へコピーしてどのような画像になっているかを確認しましょう。

まとめ
==========================================================================================================================

ここまででAIを創るための一連の流れを体験しました。
実際は非常に泥臭い内容になっていることをご理解いただけたかと思います。

また、ここでは一連のワークフローを体験いただくため画像判定の精度が十分に向上できていない状況です。
画像判定が可能な推論モデルはデータの事前準備の中でダウンロードしていますので、物体が四角で囲われた画像を出力したい場合は次の手順を実施しましょう。
