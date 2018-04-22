==============================================================
Ingressを導入する
==============================================================


Level1,2ではデプロイしたアプリケーションが配置されているノードのIPに対してアクセスして稼働を確認していました。
ここからは外部にアプリケーションを公開しアクセスする方法を使用します。

具体的にはServiceを定義する際に指定する「type」が複数提供されています。

#. ClusterIP
#. NodePort
#. LoadBalancer

- https://medium.com/@maniankara/kubernetes-tcp-load-balancer-service-on-premise-non-cloud-f85c9fd8f43c
- https://kubernetes.io/docs/concepts/services-networking/service/

今回はServiceのtypeをNodePortとして、Serviceの前段にIngressを配置する構成とします。
Ingressを使用してアプリケーションを外部に公開します。
IngressはL7ロードバランサーのような動きをします。


Ingress用のネームスペースを作成
==============================================================

Nginx Ingressをデプロイするネームスペースを作成します。

.. literalinclude:: resources/ingress/ingress-ns.yaml
        :language: yaml
        :caption: Nginx Ingressをデプロイするネームスペース用マニフェストファイル

以下のコマンドでネームスペースを作成します。

.. code-block:: console

   $ kubectl create -f ingress-ns.yaml

     namespace "ingress" created


Nginx Ingressのデプロイメント
==============================================================

helm chartを使ったNginx Ingressのデプロイメントです。

`--dry-run` を付与してhelmを実行することでドライランモードで実行することが可能です。

.. code-block:: console

    $ helm install stable/nginx-ingress --name nginx-ingress --set rbac.create=true --namespace ingress

    NAME:   nginx-ingress
    LAST DEPLOYED: Mon Apr  9 13:58:29 2018
    NAMESPACE: ingress
    STATUS: DEPLOYED

    RESOURCES:
    ==> v1/ServiceAccount
    NAME           SECRETS  AGE
    nginx-ingress  1        0s

    ==> v1beta1/ClusterRoleBinding
    NAME           AGE
    nginx-ingress  0s

    ==> v1beta1/Role
    NAME           AGE
    nginx-ingress  0s

    ==> v1beta1/RoleBinding
    NAME           AGE
    nginx-ingress  0s

    ==> v1/Service
    NAME                           TYPE          CLUSTER-IP     EXTERNAL-IP  PORT(S)                     AGE
    nginx-ingress-controller       LoadBalancer  10.96.106.165  <pending>    80:32065/TCP,443:32049/TCP  0s
    nginx-ingress-default-backend  ClusterIP     10.101.0.249   <none>       80/TCP                      0s

    ==> v1beta1/Deployment
    NAME                           DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
    nginx-ingress-controller       1        1        1           0          0s
    nginx-ingress-default-backend  1        1        1           0          0s

    ==> v1/ConfigMap
    NAME                      DATA  AGE
    nginx-ingress-controller  1     0s

    ==> v1beta1/PodDisruptionBudget
    NAME                           MIN AVAILABLE  MAX UNAVAILABLE  ALLOWED DISRUPTIONS  AGE
    nginx-ingress-controller       1              N/A              0                    0s
    nginx-ingress-default-backend  1              N/A              0                    0s

    ==> v1/Pod(related)
    NAME                                           READY  STATUS             RESTARTS  AGE
    nginx-ingress-controller-5475585cc9-q5ckc      0/1    ContainerCreating  0         0s
    nginx-ingress-default-backend-956f8bbff-5znnc  0/1    ContainerCreating  0         0s

    ==> v1beta1/ClusterRole
    NAME           AGE
    nginx-ingress  0s


    NOTES:
    The nginx-ingress controller has been installed.
    It may take a few minutes for the LoadBalancer IP to be available.
    You can watch the status by running 'kubectl --namespace ingress get services -o wide -w nginx-ingress-controller'

    An example Ingress that makes use of the controller:

      apiVersion: extensions/v1beta1
      kind: Ingress
      metadata:
        annotations:
          kubernetes.io/ingress.class: nginx
        name: example
        namespace: foo
      spec:
        rules:
          - host: www.example.com
            http:
              paths:
                - backend:
                    serviceName: exampleService
                    servicePort: 80
                  path: /
        # This section is only required if TLS is to be enabled for the Ingress
        tls:
            - hosts:
                - www.example.com
              secretName: example-tls

    If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

      apiVersion: v1
      kind: Secret
      metadata:
        name: example-tls
        namespace: foo
      data:
        tls.crt: <base64 encoded cert>
        tls.key: <base64 encoded key>
      type: kubernetes.io/tls


Ingressを作成するサンプルです。

.. literalinclude:: resources/ingress/ingress-controller.yaml
        :language: yaml
        :caption: L7ロードバランス的なもの


上記のマニフェストファイルをインプットとして、Ingressを作成します。

.. code-block:: console

        $ kubectl create -f ingress-controller.yaml

        ingress.extensions "mynginx-ingress" created

        $ kubectl get ing

        NAME              HOSTS                 ADDRESS   PORTS     AGE
        mynginx-ingress   user10.netapp.local             80        51s

Ingressが作成されると、「spec - rules - host」で指定したホスト名でアクセス出来るようになります。
以下の確認では簡易的にcurlコマンドでipとホスト名をマッピングしていますが、通常はDNSへAレコードを登録します。

.. code-block:: console

        $ curl -L --resolve user10.netapp.local:80:10.244.0.3 http://user10.netapp.local

        <!DOCTYPE html>
        <html>
        <head>
        <title>Welcome to nginx!</title>
        <style>
            body {
                width: 35em;
                margin: 0 auto;
                font-family: Tahoma, Verdana, Arial, sans-serif;
            }
        </style>
        </head>
        <body>
        <h1>Welcome to nginx!</h1>
        <p>If you see this page, the nginx web server is successfully installed and
        working. Further configuration is required.</p>

        <p>For online documentation and support please refer to
        <a href="http://nginx.org/">nginx.org</a>.<br/>
        Commercial support is available at
        <a href="http://nginx.com/">nginx.com</a>.</p>

        <p><em>Thank you for using nginx.</em></p>
        </body>
        </html>

今回のサンプルではDNS登録することとの違いがわからないかもしれませんが、複数のサービスのエンドポイントを統一出来るようになります。




