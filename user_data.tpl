#cloud-config
package_update: true
package_upgrade: true

packages:
 - docker.io
 - docker-compose
 - git

runcmd:
 - git clone https://github.com/jitsi/docker-jitsi-meet.git
 - cd docker-jitsi-meet
 - git checkout ${release}
 - cp env.example .env
 - ./gen-passwords.sh
 - mkdir -p ${config_folder}/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
${env_vars}
 - export PUBLIC_URL=https://${domain}:443
 - docker-compose up -d
 - sleep 20
${create_users}
