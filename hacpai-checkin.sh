#!/bin/bash

host="hacpai.com"
dailyUrl="https://www.hacpai.com/activity/checkin"
cookie=""
userAgent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36"
file="hacpai.txt"
time=$(date "+%Y-%m-%d %H:%M:%S")
sendDate=$(date "+%Y-%m-%d")
mailTo=xxxxx@xx.com
checkInResult=hacpai_checkin_result.html
uname="xxx"
pwd="xxx"

#href=`curl -H "host:$host" -H "cookie:$cookie" $dailyUrl |grep "?token="|awk '{print $2}'`

cookie=`curl -s https://hacpai.com/api/v2/login -X POST -H "Content-Type:application/json" -d '{"userName":'$uname',"userPassword":'$pwd'}' | jq '.token'`
cookie=${cookie:1}
cookie=${cookie%"\""}
cookie="symphony=$cookie"

#echo "cookie: $cookie"

function getPoint(){
  point=`cat $file |grep "今日签到获得"|awk '{print $2}'`
  point=${point:6}
  point=${point%%</code>*}
  echo $point
}

function getBalance(){
  ret=`cat $file |grep "积分余额" |awk '{print $5}'`
  ret=${ret%"&nbsp;"}
  echo $ret
}

function getMaxCheckDays(){
  days=`cat $file |grep "最长连续签到"|awk '{print $2}'`
  echo $days
}

function getCurrentCheckDays(){
  days=`cat $file |grep "天，当前"|awk '{print $2}'`
  echo $days
}

function fetchCheckInfo() {
  checkLog="当前时间：$time"
  checkLog="$checkLog\n==========今日已签到，正在查询签到信息=========="

  maxCheckDays=`getMaxCheckDays`
  currentDays=`getCurrentCheckDays`
  point=`getPoint`
  bal=`getBalance`

  checkLog="$checkLog\n最长连续签到：$maxCheckDays 天，当前签到：$currentDays 天"
  checkLog="$checkLog\n今日签到获得积分：$point 分"
  checkLog="$checkLog\n积分余额：$bal 分"
  checkLog="$checkLog\n==========查询签到信息成功==========\n"

  echo -e $checkLog
  echo -e $checkLog >> hacpai_check.log
  echo -e ${checkLog//"\n"/"<br>"} > $checkInResult
  mail -s "$(echo -e "Hacpai-$sendDate-已签到提醒\nContent-Type: text/html; charset=utf-8")" $mailTo < $checkInResult
}

curl -s -H "host:$host" -H "cookie:$cookie" $dailyUrl > $file

result=`cat $file |grep "?token="|awk '{print $2}'`

if [ -z "$result" ]; then
  fetchCheckInfo
fi

if [ -n "$result" ]; then
  checkLog="当前时间：$time"
  checkLog="$checkLog\n==========开始签到==========";

  link=${result:6}
  link=${link%"\""}

  checkLog="$checkLog\n获取签到地址: $link"

  curl -s -H "host:$host" -H "cookie:$cookie" -H "referer:$dailyUrl" -H "user-agent:$userAgent" $link

  checkLog="$checkLog\n==========签到结束==========\n"
  echo -e $checkLog
  echo -e $checkLog >> hacpai_checkin.log
  
  curl -H "host:$host" -H "cookie:$cookie" $dailyUrl > $file

  fetchCheckInfo

fi


