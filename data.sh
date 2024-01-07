sudo yum update -y 
sudo yum install docker -y 
sudo systemctl enable docker --now 
sudo usermod -aG docker ec2-user 
newgrp docker 
sudo chmod 666 /var/run/docker.sock 
docker pull shantayya/connected-app:v1
docker run -d -p 80:5000 shantayya/connected-app:v1