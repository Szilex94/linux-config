# Configuring MongoDB with replication without security (for local development)

**This approach is intended for local development, where security and sensitive information is not a concern!**

Sauce 
* [Deploying a MongoDB Cluster with Docker](https://www.mongodb.com/compatibility/deploying-a-mongodb-cluster-with-docker)
* [Prevent Secondary from Becoming Primary](https://www.mongodb.com/docs/manual/tutorial/configure-secondary-only-replica-set-member/)


## Docker

```docker
docker compose up -d
```

Use the following command to enter the container
```docker
docker exec -it mongoMaster /bin/bash
```

In case someting went south use the commands listed bellow to reset everything (information created by the containers needs to be removed manually!)
```shell
docker compose -f "docker-compose.yml" down
docker system prune --force
```

## Setup Replication (from the master node)

Use mongosh to enter the shell (in this confiugration no credentials are required)
```shell
mongosh
```

```javascript
rs.initiate({_id:"rs0",members:[{_id:0,host:"mongoMaster"},{_id:1,host:"mongoSlave1"},{_id:2,host:"mongoSlave2"}]});
```

Since we are already connected to the shell we might as well as add a user which can be used during application development to simulate various roles.
```javascript
db.createUser({user:"root",pwd:"superSecret",roles:["root"]});
```

## Prevent Secondary from Becoming Primary
This step might be optional (I am new to this mechanism as such it`s usage might not be as intended).

During system restarts it is possible that the primary node in the cluster to shift around in which case we might encounter problems (since we can only interact with the cluster using the primary node).  
In order to prevent such situations we can configure the priority of the nodes ensuring that regardless of circumstances the same node gets promoted.  
This can be achieved using the following steps (from mongoshell):
```javascript
cfg = rs.conf()
cfg.members[1].priority = 0
cfg.members[2].priority = 0
rs.reconfig(cfg)
```
Alternatively (not tested) it should be possible to connect to the cluster by specifing the ports of each node in the connection string `mongodb://localhost:27017,2018,2019/`. Theoretically regardless which node is acting as the primary it should be able to connect to it.