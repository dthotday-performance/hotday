#!/usr/bin/env bash

export JENKINS_USER=$(cat ../creds.json | jq -r '.jenkinsUser')
export JENKINS_PASSWORD=$(cat ../creds.json | jq -r '.jenkinsPassword')
export GITHUB_PERSONAL_ACCESS_TOKEN=$(cat creds.json | jq -r '.githubPersonalAccessToken')
export GITHUB_USER_NAME=$(cat ../creds.json | jq -r '.githubUserName')
export GITHUB_USER_EMAIL=$(cat ../creds.json | jq -r '.githubUserEmail')
export DT_TENANT_ID=$(cat ../creds.json | jq -r '.dynatraceTenant')
export DT_ACCOUNTID=$(cat ../creds.json | jq -r '.dtaccountid')
export NL_WEB_API_KEY=$(cat ../creds.json | jq -r '.nlwebapikey')
export DT_API_TOKEN=$(cat ../creds.json | jq -r '.dynatraceApiToken')
export DT_PAAS_TOKEN=$(cat ../creds.json | jq -r '.dynatracePaaSToken')
export GITHUB_ORGANIZATION=$(cat ../creds.json | jq -r '.githubOrg')
export DT_TENANT_URL="$DT_ACCOUNTID.live.dynatrace.com"
export NL_WEB_LOGIN=$(cat ../creds.json | jq -r '.nlwebloginaccount')


sudo apt install default-jre
sudo install openjdk-8-jre-headless
sudo  apt-get update
sudo apt-get install -y git curl gosu
sudo rm -rf /var/lib/apt/lists/*
echo "building jenkins!"
user=jenkins
group=jenkins
uid=1000
gid=1000
http_port=8080
agent_port=50000


JENKINS_HOME=/var/jenkins_home

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
sudo mkdir -p $JENKINS_HOME \
  &&  groupadd -g ${gid} ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
  && chown ${uid}:${gid} $JENKINS_HOME \


sudo mkdir -p $JENKINS_HOME/jobs \
  && chown ${uid}:${gid} $JENKINS_HOME/jobs

sudo mkdir -p $JENKINS_HOME/workspaces \
  && chown ${uid}:${gid} $JENKINS_HOME/workspaces


# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
sudo mkdir -p /usr/share/jenkins/ref/init.groovy.d


cp init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

JENKINS_VERSION=2.99

# jenkins.war checksum, download will be validated using it
JENKINS_SHA=ecb84b6575e86957b902cce5e68e360e6b0768b0921baa405e61d314239e5b27

# Can be used to customize where jenkins.war get downloaded from
JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war
# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
sudo  curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

JENKINS_UC =https://updates.jenkins.io
JENKINS_UC_EXPERIMENTAL =https://updates.jenkins.io/experimental
JENKINS_INCREMENTALS_REPO_MIRROR =https://repo.jenkins-ci.org/incrementals
chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref



COPY_REFERENCE_FILE_LOG = $JENKINS_HOME/copy_reference_file.log

cp jenkins-support /usr/local/bin/jenkins-support
cp jenkins.sh /usr/local/bin/jenkins.sh

chmod +x /usr/local/bin/jenkins.sh

cp /configs/config.xml "$JENKINS_HOME"/config.xml
cp /configs/org.jenkinsci.plugins.neoload.integration.NeoGlobalConfig.xml "$JENKINS_HOME"/org.jenkinsci.plugins.neoload.integration.NeoGlobalConfig.xml

cp /configs/jobs /tmp/jobs
cp /configs/users "$JENKINS_HOME"/users

# from a derived Dockerfile, can use `RUN plugins.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
cp install-plugins.sh /usr/local/bin/install-plugins.sh
chmod 755 /usr/local/bin/install-plugins.sh

/usr/local/bin/install-plugins.sh \
workflow-job:2.31 \
workflow-aggregator:2.6 \
credentials-binding:1.16 \
git:3.9.1 \
google-oauth-plugin:0.6 \
google-source-plugin:0.3 \
github-branch-source:2.4.0 \
neoload-jenkins-plugin:2.2.6 \
ws-cleanup-plugin:2.121

cp -R /tmp/jobs/* "$JENKINS_HOME"/jobs/
chown -R ${user} "$JENKINS_HOME"
chmod -R 777 "$JENKINS_HOME"
chmod -R 777 /root

cp tini-shim.sh /bin/tini

./usr/local/bin/jenkins.sh