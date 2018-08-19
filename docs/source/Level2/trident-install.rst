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

バイナリをダウンロードしてインストールします。(例はバージョン18.07)
バックエンドストレージのための ``setup/backend.json`` を編集します。

.. code-block:: console

    $ wget https://github.com/NetApp/trident/releases/download/v18.07.0/trident-installer-18.07.0.tar.gz

    $ tar xzf trident*.tar.gz && cd trident-installer

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
    INFO Starting storage driver.                      backend=/home/localadmin/manifest/trident/trident-installer/setup/backend.json
    DEBU config: {"backendName":"NFS_ONTAP_Backend","dataLIF":"192.168.14.200","managementLIF":"192.168.14.200","password":"netapp123","storageDriverName":"ontap-nas","svm":"svm14","username":"vsadmin","version":1}
    DEBU Storage prefix is absent, will use default prefix.
    DEBU Parsed commonConfig: {Version:1 StorageDriverName:ontap-nas BackendName:NFS_ONTAP_Backend Debug:false DebugTraceFlags:map[] DisableDelete:false StoragePrefixRaw:[] StoragePrefix:<nil> SerialNumbers:[] DriverContext:}
    DEBU Initializing storage driver.                  driver=ontap-nas
    DEBU Addresses found from ManagementLIF lookup.    addresses="[192.168.14.200]" hostname=192.168.14.200
    DEBU Using specified SVM.                          SVM=svm14
    DEBU ONTAP API version.                            Ontapi=1.130
    WARN Could not determine controller serial numbers. API status: failed, Reason: Unable to find API: system-node-get-iter, Code: 13005
    DEBU Configuration defaults                        Encryption=false ExportPolicy=default FileSystemType=ext4 NfsMountOptions="-o nfsvers=3" SecurityStyle=unix Size=1G SnapshotDir=false SnapshotPolicy=none SpaceReserve=none SplitOnClone=false StoragePrefix=trident_ UnixPermissions=---rwxrwxrwx
    DEBU Data LIFs                                     dataLIFs="[192.168.14.200]"
    DEBU Found NAS LIFs.                               dataLIFs="[192.168.14.200]"
    DEBU Addresses found from hostname lookup.         addresses="[192.168.14.200]" hostname=192.168.14.200
    DEBU Found matching Data LIF.                      hostNameAddress=192.168.14.200
    DEBU Configured EMS heartbeat.                     intervalHours=24
    DEBU Read storage pools assigned to SVM.           pools="[aggr1_01 aggr2_01]" svm=svm14
    DEBU Read aggregate attributes.                    aggregate=aggr1_01 mediaType=ssd
    DEBU Read aggregate attributes.                    aggregate=aggr2_01 mediaType=hdd
    DEBU Storage driver initialized.                   driver=ontap-nas
    INFO Storage driver loaded.                        driver=ontap-nas
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
    INFO Starting storage driver.                      backend=/home/localadmin/manifest/trident/trident-installer/setup/backend.json
    DEBU config: {"backendName":"NFS_ONTAP_Backend","dataLIF":"192.168.14.200","managementLIF":"192.168.14.200","password":"netapp123","storageDriverName":"ontap-nas","svm":"svm14","username":"vsadmin","version":1}
    DEBU Storage prefix is absent, will use default prefix.
    DEBU Parsed commonConfig: {Version:1 StorageDriverName:ontap-nas BackendName:NFS_ONTAP_Backend Debug:false DebugTraceFlags:map[] DisableDelete:false StoragePrefixRaw:[] StoragePrefix:<nil> SerialNumbers:[] DriverContext:}
    DEBU Initializing storage driver.                  driver=ontap-nas
    DEBU Addresses found from ManagementLIF lookup.    addresses="[192.168.14.200]" hostname=192.168.14.200
    DEBU Using specified SVM.                          SVM=svm14
    DEBU ONTAP API version.                            Ontapi=1.130
    WARN Could not determine controller serial numbers. API status: failed, Reason: Unable to find API: system-node-get-iter, Code: 13005
    DEBU Configuration defaults                        Encryption=false ExportPolicy=default FileSystemType=ext4 NfsMountOptions="-o nfsvers=3" SecurityStyle=unix Size=1G SnapshotDir=false SnapshotPolicy=none SpaceReserve=none SplitOnClone=false StoragePrefix=trident_ UnixPermissions=---rwxrwxrwx
    DEBU Data LIFs                                     dataLIFs="[192.168.14.200]"
    DEBU Found NAS LIFs.                               dataLIFs="[192.168.14.200]"
    DEBU Addresses found from hostname lookup.         addresses="[192.168.14.200]" hostname=192.168.14.200
    DEBU Found matching Data LIF.                      hostNameAddress=192.168.14.200
    DEBU Configured EMS heartbeat.                     intervalHours=24
    DEBU Read storage pools assigned to SVM.           pools="[aggr1_01 aggr2_01]" svm=svm14
    DEBU Read aggregate attributes.                    aggregate=aggr1_01 mediaType=ssd
    DEBU Read aggregate attributes.                    aggregate=aggr2_01 mediaType=hdd
    DEBU Storage driver initialized.                   driver=ontap-nas
    INFO Storage driver loaded.                        driver=ontap-nas
    INFO Starting Trident installation.                namespace=trident
    DEBU Created Kubernetes object by YAML.
    INFO Created namespace.                            namespace=trident
    DEBU Deleted Kubernetes object by YAML.
    DEBU Deleted cluster role binding.
    DEBU Deleted Kubernetes object by YAML.
    DEBU Deleted cluster role.
    DEBU Deleted Kubernetes object by YAML.
    DEBU Deleted service account.
    DEBU Created Kubernetes object by YAML.
    INFO Created service account.
    DEBU Created Kubernetes object by YAML.
    INFO Created cluster role.
    DEBU Created Kubernetes object by YAML.
    INFO Created cluster role binding.
    DEBU Created Kubernetes object by YAML.
    INFO Created PVC.
    DEBU Attempting volume create.                     size=2147483648 storagePool=aggr1_01 volConfig.StorageClass=
    DEBU Creating Flexvol.                             aggregate=aggr1_01 encryption=false exportPolicy=default name=trident_trident securityStyle=unix size=2147483648 snapshotDir=false snapshotPolicy=none snapshotReserve=0 spaceReserve=none unixPermissions=---rwxrwxrwx
    DEBU SVM root volume has no load-sharing mirrors.  rootVolume=svm_root
    DEBU Created Kubernetes object by YAML.
    INFO Created PV.                                   pv=trident
    INFO Waiting for PVC to be bound.                  pvc=trident
    DEBU PVC not yet bound, waiting.                   increment=282.430263ms pvc=trident
    DEBU PVC not yet bound, waiting.                   increment=907.038791ms pvc=trident
    DEBU PVC not yet bound, waiting.                   increment=1.497234254s pvc=trident
    DEBU PVC not yet bound, waiting.                   increment=1.182346358s pvc=trident
    DEBU PVC not yet bound, waiting.                   increment=3.794274009s pvc=trident
    DEBU Logged EMS message.                           driver=ontap-nas
    DEBU PVC not yet bound, waiting.                   increment=2.554707984s pvc=trident
    DEBU Created Kubernetes object by YAML.
    INFO Created Trident deployment.
    INFO Waiting for Trident pod to start.
    DEBU Trident pod not yet running, waiting.         increment=481.632837ms
    DEBU Trident pod not yet running, waiting.         increment=848.840617ms
    DEBU Trident pod not yet running, waiting.         increment=1.171028148s
    DEBU Trident pod not yet running, waiting.         increment=871.68468ms
    DEBU Trident pod not yet running, waiting.         increment=2.784723303s
    DEBU Trident pod not yet running, waiting.         increment=3.037298468s
    DEBU Trident pod not yet running, waiting.         increment=7.540652793s
    DEBU Trident pod not yet running, waiting.         increment=12.611925219s
    DEBU Trident pod not yet running, waiting.         increment=18.389729895s
    INFO Trident pod started.                          namespace=trident pod=trident-6946fdf6d8-8cb8q
    INFO Waiting for Trident REST interface.
    DEBU Invoking tunneled command: kubectl exec trident-6946fdf6d8-8cb8q -n trident -c trident-main -- tridentctl -s 127.0.0.1:8000 version -o json
    INFO Trident REST interface is up.                 version=18.07.0
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
    | 18.07.0        | 18.07.0        |
    +----------------+----------------+

バージョンが表示されていればインストール成功です。
作成した定義ファイル、 ``setup/backend.json`` を使用し、バックエンド登録を実行します。
まずは NFS ストレージバックエンドであるONTAPを登録します。

.. code-block:: console

    $ ./tridentctl -n trident create backend -f setup/backend.json

    +-------------------+----------------+--------+---------+
    |       NAME        | STORAGE DRIVER | ONLINE | VOLUMES |
    +-------------------+----------------+--------+---------+
    | NFS_ONTAP_Backend | ontap-nas      | true   |       0 |
    +-------------------+----------------+--------+---------+

つづいて、iSCSI ブロック・ストレージバックエンドのSolidFireを登録します。

NFSバックエンドストレージと同様に ``setup`` ディレクトリに ``solidfire-backend.json`` を作成します。

基本的な設定項目としては以下の表野通りです。

.. todo:: MVIPのIP確認

.. list-table:: solidfire-backend.jsonの設定パラメータ (iSCSI SolidFire バックエンド)
    :header-rows: 1

    * - パラメータ名
      - 説明
      - 設定内容
    * - Endpoint
      - SolidFire の管理用IPを設定(MVIP)、URL先頭にユーザーIDとパスワードを付与
      - 別途記載
    * - SVIP
      - データ通信のIPを設定（クラスタで１つ）
      - 192.168.0.240:3260
    * - TenantName
      - 任意の名称を設定、SolidFire側でのテナントとなる。
      - 今回は環境番号とする(userXX)
    * - Types
      - ストレージカタログとしてのQoSのリストを指定
      - 1つ以上のminIOPS, maxIOPS, burstIOPSを指定


.. code-block:: json solidfire-backend.json

    {
        "version": 1,
        "storageDriverName": "solidfire-san",
        "Endpoint": "https://admin:netapp123@10.128.223.240/json-rpc/8.0",
        "SVIP": "192.168.0.240:3260",
        "TenantName": "user14",
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
