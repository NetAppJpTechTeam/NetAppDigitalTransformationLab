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

バイナリをダウンロードしてインストールします。(例はバージョン19.01)
Tridentのメタデータの保存先を定義した ``setup/backend.json`` を編集します。

.. code-block:: console

    $ wget https://github.com/NetApp/trident/releases/download/v19.01.0/trident-installer-19.01.0.tar.gz

    $ tar -xf trident-installer-19.01.0.tar.gz

    $ cd trident-installer

    $ cp sample-input/backend-ontap-nas.json setup/backend.json

.. list-table:: backend.jsonの設定パラメータ (NFS ONTAPバックエンド)
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
      - SVM管理者を設定: vsadmin/netapp123

「XX」はユーザ環境番号になります。

編集後は以下の通りとなります。
疎通が取れないIPを設定するとtridentデプロイが失敗します。

.. code-block:: console

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

``tridentctl`` ユーティリティではドライランモードとデバッグモードがオプションで指定できます。
２つを設定し、実行すると以下のように必要事項を事前チェックし、その内容をすべて標準出力にプリントします。

まずは、ドライランモードで実行し問題ないことを確認します。以下の出力結果はユーザ14で実施した場合です。

.. code-block:: console

    $ kubectl create ns trident
    $ ./tridentctl install --dry-run -n trident -d

    DEBU Initialized logging.                          logLevel=debug
    DEBU Running outside a pod, creating CLI-based client.
    DEBU Initialized Kubernetes CLI client.            cli=kubectl flavor=k8s namespace=default version=1.11.0
    DEBU Validated installation environment.           installationNamespace=trident kubernetesVersion=
    DEBU Parsed requested volume size.                 quantity=2Gi
    DEBU Dumping RBAC fields.                          ucpBearerToken= ucpHost= useKubernetesRBAC=true
    DEBU Namespace does not exist.                     namespace=trident
    DEBU PVC does not exist.                           pvc=trident
    DEBU PV does not exist.                            pv=trident
    - snip
    INFO Dry run completed, no problems found.

ドライランモードで実施すると最後に問題ない旨(INFO Dry run completed, no problems found.) が表示されれば、インストールに必要な事前要件を満たしていることが確認できます。

上記の状態まで確認できたら実際にインストールを実施します。

.. code-block:: console

    $ ./tridentctl install -n trident -d

    DEBU Initialized logging.                          logLevel=debug
    DEBU Running outside a pod, creating CLI-based client.
    DEBU Initialized Kubernetes CLI client.            cli=kubectl flavor=k8s namespace=default version=1.11.0
    DEBU Validated installation environment.           installationNamespace=trident kubernetesVersion=
    DEBU Parsed requested volume size.                 quantity=2Gi
    DEBU Dumping RBAC fields.                          ucpBearerToken= ucpHost= useKubernetesRBAC=true
    DEBU Namespace does not exist.                     namespace=trident
    DEBU PVC does not exist.                           pvc=trident
    DEBU PV does not exist.                            pv=trident
    - snip
    INFO Trident installation succeeded.

「INFO Trident installation succeeded.」が出力されればインストール成功です。

また、問題が発生した場合には ``tridentctl`` を使用してtridentに関するログをまとめて確認することが出来ます。

.. code-block:: console

    $ ./tridentctl -n trident logs

    time="2018-02-15T03:32:35Z" level=error msg="API invocation failed. Post https://10.0.1.146/servlets/netapp.servlets.admin.XMLrequest_filer: dial tcp 10.0.1.146:443: getsockopt: connection timed out"
    time="2018-02-15T03:32:35Z" level=error msg="Problem initializing storage driver: 'ontap-nas' error: Error initializing ontap-nas driver. Could not determine Data ONTAP API version. Could not read ONTAPI version. Post https://10.0.1.146/servlets/netapp.servlets.admin.XMLrequest_filer: dial tcp 10.0.1.146:443: getsockopt: connection timed out" backend= handler=AddBackend
    time="2018-02-15T03:32:35Z" level=info msg="API server REST call." duration=2m10.64501326s method=POST route=AddBackend uri=/trident/v1/backend


Tridentへバックエンドストレージの登録
=============================================================

インストールが完了したらtridentのバージョンを確認します。

.. code-block:: consile

    $ ./tridentctl  version -n trident

    +----------------+----------------+
    | SERVER VERSION | CLIENT VERSION |
    +----------------+----------------+
    | 19.01.0        | 19.01.0        |
    +----------------+----------------+

バージョンが表示されていればインストール成功です。

Trident 19.01 からはこれまでと挙動が変わっており、Tridentのメタデータ保存先をバックエンドストレージとして登録されます。

.. code-block:: console

    $ ./tridentctl -n trident create backend -f setup/backend.json

    +-------------------+----------------+--------+---------+
    |       NAME        | STORAGE DRIVER | ONLINE | VOLUMES |
    +-------------------+----------------+--------+---------+
    | NFS_ONTAP_Backend | ontap-nas      | true   |       0 |
    +-------------------+----------------+--------+---------+

つづいて、iSCSI ブロック・ストレージバックエンドのSolidFireを登録します。

NFSバックエンドストレージと同様に ``setup`` ディレクトリに ``solidfire-backend.json`` を作成します。

基本的な設定項目としては以下の表の通りです。

.. list-table:: solidfire-backend.jsonの設定パラメータ (iSCSI SolidFire バックエンド)
    :header-rows: 1

    * - パラメータ名
      - 説明
      - 設定内容
    * - Endpoint
      - SolidFire の管理用IPを設定(MVIP)、URL先頭にユーザーIDとパスワードを付与
      - 10.128.223.240
    * - SVIP
      - データ通信のIPを設定（クラスタで１つ）
      - 192.168.0.240:3260
    * - TenantName
      - 任意の名称を設定、SolidFire側でのテナントとなる。
      - 今回は環境番号とする(userXX)
    * - Types
      - ストレージカタログとしてのQoSのリストを指定
      - 1つ以上のminIOPS, maxIOPS, burstIOPSを指定


テンプレートとなるSolidFireのバックエンド定義ファイルは以下の通りです。

.. code-block:: json

    {
        "version": 1,
        "storageDriverName": "solidfire-san",
        "Endpoint": "https://ユーザ名:パスワード@マネジメント用IP/json-rpc/8.0",
        "SVIP": "ストレージアクセス用IP:3260",
        "TenantName": "ユーザ環境番号",
        "backendName": "iSCSI_SF_Backend",
        "InitiatorIFace": "default",
        "UseCHAP": true,
        "Types": [
            {
                "Type": "Bronze",
                "Qos": {
                    "minIOPS": 1000,
                    "maxIOPS": 3999,
                    "burstIOPS": 4500
                }
            },
            {
                "Type": "Silver",
                "Qos": {
                    "minIOPS": 4000,
                    "maxIOPS": 5999,
                    "burstIOPS": 6500
                }
            },
            {
                "Type": "Gold",
                "Qos": {
                    "minIOPS": 6000,
                    "maxIOPS": 8000,
                    "burstIOPS": 10000
                }
            }
        ]
    }



同様にバックエンド登録を実施します。

.. code-block:: console

    $ ./tridentctl -n trident create backend -f setup/solidfire-backend.json

    +------------------+----------------+--------+---------+
    |       NAME       | STORAGE DRIVER | ONLINE | VOLUMES |
    +------------------+----------------+--------+---------+
    | iSCSI_SF_Backend | solidfire-san  | true   |       0 |
    +------------------+----------------+--------+---------+

今までに登録したストレージバックエンドを確認します。

.. code-block:: console

    $ ./tridentctl get backend -n trident

    +-------------------+----------------+--------+---------+
    |       NAME        | STORAGE DRIVER | ONLINE | VOLUMES |
    +-------------------+----------------+--------+---------+
    | NFS_ONTAP_Backend | ontap-nas      | true   |       0 |
    | iSCSI_SF_Backend  | solidfire-san  | true   |       0 |
    +-------------------+----------------+--------+---------+

.. note::

    （Troubleshooting) Tridentをアンインストールする
    =============================================================

    ``tridentctl`` ユーティリティにはアンインストール用のサブコマンドがあります。

    以下のように ``-a`` オプションを付与して実行すると生成した管理用のetcdのデータなどすべてを削除した上でアンインストールします。
    インストール実行時に失敗したときなど、クリーンに再インストールしたい場合に使います。

    .. code-block:: console

        $ ./tridentctl uninstall -n trident -a
