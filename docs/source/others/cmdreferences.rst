=============================================================
コマンドリファレンス
=============================================================


kubectlの使い方
==============================================================

https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/

状況確認
--------------------------------------------------------------

- kubectl get po
- kubectl get svc
- kubectl get deployment
- kubectl get ing


ネームスペースを考慮したコマンド
``-n`` オプション、または ``--namespace``で全ネームスペースのオブジェクトを確認できます。

.. code-block:: console

    $ kubectl get all -n ネームスペース名


デプロイメントの構成ファイルを使用している場合

- kubectl get -f deployment.yaml
- kubectl get




デプロイメントの実行
--------------------------------------------------------------

kubectl create/apply/patch

kubectl create -f deployment.yaml

トラブルシュート
--------------------------------------------------------------

kubectl describe オブジェクト名
kubectl describe -f deployment.yaml


Gitの使い方
==============================================================