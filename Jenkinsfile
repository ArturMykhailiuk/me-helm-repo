pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command:
        - sleep
      args:
        - 99d
    - name: git
      image: alpine/git:2.36.2
      command:
        - cat
      tty: true
"""
    }
  }



  environment {
    ECR_REGISTRY = "145023106654.dkr.ecr.us-east-1.amazonaws.com"
    IMAGE_NAME   = "lesson-8-9-ecr"
    IMAGE_TAG    = "build-v.${BUILD_NUMBER}"
    GITHUB_TOKEN = credentials('github-token')
  }

  stages {
    stage('Check commit message') {
      steps {
        script {
          def commitMsg = sh(script: "git log -1 --pretty=%B", returnStdout: true).trim()
          if (commitMsg.contains('[ci skip]')) {
              echo "Found [ci skip] in commit message. Skipping pipeline."
              currentBuild.result = 'SUCCESS'
              // Завершуємо pipeline goit-django-docker
              error('Skipping pipeline')
          }
        }
      }
    }
    stage('Clone Django App Repo') {
      steps {
        container('git') {
          sh 'git clone --branch main https://github.com/ArturMykhailiuk/me-helm-repo.git django-app'
        }
      }
    }
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \\
              --context `pwd`//django-app \\
              --dockerfile `pwd`//django-app/Dockerfile \\
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \\
              --cache=true \\
              --insecure \\
              --skip-tls-verify
          '''
        }
      }
    }

    stage('Clone values.yaml repo') {
      steps {
        container('git') {
          sh '''
            rm -rf goit-devops
            git clone --branch lesson-8-9 https://github.com/ArturMykhailiuk/goit-devops.git
          '''
        }
      }
    }

    stage('Update image tag in values.yaml') {
      steps {
        container('kaniko') {
          sh '''
            sed -i "s|tag:.*|tag: $IMAGE_TAG|" goit-devops/charts/django-app/values.yaml
          '''
        }
      }
    }

    stage('Commit & Push changes to values.yaml repo') {
      steps {
        container('git') {
          sh '''
            cd goit-devops
            git config user.email "jenkins@local"
            git config user.name "Jenkins CI"
            git add charts/django-app/values.yaml
            git commit -m "Update image tag to $IMAGE_TAG [ci skip]" || echo "No changes to commit"
            git push https://${GITHUB_TOKEN}@github.com/ArturMykhailiuk/goit-devops.git lesson-8-9
          '''
        }
      }
    }
  }
}

