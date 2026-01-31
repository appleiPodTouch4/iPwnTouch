#!/usr/bin/env python3
import plistlib
import sys
from collections import OrderedDict

def insert_before_usi_in_cacheextra(plist_data):
    if 'CacheExtra' in plist_data:
        # 创建新的有序字典来保持键的顺序
        new_cacheextra = OrderedDict()
        inserted = False
        
        for key, value in plist_data['CacheExtra'].items():
            # 在USI前插入新键值
            if key == 'USI' and not inserted:
                new_cacheextra['a6vjPkzcRjrsXmniFsm0dg'] = True
                inserted = True
            new_cacheextra[key] = value
        
        # 如果USI不存在，我们仍然添加新键值(到CacheExtra末尾)
        if not inserted:
            new_cacheextra['a6vjPkzcRjrsXmniFsm0dg'] = True
        
        # 更新原始数据
        plist_data['CacheExtra'] = new_cacheextra
    else:
        # 如果CacheExtra不存在，创建它并添加键值
        plist_data['CacheExtra'] = {'a6vjPkzcRjrsXmniFsm0dg': True}
    
    return plist_data

def modify_plist(file_path):
    # 备份文件
    backup_path = file_path + ".backup"
    with open(file_path, 'rb') as orig, open(backup_path, 'wb') as backup:
        backup.write(orig.read())
    print(f"已创建备份文件: {backup_path}")
    
    # 读取并修改plist
    with open(file_path, 'rb') as f:
        plist = plistlib.load(f)
    
    modified_plist = insert_before_usi_in_cacheextra(plist)
    
    # 写回修改后的文件
    with open(file_path, 'wb') as f:
        plistlib.dump(modified_plist, f)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python modify_plist.py <plist文件路径>")
        sys.exit(1)
    
    modify_plist(sys.argv[1])
    print("修改完成")