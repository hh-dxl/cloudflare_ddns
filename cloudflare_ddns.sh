#!/bin/sh

# 配置参数
CF_API_KEY="你的API密钥"
CF_ZONE_ID="您的区域ID"
CF_DNS_RECORD_NAME="域名"
RECORD_TYPE="both" # 可选值：A/AAAA/both
URL_V4="https://v4.myip.la/" #要求直接返回ip地址, 可以使用双栈域名,已经对curl进行网络指定
URL_V6="https://v6.myip.la/"


echo "----- $(date "+%Y-%m-%d %H:%M:%S") -----"
# 获取DNS记录ID
if [ "$RECORD_TYPE" = "both" ]; then
  RECORD_TYPES="A AAAA"
elif [ "$RECORD_TYPE" = "A" ]; then
  RECORD_TYPES="A"
elif [ "$RECORD_TYPE" = "AAAA" ]; then
  RECORD_TYPES="AAAA"
else
  echo "记录类型错误"
  exit 1
fi

for type in $RECORD_TYPES; do
    # 获取当前公网IP地址
  if [ "$type" = "A" ] ; then
    CURRENT_IP=$(curl --connect-timeout 10 --retry 3 -s -4 ${URL_V4})
    if [ $? -ne 0 ] || ! echo "$CURRENT_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        echo "IPv4地址获取失败或格式无效"
        exit 2
    fi
    echo "当前IPv4为: ${CURRENT_IP}"
  elif [ "$type" = "AAAA" ]; then
    CURRENT_IP=$(curl --connect-timeout 10 --retry 3 -s -6 ${URL_V6})
    if [ $? -ne 0 ] || ! echo "$CURRENT_IP" | grep -Eq '^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$'; then
        echo "IPv6地址获取失败或格式无效"
        exit 3
    fi
    echo "当前IPv6为: ${CURRENT_IP}"
  fi

  # 获取DNS记录并检查响应
  RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?type=${type}&name=${CF_DNS_RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_KEY}" \
  -H "Content-Type: application/json")
  
  RECORD_ID=$(echo "${RESPONSE}" | sed -nE 's/.*"id":"([^"]+)".*/\1/p')
  EXISTING_IP=$(echo "${RESPONSE}" | sed -nE 's/.*"content":"([^"]+)".*/\1/p')
  
  if [ -z "$RECORD_ID" ] || [ -z "$EXISTING_IP" ]; then
    echo "无法解析DNS记录响应"
    exit 4
  fi

  echo "当前 ${CF_DNS_RECORD_NAME} 记录值为: ${EXISTING_IP}"
  if [ -n "$CURRENT_IP" ] && [ "$CURRENT_IP" != "$EXISTING_IP" ]; then
    echo "开始更新 ${CF_DNS_RECORD_NAME} 记录..."
    UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_KEY}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"${type}\",\"name\":\"${CF_DNS_RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"ttl\":60}")
    
    if ! echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
      echo "${type} 记录更新失败"
      echo "错误响应：$UPDATE_RESPONSE"
      exit 6
    fi
    echo "${type} 记录更新成功: ${EXISTING_IP} -> ${CURRENT_IP}"
  else
    echo "${type} 记录未变化"
  fi
done

echo "----- $(date "+%Y-%m-%d %H:%M:%S") -----"
