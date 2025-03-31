#!/bin/bash

# Define variables
BUCKET_NAME="lovely-company-files-maxmedov"
DYNAMODB_TABLE_NAME="UserDetails"
AWS_REGION="us-east-2"
KMS_KEY_ARN=${kms_key_arn}

# Update and install required packages
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo yum install -y python3 git
sudo pip3 install Flask boto3 watchdog pytesseract pillow python-dotenv

# Prepare app folder
sudo mkdir -p /home/ec2-user/app
cd /home/ec2-user/app
sudo git clone https://github.com/Max-Medov/Automatic-File-Sorter.git .

# Create .env file
echo "S3_BUCKET_NAME=${bucket_name}" | sudo tee /home/ec2-user/app/.env
echo "DYNAMODB_TABLE_NAME=${dynamodb_table}" | sudo tee -a /home/ec2-user/app/.env
echo "DEPARTMENT_FOLDERS=R&D,DevOps,IT" | sudo tee -a /home/ec2-user/app/.env
echo "KMS_KEY_ARN=${kms_key_arn}" | sudo tee -a /home/ec2-user/app/.env
echo "SELECTED_DEPARTMENT=IT" | sudo tee -a /home/ec2-user/app/.env

# Create Dockerfile
sudo tee /home/ec2-user/app/Dockerfile > /dev/null << 'EOF'
FROM python:3.7
WORKDIR /app
COPY . /app
RUN pip install Flask boto3 watchdog pytesseract pillow python-dotenv
ENV $(cat /app/.env | xargs)
EXPOSE 3000
CMD ["sh", "-c", "python /app/Simple-uplaod-page.py & python /app/file-sorter-locally-to-bucket.py"]
EOF

# Build and run Docker container
sudo docker build -t flask-sorter .
sudo docker run -d -p 3000:3000 --name flask-sorter-upload flask-sorter

# Populate DynamoDB from JSON (optional)
sudo docker exec flask-sorter-upload python /app/Database-from-json.py

