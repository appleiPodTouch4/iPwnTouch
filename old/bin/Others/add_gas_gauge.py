#!/usr/bin/env python3
import sys
import os
import shutil
import plistlib

def backup_file(original_file):
    """创建文件备份，只加.backup后缀"""
    backup_file = f"{original_file}.backup"
    shutil.copy2(original_file, backup_file)
    return backup_file

def restore_and_cleanup(backup_path, original_file):
    """恢复备份并清理：将backup文件重命名为原文件，删除backup"""
    if os.path.exists(backup_path):
        # 如果原文件存在，先删除
        if os.path.exists(original_file):
            os.remove(original_file)
        # 将backup文件重命名为原文件
        os.rename(backup_path, original_file)
        print(f"已恢复备份并清理: {backup_path} -> {original_file}")
    else:
        print("错误: 备份文件不存在")

def add_gas_gauge_battery(plist_file):
    # 创建备份
    backup_path = backup_file(plist_file)
    print(f"已创建备份: {backup_path}")
    
    try:
        # 检测文件格式并读取plist文件
        try:
            # 先尝试作为二进制plist读取
            with open(plist_file, 'rb') as f:
                plist_data = plistlib.load(f)
            file_format = 'binary'
        except:
            # 如果二进制读取失败，尝试作为XML读取
            with open(plist_file, 'r', encoding='utf-8') as f:
                plist_data = plistlib.load(f)
            file_format = 'xml'
        
        print(f"检测到文件格式: {file_format}")
        
        # 检查是否已存在gas-gauge-battery
        if 'gas-gauge-battery' in plist_data:
            print("警告: gas-gauge-battery 键已存在，将被覆盖")
        
        # 在capabilities字典中添加gas-gauge-battery
        if 'capabilities' in plist_data and isinstance(plist_data['capabilities'], dict):
            # 如果capabilities存在且是字典，在里面添加
            plist_data['capabilities']['gas-gauge-battery'] = True
            print("在 capabilities 字典内添加 gas-gauge-battery")
        else:
            # 如果capabilities不存在或不是字典，在根字典添加
            plist_data['gas-gauge-battery'] = True
            print("capabilities 不存在，在根字典添加 gas-gauge-battery")
        
        # 写回文件，保持原始格式
        if file_format == 'binary':
            with open(plist_file, 'wb') as f:
                plistlib.dump(plist_data, f)
        else:
            with open(plist_file, 'w', encoding='utf-8') as f:
                plistlib.dump(plist_data, f)
        
        # 修补成功，删除备份文件
        if os.path.exists(backup_path):
            os.remove(backup_path)
            print(f"修补成功，已删除备份文件: {backup_path}")
        
        print(f"成功在 {plist_file} 中添加 gas-gauge-battery 键")
        
    except Exception as e:
        # 如果出错，恢复备份并清理
        print(f"错误: {e}")
        print("修补失败，正在恢复备份并清理...")
        restore_and_cleanup(backup_path, plist_file)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python3 add_gas_gauge.py N18AP.plist")
        sys.exit(1)
    
    add_gas_gauge_battery(sys.argv[1])