#!/bin/bash
# INSTALLS AND RUNS THE TUUL APP FOR CREATING KARAOKE SONGS 

# change google-cheome to the web browser of your choice to auto-open the webui when installed and running
function RunTuul () {
if ! grep -i "mytuul" < <(docker ps); then
  if ! docker run -itd --name mytuul --network host -p 8080:8080 mytuul:latest; then echo "Failed to run mytuul container"; exit 10; fi 
fi
env DISPLAY=:0 nohup google-chrome "https://127.0.0.1:8080" &; 
}

function ImportImage () {
echo "Please wait while tar.gz file is loaded into docker image registry"; 
docker image load -i mytuul_latest.tar.gz; 
echo "Image loaded successfully"
}

function CloneTuulRepo () {
if ! [[ -d $HOME/the_tuul ]]; then git clone https://github.com/incidentist/the_tuul.git ; fi
}

function InstallPython () {
if ! which python3.11; then 
   sudo add-apt-repository ppa:deadsnakes/ppa -y; sudo apt update; 
   sudo apt install python3 python3.11 software-properties-common -y; 
fi
}

function InstallPoetry () {
if ! which poetry; then sudo apt install python3-poetry -y ; fi
#       curl -sSL https://install.python-poetry.org | python3 - 
if ! grep -iq ".local/bin" <"${HOME}/.bashrc"; then echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> ${HOME}/.bashrc ; source ${HOME}/.bashrc ; fi
}

function InstallTuul () {
cd $HOME/the_tuul
poetry install && npm install && npm run build
docker build -t mytuul:latest .
# docker images # get the image id so we can tag it
# docker image tag imageid mytuul:latest
docker save mytuul:latest | gzip > "${HOME}/the_tuul/mytuul_latest.tar.gz"
# docker run --rm --network host -p 8080:8080 mytuul:latest
}

###################### MAIN ###################################

if grep -iow "mytuul" < <(docker images); then RunTuul; exit 0; 
elif [[ -f ${HOME}/the_tuul/mytuul_latest.tar.gz ]]; then 
  if ImportImage; then RunTuul; exit 0; fi 
else
  if ! CloneTuulRepo; then echo "Failed to clone the_tuul git repo"; exit 10; fi 
  if ! InstallPython; then echo "Failed to install Python package"; exit 10; fi 
  if ! InstallPoetry; then echo "Failed to install Poetry package"; exit 10; fi
  if ! InstallTuul; then echo "Failed to build the_tuul docker image"; exit 10; fi
  RunTuul;
fi
