#!/usr/bin/env python3
"""
在 com.apple.springboard.plist 文件中添加 SBShowBatteryLevel 键值对
"""

import plistlib
import os
import sys

def add_battery_level_key(plist_path):
    """
    在指定的plist文件中添加SBShowBatteryLevel键值对
    
    Args:
        plist_path (str): plist文件路径
    """
    
    # 检查文件是否存在
    if not os.path.exists(plist_path):
        print(f"错误: 文件 {plist_path} 不存在")
        return False
    
    try:
        # 读取二进制plist文件
        with open(plist_path, 'rb') as f:
            # 检测文件类型并读取
            if f.read(6) == b'bplist':
                f.seek(0)
                plist_data = plistlib.load(f)
            else:
                print("错误: 不是有效的二进制plist文件")
                return False
        
        # 添加新的键值对
        plist_data['SBShowBatteryLevel'] = True  # YES 对应 Boolean True
        
        # 备份原文件
        backup_path = plist_path + '.backup'
        os.rename(plist_path, backup_path)
        print(f"已创建备份文件: {backup_path}")
        
        # 写入修改后的内容
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist_data, f, fmt=plistlib.FMT_BINARY)
        
        print("成功添加 SBShowBatteryLevel = YES 到plist文件")
        return True
        
    except Exception as e:
        print(f"处理文件时出错: {e}")
        return False

def main():
    # 文件路径 - 根据你的需要修改路径
    plist_path = "com.apple.springboard.plist"
    
    # 如果文件在当前目录不存在，尝试常见的位置
    if not os.path.exists(plist_path):
        possible_paths = [
            "/var/mobile/Library/Preferences/com.apple.springboard.plist",
            "./com.apple.springboard.plist",
            "com.apple.springboard.plist"
        ]
        
        for path in possible_paths:
            if os.path.exists(path):
                plist_path = path
                break
        else:
            print("错误: 找不到 com.apple.springboard.plist 文件")
            print("请将文件放在当前目录或指定完整路径")
            sys.exit(1)
    
    print(f"找到plist文件: {plist_path}")
    
    # 执行修改
    if add_battery_level_key(plist_path):
        print("操作完成!")
    else:
        print("操作失败!")
        sys.exit(1)

if __name__ == "__main__":
    main()