## Kafka Tool deployment Instructions

1. Create Kafka.properties file
```
cat << EOF > kafka.properties
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOF
```

2. Download msk iam auth jar file

```
mkdir extra-kafdrop-classes

wget --directory-prefix=extra-kafdrop-classes wget https://github.com/aws/aws-msk-iam-auth/releases/download/v1.1.1/aws-msk-iam-auth-1.1.1-all.jar
```

3. Run the tool (Replace the MSK endpoint)

```
docker run --rm -p 9000:9000 \
    -v $(pwd)/kafka.properties:/tmp/kafka.properties:ro \
    -v $(pwd)/extra-kafdrop-classes:/extra-classes:ro \
    -e KAFKA_BROKERCONNECT=<REPLACE_MSK_ENDPOINT> \
    -e SERVER_SERVLET_CONTEXTPATH="/" \
    -e KAFKA_PROPERTIES_FILE=/tmp/kafka.properties \
    obsidiandynamics/kafdrop
```

4. Update the Ec2 security group to allow traffic from your IP address to access the UI on ec2 public IP address

5. Access the tool on Ec2 public IP address port 9000