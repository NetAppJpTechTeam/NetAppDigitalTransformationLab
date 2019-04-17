=============================================================
GPUの活用,異なる環境でのトレーニング、デプロイ
=============================================================

目的・ゴール: GPU・クラウドを活用する・CI/CDパイプラインの作成
===================================================================================

この前の章ではデータサイエンスワークフローの一連の流れを体験しました。
基本的なワークフローは今までのとおりですが実施してみて課題がいくつかわかってきました。

例えば、CPUでは処理しきれない計算量をどのように高速化するか？
ステージングはオンプレ、本番はクラウドといった複数環境でのユースケースにどう対応するかが挙げられます。

ここからはオプションとして以下のシナリオで対応していきます。

環境へのアクセス方法についてはハンズオンが完了している方へお渡ししますのでお声がけください。

- フローの中を更に高速化
    - GPUの活用: GPUを活用し演算の高速化を体験
    - KubeflowのコンポーネントであるArogo CIを使い自動化を体験
- クラウドの活用: メインはオンプレの環境を使用しましたが、これがクラウドに行ってもアーキテクチャの変更なしに同じことができることを確認

フローの中を更に高速化
===================================================================================

フローの中の高速化としては２つ題材を挙げています。

１つ目はGPUの活用となります。

２つ目は自動化という観点です、こちらについてはKubeflowのコンポーネントであるArgoCIを使用することで実現できます。


GPUの活用
===================================================================================
GPUの活用は容易です。

:doc:`../training/index` で実施したトレーニングをおこなうところで、GPUの数を指定することで自動でGPUを活用できるようになります。

接続用のコンフィグファイルを配布されたことを確認します。

.. code-block:: console

    $ kubectl get node --kubeconfig=config.gpu

Nameの箇所でdgxが表示されていることを確認ください、これがGPUが搭載されたノードになります。

GPUを活用するためのコンテナイメージが必要です。
今回は事前にGPUを利用できるDockerfileを準備していますのでイメージのビルドを実行しましょう。

作業ディレクトリへ移動します。

.. code-block:: console

    $ cd ~/examples/object_detection/docker
    $ ls Dockerfile.training.gpu

上記Dockerfile.training.gpuが存在することを確認してください。

上位のイメージをビルドします。

.. code-block:: console

    $ docker build -t pets_object_detection:1.0-gpu -f Dockerfile.training.gpu .

ビルドが終了したらリポジトリに登録します。

.. code-block:: console

    $ docker login https://registry.ndxlab.net
    $ docker tag  pets_object_detection:1.0-gpu  registry.ndxlab.net/user[XX]/pets_object_detection:1.0
    $ docker push registry.ndxlab.net/user[XX]/pets_object_detection:1.0


ksonnetの環境にGPUクラスタを追加します。

.. code-block:: console

    $ cd ~/examples/object_detection/ks-app
    $ ks env add gpu --kubeconfig config.gpu

現在のパラメータを確認します。

ここでは ``numGpu`` が０であることを確認ください。

.. code-block:: console

    $ ks param list tf-training-job

    COMPONENT       PARAM              VALUE
    =========       =====              =====
    tf-training-job image              'registry.ndxlab.net/user[XX]/pets_object_detection:1.0'
    tf-training-job mountPath          '/pets_data'
    tf-training-job name               'tf-training-job'
    tf-training-job numGpu             0
    tf-training-job numPs              1
    tf-training-job numWorkers         1
    tf-training-job pipelineConfigPath '/pets_data/faster_rcnn_resnet101_pets.config'
    tf-training-job pvc                'pets-pvc'
    tf-training-job trainDir           '/pets_data/train'

GPUを有効にするコンテナイメージの設定とGPU数を設定します。

.. code-block:: console

    $ ks param set tf-training-job image 'registry.ndxlab.net/user[XX]/pets_object_detection:1.0-gpu'
    $ ks param set tf-training-job numGpu 1

これで tf-train-job を実行するとGPUが使用できるようになります。

tf-train-job を実行については :doc:`../training/index`  を参考に実行ください。

クラウドを活用する
===================================================================================

こちらもGPU同様で接続用のコンフィグが配布されたことを確認ください。
以下のようにgkeというキーワードがついているノードが表示されれば切り替え完了です。

.. code-block:: console

    $ kubectl get node

    NAME                                                STATUS   ROLES    AGE     VERSION
    gke-ndxsharedcluster-standardpool01-8b5da289-2pw3   Ready    <none>   4d11h   v1.12.5-gke.5
    gke-ndxsharedcluster-standardpool01-8b5da289-ffws   Ready    <none>   4d11h   v1.12.5-gke.5


ここからは最初から手順を実行し、なにも変更することなく実現できることを確認ください。

オペレーションとしては変更はありませんがデータをどこに置くかの検討が必要となってきます。

例えば今回の例だと以下の検討が必要になります。

- 生成したコンテナイメージの配置場所
- 別のクラスタで作ったデータを別の環境で持っていく方法