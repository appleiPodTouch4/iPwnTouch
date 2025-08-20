

# iPwnTouch

此工具用于iPod Touch 4th写入双系统iOS7.1.2的半自动工具
为解决写入分区或替换文件的大部分复杂流程

<!-- PROJECT SHIELDS -->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]



<!-- PROJECT LOGO -->
<br />

<p align="center">
  <a href="https://github.com/appleiPodTouch4/Open-Touch-4th-Tools/">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>
  
  <h3 align="center">Open-Touch-4th-Tools</h3>
  <p align="center">
    一个适用于iPod touch 的开源工具
    <br />
    <a href="https://github.com/appleiPodTouch4/iPwnTouch"><strong>探索本项目的文档 »</strong></a>
    <br />
    <br />
    <a href="https://github.com/appleiPodTouch4/iPwnTouch/releases/tag/Latest">下载最新版本</a>
    ·
    <a href="https://github.com/appleiPodTouch4/iPwnTouch/issues">报告Bug</a>
    ·
  </p>

</p>


 
## 目录

- [目前实现的功能](#目前实现的功能)
 - [目前存在无法修复问题与相关提示](#目前存在无法修复问题与相关提示)
- [贡献者](#贡献者)
- [作者](#作者)
- [鸣谢](#鸣谢)

### 目前实现的功能

"越狱（iOS6.1.6）:内置SSH Ramdisk越狱

"iOS7强刷"部分：

"可选择刷入iOS7.1.2(推荐)和iOS7.0，

"开始刷入"部分使用idevicerestore自动刷入自制固件（全自动）

"美化/修复WIFI" 删除Phone.app，将"正在搜索"字样改为"iPod"，修复驱动（全自动）

"开始刷入"部分使用idevicerestore自动刷入自制固件（全自动）

"越狱"部分：为iOS7.1.2刷入Cydia商店(使用SSHRD)

"引导启动"部分：使用Futurerestore和keyserver启动iOS7

"激活"部分：使用activition.py 自动修补激活文件并输入(需先至少启动一次后再刷入)

"准备工作"部分可以实现全自动依赖插件安装（全自动）

"分区"部分需要手动计算出数值（半自动）

"写入分区表"部分提供教程手写分区表大部分内容（手动）

"系统安装"部分自动执行原教材命令内容（全自动）

"工厂激活"部分自动还原data_ark.plist文件实现工厂激活（全自动）

"安装Cydia"部分自动为iOS7.1.2副系统写入Cyida越狱商店（全自动）

"运营商美化"部分自动为iOS7.1.2副系统删除Phone.app，将"正在搜索"字样改为"iPod"（全自动）

### 目前存在无法修复问题与相关提示

"iOS7强刷"部分：
1.激活设备需要引导启动第一次设备后才可执行，否则无法识别到需要修改的文件导致无法修改激活；
2.越狱后每次引导启动Cydia以及其他系统应用可能会出现闪退，需要等待一段时间才会恢复正常工作；
3.若系统应用能够启动，而Cydia仍闪退，可在Safari自带浏览器输入网址"cydia://"跳转至Cydia启动。

"iOS7双系统"部分：
1.请不要尝试先引导启动iOS7后再回到iOS6为iOS7执行"安装Cydia"步骤，这会导致iOS7桌面Cydia图标可能会无法显示/刷新出来，导致无法使用越狱商店安装破解插件，首次启动前需要先运行一次"安装Cydia"，这样iOS7桌面上得以刷新出Cydia图标；
2.首次写入Cydia引导后iOS7桌面上Cydia闪退需要回到iOS6重新运行一次"安装Cydia"命令；
3.在尝试从iOS7回到iOS6时建议不要关机后立刻重启或使用PC工具（爱思助手）一键重启，这样可能会双系统导致系统崩溃设备无限恢复模式等问题，建议手动关机后等待一段时间后再启动。

### 组织
QQ群
981235347
973862082
624537900

### 贡献者

@XiaoWZ

### 作者

QQ交流群@MrY0000

bilibili@电脑病毒君

github@appleiPodTouch4

 *您也可以在贡献者名单中参看所有参与该项目的开发者。*
 
 <!-- links -->
[your-project-path]:appleiPodTouch4/iPwnTouch
[contributors-shield]: https://img.shields.io/github/contributors/shaojintian/Best_README_template.svg?style=flat-square
[contributors-url]: https://github.com/appleiPodTouch4/iPwnTouch/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/shaojintian/Best_README_template.svg?style=flat-square
[forks-url]: https://github.com/appleiPodTouch4/iPwnTouch/network/members
[stars-shield]: https://img.shields.io/github/stars/shaojintian/Best_README_template.svg?style=flat-square
[stars-url]: https://github.com/appleiPodTouch4/iPwnTouch/stargazers
[issues-shield]: https://img.shields.io/github/issues/shaojintian/Best_README_template.svg?style=flat-square
[issues-url]: https://github.com/appleiPodTouch4/iPwnTouch/issues















