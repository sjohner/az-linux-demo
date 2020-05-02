#! /bin/bash
apt-get update
apt-get install -y apache2 docker.io
git clone https://github.com/sjohner/jhnr.ch.git src
git clone https://github.com/sjohner/hyde.git src/themes/hyde
docker run --rm --name "hugo" -v $(pwd)/src:/src -v $(pwd)/output:/output -e HUGO_THEME="hyde" jojomi/hugo
mv $(pwd)/output/* /var/www/html/
systemctl start apache2
systemctl enable apache2