pipeline {
    agent any

    tools {
        nodejs 'NodeJS-20'
    }

    environment {
        FRONTEND_IMAGE = 'divyap1571/mern-app-frontend'
        BACKEND_IMAGE  = 'divyap1571/mern-app-backend'
        KUBE_CONTEXT   = 'kind-my-cluster'
        KUBE_NAMESPACE = 'mern-app'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            parallel {

                stage('Frontend Dependencies') {
                    steps {
                        dir('frontend') {
                            sh 'npm ci'
                        }
                    }
                }

                stage('Backend Dependencies') {
                    steps {
                        dir('backend') {
                            sh 'npm ci --omit=dev'
                        }
                    }
                }
            }
        }

        stage('Lint Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm run lint -- --max-warnings 100'
                }
            }
        }

        stage('Build React Application') {
            steps {
                dir('frontend') {
                    sh 'npm run build'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    set -e

                    echo "Building frontend image..."
                    docker build \
                      -t $FRONTEND_IMAGE:$BUILD_NUMBER \
                      -t $FRONTEND_IMAGE:latest \
                      ./frontend

                    echo "Building backend image..."
                    docker build \
                      -t $BACKEND_IMAGE:$BUILD_NUMBER \
                      -t $BACKEND_IMAGE:latest \
                      ./backend

                    echo "Docker images created:"
                    docker images | grep "divyap1571/mern-app"
                '''
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -e

                        echo "$DOCKER_PASSWORD" | docker login \
                          -u "$DOCKER_USERNAME" \
                          --password-stdin

                        docker push $FRONTEND_IMAGE:$BUILD_NUMBER
                        docker push $FRONTEND_IMAGE:latest

                        docker push $BACKEND_IMAGE:$BUILD_NUMBER
                        docker push $BACKEND_IMAGE:latest
                    '''
                }
            }
        }

        stage('Kubernetes Pre-Check') {
            steps {
                sh '''
                    set -e

                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    kubectl config use-context $KUBE_CONTEXT
                    kubectl get nodes
                    kubectl get namespace $KUBE_NAMESPACE
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    set -e

                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "Updating frontend image..."
                    kubectl set image deployment/client \
                      client=$FRONTEND_IMAGE:$BUILD_NUMBER \
                      -n $KUBE_NAMESPACE

                    echo "Updating backend image..."
                    kubectl set image deployment/server \
                      server=$BACKEND_IMAGE:$BUILD_NUMBER \
                      -n $KUBE_NAMESPACE

                    echo "Waiting for backend rollout..."
                    kubectl rollout status deployment/server \
                      -n $KUBE_NAMESPACE \
                      --timeout=180s

                    echo "Waiting for frontend rollout..."
                    kubectl rollout status deployment/client \
                      -n $KUBE_NAMESPACE \
                      --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -e

                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "=== Pods ==="
                    kubectl get pods -n $KUBE_NAMESPACE

                    echo "=== Services ==="
                    kubectl get svc -n $KUBE_NAMESPACE

                    echo "=== Deployment Status ==="
                    kubectl get deployments -n $KUBE_NAMESPACE

                    echo "=== Backend Health ==="
                    kubectl run pipeline-health-check \
                      -n $KUBE_NAMESPACE \
                      --rm \
                      -i \
                      --restart=Never \
                      --image=curlimages/curl \
                      -- curl -f http://server-service:5000/api/health
                '''
            }
        }
    }

    post {

        success {
            echo '========================================='
            echo 'CI/CD PIPELINE COMPLETED SUCCESSFULLY!'
            echo '========================================='
        }

        failure {
            echo '========================================='
            echo 'PIPELINE FAILED'
            echo 'Check the failed stage and Jenkins console output.'
            echo '========================================='
        }

        always {
            sh 'docker logout || true'
        }
    }
}
