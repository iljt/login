pipeline {
    agent any

    environment {
        PGY_API_KEY = credentials('pgyer_api_key')
        PGY_USER_KEY = credentials('pgyer_user_key')
    }

    parameters {
        choice(name: 'BUILD_PLATFORM', choices: ['android', 'ios'], description: '请选择构建平台')
        choice(name: 'BUILD_TYPE', choices: ['release', 'debug'], description: '请选择构建类型')
        string(name: 'FLUTTER_BUILD_ARGS', defaultValue: '', description: '请输入Flutter构建参数（例如：--target-platform android-arm,android-arm64）')
    }

    stages {
        stage('获取分支列表') {
            steps {
                script {
                    // 获取分支列表
                    def branchList = []
                    if (fileExists('branch_list.txt')) {
                        // 如果文件已经存在，读取文件内容
                        branchList = readFile('branch_list.txt').split('\n')
                    } else {
                        // 如果文件不存在，则通过 Git 获取分支列表
                        branchList = sh(script: 'git ls-remote --heads git@github.com:iljt/login.git', returnStdout: true)
                            .split('\n')
                            .collect { it.split()[1].replaceAll('refs/heads/', '') }
                            .findAll { it != 'master' && it != 'dev' } // 排除默认的分支 master 和 dev
                        // 将分支列表写入文件，方便下次使用
                        writeFile file: 'branch_list.txt', text: branchList.join('\n')
                    }
                    // 将分支列表加入环境变量以供后续步骤使用
                    env.BRANCH_LIST = branchList.join(',')
                    echo "Branch List: ${env.BRANCH_LIST}"
                }
            }
        }

        stage('选择构建分支') {
            steps {
                script {
                    def branchList = env.BRANCH_LIST.split(',')
                    def branchChoice = input(
                        message: '请选择需要构建的分支',
                        parameters: [
                            choice(name: 'BRANCH_NAME', choices: ['master', 'dev'] + branchList, description: '请选择需要构建的分支')
                        ]
                    )
                    env.BRANCH_NAME = branchChoice
                    echo "Selected Branch: ${env.BRANCH_NAME}"
                }
            }
        }

        stage('从Git Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[url: 'git@github.com:iljt/login.git']]
                ])
            }
        }

        stage('设置 Flutter Sdk Path') {
            steps {
                script {
                    if (isUnix()) {
                        env.FLUTTER_HOME = '/path/to/flutter' // macOS/Linux 路径
                    } else {
                        env.FLUTTER_HOME = 'D:\\flutter\\bin' // Windows 路径
                    }
                    env.PATH = "${env.FLUTTER_HOME};${env.PATH}"
                }
            }
        }

        stage('打包Build') {
            steps {
                dir('login') {
                    sh 'flutter pub get'

                    script {
                        if (env.BUILD_PLATFORM == 'android') {
                            if (env.BUILD_TYPE == 'release') {
                                sh "flutter build apk --release ${env.FLUTTER_BUILD_ARGS}"
                            } else if (env.BUILD_TYPE == 'debug') {
                                sh "flutter build apk --debug ${env.FLUTTER_BUILD_ARGS}"
                            }
                        } else if (env.BUILD_PLATFORM == 'ios') {
                            if (env.BUILD_TYPE == 'release') {
                                sh "flutter build ios --release ${env.FLUTTER_BUILD_ARGS}"
                            } else if (env.BUILD_TYPE == 'debug') {
                                sh "flutter build ios --debug ${env.FLUTTER_BUILD_ARGS}"
                            }
                        }
                    }
                }
            }
        }

        stage('归档Archive') {
            steps {
                script {
                    if (env.BUILD_PLATFORM == 'android') {
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'build/app/outputs/flutter-apk/*.apk'
                    } else if (env.BUILD_PLATFORM == 'ios') {
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'build/ios/ipa/*.ipa'
                    }
                }
            }
        }

        stage('上传到蒲公英') {
            steps {
                script {
                    if (env.BUILD_PLATFORM == 'android') {
                        def apkPath = "build/app/outputs/flutter-apk/app-${env.BUILD_TYPE}.apk"
                        env.UPLOAD_RESPONSE = sh(
                            script: """
                            curl -F "file=@${apkPath}" \
                                 -F "_api_key=$PGY_API_KEY" \
                                 -F "uKey=$PGY_USER_KEY" \
                                 https://www.pgyer.com/apiv2/app/upload
                            """,
                            returnStdout: true
                        ).trim()
                        echo "Upload response: ${env.UPLOAD_RESPONSE}"
                    } else if (env.BUILD_PLATFORM == 'ios') {
                        def ipaPath = "build/ios/ipa/app-${env.BUILD_TYPE}.ipa"
                        env.UPLOAD_RESPONSE = sh(
                            script: """
                            curl -F "file=@${ipaPath}" \
                                 -F "_api_key=$PGY_API_KEY" \
                                 -F "uKey=$PGY_USER_KEY" \
                                 https://www.pgyer.com/apiv2/app/upload
                            """,
                            returnStdout: true
                        ).trim()
                        echo "Upload response: ${env.UPLOAD_RESPONSE}"
                    }
                }
            }
        }

        stage('发送钉钉通知') {
            steps {
                script {
                    def jsonResponse = readJSON text: env.UPLOAD_RESPONSE
                    def buildQRCodeURL = jsonResponse.data.buildQRCodeURL
                    echo "蒲公英下载地址: $buildQRCodeURL"

                    def webhookUrl = "https://oapi.dingtalk.com/robot/send?access_token=3f097c4f1f749329a795bc0e23e40b101f3b0168e837dfd86de1e77df440660a"
                    def message = [
                        msgtype: "text",
                        text: [
                            content: "Flutter 应用已打包并上传到蒲公英，下载地址：${buildQRCodeURL}，分支：${env.BRANCH_NAME}，平台：${env.BUILD_PLATFORM}，类型：${env.BUILD_TYPE}，关键词：package"
                        ]
                    ]
                    def messageJson = groovy.json.JsonOutput.toJson(message)
                    sh """
                        curl -X POST -H 'Content-Type: application/json; charset=UTF-8' \
                             -d '${messageJson}' \
                             '${webhookUrl}'
                    """
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
