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
    IMAGE_TAG    = "build-${BUILD_NUMBER}"
    GIT_CRED     = credentials('GITHUB_TOKEN_ID') // Jenkins credential id for GitHub token
    VALUES_REPO  = "https://github.com/ArturMykhailiuk/goit-devops.git"
    VALUES_BRANCH = "lesson-8-9"
    VALUES_PATH  = "lesson-8-9/modules/jenkins/values.yaml"
  }

  stages {
    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            ls -l
            /kaniko/executor \
              --context `pwd` \
              --dockerfile=Dockerfile \
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \
              --cache=true \
              --insecure \
              --skip-tls-verify
          '''
        }
      }
    }

    stage('Clone values.yaml repo') {
      steps {
        container('kaniko') {
          sh '''
            rm -rf goit-devops
            git clone --branch $VALUES_BRANCH https://$GIT_CRED@github.com/ArturMykhailiuk/goit-devops.git
          '''
        }
      }
    }

    stage('Update image tag in values.yaml') {
      steps {
        sh '''
          chmod -R 777 goit-devops
          sed -i "s|tag:.*|tag: $IMAGE_TAG|" goit-devops/$VALUES_PATH
        '''
      }
    }

    stage('Commit & Push changes to values.yaml repo') {
      steps {
        container('kaniko') {
          sh '''
            cd goit-devops
            git config user.email "jenkins@local"
            git config user.name "Jenkins CI"
            git add $VALUES_PATH
            git commit -m "Update image tag to $IMAGE_TAG [ci skip]" || echo "No changes to commit"
            git push https://$GIT_CRED@github.com/ArturMykhailiuk/goit-devops.git $VALUES_BRANCH
          '''
        }
      }
    }
  }
}
