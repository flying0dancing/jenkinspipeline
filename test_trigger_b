#!groovy
@Library('pipeline-libs') _

 SELECTED_ENV = [
                homeDir  : '/home/test',
                configDir: 'scripts/sha-qa2-env',
                cluster  : false,
                skipS3DeployDownload: false
        ]
pipeline {
    agent { label 'PRODUCT-CI-SHA-LOCAL1' }
    options {
        timeout(time: 60, unit: 'MINUTES') 
    }
    
    stages {
        stage('checkout'){
			steps{
				echo "start job B ${JOB_URL}"
				echo "branch number: ${env.BUILD_NUMBER}"
				echo "${TEST_WORKSPACE}"
				echo "${S3BUCKET}"
				echo "${S3DOWNPATH}"
				echo "${DOWNLOADFILENAMES}"
				sh 'pwd'
				checkoutIgnis()
				
			}
		}
        stage('Copy Installers') {
            // This stage is only executed as a workaround for environments that have been closed off from AWS
            when {
                expression {
                    return SELECTED_ENV.skipS3DeployDownload
                }
            }
            steps {
                copyToEnvironment(SELECTED_ENV, 'design-studio/2.3.0-b1090/fcr-engine-design-studio-2.3.0-b1090.zip', env.WORKSPACE)
                
            }
        }
		stage('download package'){
			steps{
				echo "download all package"
                //downloadProductPackage(S3BUCKET,S3DOWNPATH,DOWNLOADFILENAMES)
                copyToEnvironmenttest()
			}
		}
		stage('build package'){
			steps{
				echo "build all packages"
			}
		}
		stage('upload package'){
           steps{
			   echo "upload all packages"
			} 
        }
		
    }
	post {
        always {
            echo 'This will always run'
        }
        success {
            echo 'This will run only if successful'

        }
        failure {
            echo 'This will run only if failed'
        }
        unstable {
            echo 'This will run only if the run was marked as unstable'
        }
        changed {
            echo 'This will run only if the state of the Pipeline has changed'
            echo 'For example, if the Pipeline was previously failing but is now successful'
        }
    }
}



void checkoutIgnis(){
    checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, 
        extensions: [[$class: 'CloneOption', depth: 0, honorRefspec: true, noTags: true, reference: '', shallow: true],
                    [$class: 'CleanBeforeCheckout']], 
        submoduleCfg: [], 
        userRemoteConfigs: [[credentialsId: '4775e132-d845-4896-971d-f2a210ccdb02', url: "ssh://git@bitbucket.lombardrisk.com:7999/cs/ignis.git"]]])      
}

void downloadProductPackage(s3bucket,s3repo,packageNames){

    String[] packageNameArr=packageNames.split(':')
    for(String packageName in packageNameArr){
        println packageName
        //String localPath = 'Downloads/'+packageName
        //String remotePath = s3repo+packageName
        //String bucket = aws.S3.Deploy.bucketName
        //String cmd = "s3 cp s3://$bucket/$remotePath $localPath  --no-progress"
        //execute(cmd)
        withAWS(credentials: 'aws',region: 'eu-west-1') {
            //execute('s3 cp s3://lrm-deploy/FCR-Engine/Releases/CandidateReleases/design-studio/2.3.0-b1074/fcr-engine-design-studio-2.3.0-b1074.zip Downloads/fcr-engine-design-studio-2.3.0-b1074.zip --no-progress')
            //execute('s3 cp s3://'+s3bucket+'/'+s3repo+packageName+' '+ packageName+' --no-progress --no-verify-ssl') //ssl error
            s3Download(bucket:s3bucket, path:s3repo+packageName,file:packageName,force:true) 
            
            //s3Download(bucket:s3bucket, path:'FCR-Engine/Releases/CandidateReleases/design-studio/2.3.0-b1090/fcr-engine-design-studio-2.3.0-b1090.zip',file:'fcr-engine-design-studio-2.3.0-b1090.zip',force:true)
        }
    }
    
   // withAWS(credentials: 'aws',region: 'eu-west-1') {
            //execute('s3 cp s3://lrm-deploy/FCR-Engine/Releases/CandidateReleases/design-studio/2.3.0-b1074/fcr-engine-design-studio-2.3.0-b1074.zip fcr-engine-design-studio-2.3.0-b1074.zip --no-progress')
            //execute('s3 cp s3://lrm-deploy/arproduct/mas/CandidateReleases/2.33.0/b43/CE_MAS_v3.0.1-b43_sign.lrm Downloads/CE_MAS_v3.0.1-b43_sign.lrm --no-progress --no-verify-ssl') //ssl error
            //s3Download(bucket:s3bucket, path:s3repo+packageName,file:packageName,force:true) 
            
            //s3Download(bucket:s3bucket, path:'FCR-Engine/Releases/CandidateReleases/design-studio/2.3.0-b1074/fcr-engine-design-studio-2.3.0-b1074.zip',file:'fcr-engine-design-studio-2.3.0-b1074.zip',force:true)
       // }
    
}

private void copyToEnvironmenttest() {
    
    //echo "method 1" 
    //aws.s3Deploy().get('fcrEngine').download('design-studio/2.3.0-b1074/fcr-engine-design-studio-2.3.0-b1074.zip','fcr-engine-design-studio-2.3.0-b1074.zip')
    echo "method 2" 
    String bucket = 'lrm-deploy'
    String remotePath='FCR-Engine/Releases/CandidateReleases/design-studio/2.3.0-b1090/fcr-engine-design-studio-2.3.0-b1090.zip'
    String localPath='fcr-engine-design-studio-2.3.0-b1090.zip'
    String cmd = "s3 cp s3://$bucket/$remotePath $localPath  --no-progress  --no-verify-ssl"//
    execute(cmd)
   
}

private void copyToEnvironment(Map selectedEnv, String candidateReleasePath, String agentWorkspace) {
    if (candidateReleasePath) {
        s3Deploy.download candidateReleasePath
        copyFileToEnvironment(selectedEnv, candidateReleasePath, candidateReleasePath, agentWorkspace)
    }
}
private void copyFileToEnvironment(Map selectedEnv, String localPath, String remotePath, String agentWorkspace) {
    String fullRemotePath = "${agentWorkspace}/${selectedEnv.configDir}/${remotePath}"
    String remoteInstallerDirectory = extractDirectoryFromPath(fullRemotePath)

    echo "Copying [$localPath] to [$fullRemotePath] on ${selectedEnv.host}"

    sshagent(credentials: [selectedEnv.credentials]) {
        sh "ssh -o StrictHostKeyChecking=no ${selectedEnv.host} 'hostname'"
        sh "ssh -o StrictHostKeyChecking=no ${selectedEnv.host} 'mkdir -p ${remoteInstallerDirectory}'"
        sh "scp -o StrictHostKeyChecking=no ${localPath} ${selectedEnv.host}:${fullRemotePath}"
    }
}
private String extractDirectoryFromPath(String path) {
    def directoryMatcher = (path =~ /(^.*\/)/);
    if (directoryMatcher.find()) {
        return directoryMatcher[0][1];
    }
    return null;
}
private def execute(String cmd) {
    withCredentials([usernamePassword(
            credentialsId: 'aws',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {

        String localBin = "${env.HOME}/.local/bin"

        withEnv(["PATH+LOCAL_BIN=$localBin"]) {
            sh "aws $cmd"
        }
    }
}

