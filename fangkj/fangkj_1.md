# 门禁访客机API

## 索引所有被访者信息

|url|请求方法|请求体|
|:--|:--|:--|
|http://ip地址(域名)/phone_teacher_list.do|GET|空|


**原获取JSON数据为**：

```
{
 "return_code":1,
 "return_data":[
    {"tc_id":18,"tc_name":"刘贵龙","sex_name":"男","phone":"13811111111","tc_number":"1012","tc_pic":""},
    {"tc_id":17,"tc_name":"陈心思","sex_name":"男","phone":"13800000000","tc_number":"1010","tc_pic":""},
    {"tc_id":16,"tc_name":"路暇","sex_name":"男","phone":"18901448817","tc_number":"1008","tc_pic":""},
    {"tc_id":15,"tc_name":"任陈俊","sex_name":"男","phone":"13773449989","tc_number":"1007","tc_pic":""},
    {"tc_id":14,"tc_name":"张存","sex_name":"男","phone":"15896246432","tc_number":"1006","tc_pic":""},
    {"tc_id":13,"tc_name":"石德","sex_name":"男","phone":"13852754532","tc_number":"1004","tc_pic":""},
    {"tc_id":12,"tc_name":"张海能","sex_name":"男","phone":"15152769828","tc_number":"1003","tc_pic":""},
    {"tc_id":11,"tc_name":"龙兆红","sex_name":"女","phone":"17626049696","tc_number":"1002","tc_pic":""},
    {"tc_id":10,"tc_name":"刘顺喜","sex_name":"男","phone":"18052550888","tc_number":"1001","tc_pic":""}
 ]
}
```


## 索引访客记录

1. 按时间段索引
2. 按时间段和姓名索引

|url|请求方法|请求体|请求头|
|:--|:--|:--|:--|
|http://ip地址(域名)/phone_visit_list.do|POST|如下|如下|

**请求体**:

`"*"`星号标记不为空，`"#"`井号标记可为空，以下都是！！

|key|value|是否可为空|
|:--|:--|:--|
|page|例:1|*|
|page_size|例:8|*|
|begin_time|例:2018-05-17 00:00|*|
|end_time|例:2018-05-19 23:59|*|
|visit_name|例:张三|#|

**请求头**:

|key|value|
|:--|:--|
|Accept-Charset|utf-8|
|Accept-Language|en-us,zh-ch|

**原获取的JSON数据为**:
```
{
 "return_code":0,
  "return_data":[
     {"code":"ee532e489d1a48f7aa4eac87d68e885b","cause":"了解","visit_num":1,"visit_day":"2018-06-23 09:00","visit_name":"张虹宇","id_card":"320681199211197023","visit_pic":"","id_card_pic":"","iphone":"","car_no":"","state":1,"reply":"","arrive_time":"","type":1,"sex":"","address":"","leave_time":"","create_time":"2018-06-23 08:55:21","visit_state":0},
     {"code":"b0e1e599410341c088e221aaef9478a2","cause":"了解","visit_num":1,"visit_day":"2018-06-23 10:00","visit_name":"张虹宇","id_card":"320681199211197023","visit_pic":"","id_card_pic":"","iphone":"","car_no":"","state":1,"reply":"","arrive_time":"","type":1,"sex":"","address":"","leave_time":"","create_time":"2018-06-23 09:20:09","visit_state":0},
     {"code":"10581ca9f9f3472e96dce8c2463012c5","cause":"找你了解小孩成绩","visit_num":2,"visit_day":"2018-06-25 11:00","visit_name":"钟玉英","id_card":"321022197612290412","visit_pic":"","id_card_pic":"","iphone":"","car_no":"","state":0,"reply":"","arrive_time":"","type":1,"sex":"","address":"","leave_time":"","create_time":"2018-06-25 10:16:56","visit_state":0}
  ],
  "all_cnt":22,
  "order_cnt":3,
  "in_cnt":5,
  "out_cnt":14
}

```


## 发送访客通知

|url|请求方法|请求体|请求头|
|:--|:--|:--|:--|
|http://ip地址(域名)/phone_local_visit.do|POST|如下|如下|

**请求体**:

|key|value|是否可为空|
|:--|:--|:--|
|tc_id||*|
|visit_name||*|
|visit_day||*|
|visit_num||*|
|id_card||#|
|iphone||#|
|sex||*|
|address||#|
|visit_pic||*|
|id_card_pic||#|
|cause||*|


**请求头**:

|key|value|
|:--|:--|
|Accept-Charset|utf-8|
|Accept-Language|en-us,zh-ch|

**响应返回数据**:
```
{
  return_code : 1 ,
  return_info : 19455dad38084ea4aa06217a16c0cf7c
}
```

`"19455dad38084ea4aa06217a16c0cf7c" UUID随机码，标识每个访客`

## 访客离开

|url|请求方法|请求体|
|:--|:--|:--|
|http://ip地址(域名)/phone_visit_leave.do|POST/GET|如下|


**请求体**:

|key|value|是否可为空|
|:--|:--|:--|
|code||*|

**成功离开返回数据**:

```
{
 "return_code":1
}
```

## 判断是否预约到访

|url|请求方法|请求体|
|:--|:--|:--|
|http://ip地址(域名)/phone_visit_in.do|POST/GET|如下|


**请求体**:

|key|value|是否可为空|
|:--|:--|:--|
|id_card||*|

**返回JSON数据**:
```
{
  return_code : 1,
  return_data : 7b8965e09b2642bb94b0657bf10fbe87
}
```

## 超时通知

|url|请求方法|请求体|
|:--|:--|:--|
|http://ip地址(域名)/phone_visit_time_out.do|POST/GET|如下|


**请求体**:

|key|value|是否可为空|
|:--|:--|:--|
|code||*|


**返回JSON数据**:
```
{
  return_code : 1,
  state : 0
}
```
state 同意 待审批 拒绝

## 快件通知


|url|请求方法|请求体|
|:--|:--|:--|
|http://ip地址(域名)/phone_express_in.do|POST/GET|如下|

**请求体**:

|key|value|是否可为空|
|:--|:--|:--|
|tc_id||*|

`注： 快件这块还没开发，待续。。`

如有不懂或问题，请联系我，谢谢！



