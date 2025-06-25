pipeline {
    agent {
        docker {
            image 'php:8.2-apache'  // Using official PHP image with Apache
            args '-v /var/run/docker.sock:/var/run/docker.sock'
            reuseNode true
        }
    }

    environment {
        DEPLOY_PLAYBOOK = 'ansible/deploy_laravel.yml'
        COMPOSER_ALLOW_SUPERUSER = 1
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    triggers {
        pollSCM('H/5 * * * *')  // Poll SCM every 5 minutes
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/Cheakimhorn/FinalDevopsExam.git',
                        credentialsId: 'Jenkins'
                    ]],
                    extensions: [[
                        $class: 'CleanBeforeCheckout'
                    ]]
                ])
            }
        }

        stage('Install System Dependencies') {
            steps {
                sh '''
                apt-get update && apt-get install -y \
                    git \
                    unzip \
                    curl \
                    npm \
                    default-mysql-client \
                    libzip-dev \
                    libpng-dev \
                    libonig-dev \
                    libxml2-dev \
                    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip
                '''
            }
        }

        stage('Install Composer') {
            steps {
                sh '''
                curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
                chmod +x /usr/local/bin/composer
                composer --version
                '''
            }
        }

        stage('Install App Dependencies') {
            steps {
                dir('laravel') {
                    sh '''
                    composer install --no-interaction --prefer-dist --optimize-autoloader
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
                    php artisan config:clear
                    php artisan migrate --env=testing
                    php artisan test --env=testing
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            agent {
                docker {
                    image 'python:3.9-alpine'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                    reuseNode true
                }
            }
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'ansible-ssh-key',
                    keyFileVariable: 'SSH_KEY',
                    usernameVariable: 'SSH_USER'
                )]) {
                    sh '''
                    pip install ansible
                    ansible-playbook ${DEPLOY_PLAYBOOK} --private-key ${SSH_KEY} -u ${SSH_USER}
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
            script {
                // Archive test results if they exist
                junit 'laravel/tests/**/*.xml' 
            }
        }
        failure {
            emailext(
                subject: "❌ Build Failed: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                body: """<p>Build failed on ${env.JOB_NAME} [#${env.BUILD_NUMBER}]</p>
                         <p>Check logs at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>
                         <p>Commit: ${env.GIT_COMMIT}</p>
                         <p>Error: ${currentBuild.result}</p>""",
                to: 'srengty@gmail.com,kimhornchea612@gmail.com',
                mimeType: 'text/html',
                attachLog: true
            )
        }
        success {
            emailext(
                subject: "✅ Build Success: ${env.JOB_NAME} [#${env.BUILD_NUMBER}]",
                body: """<p>Build succeeded on ${env.JOB_NAME} [#${env.BUILD_NUMBER}]</p>
                         <p>View results at: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'srengty@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}