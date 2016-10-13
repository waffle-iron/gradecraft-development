#!/usr/bin/env bash

cp config/puma.sample-env.rb config/puma.rb

if [ "${GC_PROCESS_TYPE}" = "worker" ]; then
  apt-get update
  apt-get install -y nginx
  echo "server { listen 5000; root html; index index.html; }" >> /etc/nginx/sites-enabled/default
  service nginx restart
  bundle exec rake resque:work
else
  aws.rb -e 'Aws::S3::Resource.new.bucket("gc-staging-deploy").object("saml.pem").get(response_target: "saml.pem")'
  export SAML_CERT=/gradecraft/saml.pem
  aws.rb -e 'Aws::S3::Resource.new.bucket("gc-staging-deploy").object("saml.key").get(response_target: "saml.key")'
  export SAML_KEY=/gradecraft/saml.key
  aws.rb -e 'Aws::S3::Resource.new.bucket("gc-staging-deploy").object("saml_idp.pem").get(response_target: "saml_idp.pem")'
  export IDP_CERT=/gradecraft/saml_idp.pem

  bundle exec rake resque:scheduler &
  bundle exec puma
fi
