=============================================================
Kubernetes クラスタの操作性を向上させる
=============================================================

Rancher でできること
=============================================================

RancherはブラウザーのUIを通したグラフィカルなインターフェースを持っており、様々な環境のkubernetesクラスタを管理するとともに、コンテナーの管理、アプリケーションの管理も行うことができます。ここでいうアプリケーションは kubernetes 上で動くものすべてです。

Rancherの機能については、以下のサイトからご確認ください。

Your Enterprise Kubernetes Platform | Rancher Labs
https://rancher.com/

ここではRancherの導入から、アプリケーションのデプロイを実施します。
アプリケーションとして、kubernetes クラスタを監視するソフトウェアスタック(Prometheus+Grafana）をkubernetes上で簡単に起動してみます。

Rancher を導入する
=============================================================

dockerをインストールする
------------------------

Rancherの導入には、Dockerコマンドを利用します。もし、Dockerをインストールしていない場合にはDockerをインストールします。

Rancherに必要なDockerのバージョンは、以下のURLに書いてあります。
https://rancher.com/docs/rancher/v2.x/en/installation/requirements/

* 1.12.6
* 1.13.1
* 17.03.2

となっていますが、18.06.01 でも動いています。今回は、18.06を使います。

インストール方法は、

.. code-block:: console

  curl https://releases.rancher.com/install-docker/18.06.sh | sh

でインストールしてください。

Rancherをインストールする
------------------------------------

次にRancherをインストールします。

以下のDockerHubのタグでv2.x系の最新のバージョンを確認してください。。

  https://hub.docker.com/r/rancher/rancher/tags/

今回は、v2.2.6 をインストールします。

.. code-block:: console

    docker run -d --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    rancher/rancher:v2.2.6


Rancher へログイン
------------------------------------

上記のRancherをインストールしたホストのIPアドレスでブラウザーを開くと以下のような画面が表示されます。

.. image:: resources/Login.png
    :scale: 50%
    :width: 1223px
    :height: 843px

パスワードを指定するか、ランダムのパスワードを生成して **Continue** を押します。

Kubernetes クラスターのインポート
=============================================================

次に、作っておいた Kubernetesクラスターを Rancherから認識できるようにインポートします。
Globalから **Add Cluster** ボタンを押します。

.. image:: resources/Add-Cluster-Dashboard.png
    :scale: 50%
    :width: 1223px
    :height: 843px

クラスター追加画面が出てきますが、右上の **IMPORT** ボタンを押します。

.. image:: resources/Import-Cluster.png
    :scale: 50%
    :width: 1223px
    :height: 843px

次に、Cluster Nameを指定して **Create** ボタンを押します(Memberは自分一人で使う分には追加する必要はありません)。

.. image:: resources/Set-ClusterName.png
    :scale: 50%
    :width: 1205px
    :height: 482px

以下のページで表示されたコマンドを実行します。
kubectlコマンドは事前にインストールし、kubernetesに接続できるよう設定しておいてください。

.. image:: resources/Import-command.png
    :scale: 50%
    :width: 1223px
    :height: 908px

.. code-block:: console

    kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user [USER_ACCOUNT]

上記の [USER_ACCOUNT] は上記コマンドを実行するユーザーIDを指定します。

.. code-block:: console

    kubectl apply -f https://xxxxxxxxxxxxxx.com/v3/import/XXXXXXXXXXXXXXXXXXXXXXXXX.yaml

上記のコマンドで証明書の問題のエラーが発生する場合は、以下のコマンドを実行して下さい。

.. code-block:: console

    curl --insecure -sfL https://xxxxxxxxxxxxxx.com/v3/import/XXXXXXXXXXXXXXXXXXXXXXXXX.yaml | kubectl apply -f -

KubernetesクラスターがRancherにインポートされると以下のようにGlobalのClusterダッシュボードにインポートされたクラスターが表示されます。

.. image:: resources/cluster-list.png
    :scale: 50%
    :width: 1050px
    :height: 600px

アプリケーションをデプロイ
=============================================================

Prometheus+Grafanaのデプロイする
------------------------------------------------------------

上記、クラスターがインポートされた状態でPrometheus+Grafanaをデプロイしてみましょう。
まず、インポートされたKubernetesクラスターのDefaultネームスペースに切り換えます。

.. image:: resources/change-name-default.png
    :scale: 50%
    :width: 1131px
    :height: 862px

**Global** を押してドロップダウンしたメニューの **Default** をクリックします。
ワークロードのダッシュボード画面に切り替わります。

.. image:: resources/cluster-default-dashboard.png
    :scale: 50%
    :width: 1152px
    :height: 843px

この画面の **Catalog Apps** をクリックします。

.. image:: resources/CatalogApp-list.png
    :scale: 50%
    :width: 1198px
    :height: 806px

カタログリストから 右側の Search 検索ボックスに ``Prometheus`` を入力します。

.. image:: resources/CatalogApp-Prometheus.png
    :scale: 50%
    :width: 1223px
    :height: 843px

**View Details** をクリックします。
様々な設定項目がありますが、``Grafana Admin Password`` だけ任意のパスワード入力します。

.. image:: resources/Settings-Prometheus-Grafana.png
    :scale: 50%
    :width: 1223px
    :height: 843px

デプロイが開始されると以下のような画面になります。

.. image:: resources/Deployed-Prometheus.png
    :scale: 50%
    :width: 1223px
    :height: 843px

Prometheusをクリックします。

.. image:: resources/Prometheus-Details.png
    :scale: 50%
    :width: 1223px
    :height: 4278px

上記の ``Workloads`` を確認します。

.. image:: resources/Workloads-prometheus.png
    :scale: 50%
    :width: 1155px
    :height: 549px

**prometheus-grafana** の80/http をクリックします。

.. image:: resources/Grafana-Dashboard.png
    :scale: 50%
    :width: 1223px
    :height: 843px

画面が表示されれば正常にデプロイされています。
