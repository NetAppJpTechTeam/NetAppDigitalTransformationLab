

オリジナルのyamlを記述しJenkinsをデプロイする方法です。

Level1,2で習得した内容でデプロイすることが可能です。
全体のフローとしては以下の通りです。

#. 外部公開用にIngress、Service(typeはNodePortで作成）を作成
#. Deploymentの定義
#. 永続化するためのPersistentVolumeClaimの定義

上記を記述してデプロイします。 ::

    $ kubectl create -f jenkins.yaml

以下がサンプルのyamlです。

.. todo:: jenkinsのyaml作成

.. literalinclude:: resources/jenkins.yaml
    :language: yaml
    :caption: Jenkinsデプロイ用定義ファイルの例 jenkins.yaml

