pipeline { 
   agent any 
   environment {
      GIT_REPO = 'bookstore-back'
      GIT_CREDENTIAL_ID = 'github-token'
      // SONARQUBE_URL = 'http://172.24.101.209:8082/sonar-isis2603'
      // ARCHID_TOKEN = credentials('archid')
      // SONAR_TOKEN = credentials('sonar-login')
   }
   stages { 
      stage('Checkout') { 
         steps {
            scmSkip(deleteBuild: true, skipPattern:'.*\\[ci-skip\\].*')
            git branch: 'main', 
               credentialsId: env.GIT_CREDENTIAL_ID,
               url: 'https://github.com/Crola1702-DSO-CICD-Testing/' + env.GIT_REPO
         }
      }
      stage('Build') {
         steps {
            option {
               timeout(time: 5, unit: 'MINUTES')
            }
            script {
               CURRENT_STAGE = 'Build'
               sh "docker build --target build -t ${env.GIT_REPO}-build:latest ."
            }
         }
      }
      stage('Test') {
         options {
            timeout(time: 5, unit: 'MINUTES')
         }
         steps {
            script {
               CURRENT_STAGE = 'Build and Test'
               sh "docker build --target test -t ${env.GIT_REPO}-test:latest ."
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
            }
         }
      }
      stage('Save Docker Artifact') {
         steps {
            script {
               CURRENT_STAGE = 'Save Docker Artifact'
               // Export the Docker image to a .tar file
               sh "docker save -o ${env.GIT_REPO}-runtime-${env.BUILD_ID}.tar ${env.GIT_REPO}-runtime:latest"
               
               // Archive the .tar file natively in Jenkins
               archiveArtifacts artifacts: "*.tar", fingerprint: true
            }
         }
      }
      // stage('GitInspector') { 
      //    steps {
      //       withCredentials([usernamePassword(credentialsId: env.GIT_CREDENTIAL_ID, passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
      //          sh 'mkdir -p code-analyzer-report'
      //          sh """ curl --request POST --url https://code-analyzer.virtual.uniandes.edu.co/analyze --header "Content-Type: application/json" --data '{"repo_url":"git@github.com:Uniandes-isis2603/${GIT_REPO}.git", "access_token": "${GIT_PASSWORD}" }' > code-analyzer-report/index.html """   
      //       }
      //       publishHTML (target: [
      //          allowMissing: false,
      //          alwaysLinkToLastBuild: false,
      //          keepAll: true,
      //          reportDir: 'code-analyzer-report',
      //          reportFiles: 'index.html',
      //          reportName: "GitInspector"
      //       ])
      //    }
      // }
      // stage('Build') {
      //    // Build artifacts
      //    options {
      //       timeout(time: 1, unit: 'MINUTES')
      //    }
      //    steps {
      //       script {
      //          CURRENT_STAGE = 'Build'
      //          docker.image('citools-isis2603:latest').inside('-v $HOME/.m2:/root/.m2:z -u root') {
      //             sh '''
      //                java -version
      //                mvn clean install -DskipTests 
      //             '''
      //          }
      //       }
      //    }
      // }
      // stage('Unit Tests') {
      //    // Run unit tests
      //    options {
      //       timeout(time: 1, unit: 'MINUTES')
      //    }
      //    steps {
      //       script {
      //          CURRENT_STAGE = 'Unit Tests'
      //          docker.image('citools-isis2603:latest').inside('-v $HOME/.m2:/root/.m2:z -u root') {
      //             sh '''
      //                mvn verify -Punit-tests
      //             '''
      //          }
      //       }
      //    }
      // }
      // stage('Integration Tests') {
      //    // Run integration tests
      //    options {
      //       timeout(time: 1, unit: 'MINUTES')
      //    }
      //    steps {
      //       script {
      //          CURRENT_STAGE = 'Integration Tests'
      //          docker.image('citools-isis2603:latest').inside('-v $HOME/.m2:/root/.m2:z -u root') {
      //             sh '''
      //                mvn verify -Pintegration-tests
      //             '''
      //          }
      //       }
      //    }
      // }
      // stage('Static Analysis') {
      //    // Run static analysis
      //    steps {
      //       script {
      //          docker.image('citools-isis2603:latest').inside('-v $HOME/.m2:/root/.m2:z -u root') {
      //             sh '''
      //                mvn sonar:sonar -Dsonar.token=${SONAR_TOKEN} -Dsonar.host.url=${SONARQUBE_URL}
      //             '''
      //          }
      //       }
      //    }
      // }
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
