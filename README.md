# Pranay-ecommerce-app

Assumptions made-

1. This is not a production grade setup and thus does not envolve creating DNS zones and records for domain name resolution or creating ssl certificates for transport layer security .
2. As no critical workload or sensitive data was served through the webapp therefore we haven't used https protocol and thus did not implement ssl offloading on the ALB
3. We are using pre-build docker images from the docker registry weaveworksdemos for creating the application although we can build our own images using github actions pipeline and push them to the desired docker registry,
4.The helm charts used for deployment of monitoring ,logging and deployment tools are not managed in this repository in order to keep the presentation clean be close to the actual task requirements.


Application architecture diagram with k8's resources and connections deployed in vcluster -

![Screenshot from 2024-08-12 08-12-12](https://github.com/user-attachments/assets/1557e862-4df1-4110-879d-706e6a166b73)



Tools used for Monitoring, logging, continuous deployment and cluster isolation 

![Screenshot from 2024-08-12 08-11-33](https://github.com/user-attachments/assets/d90eea48-9e6f-4241-bd0e-0f29a7f0a28b)



Infrastructure setup overview

![Screenshot from 2024-08-11 04-26-34](https://github.com/user-attachments/assets/45fa8398-08e1-4a55-bb72-3914124b3e40)


We can use the following debugging guide to debug the fllowing three scenarios

## **1. Frontend Accessibility**

**Issue**: The frontend service is not accessible externally post-deployment.

Possible scenarios and debugging steps - 

First of all identity the error code when sending the request by `curl -k -I https://domain.com`
If it is a 4XX error then it is a client side error and if it is a 5XX error then its a server side error

**a**. **Check Service and endpoints** The service exposing the pod (**ClusterIp , NodePort , Loadbalancer)** is not forwarding traffic to the frontend pod. We need to check if service has **endpoint attached** to it and also if the service config has **correct labels** to point to the correct app pod. Check **kibana** for the logs with any logs with errors like `404`, `503`, `connection refused`, `timed out`
      
 **b**.**Check issues with Ingress** If the pod is exposed using an ingress then we need to check the **ingress controller logs** and also check if the ALB created has the **target group registered** to the service pod and the health checks are passing which means load balancer is able to connect to the service. If the ingress is using **IP mode** then it should have the pod ip attached as secondary ip on the host and cluster should also have **AWS CNI Plugin** .

**c.** **Check** **DNS Resolution**  We need to check if the DNS of the ingress can be resolved from the public internet.  We can use the nameserver lookup with command  “nslookup <your-domain>” which queries the nameservers for the any records which might exist. 
      
**d.** **Check** **Security Group & Firewall Rules :** we will check if we are able to resolve the domain name when we **telnet to the domain** which verify that we are able to connect on **layer 4** and it’s not a security group issue.
Also check the **load balancer security group** port and **cidr whitelisting** and if it open to the public internet. Also check the eks **cluster security group** if it allows traffic from that security group.

**e**.**Check pod health and Network Policies:** we need to check if the pod had any restarts or it’s liveness probes , or the memory and cpu usage of the pod if it throttling the requests and restarting.
In such a case the application logs on elastisearch is also helpfull to identify any issue on application

## **2. Intermittent Backend-Database Connectivity:**

**Issue:** The backend services occasionally lose connection to the MongoDB cluster, causing request failures.

**a. Application and backend log retrieval , analysis and corelation with incidence time** - 
Check kibana dashboard and filter logs by container name and time of incident and look for the logs with errors or warning such as (`connection refused`, `timeout`, `connection reset by peer`)

**b.Check the pods for any resource bottlenecks and health** - Check if pods are not running out of memory ( OOM kills ) or having high cpu usage. Also check if limits are properly set on the pod
****and pod is having appropriate scaling solution in place like HPA .

**c.Check the metrics of the Mongodb** database pods on grafana or any serverless cluster like mongodb atlas for the metrics like `mongodb_connections_current`, `query execution time, and memory usage`. We can also check if its a network issue by checking network metrics like `network latency and packet loss` on the node and pods

**d.Check Mongodb configuration and codebase for timeout and retries logic -** we will check the mongodb databse parameters like `connection pool size` or `replication settings` .we will also check the code base if there is any logic to retry the failed connections  and will try increasing the connection timeouts so that small intermittent connection drops can be handled

## **3. Order Processing Delays**:

**Issue:** Users report delays in order processing, suspecting issues with the RabbitMQ message queue.

**a.Check health of RabbitMQ pod** and it’s cpu and memory usage as it may cause disruption in service. also check if there are any resource limits set on its deployment which should be enough to handle the amount of traffic 

**b.Check the length of Queue and the number of consumers** using the queue using prometheus metrics because the long queue length may cause delays in consumpt

**c. Check the Dead-letter Queue configuration and if there is any retry logic** in the code which might be causing the messages to be stuck in the dead letter queue 

**d. Check the health of consumers** in the backend because if they are experiencing any bottlenecks in message processing then it will naturally cause delay in requests so check for metrics such as  message processing time, error rates, and resource usage of the consumer pods





