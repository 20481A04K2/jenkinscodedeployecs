pipeline {
  agent any

  environment {
    AWS_REGION = 'ap-south-1'
    CODEBUILD_PROJECT = 'vamsi-codebuild-project'
    CODEDEPLOY_APP = 'vamsi-app'
    CODEDEPLOY_DG = 'vamsi-dg'
    ECS_CLUSTER = 'vamsi-cluster'
    ECS_SERVICE = 'vamsi-task-service-8q8i0t01'
    ECS_ROLE_ARN = 'arn:aws:iam::337243655832:role/ecsCodeDeployRole'
    TARGET_GROUP_NAME = 'vamsi-target-ip'
    LISTENER_ARN = 'arn:aws:elasticloadbalancing:ap-south-1:337243655832:listener/app/vamsi-alb/2d62fc67cc787482/dd7f07964f1faae1'
    GITHUB_REPO = '20481A04K2/awsfrontendecs'
    GITHUB_BRANCH = 'main'
  }

  stages {
    stage('Create CodeDeploy App & Deployment Group') {
      steps {
        script {
          sh """
          echo "🔧 Checking CodeDeploy application..."
          APP_EXISTS=\$(aws deploy get-application \
            --application-name \$CODEDEPLOY_APP \
            --region \$AWS_REGION \
            --query 'application.applicationName' \
            --output text 2>/dev/null || echo "MISSING")

          if [ "\$APP_EXISTS" = "MISSING" ]; then
            aws deploy create-application \
              --application-name \$CODEDEPLOY_APP \
              --compute-platform ECS \
              --region \$AWS_REGION
            echo "✅ Created CodeDeploy application."
          else
            echo "✅ CodeDeploy application exists."
          fi

          echo "🔧 Checking CodeDeploy Deployment Group..."
          DG_EXISTS=\$(aws deploy get-deployment-group \
            --application-name \$CODEDEPLOY_APP \
            --deployment-group-name \$CODEDEPLOY_DG \
            --region \$AWS_REGION \
            --query 'deploymentGroupInfo.deploymentGroupName' \
            --output text 2>/dev/null || echo "MISSING")

          if [ "\$DG_EXISTS" = "MISSING" ]; then
            aws deploy create-deployment-group \
            --application-name $CODEDEPLOY_APP \
            --deployment-group-name $CODEDEPLOY_DG \
            --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
            --deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
            --blue-green-deployment-configuration 'terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=1},deploymentReadyOption={actionOnTimeout=CONTINUE_DEPLOYMENT},greenFleetProvisioningOption={action=DISCOVER_EXISTING}' \
            --load-balancer-info 'targetGroupPairInfoList=[{targetGroups=[{name=vamsi-target-ip}],prodTrafficRoute={listenerArns=["arn:aws:elasticloadbalancing:ap-south-1:337243655832:listener/app/vamsi-alb/2d62fc67cc787482/b7e94f9c1f19071f"]},testTrafficRoute={listenerArns=["arn:aws:elasticloadbalancing:ap-south-1:337243655832:listener/app/vamsi-alb/2d62fc67cc787482/dd7f07964f1faae1"]}}]' \
            --ecs-services clusterName=$ECS_CLUSTER,serviceName=$ECS_SERVICE \
            --service-role-arn $ECS_ROLE_ARN \
            --region $AWS_REGION
            echo "✅ Created Deployment Group."
          else
            echo "✅ Deployment Group exists."
          fi
          """
        }
      }
    }

    stage('Trigger CodeBuild') {
      steps {
        script {
          sh """
          echo "🚀 Starting CodeBuild..."
          aws codebuild start-build \
            --project-name \$CODEBUILD_PROJECT \
            --region \$AWS_REGION
          """
        }
      }
    }

    stage('Trigger CodeDeploy from GitHub') {
      steps {
        script {
          COMMIT_ID = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

          sh """
          echo "📦 Creating CodeDeploy deployment from GitHub commit: \$COMMIT_ID"

          aws deploy create-deployment \
            --application-name \$CODEDEPLOY_APP \
            --deployment-group-name \$CODEDEPLOY_DG \
            --revision revisionType=GitHub,gitHubLocation={repository=\$GITHUB_REPO,commitId=\$COMMIT_ID} \
            --region \$AWS_REGION
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD pipeline completed successfully using GitHub, CodeBuild, ECS, and CodeDeploy!"
    }
    failure {
      echo "❌ Pipeline failed. Check AWS CodeBuild or CodeDeploy logs."
    }
  }
}
