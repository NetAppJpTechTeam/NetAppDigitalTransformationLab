Gitリポジトリに変更があったら自動でテストを実行するpipelineを定義します。
そのためにはまずJenkinsでGitリポジトリに操作があった場合の動作の定義とKubernetesとの接続の設定をします。

定義出来る動作としては以下の単位が考えられます。
細かく設定することも可能です。運用に合わせた単位で設定します。

* pull request 単位
* release tag 単位
* 定期実行

前述した項目を盛り込みCI/CDパイプラインを作成しましょう。
シンプルなパイプラインからはじめ、必要に応じてステージを追加していきましょう。

Jenkins AgentをKubernetes上で実行できるようにする
-------------------------------------------------------------

Jenkinsからkubernetes上でJenkins agentを実行する場合にはJenkins kubernetes-plugin の導入が必要です。
通常はソースコードの取得から実施することになります。gitを使う場合であればgitのjenkins-pluginが必要です。

本ガイドで準備した values.yaml を使用している場合にはすでにどちらも導入されている状態となります。

ここでは Jenkins から kubernetesへ接続できるようにする設定を提示いたします。

Jeninsログイン後、クレデンシャルを事前に作成します。

.. image:: resources/Kubernetes-Credentials.jpg

jenkins 導入済みのネームスペースにサービスアカウントを作成します。

.. code-block:: console

        kubectl create clusterrolebinding jenkins --clusterrole cluster-admin --serviceaccount=jenkins:default

Configurationから「Kubernetes設定」を選択します。

.. image:: resources/jenkins-configuration.jpg

ここでは必要となるパラメータを設定していきます。

- kubernetes URL: マスタのIP, 192.168.XX.10
- Kubernetes Namespace: Jenkinsをインストールしたnamespace名
- kubernetes certificate key: /etc/kubernetes/pki/apiserver.crtの内容をペースト
- Credentials: Secret を選択



