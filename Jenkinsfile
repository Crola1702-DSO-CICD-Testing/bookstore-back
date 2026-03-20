pipeline { 
   agent { label 'built-in' } 
   environment {
      GIT_ORG = 'Crola1702-DSO-CICD-Testing'
      GIT_REPO = 'bookstore-back'
      GIT_CREDENTIAL_ID = 'github-token'
      SONARQUBE_URL = 'http://sonarqube:9000'
      SONAR_TOKEN = credentials('sonar-login')
      // ARCHID_TOKEN = credentials('archid')
   }
   stages { 
      // stage('Checkout') { 
      //    steps {
      //       scmSkip(deleteBuild: true, skipPattern:'.*\\[ci-skip\\].*')
      //       git branch: 'main', 
      //          credentialsId: env.GIT_CREDENTIAL_ID,
      //          url: 'https://github.com/' + env.GIT_ORG + '/' + env.GIT_REPO
      //    }
      // }
      stage('Build') {
         options {
            timeout(time: 5, unit: 'MINUTES')
         }
         steps {
            script {
               sh "docker build --target build -t ${env.GIT_REPO}-build:latest ."
            }
         }
      }
      stage('Unit Tests') {
         options {
            timeout(time: 5, unit: 'MINUTES')
         }
         steps {
            script {
               sh "docker build --target unit-tests -t ${env.GIT_REPO}-test:latest ."
            }
         }
      }
      stage('Integration Tests') {
         options {
            timeout(time: 1, unit: 'MINUTES')
         }
         steps {
            script {
               sh "docker build --target integration-tests -t ${env.GIT_REPO}-integration:latest ."
            }
         }
      }
      stage('Static Analysis') {
         steps {
            script {
               // # `dso-net` debe existir y conectar con el contenedor de SonarQube
               sh """
                  # Crear y usar un builder de Buildx que tenga acceso a la red `dso-net` para comunicarse con SonarQube
                  docker buildx create \
                     --name dso-builder \
                     --driver-opt network=dso-net \
                     --use || docker buildx use dso-builder

                  # Usar el builder para construir la imagen
                  docker buildx build \
                     --secret id=sonar_token,env=${env.SONAR_TOKEN} \
                     --build-arg SONARQUBE_URL=${env.SONARQUBE_URL} \
                     --target static-analysis \
                     --load \
                     -t ${env.GIT_REPO}-static-analysis:latest .
               """
            }
         }
         post {
            always {
               echo "Static analysis completed. Check SonarQube for details."
            }
         }
      }
      stage('Package Runtime Image') {
         options {
            timeout(time: 2, unit: 'MINUTES')
         }
         steps {  
            script {
               CURRENT_STAGE = 'Package Runtime Image'
               sh "docker build -t ${env.GIT_REPO}-runtime:${env.BUILD_ID} -t ${env.GIT_REPO}-runtime:latest ."
               sh "docker save -o ${env.GIT_REPO}-runtime-${env.BUILD_ID}.tar ${env.GIT_REPO}-runtime:latest"
               archiveArtifacts artifacts: "*.tar", fingerprint: true
            }
         }
      }
      stage('GitInspector') { 
         steps {
            withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIAL_ID, passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
               sh 'mkdir -p code-analyzer-report'
               sh """ curl --request POST --url https://code-analyzer.virtual.uniandes.edu.co/analyze --header "Content-Type: application/json" --data '{"repo_url":"git@github.com:${GIT_ORG}/${GIT_REPO}.git", "access_token": "${GIT_PASSWORD}" }' > code-analyzer-report/index.html """   
            }
            publishHTML (target: [
               allowMissing: false,
               alwaysLinkToLastBuild: false,
               keepAll: true,
               reportDir: 'code-analyzer-report',
               reportFiles: 'index.html',
               reportName: "GitInspector"
            ])
         }
      }
      // stage('ARCC') {
      //    // Run arcc analysis
      //    steps {
      //       script {
      //          docker.image('arcc-tools-isis2603:latest').inside('-e ARCHID_TOKEN=${ARCHID_TOKEN}'){
      //             sh '''
      //                java -version
      //                rsync --recursive . bookstore-back
      //                java -cp /eclipse/plugins/org.eclipse.equinox.launcher_1.5.700.v20200207-2156.jar org.eclipse.equinox.launcher.Main -application co.edu.uniandes.archtoring.archtoring bookstore-back
      //             '''
      //          }
      //       }
      //    }
      // }      
   }
   post {
      always {
        cleanWs()
        deleteDir() 
        dir("${env.GIT_REPO}@tmp") {
          deleteDir()
        }
      }
      aborted {
         error("⏰ Pipeline aborted: time limit exceeded at stage '${CURRENT_STAGE}'")
      }
   }
}
