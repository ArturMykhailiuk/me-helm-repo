pipeline {
    agent any
    environment {
        DJANGO_SETTINGS_MODULE = "myproject.settings"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Install dependencies') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }
        stage('Lint') {
            steps {
                sh 'pip install flake8 && flake8 myproject'
            }
        }
        stage('Test') {
            steps {
                sh 'pip install pytest && pytest'
            }
        }
        stage('Build Docker image') {
            steps {
                sh 'docker build -t django-app:${BUILD_NUMBER} .'
            }
        }
        // Додайте деплой-стадію за потреби
    }
    post {
        always {
            junit '**/test-*.xml'
        }
    }
}
