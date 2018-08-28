=========================================
Helmで監視システムを簡単デプロイ
=========================================

監視システムの概要
========================================

今回挑戦する監視システムの中身は以下の通りです。

* フロントエンドにはGrafana
* データを蓄積するところはPrometheusを使用
* データを収集するところはnodeExporterを使用

Helmを使うことで、簡単にデプロイができすぐにkubernetesクラスタの監視が可能になります。
Grafanaで可視化のダッシュボードは提供されますが、デフォルトのままだと足りないと思われるかもしれません。

その場合はGrafanaLabでダッシュボードが公開されているので、参照しデプロイ後に追加したり、デプロイ時にダッシュボードが自動で追加されるようカスタマイズしてみましょう。

- https://grafana.com/dashboards

Helm Chartを選定する
========================================

Prometheusの導入
-----------------------------------------
values.yamlは以下のURLに公開されています。

本ラボではこれまでと同様に ``persistent`` を適切なものに変更します。

- https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml

helmコマンドで導入しましょう。

.. code-block:: console

    $ helm install stable/prometheus --version x.x.x --name prometheus

Grafanaの導入
-----------------------------------------

Prometheusを導入したら今度はデータを可視化するためGrafanaを導入します。
Grafanaも同様にHelm Chartで導入しましょう。

Grafanaを外部公開するために ``Service`` を作成しましょう。

helmでインストールできるよう ``Prometheus`` と同様にvalues.yamlを以下のサイトを参考にし作成しましょう。

- valuesファイル: https://github.com/helm/charts/blob/master/stable/grafana/values.yaml
- valuesファイルのパラメータ説明: https://github.com/helm/charts/tree/master/stable/grafana#configuration

.. code-block: console

    $ helm install --name grafana stable/grafana --version 1.11.6 -f grafana-values.yaml
    $ kubectl create -f grafana-service.yaml

.. note::

    Rancherのアプリケーションカタログを使用するとより簡単にデプロイが可能です。
    今回はPrometheusとGrafanaを別々に導入しましたが、Rancherのカタログ上には1つにまとめたものが存在し、
    デプロイ時にパラメータを設定することでまとめてデプロイが可能になっています。
