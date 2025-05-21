package main

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

// 公共文件保存方法
func saveFile(c *gin.Context, formField string, targetDir string) (string, error) {
	// 步骤1：获取上传文件
	file, err := c.FormFile(formField)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("文件缺失: %v", err.Error())})
		return "", err
	}

	// 步骤2：创建目标目录
	if err := os.MkdirAll(targetDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "目录创建失败"})
		return "", fmt.Errorf("创建目录失败: %v", err)
	}

	// 步骤3：生成唯一文件名
	timestamp := time.Now().Format("20060102-150405.000")
	fileName := fmt.Sprintf("%s-%s", formField, timestamp)
	dstPath := filepath.Join(targetDir, fileName)

	// 步骤4：保存文件
	if err := c.SaveUploadedFile(file, dstPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "文件保存失败"})
		return "", fmt.Errorf("保存失败: %v", err)
	}

	return dstPath, nil
}

// 执行Docker命令
func execDockerAsync(arg ...string) {
	go func() {
		// 步骤1：拼装命令参数
		cmd := exec.Command("docker", arg...)

		// 步骤2：捕获命令输出
		var stderr bytes.Buffer
		cmd.Stderr = &stderr

		// 步骤3：执行并记录日志
		if output, err := cmd.CombinedOutput(); err != nil {
			log.Printf("Docker命令执行失败: 命令:%v | 错误:%v | 输出:%s", cmd.Args, err, string(output))
		} else {
			log.Printf("Docker命令执行成功: 输出:%s", string(output))
		}
	}()
}

// 部署Yaml处理器
func deployYamlHandler(c *gin.Context) {
	// 步骤1：获取Stack名称
	stackName := c.PostForm("stackName")
	if strings.TrimSpace(stackName) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "必须提供stackName参数"})
		return
	}

	// 步骤2：保存YAML文件
	yamlPath, err := saveFile(c, "yaml_file", "docker-stack-yaml")
	if err != nil {
		return // 错误响应已在saveFile处理
	}

	// 步骤3：异步执行部署
	execDockerAsync("stack", "deploy", "-c", yamlPath, stackName)

	// 步骤4：返回响应
	c.JSON(http.StatusOK, gin.H{
		"status":  "部署指令已下发",
		"detail":  "后台异步处理中",
		"stack":   stackName,
		"monitor": fmt.Sprintf("/stacks/%s", stackName), // 监控端点示例
	})
}

// 部署tar处理器
func deployTarHandler(c *gin.Context) {

	// 获取部署的目录
	targetDir := c.PostForm("targetDir")
	if strings.TrimSpace(targetDir) == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "必须提供targetDir参数"})
		return
	}

	// 步骤1：保存上传的tar文件到临时目录
	tempDir := os.TempDir()
	tarPath, err := saveFile(c, "file", tempDir)
	if err != nil {
		return // 错误响应已在saveFile处理
	}
	defer os.Remove(tarPath) // 最后清理临时文件

	// 步骤2：配置部署目录
	tempDeployDir := targetDir + "-temp-" + time.Now().Format("20060102150405")
	backupDir := targetDir + "-backup-" + time.Now().Format("20060102150405")

	// 步骤3：执行原子化部署
	if err := atomicDeploy(tarPath, targetDir, tempDeployDir, backupDir); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 步骤4：返回成功响应
	c.JSON(http.StatusOK, gin.H{
		"status":    "部署成功",
		"targetDir": targetDir,
		"time":      time.Now().Format("2006-01-02 15:04:05"),
	})
}

// 执行原子化tar部署
func atomicDeploy(tarPath, targetDir, tempDir, backupDir string) error {
	// 阶段1：准备部署环境
	// 步骤1：创建临时解压目录
	log.Printf("创建临时解压目录: %s", tempDir)
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return fmt.Errorf("临时目录创建失败: %v", err)
	}
	defer func() {
		log.Printf("清理临时目录: %s", tempDir)
		os.RemoveAll(tempDir)
	}()

	// 步骤2：执行解压操作
	log.Printf("开始解压文件: %s -> %s", tarPath, tempDir)
	if err := extractTar(tarPath, tempDir); err != nil {
		return fmt.Errorf("解压过程失败: %v", err)
	}

	// 阶段2：执行部署切换
	// 步骤3：备份现有版本
	if _, err := os.Stat(targetDir); err == nil {
		log.Printf("开始备份当前版本: %s -> %s", targetDir, backupDir)
		if err := os.Rename(targetDir, backupDir); err != nil {
			return fmt.Errorf("备份失败: %v", err)
		}
		defer func() {
			log.Printf("清理备份目录: %s", backupDir)
			os.RemoveAll(backupDir)
		}()
	}

	// 步骤4：原子切换新版本
	log.Printf("执行目录切换: %s -> %s", tempDir, targetDir)
	if err := os.Rename(tempDir, targetDir); err != nil {
		// 尝试恢复备份
		if backupDir != "" {
			log.Printf("检测到切换失败，执行回滚: %s -> %s", backupDir, targetDir)
			if rollbackErr := os.Rename(backupDir, targetDir); rollbackErr != nil {
				return fmt.Errorf("紧急回滚失败: %v", rollbackErr)
			}
		}
		return fmt.Errorf("部署切换失败: %v", err)
	}

	log.Printf("完成部署")
	return nil
}

// 解压tar
func extractTar(tarPath string, targetDir string) error {
	// 验证步骤1：规范化路径
	absTargetDir, err := filepath.Abs(targetDir)
	if err != nil {
		return fmt.Errorf("路径校验失败: %v", err)
	}

	// 解压步骤1：构建命令参数
	args := []string{
		"xf", tarPath,
		"-C", absTargetDir,
		"--no-same-permissions",
		"--strip-components=0",
	}

	// 解压步骤2：执行命令
	cmd := exec.Command("tar", args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	log.Printf("执行解压命令: %v", cmd.Args)
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("解压命令执行失败: 错误:%v\n详细输出: %s", err, stderr.String())
	}

	// 安全验证步骤
	log.Printf("开始安全校验: %s", absTargetDir)
	if err := verifyPathSafety(absTargetDir); err != nil {
		return fmt.Errorf("安全校验未通过: %v", err)
	}

	return nil
}

func verifyPathSafety(rootDir string) error {
	return filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return fmt.Errorf("文件扫描错误: %v", err)
		}

		// 安全检查1：禁止符号链接
		if info.Mode()&os.ModeSymlink != 0 {
			return fmt.Errorf("发现非法符号链接: %s", path)
		}

		// 安全检查2：路径越界检测
		absPath, _ := filepath.Abs(path)
		if !strings.HasPrefix(absPath, rootDir) {
			return fmt.Errorf("路径越界文件: %s", path)
		}

		// 安全检查3：可执行文件检查
		if !info.IsDir() {
			ext := filepath.Ext(path)
			if isExecutable(ext) && info.Mode().Perm()&0111 != 0 {
				return fmt.Errorf("发现可疑可执行文件: %s", path)
			}
		}
		return nil
	})
}

// 可执行文件扩展名白名单
var execWhitelist = map[string]bool{
	".sh":  true,
	".exe": true,
}

func isExecutable(ext string) bool {
	return execWhitelist[strings.ToLower(ext)]
}

func main() {
	// 初始化日志配置
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// 创建路由引擎
	r := gin.Default()

	// CICD接口
	r.POST("/deploy-yaml", deployYamlHandler) // Docker Stack部署
	r.POST("/deploy-tar", deployTarHandler)   // 前端代码部署

	// 启动服务
	log.Println("启动部署服务 :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("服务启动失败: %v", err)
	}
}
