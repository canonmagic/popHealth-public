# Installation instructions


This installation process is tested over clean Ubuntu 22.04.3 LTS [Jammy Jellyfish] operative system.
[Ubuntu 22.04.3](https://releases.ubuntu.com/jammy)


# User Setup


Step 1: Switch to root user

```

sudo -i

```

Step 2:

Creating user pophealth

```

sudo adduser pophealth

```

Step 3: Enabling pophealth as sudo user

```

usermod -aG sudo pophealth

```

Step 4: Log as pophealth user

```

exit
su - pophealth

```

Note: In some cases a reboot might be neccesary to load sudo privilegies correctly


# RVM Installation


Step 1: Install previous required packages

```

sudo apt-get install software-properties-common

```

Step 2: Add RVM to repository and update

```

sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get update

```

Step 3: Install RVM

```

sudo apt-get install rvm

```

Step 4: add user to RVM group and 

```

sudo usermod -a -G rvm $USER

```

Step 5: Add RVM to source and reboot

```
echo 'source "/etc/profile.d/rvm.sh"' >> ~/.bashrc
sudo reboot

```

Note: In case of errors during RVM installation due missing permissions, try the following

```
rvm fix-permissions system; rvm fix-permissions user

```


# Ruby 3.1.0 Installation


Step 1: Install Ruby 3.1.0

```

rvm install 3.1.0

```


# MongoDB 6.0 Installation


Step 1: Import the public key used by the package management system

```

sudo apt-get install gnupg curl

```

Step 2: Issue the following command to import the MongoDB public GPG Key

```

curl -fsSL https://pgp.mongodb.com/server-6.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg \
    --dearmor

```

Step 3: Create a list file for MongoDB

```

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

```

Step 4: Reload local package database and Install the MongoDB packages

```

sudo apt-get update
sudo apt-get install -y mongodb-org

```

Step 5: Enable mongod service and check his status

```

sudo systemctl enable mongod
sudo systemctl start mongod
sudo systemctl status mongod

```


# NPM and NodeJS Installation


Step 1: Install NPM

```

sudo apt-get install npm

```


Step 2: Install NodeJS

```

sudo apt-get install nodejs

```


# Installing Git


Step 1: Install Git from the default Ubuntu repository by running

```

sudo apt install git

```


# PopHealth Source Code


Step 1: Download from Git

```

cd ~/
git clone https://github.com/canonmagic/popHealth-public popHealth

```


Step 2: Setup bundle to install gems locally

```

bundle config path 'vendor/bundle' --local

```


Step 2: Install vendor libraries

```

cd ~/popHealth
bundle install

```


# CQM-Execution Source Code


Step 1: Download from Git

```

cd ~/
git clone https://github.com/projecttacoma/cqm-execution-service.git -b cypress_v7

```

Step 2: Install all required packages

```

cd cqm-execution-service
npm install

```


# Import the measure bundle


In addition to the measure bundle, the value sets need to be loaded into popHealth from the NLM VSAC Service. You will need an NLM account in order to complete this step and load value sets from the VSAC service._ Register for an account [here](https://uts.nlm.nih.gov/uts/signup-login):

Step 1: Execute the following rake task

```

cd ~/popHealth
bundle exec rake pophealth:download_update_install version=2023 RAILS_ENV=development

```


# Precompile PopHealth Assets


Step 1: Execute the following rake task

```

rake assets:precompile

```


# Create default Admin user


Step 1: Execute the following rake task

```

bundle exec rake admin:create_admin_account RAILS_ENV=development

```


# Prepare Systemd services

Step 1: Configure delayed job to start up on server startup

```

cd ~
echo -e '#!/bin/bash\ncd /home/pophealth/popHealth\n. /usr/share/rvm/scripts/rvm\nbundle exec rake jobs:work RAILS_ENV=development\n' > start_delayed_job.sh
chmod +x start_delayed_job.sh

cat << DELAYED_WORKER_END | sudo dd of=/etc/systemd/system/pophealth_delayed_worker.service
  [Unit]
  Description=delayed_worker
  After=mongod.service
  Requires=mongod.service

  [Service]
  Type=simple
  User=root
  WorkingDirectory=/home/pophealth/popHealth
  ExecStart=/home/pophealth/start_delayed_job.sh
  TimeoutSec=120

  [Install]
  WantedBy=multi-user.target
DELAYED_WORKER_END

```

Step 2: Enable Delayed Worker service

```

sudo systemctl enable pophealth_delayed_worker
sudo systemctl start pophealth_delayed_worker

```

Step 3: Configure cqm-execution to start up on server startup

```

cat << CQM_EXECUTION_END | sudo dd of=/etc/systemd/system/cqm-execution.service
    [Unit]
    Description=CQM Calculation Service

    [Service]
    User=root
    WorkingDirectory=/home/pophealth/cqm-execution-service
    ExecStart=node server.js
    Restart=always

    [Install]
    WantedBy=multi-user.target
CQM_EXECUTION_END

```

Step 4: Enable CQM-execution service

```

sudo systemctl enable cqm-execution
sudo systemctl start cqm-execution

```

Step 5: Configure popHealth puma Webserver to start up on server startup

```

cat << POPHEALTH_END | sudo dd of=/etc/systemd/system/pophealth.service
    [Unit]
    Description=PopHealth Puma Webserver
    Wants=network-online.target
    After=network.target network-online.target

    [Service]
    Type=simple
    User=root
    WorkingDirectory=/home/pophealth/popHealth
    ExecStart=/bin/bash -lc 'bundle exec puma -C /home/pophealth/popHealth/config/puma.rb'
    Environment="PORT=80"

    TimeoutSec=15
    Restart=always

    [Install]
    WantedBy=multi-user.target
POPHEALTH_END

```

Step 6: Enable PopHealth service

```

sudo systemctl enable pophealth
sudo systemctl start pophealth

```


# Final comments

Now you should be able to access to popHealth by the following URL

http://localhost.com

