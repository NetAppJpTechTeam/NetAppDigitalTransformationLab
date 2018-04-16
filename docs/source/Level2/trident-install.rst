Tridentインストール事前準備
=============================================================

Trident のインストールでk8sクラスタの管理者権限が必要になります。

.. code-block:: console

    $ kubectl auth can-i '*' '*' --all-namespaces

バックエンドに登録するマネジメントIPにk8sクラスタのコンテナから疎通が取れるかを確認します。

.. code-block:: console

    $ kubectl run -i --tty ping --image=busybox --restart=Never --rm --  ping [ipアドレス]


Tridentインストール
=============================================================

バイナリをダウンロードしてインストールします。
バックエンドストレージのための ``setup/backend.json`` を編集します。以下はサンプルとなります。

.. code-block:: console

    $ wget https://github.com/NetApp/trident/releases/download/v18.01.0/trident-installer-18.01.0.tar.gz
    $ tar xzf trident*.tar.gz && cd trident-installer
    $ cp sample-input/backend-ontap-nas.json setup/backend.json


.. list-table:: backend.jsonの設定パラメータ
    :header-rows: 1

    * - パラメータ名
      - 説明
      - 設定内容
    * - managementLIF
      - ONTAPのクラスタ管理LIFまたはSVM管理LIFを設定
      - 192.168.XX.200
    * - dataLIF
      - データ通信LIF
      - 192.168.XX.200
    * - svm
      - tridentから使用するSVM
      - svmXX
    * - username/password
      - クラスタ管理者またはSVM管理者のクレデンシャル
      - 今回SVM管理者を設定: vsadmin/netapp123

編集後は以下の通りとなります。
疎通が取れないIPを設定するとtridentデプロイが失敗します。

.. code-block:: console

    $ vi setup/backend.json
    $ cat setup/backend.json

    {
        "version": 1,
        "storageDriverName": "ontap-nas",
        "managementLIF": "192.168.XX.200",
        "dataLIF": "192.168.XX.200",
        "svm": "svmXX",
        "username": "vsadmin",
        "password": "netapp123"
    }
    $ ./install_trident.sh -n trident


インストールの進捗を確認します。

.. code-block:: console

    $ kubectl get pod -n trident

    NAME                READY     STATUS    RESTARTS   AGE
    trident-ephemeral   1/1       Running   0          58s


上記の状態で止まってしまう場合は、 ``trident-installer/`` 配下に ``tridentctl`` というtridentのコマンドラインユーティリティが同梱されています。
このツールを使って状況を確認します。

tridentctlはパスの通った場所に配置します。

.. code-block:: console

    $ sudo cp tridentctl /usr/local/bin

以下のようにtridentに関するログをまとめて確認することが出来るようになります。

.. code-block:: console

    $ tridentctl -n trident logs

    time="2018-02-15T03:32:35Z" level=error msg="API invocation failed. Post https://10.0.1.146/servlets/netapp.servlets.admin.XMLrequest_filer: dial tcp 10.0.1.146:443: getsockopt: connection timed out"
    time="2018-02-15T03:32:35Z" level=error msg="Problem initializing storage driver: 'ontap-nas' error: Error initializing ontap-nas driver. Could not determine Data ONTAP API version. Could not read ONTAPI version. Post https://10.0.1.146/servlets/netapp.servlets.admin.XMLrequest_filer: dial tcp 10.0.1.146:443: getsockopt: connection timed out" backend= handler=AddBackend
    time="2018-02-15T03:32:35Z" level=info msg="API server REST call." duration=2m10.64501326s method=POST route=AddBackend uri=/trident/v1/backend


Tridentへバックエンドストレージの登録
=============================================================

インストールが完了したことを以下のコマンドで確認します。

.. code-block:: console

    $ tridentctl -n trident version

    +----------------+----------------+
    | SERVER VERSION | CLIENT VERSION |
    +----------------+----------------+
    | 18.01.0        | 18.01.0        |
    +----------------+----------------+

バージョンが表示されていればインストール成功です。
作成した ``setup/backend.json`` を指定し作成します。

.. code-block:: console

    $ ./tridentctl -n trident create backend -f setup/backend.json

    +-------------------------+----------------+--------+---------+
    |          NAME           | STORAGE DRIVER | ONLINE | VOLUMES |
    +-------------------------+----------------+--------+---------+
    | ontapnas_192.168.10.200 | ontap-nas      | true   |       0 |
    +-------------------------+----------------+--------+---------+

