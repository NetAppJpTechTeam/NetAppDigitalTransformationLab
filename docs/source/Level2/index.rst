==============================================================
Level 2: ステートフルコンテナの実現
==============================================================


目的・ゴール: アプリケーションのデータ永続化を実現
=============================================================

アプリケーションは永続化領域がないとデータの保存ができません。
KubernetesではStatic provisioningとDynamic provisioningの２つの永続化の手法があります。

このレベルではDynamic provisioningを実現するためDynamic provisonerであるTridentをインストールし、
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

例えば、v18.01のTridentでは以下の項目をStorageClassを作成するときに設定できます。

* 性能に関する属性: メディアのタイプ、プロビジョニングのタイプ（シン・シック）、IOPS
* データ保護・管理に関する属性:スナップショット、クローニング、暗号化の有効・向こう
* バックエンドのストレージプラットフォーム

全てのパラメータ設定については以下のURLに記載があります。

* https://netapp-trident.readthedocs.io/en/stable-v18.01/kubernetes/concepts/objects.html#kubernetes-storageclass-objects


StorageClassの定義
=============================================================

StorageClassを定義して、ストレージのサービスカタログを作りましょう。

* DB 用の高速領域: SSD を使ったストレージサービス
* Web コンテンツ用のリポジトリ: HDDを使ったストレージサービス

ストレージ構成は以下の通りです。
今回、意識する必要があるところは異なるメディアタイプ(HDDとSSD)のアグリゲートを保有しているところです。

* ONTAP 9.3
* 各SVMにHDD, SSDのアグリゲートを割り当て済み

    * aggr1_01:SSDのアグリゲート
    * aggr2_01:HDDのアグリゲート


StorageClassの作成方法のサンプルは以下の通りです。

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

Persistent Volume Claimの作成
=============================================================

アプリケーションで必要とされる永続化領域の定義をします。
PVCを作成時に独自の機能を有効化することができます。

``reclaimPolicy`` によってポッドがなくなった際のデータの保管ポリシーの設定ができます。
他にもデータ保護、SnapShotの取得ポリシーなどを設定できます。

一覧については以下のURLに記載があります。

* https://netapp-trident.readthedocs.io/en/stable-v18.01/kubernetes/concepts/objects.html#trident-volume-objects

デプロイ用のマニフェストファイルににPVCを追加
=============================================================

Level1で作成したマニフェストファイルにPVCの項目を追加し、ダイナミックプロビジョニングで永続化出来るアプリケーションを定義します。

.. literalinclude:: resources/sample-pvc.yaml
    :language: yaml
    :caption: 高速ストレージ用の定義ファイルの例 PVCFastest.yml

デプロイメント実施
=============================================================

アプリケーションから何かしらのデータを保存するようにします。

    * アプリケーションからデータを記録
    * シンプルにnginxのアクセスログファイルを永続化

アプリケーションの停止
=============================================================

永続化されていることを確認するため、一度アプリケーションを停止します。
可能であればアプリケーションのバージョンアップを行ってみましょう。

Deploymentで必ず１つのポッドは起動するような設定になっているため、
簡単に実施するためにはポッドを削除する手段がとれます。
DeploymentによってPodの起動数は管理されるため新たにポッドが起動します。


再デプロイメント
=============================================================

再起動したPodに対してボリュームがマウントされていることを確認することも可能です。
容易に行える操作としてはDeployment配下にあるPodを削除し、Deploymentによって起動し直させるといったやり方です。

* アプリケーションであれば再度ログインし、保存したデータを確認します。

* 通常運用のリリースに想定するオペレーションをして、外部ストレージにデータ永続化されていることを確認します。

動的にボリュームが作成されていることを確認します。

.. code-block:: console

    $ ssh vsadmin@192.168.20.20 vol show

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

**巨大なボリュームでも容量消費せずに超高速にデータをコピーする** クローニングテクノロジーがkubernetesから使用可能となります。

ユーザーが既存のボリュームを複製することによって新しいボリュームをプロビジョニングできる機能を提供しています。
PVCアノテーションである、``trident.netapp.io/cloneFromPVC`` を介してクローン機能を利用できます。

引数にPVC名（いわゆるボリューム名）を指定します。

.. literalinclude:: resources/sample-pvccloning.yaml
    :language: yaml
    :caption: クローニングのマニフェストファイルの例 pvccloning.yml

クローニング技術によって実現可能なこと
---------------------------------------------------------------

クローニング技術はシンプルですが非常に多く用途で使用することができます。
例としてあげられるのが以下の通りのことです。


* プレビルド環境の高速展開
* 本番環境に影響せずに大規模な並列テスト
* 運用時のデータリストアの高速化、瞬時に論理障害を戻す

まとめ
=============================================================

アプリケーションに対して動的に永続化領域をプロビジョニングしデータの永続化を実現しました。

今回はStorageClassの作成からアプリケーションにPersistentVolumeを割り当てるところまでを一連の流れで実現しました。

本来であればそれぞれで役割がことなるため以下のような分担になるかと思います。

    * StorageClassの作成: インフラ・kubernetesクラスタの管理者
    * PersistentVolumeClaimの作成: 利用者

今後障害時の動作が気になると思いますが、 :doc:`../Level4/index` での検討事項とします。

ここまでで Level2 は終了です。
