#!/bin/bash
clear
echo helpful.sh ver1.0 精简版
export integer_part
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
zenity=$script_dir/../../lib/zenity
log 选择UDZO.dmg
udzo="$($zenity --file-selection --multiple --file-filter='IPSW | *.dmg' --title="Select UDZO.dmg file(s)")"
DIR=$udzo
while true; do
    if [ -n "$(ls -A $DIR 2>/dev/null)" ]; then
        break
    else
        echo "未下载UDZO.dmg，请下载后重试"
        exit
    fi
done
echo 注意：下列命令有类似于单个字母或数字的，请在输入后回车
echo "请填入提示复制的值";read diskused
echo 注意：下列命令有类似于单个字母或数字的，请在输入后回车
read -p 回车开始分区表操作
echo 请按照以下步骤执行分区表操作
echo 依次输入
echo p
echo i
echo "2"
echo 执行完毕后会输出一段磁盘信息，请在下方输入对应的信息，随后回车
echo "输入partition unique GUID的值";read guid
echo "输入attribute flags的值";read flags
echo 依次输入
echo d
echo "2"
echo n
echo 出现第一个输入框直接回车
echo "输入第一个输入框中default=后面的数值";read first
firstsenctor=$(echo "scale=0; $diskused / 8092 " | bc)
firstsenctor1=$(echo "scale=0; $firstsenctor + $first " | bc)
echo "在第二个输入框输入$firstsenctor1 后回车"
echo 出现第三个输入框继续直接回车
echo 依次输入
echo c
echo "2"
echo Data
echo x
echo a
echo "2"
echo 此时若您的attribute flags值为0003000000000000
echo 则在输入框内输入
echo "48"
echo 回车
echo "49"
echo 回车
echo 此时若您的attribute flags值为0001000000000000
echo 则在输入框内输入
echo "48"
echo 回车
echo 回车
echo 依次执行以下命令
echo c
echo "2"
echo 输入$guid
echo s
echo "4"
echo m
echo n
echo "3"
echo 出现第一个输入框直接回车
FILE_SIZE=$(stat -f%z $udzo)
firstsenctor2=$(echo "scale=0; $FILE_SIZE / 4096" | bc)
echo "输入第一个输入框中default=后面的数值";read first1
firstsenctor3=$(echo "scale=0; $firstsenctor2 + $first1 " | bc)
echo "在第二个输入框中输入$firstsenctor3 后回车"
echo 出现第三个输入框继续直接回车
echo 依次输入
echo c
echo "3"
echo iOS7SYSTEM
echo n
echo "4"
echo 出现第一个输入框直接回车
echo "输入第二个输入框中default=后面的数值（注意:这里是第二个输入框中的值)";read last
firstsenctor4=$(echo "scale=0; $last - 5 " | bc)
echo "在第二个输入框输入$firstsenctor4 后回车"
echo 出现第三个输入框继续直接回车
echo 依次输入
echo c
echo "4"
echo iOS7DATA
echo 分区表操作结束
echo 最后输入
echo p
echo "确保iOS7SYSTEM(分区3)的大小大于 UDZO.dmg 的文件大小"
echo "确保为Data(分区2)和iOS7DATA(分区4)预留合理的大小"
echo 若出现大小特别离谱，则输入
echo q
echo 随后重新执行本脚本
echo 若大小正确
echo 则依次输入
echo w
echo y
echo 回车结束本脚本
read

