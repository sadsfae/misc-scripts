pipeline {
    agent any    
    
    environment {
        COMPOSE_PROJECT_NAME = "${env.JOB_NAME}-${env.BUILD_ID}"
        VOLUME = "${env.WORKSPACE}"
    }
    
    stages {
        stage('Checkout'){
            steps {
                script {
                    if(env.GERRIT_REFSPEC && env.GERRIT_PATCHSET_REVISION) {
                        println "GERRIT_REFSPEC: $GERRIT_REFSPEC"
                        checkout([
                            $class: 'GitSCM', 
                            branches: [[name: "$GERRIT_PATCHSET_REVISION"]], 
                            doGenerateSubmoduleConfigurations: false, 
                            extensions: [], 
                            submoduleCfg: [], 
                            userRemoteConfigs: [[
                                refspec: "$GERRIT_REFSPEC", 
                                url: 'ssh://youruser@review.gerrithub.io:29418/redhat-performance/quads'
                            ]]
                        ])
                    } else {
                        git url: 'git@github.com:redhat-performance/quads.git'
                    }
                }
            }
        }
        stage('Setup') {
            steps {
                echo "WARN: make sure to replace the following on the pipeline after docker changes are committed."
                sh 'sed -i "s/80/81/g" docker/docker-compose.yml'
                sh 'sed -i "s/443/444/g" docker/docker-compose.yml'
                sh 'sed -i "s@\\/opt\\/docker\\/quads@\${VOLUME}@g" docker/docker-compose.yml'
                sh 'docker-compose -f docker/docker-compose.yml build'
                sh 'docker-compose -f docker/docker-compose.yml up -d'
            }
        }
        stage('Lint') {
        	steps {
        	    sh "flake8 quads --ignore=F401,E302,E226,E231,E501,E225,E402,F403,F999,E127,W191,E101,E711,E201,E202,E124,E203,E122,E111,E128,E116,E222"
        	    sh "shellcheck bin/*.sh --exclude=SC1068,SC2086,SC2046,SC2143,SC1068,SC2112,SC2002,SC2039,SC2155,SC2015,SC2012,SC2013,SC2034,SC2006,SC2059,SC2148,SC2154,SC2121,SC2154,SC2028,SC2003,SC2035,SC2005,SC2027,SC2018,SC2019,SC2116,SC2001"
        	}
        }
        stage('Test') {
        	steps {
        	    sh "testing/dev_tests.sh"
        	}
        }

    }
        
    post {
        always {
            sh 'docker-compose -f docker/docker-compose.yml down'
            sh 'docker volume rm \$(docker volume ls -q)'
        }
    }
}
