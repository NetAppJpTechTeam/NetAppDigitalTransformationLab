:orphan:

Trident のインストールでk8sクラスタの管理者権限が必要になります。 ::

    kubectl auth can-i '*' '*' --all-namespaces

バックエンドに登録するマネジメントIPにk8sクラスタのコンテナから疎通が取れるかを確認します。 ::

    kubectl run -i --tty ping --image=busybox --restart=Never --rm --  ping [ipアドレス]


