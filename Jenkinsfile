pipeline {
    agent {
        docker {
            image 'composer:latest' // Includes PHP & Composer
            args '-v /var/run/docker.sock:/var/run/docker.sock' // If needed
        }
    }

    environment {
        DEPLOY_PLAYBOOK = 'ansible/deploy_laravel.yml'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    triggers {
        pollSCM('H/5 * * * *') // Check GitHub every 5 minutes
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('laravel') {
                    sh '''
                    apt-get update && apt-get install -y npm
                    composer install --no-interaction --prefer-dist
                    npm install
                    npm run build
                    '''
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
            emailext(
                subject: "❌ Build Failed: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                body: """<p>Build failed on ${env.JOB_NAME} [#${env.BUILD_NUMBER}]</p>
                         <p>Check logs at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'srengty@gmail.com,kimhornchea612@gmail.com'
            )
        }
    }
}
