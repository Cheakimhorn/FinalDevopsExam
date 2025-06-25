pipeline {
    agent {
        docker {
            image 'php:8.2-fpm'
            args '-u root'
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
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                apt-get update && apt-get install -y curl nodejs npm
                if ! command -v composer >/dev/null 2>&1; then
                    curl -sS https://getcomposer.org/installer -o composer-installer.php
                    php composer-installer.php
                    mv composer.phar /usr/local/bin/composer
                    rm composer-installer.php
                fi
                composer install --no-interaction --prefer-dist
                npm install
                npm run build
                '''
            }
        }

        stage('Run Tests (SQLite)') {
            steps {
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

        stage('Deploy with Ansible') {
            steps {
                sh '''
                apt-get install -y ansible
                ansible-playbook ${DEPLOY_PLAYBOOK}
                '''
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