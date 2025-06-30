pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    CODEBUILD_PROJECT = 'vamsi-codebuild-project'
    SERVICE_ROLE_ARN = 'arn:aws:iam::337243655832:role/service-role/codebuild-vamsi-project-service-role'
    CODEDEPLOY_APP = 'vamsi-app'
    CODEDEPLOY_DG = 'vamsi-dg'
    ECS_CLUSTER = 'vamsi-cluster'
    ECS_SERVICE = 'vamsi-task-service-8q8i0t0l'
    ECS_ROLE_ARN = 'arn:aws:iam::337243655832:role/ecsCodeDeployRole'
    TARGET_GROUP_NAME = 'vamsi-ecs-tg'
  }

  stages {

    stage('Create CodeDeploy App and Deployment Group') {
      steps {
        script {
          sh """
          echo "🔧 Checking/Creating CodeDeploy Application..."
          APP_EXISTS=\$(aws deploy get-application \
            --application-name $CODEDEPLOY_APP \
            --region $AWS_REGION \
            --query 'application.applicationName' \
            --output text 2>/dev/null || echo "MISSING")

          if [ "\$APP_EXISTS" = "MISSING" ]; then
            aws deploy create-application \
              --application-name $CODEDEPLOY_APP \
              --compute-platform ECS \
              --region $AWS_REGION
            echo "✅ CodeDeploy application created."
          else
            echo "✅ CodeDeploy application already exists."
          fi

          echo "🔧 Checking/Creating CodeDeploy Deployment Group..."
          DG_EXISTS=\$(aws deploy get-deployment-group \
            --application-name $CODEDEPLOY_APP \
            --deployment-group-name $CODEDEPLOY_DG \
            --region $AWS_REGION \
            --query 'deploymentGroupInfo.deploymentGroupName' \
            --output text 2>/dev/null || echo "MISSING")

          if [ "\$DG_EXISTS" = "MISSING" ]; then
            aws deploy create-deployment-group \
              --application-name $CODEDEPLOY_APP \
              --deployment-group-name $CODEDEPLOY_DG \
              --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
              --service-role-arn $ECS_ROLE_ARN \
              --ecs-services clusterName=$ECS_CLUSTER,serviceName=$ECS_SERVICE \
              --load-balancer-info "targetGroupInfoList=[{name=$TARGET_GROUP_NAME}]" \
              --region $AWS_REGION
            echo "✅ Deployment Group created."
          else
            echo "✅ Deployment Group already exists."
          fi
          """
        }
      }
    }

    stage('Trigger CodeBuild') {
      steps {
        script {
          sh """
          echo "▶️ Triggering CodeBuild project: $CODEBUILD_PROJECT..."
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
          echo "🚀 Creating CodeDeploy deployment..."
          aws deploy create-deployment \
            --application-name $CODEDEPLOY_APP \
            --deployment-group-name $CODEDEPLOY_DG \
            --revision "revisionType=AppSpecContent,appSpecContent={content=\\\"file://appspec.yaml\\\"}" \
            --region $AWS_REGION
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD Pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check CodeBuild and CodeDeploy logs in AWS Console."
    }
  }
}
