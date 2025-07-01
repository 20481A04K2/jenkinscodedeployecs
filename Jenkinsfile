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
    S3_BUCKET = 'vamsi-deploy-artifacts'
    IMAGEDEF_KEY = 'ecs/imagedefinitions.json'
    APPSPEC_KEY = 'ecs/appspec.yaml'
  }

  stages {
    stage('Ensure CodeDeploy App and DG') {
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

            echo "🔧 Checking Deployment Group..."
            DG_EXISTS=\$(aws deploy get-deployment-group \
              --application-name \$CODEDEPLOY_APP \
              --deployment-group-name \$CODEDEPLOY_DG \
              --region \$AWS_REGION \
              --query 'deploymentGroupInfo.deploymentGroupName' \
              --output text 2>/dev/null || echo "MISSING")

            if [ "\$DG_EXISTS" = "MISSING" ]; then
              aws deploy create-deployment-group \
                --application-name \$CODEDEPLOY_APP \
                --deployment-group-name \$CODEDEPLOY_DG \
                --deployment-config-name CodeDeployDefault.ECSAllAtOnce \
                --deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
                --blue-green-deployment-configuration 'terminateBlueInstancesOnDeploymentSuccess={action=TERMINATE,terminationWaitTimeInMinutes=1},deploymentReadyOption={actionOnTimeout=CONTINUE_DEPLOYMENT}' \
                --load-balancer-info "targetGroupPairInfoList=[{targetGroups=[{name=vamsi-target-ip},{name=vamsi-target-ip-green}],prodTrafficRoute={listenerArns=[\\"arn:aws:elasticloadbalancing:ap-south-1:337243655832:listener/app/vamsi-alb/2d62fc67cc787482/b7e94f9c1f19071f\\"]},testTrafficRoute={listenerArns=[\\"arn:aws:elasticloadbalancing:ap-south-1:337243655832:listener/app/vamsi-alb/2d62fc67cc787482/dd7f07964f1faae1\\"]}}]" \
                --ecs-services clusterName=\$ECS_CLUSTER,serviceName=\$ECS_SERVICE \
                --service-role-arn \$ECS_ROLE_ARN \
                --region \$AWS_REGION
              echo "✅ Created Deployment Group."
            else
              echo "✅ Deployment Group exists."
            fi
          """
        }
      }
    }

    stage('Trigger CodeBuild (build & push + upload files)') {
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

    stage('Trigger CodeDeploy') {
      steps {
        script {
          def appspecContent = sh(
            script: "aws s3 cp s3://$S3_BUCKET/$APPSPEC_KEY - --region $AWS_REGION",
            returnStdout: true
          ).trim()

          sh """
            echo "📦 Triggering CodeDeploy using separate appspec.yaml + imagedefinitions.json..."
            aws deploy create-deployment \
              --application-name \$CODEDEPLOY_APP \
              --deployment-group-name \$CODEDEPLOY_DG \
              --revision revisionType=AppSpecContent,appSpecContent={content='''${appspecContent}'''} \
              --region \$AWS_REGION \
              --s3-location bucket=\$S3_BUCKET,key=\$IMAGEDEF_KEY,bundleType=JSON
          """
        }
      }
    }
  }

  post {
    success {
      echo "✅ ECS Blue-Green Deployment via CodeDeploy succeeded!"
    }
    failure {
      echo "❌ Deployment failed. Check logs in CodeBuild and CodeDeploy."
    }
  }
}
