### increase swap to 3Gi since server has low ram ###
dd if=/dev/zero of=/swapfile bs=1K count=3M # allocates 3 GB
chmod 600 /swapfile; mkswap /swapfile; swapon /swapfile
free -ht # to ensure that swap now exists
echo "/swapfile 	swap 	swap 	defaults 0 0" >> /etc/fstab # make it stick

### Install packages
yum install epel-release elrepo-release -y
yum install docker podman-compose firewalld git gpg pinentry -y 

git clone https://github.com/spwhitton/git-remote-gcrypt.git
cd ./git-remote-gcrypt; bash install.sh # install git-remote-gcrypt

### Create Basic Auth HTPASSWD file for your url
clear; read -p 'Please enter the url you are pointing: ' git_name;
mkdir /opt/data /opt/data/htpasswd; touch /opt/data/htpasswd/$your_url;
clear; read -p 'Enter Username for Fava Login: ' favausername;
echo -n "$favausername:" >> /opt/data/htpasswd/$your_url
echo "Enter Password for Fava Login (Below): "
openssl passwd -apr1 >> /opt/data/htpasswd/$your_url

### set up firewalld to allow :80 and :443 out 
systemctl start firewalld
firewall-cmd --permanent --add-service=http --add-service=https
firewall-cmd --reload

### use passphrase file for easy git push and pull
clear; read -p 'Enter GPG Passphrase (WILL BE STORED IN PLAINTEXT): ' tmp_key;
echo $tmp_key > /opt/data/passphrase

### set up gpg private key for encrypting benacountfiles script
clear; read -N 881 -rp $'Input GPG Private Key:\n' tmp_key; clear
echo "$tmp_key" | gpg --batch --pinentry-mode loopback --passphrase-file=/opt/data/passphrase --import

### Download beancount files from github
clear; read -p 'The email you would like to associate with your git pushes: ' git_email;
clear; read -p 'The name you would like to associate with your git pushes: ' git_name;
git config --global user.email $git_email
git config --global user.name $git_name
git config --global user.signingkey "$(gpg -k | sed "s/^ *//g;4q;d")" # does something interesting
export GPG_TTY=$(tty) # required to avoid Inappropriate ioctl error
# force gcrypt to use your passphrase file instead of asking for one
git config --global gcrypt.gpg-args '--no-tty --batch --pinentry-mode=loopback --passphrase-file=/opt/data/passphrase'

clear; read -p 'Clone link to GitHub directory where your beancount files will be stored using gcrypt: ' gh_link;
gh_link="${gh_link/*(https:\/\/|www\.)/}" # strip https:// and www.
clear; read -p 'Your GitHub Username: ' gh_usrname;
clear; read -p 'GitHub Personal Access Token with read and commit permissions (WILL BE STORED IN PLAINTEXT): ' gh_pat;
git clone gcrypt::https://$gh_usrname:$gh_pat@$gh_link /opt/data/bean

### Move over docker compose file
cp ./compose.yml /opt/compose.yml

systemctl enable --now podman.socket # make sure systemctl status podman.service is up
podman-compose -f /opt/compose.yml up -d #start the system 

### add fava cron-jobs
cp ./gitpush_cron.sh /opt/gitpush_cron.sh
cp ./cron /etc/cron.d/favaContainerJobs

### add some nice aliases for docker start and stop ###
cat aliases >> ~/.bashrc

. ~/.bashrc # reload bash
