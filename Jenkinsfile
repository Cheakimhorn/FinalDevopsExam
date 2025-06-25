pipeline {
    agent any

    environment {
        DEPLOY_PLAYBOOK = 'ansible/deploy_laravel.yml'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        pollSCM('H/5 * * * *')  // Every 5 minutes
    }

    stages {
        stage('Clone') {
            steps {
                git 'https://github.com/Cheakimhorn/FinalDevopsExam.git'
            }
        }
        
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Composer & NPM') {
            steps {
                dir('laravel') {
                    sh 'composer install --no-interaction --prefer-dist'
                    sh 'npm install'
                    sh 'npm run build'
                }
            }
        }

        stage('Run Tests (SQLite)') {
            steps {
                dir('laravel') {
                    sh '''
                    cp .env .env.testing
                    sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=sqlite/' .env.testing
                    sed -i 's|^DB_DATABASE=.*|DB_DATABASE=database/database.sqlite|' .env.testing
                    touch database/database.sqlite
                    php artisan migrate --env=testing
                    php artisan test --env=testing
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                sh "ansible-playbook ${DEPLOY_PLAYBOOK}"
            }
        }
    }

    post {
        failure {
            emailext (
                subject: "❌ Build Failed: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                body: """<p>Build failed on ${env.JOB_NAME} [#${env.BUILD_NUMBER}]</p>
                         <p>Check console log at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'srengty@gmail.com',
                recipientProviders: [developers(), culprits()]
            )
        }
    }
}