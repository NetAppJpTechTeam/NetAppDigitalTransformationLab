:orphan:

==============================================================
サンプル: Dockerfile記述例
==============================================================

ここでは始めの一歩として簡単なWebサーバを起動するコンテナとアプリケーションサーバ、
MySQLの例を記載します。 docker-composeファイルをサンプルとしてみます

オリジナルでイメージを作成するコンテナはDockerfileを確認ください。

.. literalinclude:: JHipsterSamples/app.yml
   :language: yaml
   :caption: アプリケーションをデプロイする定義ファイルの例 app.yml

.. literalinclude:: JHipsterSamples/Dockerfile
   :language: dockerfile
   :caption: アプリケーションのコンテナイメージを作成するDockerfileの例 Dockerfile

.. literalinclude:: JHipsterSamples/elasticsearch.yml
   :language: yaml
   :caption: ElasticSearchをデプロイする定義ファイルの例 elasticsearch.yml

.. literalinclude:: JHipsterSamples/mysql.yml
   :language: yaml
   :caption: MySQLをデプロイする定義ファイルの例 mysql.yaml

.. literalinclude:: JHipsterSamples/sonar.yml
   :language: yaml
   :caption: sonarをデプロイする定義ファイルの例 sonar.yaml




