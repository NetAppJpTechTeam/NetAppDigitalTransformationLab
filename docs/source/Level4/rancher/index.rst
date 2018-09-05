Rancher でできること
------------------------

Rancherは様々な環境のkubernetesクラスタを管理するとともに、アプリケーションの管理も行うことができます。

ここではRancherの導入から、アプリケーションのデプロイまでを簡単に実施します。

ここでいうアプリケーションとは kubernetes 上で動くものすべてです。

例えば、kubernetes クラスタを監視するソフトウェアスタック(Prometheus+Grafana+InfluxDB）をkubernetes上で簡単に起動することが可能です。

Rancher を導入する
------------------------

dockerをインストールする
^^^^^^^^^^^^^^^^^^^^^^

Rancherの導入には、Dockerコマンドを利用します。もし、Dockerをインストールしていない場合にはDockerをインストールします。

Rancherに必要なDockerのバージョンは、以下のURLに書いてあります。
https://rancher.com/docs/rancher/v2.x/en/installation/requirements/

* 1.12.6
* 1.13.1
* 17.03.2
となっていますが、18.06.01 でも動いています。今回は、18.06を使います。

インストール方法は、

.. code-block:: none 

  curl https://releases.rancher.com/install-docker/18.06.sh | sh

でインストールしてください。

Rancherをインストールする
^^^^^^^^^^^^^^^^^^^^^^^

次にRancherをインストールします。

以下のDockerHubのタグでv2.x系の最新のバージョンを確認してください。。

  https://hub.docker.com/r/rancher/rancher/tags/

今回は、v2.0.8 をインストールします。

.. code-block:: none 

    docker run -d --restart=unless-stopped \
    -p 80:80 -p 443:443 \
    rancher/rancher:v2.0.8


アプリケーションをデプロイ
------------------------

.. todo:: コンテンツ記載
