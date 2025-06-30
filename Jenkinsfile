pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    CODEBUILD_PROJECT = 'vamsi-codebuild-project'
    GITHUB_REPO_URL = 'https://github.com/20481A04K2/awsfrontendecs.git'
    SERVICE_ROLE_ARN = 'arn:aws:iam::337243655832:role/service-role/codebuild-vamsi-project-service-role'
    CODEDEPLOY_APP = 'vamsi-app'
    CODEDEPLOY_DG = 'vamsi-dg'
    ECS_CLUSTER = 'vamsi-cluster'
    ECS_SERVICE = 'vamsi-task-service-8q8i0t0l'
    ECS_ROLE_ARN = 'arn:aws:iam::337243655832:role/ecsCodeDeployRole'
    TARGET_GROUP_NAME = 'vamsi-ecs-tg'
  }

  stages {
    stage('Create CodeDeploy App and DG') {
      steps {
        script {
          sh """
          echo "🔧 Creating CodeDeploy App if not exists..."
          APP_EXISTS=\$(aws deploy get-application --application-name $CODEDEPLOY_APP --region $AWS_REGION --query 'application.applicationName' --output text 2>/dev/null || echo MISSING)
          if [ "\$APP_EXISTS" = "MISSING" ]; then
            aws deploy create-application \
              --application-name $CODEDEPLOY_APP \
              --compute-platform ECS \
              --region $AWS_REGION
          else
            echo "✅ CodeDeploy app exists: \$APP_EXISTS"
          fi

          echo "🔧 Creating CodeDeploy Deployment Group if not exists..."
          DG_EXISTS=\$(aws deploy get-deployment-group --application-name $CODEDEPLOY_APP --deployment-group-name $CODEDEPLOY_DG --region $AWS_REGION --query 'deploymentGroupInfo.deploymentGroupName' --output text 2>/dev/null || echo MISSING)
          if [ "\$DG_EXISTS" = "MISSING" ]; then
            aws deploy create-deployment-group \
              --application-name $CODEDEPLOY_APP \
              --deployment-group-name $CODEDEPLOY_DG \
              --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
              --service-role-arn $ECS_ROLE_ARN \
              --ecs-services clusterName=$ECS_CLUSTER,serviceName=$ECS_SERVICE \
              --region $AWS_REGION
          else
            echo "✅ CodeDeploy Deployment Group exists: \$DG_EXISTS"
          fi
          """
        }
      }
    }

    stage('Trigger CodeBuild') {
      steps {
        script {
          sh """
          echo "▶️ Starting CodeBuild project..."
          aws codebuild start-build \
            --project-name $CODEBUILD_PROJECT \
            --region $AWS_REGION
          """
        }
      }
    }

    stage('Deploy with CodeDeploy') {
      steps {
        script {
          sh """
          echo "🚀 Creating a deployment..."
          aws deploy create-deployment \
            --application-name $CODEDEPLOY_APP \
            --deployment-group-name $CODEDEPLOY_DG \
            --github-location repository=20481A04K2/awsfrontendecs,commitId=main \
            --file-exists-behavior OVERWRITE \
            --region $AWS_REGION
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD via CodeBuild → CodeDeploy to ECS triggered successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check AWS CodeBuild or CodeDeploy logs."
    }
  }
}
