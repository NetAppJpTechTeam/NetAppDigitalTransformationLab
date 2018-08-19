==============================================================
Level 2: ステートフルコンテナの実現
==============================================================


目的・ゴール: アプリケーションのデータ永続化を実現
=============================================================

アプリケーションは永続化領域がないとデータの保存ができません。
KubernetesではStatic provisioningとDynamic provisioningの２つの永続化の手法があります。

このレベルではDynamic provisioningを実現するためDynamic provisionerであるTridentをインストールし、
マニフェストファイルを作成しデータの永続化をすることが目標です。

流れ
=============================================================

#. Dynamic storage provisioningを実現(Tridentのインストール)
#. StorageClassの作成
#. PVCをkubernetesマニフェストファイルに追加

    #. 作成したStorageClassを使用する
    #. PVCをkubernetesにリクエストした時点で動的にストレージがプロビジョニングされる

#. アプリケーションを稼働させて永続化ができていることを確認

コンテナでの永続データのカテゴライズ
=============================================================

コンテナ化されたアプリケーション、環境での永続データは
以下のように分類して考え必要な物をリストアップしました。

* データベースのデータファイル、ログファイル
* 各サーバのログファイル
* 設定ファイル
* 共有ファイル

Dynamic provisioning
=============================================================

ステートフルコンテナを実現する上でストレージは重要なコンポーネントになります。

Dynamic volume provisiong はオンデマンドにストレージをプロビジョニングするためのものです。

Static provisioning、Dynamic provisioning それぞれを比較します。

Static provisioningの場合、クラスタの管理者がストレージをプロビジョニングして、PersitentVolumeオブジェクトを作成しkubernetesに公開する必要があります。

Dynamic provisioningの場合、Static provisioningで手動で行っていたステップを自動化し、管理者がおこなっていたストレージの事前のプロビジョニング作業をなくすことができます。

StorageClassオブジェクトで指定したプロビジョナを使用し、動的にストレージリソースをプロビジョニングすることができます。

StorageClassには様々なパラメータを指定することができアプリケーションに適したストレージカタログ、プロファイルを作成することができ、物理的なストレージを抽象化するレイヤとなります。

ネットアップはDynamic provisioningを実現するためのNetApp Tridentというprovisionerを提供しています。

このレベルではTridentでDynamic provisioningを行い、アプリケーションのデータ永続化を実現します。


NetApp Tridentのインストール
=============================================================

Dynamic storage provisioningを実現するためNetApp Tridentを導入します。
TridentはPodとしてデプロイされ通常のアプリケーションと同様に稼働します。

.. include:: trident-install.rst

StorageClassの定義
=============================================================

StorageClassを定義して、ストレージのサービスカタログを作りましょう。

Trident v18.07 ではStorageClassを作成するときに以下の属性を設定できます。
これらの属性のパラメータを組み合わせてストレージサービスをデザインします。

.. list-table:: StorageClass の parameters に設定可能な属性
    :header-rows: 1

    * - 設定可能な属性
      - 例
    * - 性能に関する属性
      - メデイアタイプ(hdd, hybrid, ssd)、プロビジョニングのタイプ（シン、シック)、IOPS
    * - データ保護・管理に関する属性
      - スナップショット有無、クローニング有効化、暗号化の有効化
    * - バックエンドのストレージプラットフォーム属性
      - ontap-nas, ontap-nas-economy, ontap-nas-flexgroup, ontap-san, solidfire-san, eseries-iscsi

全てのパラメータ設定については以下のURLに記載があります。

* https://netapp-trident.readthedocs.io/en/stable-v18.07/kubernetes/concepts/objects.html#kubernetes-storageclass-objects

NFSバックエンドのONTAPでのStorageClass
----------------------------------------------------------------

ストレージ構成は以下の通りです。
今回、意識する必要があるところは異なるメディアタイプ(HDDとSSD)のアグリゲートを保有しているところです。

* 各SVMにHDD, SSDのアグリゲートを割り当て済み

    * aggr1_01:SSDのアグリゲート
    * aggr2_01:HDDのアグリゲート

以下のようなイメージでStoageClassを作成しましょう。

* DB 用の高速領域: SSD を使ったストレージサービス
* Web コンテンツ用のリポジトリ: HDDを使ったストレージサービス

以下は上記の「DB 用の高速領域」のStorageClass作成方法のサンプルです。

.. literalinclude:: resources/sample-sc.yaml
    :language: yaml
    :caption: 高速ストレージ用のマニフェストファイル例 StorageClassFastest.yml

ストレージクラスを作成します。

.. code-block:: console

    $ kubectl create -f StorageClassFastest.yml

    storageclass "ontap-gold" created

    $ kubectl get sc

    NAME         PROVISIONER         AGE
    ontap-gold   netapp.io/trident   10s

同様にブロックデバイスバックエンドとして設定したSolidFireに対応するStorageClassを作成します。

バックエンド登録時に３つの性能別のQoSを作成しました。

それぞれに該当するStoageClassを作成します。StorageClassで指定されたIOPSを実現できるバックエンドのQoSがボリューム作成時に自動設定されます。

.. literalinclude:: resources/sample-block-sf-bronze-sc.yaml
    :language: yaml
    :caption: 1000IOPSの性能が出せるStorageClass


.. literalinclude:: resources/sample-block-sf-silver-sc.yaml
    :language: yaml
    :caption: 4000IOPSの性能が出せるStoageClass


.. literalinclude:: resources/sample-block-sf-gold-sc.yaml
    :language: yaml
    :caption: 8000IOPSの性能が出せるStoageClass

以降のセクションではここまでで作成したStorageClassを適切に使い分けてすすめましょう。

Persistent Volume Claimの作成
=============================================================

アプリケーションで必要とされる永続化領域の定義をします。
PVCを作成時に独自の機能を有効化することができます。

データの保管ポリシー、データ保護ポリシー、SnapShotの取得ポリシー、クローニングの有効化、暗号化の有効化などを設定できます。

一覧については以下のURLに記載があります。
``metadata.annotation`` 配下に記述することで様々な機能を使用することが可能となります。

* https://netapp-trident.readthedocs.io/en/stable-v18.07/kubernetes/concepts/objects.html#kubernetes-persistentvolumeclaim-objects

デプロイ用のマニフェストファイルにPVCを追加
=============================================================

Level1で作成したマニフェストファイルにPVCの項目を追加し、ダイナミックプロビジョニングを使用しデータを永続化出来るアプリケーションを定義します。

.. literalinclude:: resources/sample-pvc.yaml
    :language: yaml
    :caption: 高速ストレージ用の定義ファイルの例 PVCFastest.yml

デプロイメント実施
=============================================================

上記のPVCの設定が終わったら再度アプリケーションをデプロイします。

その後、アプリケーションからデータを保存するようオペレーションを行います。
WordPressであれば記事を投稿することで簡単に確認ができます。

アプリケーションの停止・起動
=============================================================

永続化されていることを確認するため、一度アプリケーションを停止します。

Deploymentで必要となるポッドは起動するような設定になっているため、
簡単にアプリケーションの停止・起動を行う方法として ``Deployment`` 配下の ``Pod`` を削除する方法がとれます。

.. code-block:: console

    $ kubectl delete pod -l "ラベル名"

    $ kubectl get deploy

実行例は以下の通りです。

.. code-block:: console

    $ kubectl delete pod -l app=wordpress

    pod "wordpress-5bc75fd7bd-kzc5l" deleted
    pod "wordpress-mysql-565494758-jjdl4" deleted

    $ kubectl get deploy

    NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    wordpress         1         1         1            0           31d
    wordpress-mysql   1         1         1            0           31d

DeploymentによってPodの起動数は管理されるため新たにPodが起動します。
``AVAILABLE`` の数が正常になるまで待ちましょう。

.. code-block:: console

    $ kubectl get deploy

    NAME              DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    wordpress         1         1         1            1           31d
    wordpress-mysql   1         1         1            1           31d

再デプロイメント後の確認
=============================================================

再起動したPodに対して永続化されたデータが使用されていることを確認します。
2つの視点から確認したいと思います。


1. アプリケーションであれば再度ログインして保存したデータを確認します。
2. バックエンドストレージに動的にボリュームが作成されていることを確認します。

.. code-block:: console

    $ ssh vsadmin@192.168.XX.20 vol show

    Password:
    Vserver   Volume       Aggregate    State      Type       Size  Available Used%
    --------- ------------ ------------ ---------- ---- ---------- ---------- -----
    tridentsvm root        aggr1        online     RW          1GB    972.2MB    5%
    tridentsvm trident_trident aggr1    online     RW       1.86GB     1.77GB    5%
    tridentsvm trident_trident_basic_f4048 aggr1 online RW     1GB    972.4MB    5%
    3 entries were displayed.


Tridentの特徴的な機能: Fast Cloning
=============================================================

Tridentには特徴的な機能であるクローニングの機能が存在します。

**巨大なボリュームでも容量消費せずに超高速にデータをコピーする** クローニングテクノロジーがkubernetesでも使用可能となります。

ユーザーが既存のボリュームを複製することによって新しいボリュームをプロビジョニングできる機能を提供しています。
PVCアノテーションである、``trident.netapp.io/cloneFromPVC`` を介してクローン機能を利用できます。

引数にPVC名（いわゆるボリューム名）を指定します。

.. literalinclude:: resources/sample-pvccloning.yaml
    :language: yaml
    :caption: クローニングのマニフェストファイルの例 pvccloning.yml

クローニング技術によって実現可能なこと
---------------------------------------------------------------

クローニング技術はシンプルですが非常に多く用途で使用することができます。
例としてあげられるのが以下の用途です。

* プレビルド環境の高速展開
* 本番環境に影響せずに大規模な並列テスト
* 運用時のデータリストアの高速化、瞬時に論理障害を戻す

Tridentの17.07でのアップデート: CSI (Container Storage Interface)への対応
=============================================================

最新のTridentではCSIモードでのデプロイが可能となっています。(インストール時に ``--csi`` を付与するだけ）
CSIは仕様自体がまだαステージということもあり実験的なモードですが、いち早くCSIをお試しいただくことが可能となっています。


- Trident CSI モードでの動作：https://netapp-trident.readthedocs.io/en/latest/kubernetes/trident-csi.html
- Trident CSI に書かれた記事: https://netapp.io/2018/07/03/netapp-trident-and-the-csi-oh-my/

CSI自体についてはこちら
- https://kubernetes.io/blog/2018/01/introducing-container-storage-interface/

.. note::

    理論的にはCSIの仕様でドライバを実装すれば、そのドライバはkubernetes、Mesos, Docker, Cloud Foundryなど
    CSIを実装したコンテナオーケストレーターから使用できるようになります。

まとめ
=============================================================

アプリケーションに対して動的に永続化領域をプロビジョニングしデータの永続化を実現しました。

今回はStorageClassの作成からアプリケーションにPersistentVolumeを割り当てるところまでを一連の流れで実現しました。

運用を考えた場合、それぞれのコンポーネントで担当が異なるため以下のような分担になるかと思います。

    * StorageClassの作成: インフラ・kubernetesクラスタの管理者
    * PersistentVolumeClaimの作成: アプリケーション開発者

今後障害時の動作が気になると思いますが、 :doc:`../Level4/index` での検討事項とします。

ここまでで Level2 は終了です。
