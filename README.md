# Monitor

![image](https://raw.githubusercontent.com/QaQAdrian/monitor/master/demo.png)

## 介绍
Mac状态栏应用，可以实时显示网速

## 实现方式
- 默认使用Nettop的命令行工具获取结果。
- 最近还想尝试使用解析/dev/bpf的方式获取数据，毕竟命令行工具多进程通信感觉有点消耗资源，对应的使用Rust开发的一个[静态库](https://github.com/QaQAdrian/network_traffic)。也是为了学习Rust和网络相关的知识。
- 更有好的切换方式懒得写了。因为静态库的方式目前还有一些欠缺。目前修改一下NetworkBar.swift的第22行和第33行注释，打开其中一个即可。默认是nettop。
