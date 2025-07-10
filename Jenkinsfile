pipeline {
    agent any
    
    environment {
        NODE_VERSION = '22'
        APP_NAME = 'smarton-backend/development'
        ECR_REPOSITORY = '354568257478.dkr.ecr.ap-south-1.amazonaws.com'  // Replace with your ECR URI (without https://)
        AWS_REGION = 'ap-south-1'
    }
    
    tools {
        nodejs 'node-22'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Code checked out successfully'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "🐳 Building Docker image..."
                    docker build -t ${APP_NAME}:${BUILD_NUMBER} .
                '''
            }
        }
        
        stage('Push to ECR') {
            steps {
                sh '''
                    echo "🔐 Logging in to Amazon ECR..."
                    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPOSITORY}
                    
                    echo "🏷️ Tagging Docker image..."
                    docker tag ${APP_NAME}:${BUILD_NUMBER} ${ECR_REPOSITORY}/${APP_NAME}:${BUILD_NUMBER}
                    docker tag ${APP_NAME}:${BUILD_NUMBER} ${ECR_REPOSITORY}/${APP_NAME}:latest
                    
                    echo "📦 Pushing Docker image to ECR..."
                    docker push ${ECR_REPOSITORY}/${APP_NAME}:${BUILD_NUMBER}
                    docker push ${ECR_REPOSITORY}/${APP_NAME}:latest
                '''
            }
        }
        
        stage('Update Deployment') {
            steps {
                sh '''
                    echo "🚀 Updating deployment..."
                    # Example: Update ECS service
                    # aws ecs update-service --cluster my-cluster --service my-service --force-new-deployment
                '''
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh 'docker rmi ${APP_NAME}:${BUILD_NUMBER} || true'
            sh 'docker rmi ${ECR_REPOSITORY}/${APP_NAME}:${BUILD_NUMBER} || true'
            cleanWs()
        }
        
        success {
            echo '✅ ECR Push successful!'
        }
        
        failure {
            echo '❌ ECR Push failed!'
        }
    }
}
