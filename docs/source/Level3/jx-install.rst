Jenkins XというKubernets上でのCI/CDに特化したJenkinsが発表されました。
2018/3に発表されたため、まだ新しいものとなります。

`Jenkins X <http://jenkins-x.io/>`_

jxコマンドをインストールし、jxコマンドでJenkinxXをインストールする流れになります。

jx コマンドのダウンロード&インストール::

    $ curl -L https://github.com/jenkins-x/jx/releases/download/v1.1.10/jx-linux-amd64.tar.gz | tar xzv
    $ sudo mv jx /usr/local/bin

Jenkins Xインストール::

    $ sudo jx install

上記コマンドを実行すると、プロバイダーの選択になるので 「kubernetes」を選択


しばらくするとインストールが完了します。



