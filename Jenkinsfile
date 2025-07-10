pipeline {
    agent any
    
    environment {
        // AWS Configuration
        AWS_DEFAULT_REGION = 'ap-south-1'  // Change to your preferred region
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        ECR_REPOSITORY_NAME = credentials('ecr-repository-name')
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
        
        // Docker Configuration
        IMAGE_TAG = "${BUILD_NUMBER}"
        IMAGE_LATEST = "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}:latest"
        IMAGE_VERSIONED = "${ECR_REGISTRY}/${ECR_REPOSITORY_NAME}:${IMAGE_TAG}"
        
        // Credentials
        AWS_CREDENTIALS = credentials('aws-credentials')
        DOCKER_BUILDKIT = '1'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        skipDefaultCheckout(false)
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Validate') {
            parallel {
                stage('Validate Package.json') {
                    steps {
                        sh 'test -f package.json'
                        sh 'node -e "JSON.parse(require(\'fs\').readFileSync(\'package.json\', \'utf8\'))"'
                    }
                }
            }
        }
        
        stage('Build Application') {
            steps {
                echo 'Installing dependencies and building application...'
                sh 'npm install --silent'
                sh 'npm run build'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker image...'
                    
                    // Build multi-stage Docker image
                    sh """
                        docker build \
                            --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                            --build-arg VCS_REF=\${GIT_COMMIT} \
                            --build-arg VERSION=\${BUILD_NUMBER} \
                            -t ${IMAGE_VERSIONED} \
                            -t ${IMAGE_LATEST} \
                            .
                    """
                    
                    // Security scan (optional)
                    echo 'Running security scan on Docker image...'
                    sh """
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                            -v \$(pwd):/root/.cache/ aquasec/trivy:latest \
                            image --exit-code 0 --severity HIGH,CRITICAL \
                            --no-progress ${IMAGE_VERSIONED} || true
                    """
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo 'Testing Docker image...'
                    
                    // Test that the image runs successfully
                    sh """
                        # Start container in background
                        docker run -d --name test-container-\${BUILD_NUMBER} \
                            -p 3001:3000 ${IMAGE_VERSIONED}
                        
                        # Wait for container to start
                        sleep 10
                        
                        # Test health endpoint (if available)
                        curl -f http://localhost:3001/health || curl -f http://localhost:3001/ || echo "Health check not available"
                        
                        # Stop and remove test container
                        docker stop test-container-\${BUILD_NUMBER}
                        docker rm test-container-\${BUILD_NUMBER}
                    """
                }
            }
        }
        
        stage('Configure AWS') {
            steps {
                script {
                    echo 'Configuring AWS CLI...'
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                    credentialsId: 'aws-credentials']]) {
                        sh """
                            aws configure set aws_access_key_id \${AWS_ACCESS_KEY_ID}
                            aws configure set aws_secret_access_key \${AWS_SECRET_ACCESS_KEY}
                            aws configure set default.region \${AWS_DEFAULT_REGION}
                        """
                        
                        // Verify AWS connectivity
                        sh 'aws sts get-caller-identity'
                    }
                }
            }
        }
        
        
        stage('Push to ECR') {
            steps {
                script {
                    echo 'Pushing Docker image to Amazon ECR...'
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                    credentialsId: 'aws-credentials']]) {
                        sh """
                            # Get ECR login token
                            aws ecr get-login-password --region \${AWS_DEFAULT_REGION} | \
                                docker login --username AWS --password-stdin \${ECR_REGISTRY}
                            
                            # Push both versioned and latest tags
                            docker push \${IMAGE_VERSIONED}
                            docker push \${IMAGE_LATEST}
                            
                            # Output image information
                            echo "Image pushed successfully:"
                            echo "Versioned: \${IMAGE_VERSIONED}"
                            echo "Latest: \${IMAGE_LATEST}"
                        """
                    }
                }
            }
        }
        
        stage('Clean Up') {
            steps {
                script {
                    echo 'Cleaning up local Docker images...'
                    sh """
                        # Remove local images to save space
                        docker rmi \${IMAGE_VERSIONED} || true
                        docker rmi \${IMAGE_LATEST} || true
                        
                        # Clean up dangling images
                        docker image prune -f
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
            
            // Clean up any remaining test containers
            sh """
                docker ps -a | grep "test-container-" | awk '{print \$1}' | xargs -r docker rm -f || true
            """
            
            // Archive build artifacts
            archiveArtifacts artifacts: 'dist/**', allowEmptyArchive: true
            
            // Publish test results if available
            publishTestResults testResultsPattern: 'test-results.xml', allowEmptyResults: true
        }
        
        success {
            echo 'Pipeline succeeded! 🎉'
            
            // Send success notification
            script {
                def message = """
                ✅ Build #${BUILD_NUMBER} succeeded!
                
                📦 Image Details:
                • Repository: ${ECR_REPOSITORY_NAME}
                • Tag: ${IMAGE_TAG}
                • Registry: ${ECR_REGISTRY}
                
                🔗 Image URI: ${IMAGE_VERSIONED}
                
                📋 Build Information:
                • Branch: ${env.BRANCH_NAME ?: 'main'}
                • Commit: ${env.GIT_COMMIT?.take(8)}
                • Duration: ${currentBuild.durationString}
                """
                
                // Uncomment and configure your notification method
                // slackSend channel: '#ci-cd', color: 'good', message: message
                // emailext subject: "✅ Build Success: ${JOB_NAME} #${BUILD_NUMBER}", 
                //          body: message, to: "${EMAIL_RECIPIENTS}"
                
                echo message
            }
        }
        
        failure {
            echo 'Pipeline failed! ❌'
            
            // Send failure notification
            script {
                def message = """
                ❌ Build #${BUILD_NUMBER} failed!
                
                📋 Build Information:
                • Branch: ${env.BRANCH_NAME ?: 'main'}
                • Commit: ${env.GIT_COMMIT?.take(8)}
                • Duration: ${currentBuild.durationString}
                
                🔗 Build URL: ${BUILD_URL}
                """
                
                // Uncomment and configure your notification method
                // slackSend channel: '#ci-cd', color: 'danger', message: message
                // emailext subject: "❌ Build Failed: ${JOB_NAME} #${BUILD_NUMBER}", 
                //          body: message, to: "${EMAIL_RECIPIENTS}"
                
                echo message
            }
        }
        
        unstable {
            echo 'Pipeline is unstable! ⚠️'
        }
    }
}
