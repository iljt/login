pipeline {
    agent any

    parameters {
        // 分支选择下拉菜单
        choice(name: 'BRANCH_NAME', choices: [], description: '请选择需要构建的分支')

        // 构建平台选择下拉菜单
        choice(name: 'BUILD_PLATFORM', choices: ['android', 'ios'], description: '请选择构建平台')

        // 构建类型选择下拉菜单：Release 或 Debug
        choice(name: 'BUILD_TYPE', choices: ['release', 'debug'], description: '请选择构建类型')

        // 可选：Flutter 构建参数
        string(name: 'FLUTTER_BUILD_ARGS', defaultValue: '', description: '请输入Flutter构建参数（例如：--target-platform android-arm,android-arm64）')
    }

    environment {
       // PATH = "D:\\flutter\\bin;${env.PATH}" // Windows 路径示例
        PGY_API_KEY = credentials('pgyer_api_key')
        PGY_USER_KEY = credentials('pgyer_user_key')
    }

    stages {
        stage('从Git Checkout') {
            steps {
              script {
               // 动态获取 Git 仓库的所有分支
               def branches = sh(script: "git branch -r | sed 's/origin\\///' | grep -v 'HEAD' | sort", returnStdout: true).trim().split("\n")

               // 默认选择的分支
               def defaultBranch = 'master'

               // 如果默认分支存在于获取的分支列表中，设置 BRANCH_NAME 参数的默认值为 'master'
               if (branches.contains(defaultBranch)) {
                   params.BRANCH_NAME = defaultBranch
                } else {
                // 如果默认分支不存在，选择列表中的第一个分支
                 params.BRANCH_NAME = branches[0]
                }
               }
                // 使用选择的分支进行拉取
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
                   // 动态设置Flutter路径 '/path/to/flutter'需改为macOS上的Flutter SDK 路径，比如 /usr/local/bin/flutter
                    if (isUnix()) {
                        env.FLUTTER_HOME = '/path/to/flutter' // macOS/Linux 路径
                    } else {
                        env.FLUTTER_HOME = 'D:\\flutter\\bin' // Windows 路径
                    }
                    // 更新 PATH 环境变量
                    env.PATH = "${env.FLUTTER_HOME};${env.PATH}"
                }
            }
        }

        stage('打包Build') {
            steps {
                dir('login') {
                    // 安装 Flutter 依赖
                    sh 'flutter pub get'

                    // 根据选择的平台和构建类型执行构建
                    script {
                        if (params.BUILD_PLATFORM == 'android') {
                            if (params.BUILD_TYPE == 'release') {
                                sh "flutter build apk --release ${params.FLUTTER_BUILD_ARGS}" // Android Release 构建
                            } else if (params.BUILD_TYPE == 'debug') {
                                sh "flutter build apk --debug ${params.FLUTTER_BUILD_ARGS}" // Android Debug 构建
                            }
                        } else if (params.BUILD_PLATFORM == 'ios') {
                            if (params.BUILD_TYPE == 'release') {
                                sh "flutter build ios --release ${params.FLUTTER_BUILD_ARGS}" // iOS Release 构建
                            } else if (params.BUILD_TYPE == 'debug') {
                                sh "flutter build ios --debug ${params.FLUTTER_BUILD_ARGS}" // iOS Debug 构建
                            }
                        }
                    }
                }
            }
        }

        stage('归档Archive') {
            steps {
                // 归档 APK 或 iOS 包文件
                script {
                    if (params.BUILD_PLATFORM == 'android') {
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'build/app/outputs/flutter-apk/*.apk'
                    } else if (params.BUILD_PLATFORM == 'ios') {
                        archiveArtifacts allowEmptyArchive: true, artifacts: 'build/ios/ipa/*.ipa'
                    }
                }
            }
        }

        stage('上传到蒲公英') {
            steps {
                script {
                    if (params.BUILD_PLATFORM == 'android') {
                        def apkPath = "build/app/outputs/flutter-apk/app-${params.BUILD_TYPE}.apk"
                        // 将上传结果存储到环境变量
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
                    } else if (params.BUILD_PLATFORM == 'ios') {
                        def ipaPath = "build/ios/ipa/app-${params.BUILD_TYPE}.ipa"
                                         // 将上传结果存储到环境变量
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
                    // 使用 Groovy 的 JsonSlurper 解析 JSON 响应
                    //Jenkins 需要安装 Pipeline Utility Steps 插件才能使用 readJSON 步骤
                    def jsonResponse = readJSON text: env.UPLOAD_RESPONSE
                    def buildQRCodeURL = jsonResponse.data.buildQRCodeURL
                    echo "蒲公英下载地址: $buildQRCodeURL"

                    // 钉钉通知消息
                    def webhookUrl = "https://oapi.dingtalk.com/robot/send?access_token=3f097c4f1f749329a795bc0e23e40b101f3b0168e837dfd86de1e77df440660a"
                    // 构建消息内容
                    def message = [
                        msgtype: "text",
                        text: [
                            content: "Flutter 应用已打包并上传到蒲公英，下载地址：${buildQRCodeURL}，分支：${params.BRANCH_NAME}，平台：${params.BUILD_PLATFORM}，类型：${params.BUILD_TYPE}，关键词：package"
                        ]
                    ]
                     // 转换为 JSON 格式
                    def messageJson = groovy.json.JsonOutput.toJson(message)
                    // 发送 HTTP 请求
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