# Cloudflare DDNS 更新脚本

## 功能说明
本脚本用于自动更新Cloudflare DNS记录的IP地址，支持同时维护A(IPv4)和AAAA(IPv6)记录。适用于家庭宽带、小型办公室等动态IP环境。

## 配置参数
```sh
CF_API_KEY="你的API密钥"        # 从Cloudflare个人资料获取
CF_ZONE_ID="你的区域ID"         # 在域名概述页面获取
CF_DNS_RECORD_NAME="域名"      # 需要更新的记录名称（如：example.com）
RECORD_TYPE="both"             # 更新类型：A/AAAA/both
URL_V4="https://v4.myip.la/"   #要求直接返回ip地址, 可以使用双栈域名,已经对curl进行网络协议指定
URL_V6="https://v6.myip.la/"   #要求直接返回ip地址, 可以使用双栈域名,已经对curl进行网络协议指定
```

## 系统要求
- 基础依赖：curl、sed
- 支持系统：常见Linux发行版
- 网络要求：能够访问Cloudflare API（api.cloudflare.com）

## 安装部署
1. 下载脚本到设备：
```sh
curl -o cloudflare_ddns.sh https://example.com/cloudflare_ddns.sh
```
```sh
wget -O cloudflare_ddns.sh https://example.com/cloudflare_ddns.sh
```
2. 赋予执行权限：
```sh
chmod +x ./cloudflare_ddns.sh
```

## 定时任务配置
在crontab中添加（每5分钟检查一次）：
```
*/5 * * * * /usr/local/bin/cloudflare_ddns.sh >> /var/log/ddns.log 2>&1
```

## 注意事项
1. API密钥需具有DNS编辑权限
2. 建议定期检查日志文件/var/log/ddns.log
3. 双栈网络环境下请保持RECORD_TYPE=both
4. 首次运行前请手动执行测试脚本功能
5. 确保设备时间与互联网时间同步
