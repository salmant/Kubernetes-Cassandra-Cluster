# Deployment of Cassandra Cluster by Kubernetes

NOTE: In order to proceed this guide, prior knowledge of working with the following technologies is highly required:

* Kubernetes container-orchestration system (Kubernetes Master and Workers)
* Cassandra Cluster
* CQLSH
* Docker containers
* YAML
* Amazon EC2 cloud infrastructure

Cassandra is considered as a capable, Cluster-based database system, which can both partition and replicate the data across multiple Cassandra nodes. If we increase the number of Cassandra nodes in the Cluster, database queries are distributed across more compute resources that means the Cluster will be more efficient. Moreover, the data is stored across multiple nodes that means the database Cluster will be more resilient to a failure.
<br><br>
Cassandra nodes can simply be added to and removed from the Cluster. No node in the Cassandra Cluster is considered more significant than the other nodes. It should be noted that the Cassandra Cluster consists of multiple nodes in a ring-based collection.  The term ring comes from the mechanism used to traverse nodes in a clockwise order until the Cassandra finds a node appropriate for the current database operation. Cassandra provides automatic data replication and keeps the data redundant as much as possible throughout different nodes in the Cassandra Cluster. Along this line, the whole system can resist to any node failure scenario since the data would be still safe, available and reliable. Moreover, partitioning is performed automatically by Cassandra. Cassandra is able to distribute the incoming data into chunks named partitions.
<br>
![Image](https://portworx.com/wp-content/uploads/2017/06/cassandra-failover-2replicas.png)
<br>
Here, I explain how to setup a Cassandra Cluster by Kubernetes on Amazon EC2 cloud infrastructure. Before you begin, make sure you have your own Kubernetes Cluster initialisied including multiple Kubernetes nodes, and you already configured kubectl.
<br>
## Step 1: Create a custom Cassandra Docker image
There is an environment variable called `CASSANDRA_SEEDS` which needs to be defined if we would like to instantiate a Cassandra Pod as a member of Cassandra Cluster.
We need to set this environment variable as the IP addresses of already existing Cassandra Pods as seeds. 
Therefore, if a new Cassandra Pod is instantiated, it should automatically discover all seed Pods' IP addresses via DNS lookups. 
In Kubernetes, `Headless Service` provides a DNS address for each associated Pod.
To this end, we need to install package `dnsutils` in every Cassandra container. 
This is because the `dnsutils` package is a very commonly used tool for resolving DNS queries.

<br>Create the `Dockerfile` file: [Dockerfile](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/Dockerfile)
<br>

As mentioned before, when a container is instantiated, all the IP addresses of already existing Cassandra Pods considered as seeds should be discovered.
To this end, we use command `nslookup` to perform a DNS query.

<br>Create the `Shell` file: [pre-docker-entrypoint.sh](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/pre-docker-entrypoint.sh)
<br><br>
Now you can build the Docker image from the `Dockerfile`.

`docker build -t salmant/kubernetes-cassandra-cluster -f Dockerfile .`
<br>
## Step 2: Create a Cassandra Headless Service
A Service in Kubernetes is an abstraction which defines a logical set of Pods and a policy by which to access them.
Although each Pod has a unique IP address, those IPs are not exposed outside the Cluster without a Service. Services allow your applications to receive traffic.
While communicating with the Service's Cluster IP, each connection to the service is forwarded to one randomly selected backing Pod.
It should be noted that Services can be exposed in different ways by specifying a type in Service Spec:
  *  `clusterIP: 10.x.x.x` This is the default setting. It exposes the Service on an internal IP in the Cluster. This type makes the Service only reachable from within the Cluster.
  *  `clusterIP: None` It is called `Headless Service`. If a client needs to connect to all of those Pods, `Headless Service` makes us able to discover Pod IPs through DNS lookups.

<br>`Headless Service` provides a DNS address for each associated Pod. It means that it allows the system to get the IP addresses of Pods.
Also if Pods themselves need to connect to all the other Pods, we need to create `Headless Service`.
For example, if we are going to create a Cassandra Cluster which includes seed Cassandra Pod and other newly extra Cassandra Pods, the `Headless Service` is necessary.
The IP address of the seed Pods need to be defined as an environment variable called `CASSANDRA_SEEDS` for other further instantiated Cassandra Pods. 
Moreover, all Cassandra Pods should be communicate with each other through two port named intra-node-communication (`7000`) and tls-intra-node-communication (`7001`). 

<br>Create the `YAML` file: [cassandra-headless-service.yaml](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/cassandra-headless-service.yaml)
<br><br>
It should be noted that all Cassandra Pods are determined by a selector called `cassandra`.
<br>
## Step 3: Create a Cassandra clusterIP Service
A `clusterIP` Service, which is the default Kubernetes Service, gives us a Service called `clusterIP` Service inside the Cluster and it will be reachable by clients inside the Cluster.
It should be noted that there is no external access by default. If you would like to have access to the `clusterIP` Service from outside the Cluster like the Internet, there different approaches to be used such as making a Kubernetes Proxy.
Again, it should be noted that all Cassandra Pods are determined by a selector called `cassandra`.

<br>Create the `YAML` file: [cassandra-clusterip-service.yaml](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/cassandra-clusterip-service.yaml)
<br><br>
## Step 4: Create a Cassandra Persistent Volume

A container's file system lives only as long as the container exists. 
Therefore, if a container is terminated or restarts, filesystem changes are all lost. 
For more consistent storage that is independent of the container, you can use a `PersistentVolume`. 
`PersistentVolume` is an interface to the actual backing storage.

<br>Create the `YAML` file: [cassandra-persistent-volume.yaml](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/cassandra-persistent-volume.yaml)
<br><br>
Thefore, you can find all data persistently stored on the Docker host machine in folder `/data/cassandra` where Cassandra Pod run.
Here, the Access Mode is defined as `ReadWriteOnce` that means the Volume can be mounted as read-write by a single node.
`ReadWriteOnce` is the most common use case for Persistent Disks and works as the default access mode for most applications.
<br>
## Step 5: Create a Cassandra Persistent Volume Claim
A `PersistentVolumeClaim` is a request for a `PersistentVolume` with specific attributes such as storage size. 
In between, the system matches the claim to an available volume and binds them together.

<br>Create the `YAML` file: [cassandra-persistent-volume-claim.yaml](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/cassandra-persistent-volume-claim.yaml)
<br><br>
## Step 6: Create Cassandra Replication Controller
`ReplicationController` is used to replicate Pods. It means that `ReplicationController` creates multiple copies of Cassandra Pod and keep them running. 
`ReplicationController` makes sure that there is always a especific number of pods running. Default number, if not especified, is a single one. 
In other words, `ReplicationController` creates by default only one Cassandra Pod, if the replica set number is not determined. 

<br>Create the `YAML` file: [cassandra-replication-controller.yaml](https://github.com/salmant/Kubernetes-Cassandra-Cluster/blob/master/cassandra-replication-controller.yaml)
<br><br>
The Cassandra Pod has a Volume of type `persistentVolumeClaim` that lasts for the life of the Pod, also if the container restarts or even terminates. As mentioned before, data is stored where Persistent Volume points to.
<br>
## Step 7: Deploy the Cassandra Cluster
By executing the following commands respectively, the Cassandra Cluster which initially contains only one Cassandra Pod will be deployed.

<br>`kubectl create -f cassandra-headless-service.yaml`
<br>`kubectl create -f cassandra-clusterip-service.yaml`
<br>`kubectl create -f cassandra-persistent-volume.yaml`
<br>`kubectl create -f cassandra-persistent-volume-claim.yaml`
<br>`kubectl create -f cassandra-replication-controller.yaml`
<br>
## Step 8: See the Cassandra Cluster information and enjoy
The Cassandra Cluster has been deployed to Kubernetes. Now, you can run the following command for details.

`kubectl get deployment,svc,pods,pvc,rc`

```
NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/cassandra                    ClusterIP   10.107.82.75   <none>        9042/TCP,9160/TCP,7199/TCP   21s
service/cassandra-headless-service   ClusterIP   None           <none>        7000/TCP,7001/TCP            21s
service/kubernetes                   ClusterIP   10.96.0.1      <none>        443/TCP                      7h3m

NAME                  READY   STATUS    RESTARTS   AGE
pod/cassandra-hxmnw   1/1     Running   0          20s

NAME                                           STATUS   VOLUME             CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/cassandra-volume-claim   Bound    cassandra-volume   1Gi        RWO                           20s

NAME                              DESIRED   CURRENT   READY   AGE
replicationcontroller/cassandra   1         1         1       20s
```
<br>

## Step 9: Scale the Cassandra Cluster
To start more Cassandra Pods and have them join the Cluster, you may scale the Cassandra Replication Controller which is basically created.

`kubectl scale replicationcontroller  cassandra --replicas=2`

```
NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/cassandra                    ClusterIP   10.107.82.75   <none>        9042/TCP,9160/TCP,7199/TCP   99s
service/cassandra-headless-service   ClusterIP   None           <none>        7000/TCP,7001/TCP            99s
service/kubernetes                   ClusterIP   10.96.0.1      <none>        443/TCP                      7h5m

NAME                  READY   STATUS    RESTARTS   AGE
pod/cassandra-7rfzj   1/1     Running   0          4s
pod/cassandra-hxmnw   1/1     Running   0          98s

NAME                                           STATUS   VOLUME             CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/cassandra-volume-claim   Bound    cassandra-volume   1Gi        RWO                           98s

NAME                              DESIRED   CURRENT   READY   AGE
replicationcontroller/cassandra   2         2         2       98s
```
<br>

## Step 10: Check the status of the Cassandra ring
You may run the Cassandra nodetool which shown bellow to display the status of the ring.

`kubectl exec -it cassandra-rbdpn -- nodetool status`

```
Datacenter: DC1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens       Owns (effective)  Host ID                               Rack
UN  10.244.1.2  117.03 KB  256          100.0%            8f335fe8-4306-431f-a4fc-a4fbca3fb890  Kubernetes Cluster
UN  10.244.1.3  102.2 KB   256          100.0%            f7d90414-187d-458b-acfd-c90919ce9ea6  Kubernetes Cluster
```
<br>

## Step 11: Free the Cassandra Cluster
In order to free all resources allocated to the Cassandra Cluster and stop it, you may execute the following commands respectively.

<br>`kubectl scale rc cassandra --replicas=0`
<br>`kubectl delete service cassandra cassandra-headless-service`
<br>`kubectl delete rc cassandra`
<br>`kubectl delete pvc cassandra-volume-claim`
<br>`kubectl delete pv cassandra-volume`
