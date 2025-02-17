#!/bin/bash

# 🔹 Google 스프레드시트 CSV URL
SPREADSHEET_URL="https://docs.google.com/spreadsheets/d/1m7fqg2Oh_c79fBjknDctl3FmGN97q0IafHm0YbnwwbU/gviz/tq?tqx=out:csv"

# 🔹 최신 사용자 데이터 다운로드
curl -s "$SPREADSHEET_URL" -o USERS.csv

# 🔹 사용자 이름을 기반으로 IP 찾기
get_ip() {
    local username="$1"
    local ip=$(awk -F '","' -v name="$username" '{gsub(/"/, "", $1); gsub(/"/, "", $2); if ($1 == name) print $2}' USERS.csv)
    echo "$ip"
}

# 🔹 사용자에게 이름 입력받기
get_user_input() {
    read -p "Enter the username to connect with (to exit, press 'exit'): " USER_NAME
    if [ "$USER_NAME" == "exit" ]; then
        exit 0
    fi
    SERVER_IP=$(get_ip "$USER_NAME")

    # 🔹 IP가 없으면 다시 입력받기
    if [ -z "$SERVER_IP" ]; then
        echo "❌ User '$USER_NAME' not found"
        get_user_input  # 다시 사용자 이름을 묻는 함수 호출
    fi
}

get_user_input

PORT=12345  # 사용할 포트 번호
MY_NAME=$(scutil --get ComputerName)  # 내 Mac 컴퓨터 이름 가져오기

# 🔹 채팅 UI
clear
echo "==================================="
echo "💬  Terminal Chat - $USER_NAME ($SERVER_IP) "
echo "       "
echo " press /help to get information"
echo "==================================="

# 🔹 메시지 수신을 계속 실행 (출력과 입력 분리)
while true; do
    nc -l $PORT | while read line; do
        SENDER=$(echo "$line" | cut -d '|' -f1)  # 발신자 이름 추출
        MESSAGE=$(echo "$line" | cut -d '|' -f2-)  # 메시지 내용 추출

        # 🔹 현재 입력 커서 위치 저장
        tput sc
        echo ""  # 줄바꿈하여 기존 입력 줄과 분리
        echo -e "\033[1;34m[$SENDER] $MESSAGE\033[0m"  # 파란색 텍스트로 표시
        # 🔹 이전 커서 위치 복원 후 입력줄 다시 표시
        tput rc
        tput ed  # 커서 아래 텍스트 지우기
        echo -n "> "
    done
done &  # 백그라운드 실행

# 🔹 메시지 입력 & 송신
while true; do
    echo -n "> "
    read message
    if [ "$message" == "/change" ]; then
        echo "Choose person..."
        get_user_input  # 상대방을 변경하려면 이름을 다시 묻도록
        echo "Ready!"
        continue
    fi
    if [ -n "$message" ]; then
        # 'change'가 아니면 메시지를 보냄
        echo -e "\033[1;32m[$MY_NAME] $message\033[0m"  # 초록색 텍스트로 표시
        echo "$MY_NAME|$message" | nc $SERVER_IP $PORT  # 발신자 이름 포함해서 전송
    fi
done
