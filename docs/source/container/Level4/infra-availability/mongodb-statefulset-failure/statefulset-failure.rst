:orphan:

======================================
Statefulset を使った障害時の動作
======================================

MongoDBを使って確認 Pod停止時の動作
============================================================================

Helmを使ってmongodbをデプロイします。
今回はreplicaを作ることを想定し、``replicaset`` を使い、ストレージをダイナミックにプロビジョニングするようにします。


Helm を使いmongodbをデプロイします。

.. code-block:: console

    $ helm install --name mongodb --namespace mongo-replica -f values.yaml stable/mongodb-replicaset --debug


ノード障害が発生し、別のポッドが上がった場合にもデータが永続化されていることを確認する。
確認のためのテストデータを投入します。


.. code-block:: console

    $ kubectl exec mongodb-mongodb-replicaset-0 -- mongo --eval="printjson(db.test.insert({key1: 'trident fail test'}))"



.. code-block:: console

    $ kubectl exec mongodb-mongodb-replicaset-0 -n mongo-replica -- mongo --eval="printjson(db.test.insert({key1: 'trident fail test'}))"

    MongoDB shell version v3.6.6
    connecting to: mongodb://127.0.0.1:27017
    MongoDB server version: 3.6.6
    { "nInserted" : 1 }

値を確認します。


.. code-block:: console

    $ kubectl exec mongodb-mongodb-replicaset-0 -n mongo-replica -- mongo --eval="rs.slaveOk(); db.test.find({key1:{\$exists:true}}).forEach(printjson)"

    MongoDB shell version v3.6.6
    connecting to: mongodb://127.0.0.1:27017
    MongoDB server version: 3.6.6
    {
            "_id" : ObjectId("5b5b0d43e521f72e61cf2f9f"),
            "key1" : "trident fail test"
    }


Podを停止させ、別ノードで起動することを確認します。

まずは起動状態を確認し、それぞれのPodがどのノードで稼働しているかを確認します。


.. code-block:: console

    mongodb-mongodb-replicaset-0   1/1       Running   0          5m        10.244.3.6   node2              │
    mongodb-mongodb-replicaset-1   1/1       Running   0          5m        10.244.4.8   node3              │
    mongodb-mongodb-replicaset-2   1/1       Running   0          4m        10.244.1.5   node0


ラベルを使って対象のPodをすべて削除します。

.. code-block:: console

    $ kubectl delete po -l "app=mongodb-replicaset,release=mongodb" -n mongo-replica
    pod "mongodb-mongodb-replicaset-0" deleted
    pod "mongodb-mongodb-replicaset-1" deleted
    pod "mongodb-mongodb-replicaset-2" deleted

起動確認後、すべてのPodが別ノードで起動していることを確認します。

.. code-block:: console

    $ kubectl get po -n mongo-replica -o wide

    NAME                           READY     STATUS    RESTARTS   AGE       IP           NODE
    mongodb-mongodb-replicaset-0   1/1       Running   0          2m        10.244.4.9   node3
    mongodb-mongodb-replicaset-1   1/1       Running   0          1m        10.244.3.7   node2
    mongodb-mongodb-replicaset-2   1/1       Running   0          1m        10.244.2.6   node1


テスト前に保存したデータベースの値を確認します。

.. code-block:: console

    $ kubectl exec mongodb-mongodb-replicaset-0 -n mongo-replica -- mongo --eval="rs.slaveOk(); db.test.find({key1:{\$exists:true}}).forEach(printjson)"

    MongoDB shell version v3.6.6
    connecting to: mongodb://127.0.0.1:27017
    MongoDB server version: 3.6.6
    {
            "_id" : ObjectId("5b5b0d43e521f72e61cf2f9f"),
            "key1" : "trident fail test"
    }

ポッドが削除され、再作成されたあとでもデータは永続化している状態を確認できました。

