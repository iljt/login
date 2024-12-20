pipeline {
    agent any

    environment {
        PGY_API_KEY = credentials('pgyer_api_key')
        PGY_USER_KEY = credentials('pgyer_user_key')
    }

    parameters {
        gitParameter name: 'BRANCH_NAME',
                         type: 'PT_BRANCH',
                         defaultValue: 'master',
                         description: '选择构建的 Git 分支',
                         branchFilter: 'origin/*',  // 获取所有分支
                         sortMode: 'ASCENDING'
        choice(name: 'BUILD_PLATFORM', choices: ['android', 'ios'], description: '请选择构建平台')
        choice(name: 'BUILD_TYPE', choices: ['release', 'debug'], description: '请选择构建类型')
        string(name: 'FLUTTER_BUILD_ARGS', defaultValue: '', description: '请输入Flutter构建参数（例如：--target-platform android-arm,android-arm64）')
    }

    stages {


        stage('从Git Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${params.BRANCH_NAME}"]],
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
            cleanWs deleteDirs: true // 强制删除目录中的所有内容
        }
    }
}
