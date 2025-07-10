# Jenkins CI/CD Pipeline Setup Guide

This guide will help you set up the Jenkins pipeline to build and deploy your NestJS application to Amazon ECR.

## Prerequisites

1. **Jenkins Server** with the following plugins installed:
   - Docker Pipeline
   - AWS Steps Plugin
   - Pipeline: AWS Steps
   - Blue Ocean (optional, for better UI)

2. **AWS Account** with ECR access
3. **Docker** installed on Jenkins agents
4. **Node.js** installed on Jenkins agents

## Jenkins Configuration

### 1. Install Required Jenkins Plugins

Navigate to `Manage Jenkins` > `Manage Plugins` and install:
- Docker Pipeline
- AWS Steps Plugin
- Pipeline: AWS Steps
- Blue Ocean (recommended)

### 2. Configure AWS Credentials

1. Go to `Manage Jenkins` > `Manage Credentials`
2. Click on `(global)` domain
3. Click `Add Credentials`

#### Option A: AWS Access Key Credentials
- **Kind**: AWS Credentials
- **ID**: `aws-credentials`
- **Description**: AWS ECR Access
- **Access Key ID**: Your AWS Access Key ID
- **Secret Access Key**: Your AWS Secret Access Key

#### Option B: IAM Role (Recommended for EC2-hosted Jenkins)
- **Kind**: AWS Credentials
- **ID**: `aws-credentials`
- **Description**: AWS ECR Access via IAM Role
- Select "IAM Role" and configure your EC2 instance role

### 3. Add AWS Account ID

1. Add another credential:
   - **Kind**: Secret text
   - **ID**: `aws-account-id`
   - **Secret**: Your 12-digit AWS Account ID
   - **Description**: AWS Account ID for ECR

### 4. Required IAM Permissions

Your AWS user/role needs the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:DescribeRepositories",
                "ecr:CreateRepository",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

## Pipeline Configuration

### 1. Create a New Pipeline Job

1. In Jenkins, click `New Item`
2. Enter job name (e.g., `nestjs-ecr-pipeline`)
3. Select `Pipeline` and click `OK`

### 2. Configure Pipeline

In the job configuration:

1. **General Section**:
   - Add description: "NestJS application CI/CD pipeline to ECR"
   - Check "GitHub project" if using GitHub

2. **Build Triggers**:
   - Check "GitHub hook trigger for GITScm polling" (if using GitHub webhooks)
   - Or configure periodic builds: `H */2 * * *` (every 2 hours)

3. **Pipeline Section**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your repository URL
   - **Credentials**: Add your Git credentials if private repo
   - **Branch**: `*/main` or your default branch
   - **Script Path**: `Jenkinsfile`

### 3. Environment Variables to Customize

Edit the Jenkinsfile to customize these variables:

```groovy
environment {
    AWS_DEFAULT_REGION = 'us-east-1'  // Change to your preferred region
    ECR_REPOSITORY_NAME = 'jenkins-ci-cd-test'  // Change to your desired repo name
    // ... other variables
}
```

## Docker Configuration

### 1. Ensure Docker is Available

Make sure Docker is installed and accessible to the Jenkins user:

```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins service
sudo systemctl restart jenkins
```

### 2. Docker in Docker (if using Docker containers for Jenkins)

If running Jenkins in Docker, you need to mount Docker socket:

```bash
docker run -d \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 8080:8080 -p 50000:50000 \
  jenkins/jenkins:lts
```

## AWS ECR Setup

### 1. Create ECR Repository (Optional)

The pipeline will create the repository automatically, but you can create it manually:

```bash
aws ecr create-repository \
    --repository-name jenkins-ci-cd-test \
    --region us-east-1 \
    --image-scanning-configuration scanOnPush=true
```

### 2. Configure Repository Policies (Optional)

Set up lifecycle policies to manage image retention:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Testing the Pipeline

### 1. Manual Build

1. Go to your pipeline job
2. Click `Build Now`
3. Monitor the build in `Console Output`

### 2. Webhook Setup (for automatic builds)

#### GitHub Webhooks:
1. Go to your GitHub repository
2. Settings > Webhooks
3. Add webhook:
   - **URL**: `http://your-jenkins-url/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Just the push event

## Troubleshooting

### Common Issues:

1. **Docker permission denied**:
   ```bash
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

2. **AWS credentials not found**:
   - Verify credential ID matches pipeline configuration
   - Check IAM permissions

3. **ECR login failed**:
   - Verify AWS region configuration
   - Check ECR permissions in IAM policy

4. **Build fails on npm install**:
   - Ensure Node.js is installed on Jenkins agent
   - Check package.json for any issues

### Viewing Logs:

- **Build Console**: Click on build number > Console Output
- **Blue Ocean**: Better visualization of pipeline stages
- **AWS CloudTrail**: For AWS API call debugging

## Security Best Practices

1. **Use IAM roles** instead of access keys when possible
2. **Enable ECR image scanning** for vulnerability detection
3. **Implement least privilege** IAM policies
4. **Use Docker multi-stage builds** for smaller, more secure images
5. **Regularly update base images** and dependencies
6. **Store secrets in Jenkins credentials store**, not in code

## Monitoring and Notifications

The pipeline includes basic notification templates. Configure:

1. **Slack notifications** (uncomment and configure Slack plugin)
2. **Email notifications** (configure SMTP in Jenkins)
3. **AWS SNS** for advanced notification scenarios

## Deployment

After successful ECR push, you can:

1. **Deploy to ECS/Fargate**:
   ```bash
   aws ecs update-service --cluster your-cluster --service your-service --force-new-deployment
   ```

2. **Deploy to EKS**:
   ```bash
   kubectl set image deployment/app app=123456789.dkr.ecr.us-east-1.amazonaws.com/jenkins-ci-cd-test:latest
   ```

3. **Use AWS CodeDeploy** for automated deployment

## Next Steps

1. Set up automated deployment to your target environment
2. Implement automated testing strategies
3. Add security scanning and compliance checks
4. Set up monitoring and alerting for your deployed application
