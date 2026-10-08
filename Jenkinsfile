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




stage('Security Scan - Trivy') {
    steps {
        sh '''
            set +e

            echo "========================================="
            echo "TRIVY SECURITY SCAN - FRONTEND"
            echo "========================================="

            trivy image \
              --severity HIGH,CRITICAL \
              --no-progress \
              --scanners vuln \
              $FRONTEND_IMAGE:$BUILD_NUMBER

            FRONTEND_STATUS=$?

            echo "========================================="
            echo "TRIVY SECURITY SCAN - BACKEND"
            echo "========================================="

            trivy image \
              --severity HIGH,CRITICAL \
              --no-progress \
              --scanners vuln \
              $BACKEND_IMAGE:$BUILD_NUMBER

            BACKEND_STATUS=$?

            echo "========================================="
            echo "TRIVY SCAN SUMMARY"
            echo "========================================="

            echo "Frontend Trivy exit code: $FRONTEND_STATUS"
            echo "Backend Trivy exit code: $BACKEND_STATUS"

            echo "========================================="
            echo "VULNERABILITY REPORT GENERATED"
            echo "Pipeline continues for project demonstration."
            echo "========================================="

            exit 0
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

                    echo "=== Kubernetes Nodes ==="
                    kubectl get nodes

                    echo "=== Application Namespace ==="
                    kubectl get namespace $KUBE_NAMESPACE
                '''
            }
        }

                stage('Deploy to Kubernetes') {
            steps {
                script {
                    try {
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

                    } catch (Exception e) {

                        echo "========================================="
                        echo "DEPLOYMENT FAILED"
                        echo "STARTING AUTOMATIC ROLLBACK"
                        echo "========================================="

                        sh '''
                            export KUBECONFIG=/var/lib/jenkins/.kube/config

                            echo "Rolling back frontend..."

                            kubectl rollout undo deployment/client \
                              -n $KUBE_NAMESPACE

                            echo "Rolling back backend..."

                            kubectl rollout undo deployment/server \
                              -n $KUBE_NAMESPACE

                            echo "Waiting for frontend rollback..."

                            kubectl rollout status deployment/client \
                              -n $KUBE_NAMESPACE \
                              --timeout=180s

                            echo "Waiting for backend rollback..."

                            kubectl rollout status deployment/server \
                              -n $KUBE_NAMESPACE \
                              --timeout=180s

                            echo "========================================="
                            echo "AUTOMATIC ROLLBACK COMPLETED"
                            echo "========================================="
                        '''

                        error("Deployment failed. Automatic rollback completed.")
                    }
                }
            }
        }
    

        stage('Verify Deployment') {
            steps {
                script {

                    try {

                        sh '''
                            set -e

                            export KUBECONFIG=/var/lib/jenkins/.kube/config

                            echo "================================="
                            echo "PODS"
                            echo "================================="

                            kubectl get pods -n $KUBE_NAMESPACE

                            echo "================================="
                            echo "SERVICES"
                            echo "================================="

                            kubectl get svc -n $KUBE_NAMESPACE

                            echo "================================="
                            echo "DEPLOYMENTS"
                            echo "================================="

                            kubectl get deployments -n $KUBE_NAMESPACE

                            echo "================================="
                            echo "BACKEND HEALTH CHECK"
                            echo "================================="

                            kubectl run pipeline-health-check-$BUILD_NUMBER \
                              -n $KUBE_NAMESPACE \
                              --rm \
                              -i \
                              --restart=Never \
                              --image=curlimages/curl \
                              -- curl -f http://server-service:5000/api/health

                            echo "================================="
                            echo "DEPLOYMENT VERIFICATION SUCCESS"
                            echo "================================="
                        '''

                    } catch (Exception e) {

                        echo "================================="
                        echo "DEPLOYMENT VERIFICATION FAILED"
                        echo "STARTING AUTOMATIC ROLLBACK"
                        echo "================================="

                        sh '''
                            export KUBECONFIG=/var/lib/jenkins/.kube/config

                            echo "Rolling back frontend..."

                            kubectl rollout undo deployment/client \
                              -n $KUBE_NAMESPACE

                            echo "Rolling back backend..."

                            kubectl rollout undo deployment/server \
                              -n $KUBE_NAMESPACE

                            echo "Waiting for frontend rollback..."

                            kubectl rollout status deployment/client \
                              -n $KUBE_NAMESPACE \
                              --timeout=180s

                            echo "Waiting for backend rollback..."

                            kubectl rollout status deployment/server \
                              -n $KUBE_NAMESPACE \
                              --timeout=180s

                            echo "================================="
                            echo "ROLLBACK COMPLETED"
                            echo "================================="

                            echo "Current frontend image:"

                            kubectl get deployment client \
                              -n $KUBE_NAMESPACE \
                              -o=jsonpath='{.spec.template.spec.containers[0].image}'

                            echo

                            echo "Current backend image:"

                            kubectl get deployment server \
                              -n $KUBE_NAMESPACE \
                              -o=jsonpath='{.spec.template.spec.containers[0].image}'

                            echo
                        '''

                        error("Deployment failed. Automatic rollback completed.")
                    }
                }
            }
        }
    }

    post {

        success {
            echo '''
            =========================================
            CI/CD PIPELINE COMPLETED SUCCESSFULLY!
            =========================================
            '''
        }

        failure {
            echo '''
            =========================================
            PIPELINE FAILED
            =========================================
            Check the failed stage and rollback status.
            '''
        }

        always {
            sh 'docker logout || true'
        }
    }
}
