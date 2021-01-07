#!/bin/bash

# Remove old runs
if [ -d "${PWD}"/cdk.out ]; then rm -Rf "${PWD}"/cdk.out; fi

# Stop/start localstack
docker stop "$(docker ps -a -q --filter="name=localstack")" &>/dev/null
docker rm "$(docker ps -a -q --filter="name=localstack")" &>/dev/null
docker run -d -p 4566:4566 --name=localstack -e SERVICES=kms,cloudformation localstack/localstack:latest

# Compile the stack
mvn clean package && cdk synth \*

echo "Waiting for stack to startup..."
sleep 10s

# Execute cloudformation template
for templateFile in ./cdk.out/*.template.json; do
  stackName=${templateFile%.template*}

  echo "Installing: ${stackName##*/}"

  aws cloudformation create-stack \
             --endpoint-url=http://localhost:4566 \
             --stack-name "${stackName##*/}" \
             --template-body file://"${templateFile}" \
             --region us-east-1 \
             >> output.txt
done

docker logs -f localstack