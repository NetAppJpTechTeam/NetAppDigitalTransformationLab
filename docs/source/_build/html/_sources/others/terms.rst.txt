
**このドキュメントは整備中です。**

=============================================================
用語集
=============================================================

本ラボで出てくる単語集です。

おもにk8s関連の用語になります。
(version1.9時点)


.. list-table:: kubernetes、ネットアップの用語集
    :header-rows: 1

    * - 用語
      - 略称
      - 分類
      - 説明
    * - Deployment
      - deploy
      - kubernetes
      - アプリケーションをデプロイする時に使うもの。デプロイの管理やレプリカの管理を行う。
    * - Service
      - svc
      - kubernetes
      - アプリケーションをkubernetesクラスタ外に公開するときに使用する。
    * - Ingress
      - ing
      - kubernetes
      - アプリケーションをkubernetesクラスタ外に公開するときに使用する。Serviceとの違いはIngressは、Serviceの前段に配置されServiceへのアクセスルールを定義する。
    * - NodePort
      - 特になし
      - kubernetes
      - アプリケーションをkubernetesクラスタ外に公開するときに使用する。各k8sノードでポートを解放しアクセスできるようする。接続したノードにポッドがなければ適切なノードに転送してアクセス可能にする。
    * - LoadBalancer
      - 特になし
      - kubernetes
      - アプリケーションをkubernetesクラスタ外に公開するときに使用する。デプロイ時にロードバランサーサービスに自動登録します。クラウドサービス、オンプレミスでは一部のプラットフォームで対応しています。
    * - ClusterIP
      - 特になし
      - kubernetes
      - アプリケーションをkubernetesクラスタ内に公開するときに使用する。

* Pod
* PersistentVolume
* PersistentVolumeClaim
* StorageClass
* Provisioner
* DevicePlugin
* ContainerStorageInterface(CSI)
* ContainerNetworkInterface(CNI)
* ConfigMap
* Secret


NetApp用語

* StorageVirtualMachine(SVM)
* Logical interface(LIF)
* vsadmin SVM管理者
