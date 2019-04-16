==========================================================================================================================
アプリケーションから使用する: トレーニング済みのモデルをアプリケーションに組み込む
==========================================================================================================================

目的・ゴール: アプリケーションからトレーニング済みのモデルを使用する方法を試す
==========================================================================================================================

ここでは事前のステップで精度が足りなかった推論モデルの替わりにトレーニング済みのモデルをアプリケーションに組み込み画像判定を実施します。
流れとしては以下の通りです。

#. トレーニング済みのモデルをTF-Servingを使用してサーブ
#. 事前のステップと同様にアプリケーションにgrpcクライアントから画像を送り判定を行う


トレーニング済みの推論モデルを使用する
==========================================================================================================================

事前にダウンロードした画像判定のモデルをksonnetでmodelPathへ設定します。

.. code-block:: console

    $ cd ~/examples/object_detection/ks-app
    $ ks param set pets-model modelPath /mnt/faster_rcnn_resnet101_coco_2018_01_28/saved_model


今回使用する ``TFServing`` では推論モデルはバージョニングして管理されるため以下のように ``1`` フォルダを作成し推論モデルを配置します。
``1`` フォルダにモデルをコピーすることでサーブできるようになります。

.. code-block:: console

    $ cd ~/models/rcnn_resnet101_coco_2018_01_28/saved_model
    $ sudo mkdir 1
    $ sudo cp * 1

準備ができたらモデルのサーブを実行します。

ここまでの手順で、モデルをすでにデプロイしているかたは一旦削除を実施してください。

.. code-block:: console

    $ cd ~/examples/object_detection/ks-app
    $ ks delete default -c pets_model


上記コマンドの実行が成功しても削除・停止処理が実行中の可能性があるため、Podが削除されたことを確認後以下のコマンドを実行してください。

.. code-block:: console

    $ ks apply default -c pets_model

ここまででトレーニング済みモデルのデプロイが完了です。


ここからは画像認識を再度実施します。

port-forward を実施済みであれば **Ctrl-C** で停止します、次の手順で再度実行しましょう。

.. code-block:: console

    # すでに実行済みであれば
    # Ctrl-C で停止後、次のコマンドを実行
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
再度画像を確認し画像認識ができていることを確認しましょう。

まとめ
==========================================================================================================================

ここではトレーニング済みモデルを適応して再度サーブするということを行いました。

確認いただけたのは一部のパラメータを変更刷るだけで容易にモデルを変更することができ、
実際に精度が変わるところを体験いただきました。