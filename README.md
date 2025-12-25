#debug ； release

# win

1.0.6 去掉管理员二次验证
1.0.7 pcdn上行宽度设置+ 绑定UI和文案优化

1.0.8 设置agent默认唯一路径
1.0.9 修改说明文档全局域名 + 修改老3测自动切换后了节点之后导致链接不是调度器而无法启动（修改：自动修改LocatorURL） + 文档地址通过api获取 + 添加usdc
1.1.0 添加收益说明

# 停止虚拟
multipass stop ubuntu-niulink

# 创建带宽组
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink add Limit --type network  --limit 10m
//D:\titan_fil_agent\PSTools
D:\titan_fil_agent\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink add Limit --type network  --limit 10m

# 绑定到网卡1 (多网卡请选择使用的网卡)
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage modifyvm ubuntu-niulink --nicbandwidthgroup1 Limit

# 启动虚拟机
multipass start ubuntu-niulink

# 修改现有带宽组限制
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink set Limit --limit 30m


# 清除网卡绑定
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage modifyvm ubuntu-niulink --nicbandwidthgroup1 none

# 删除带宽组(删除后上面的执行都会失败)
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink remove Limit
C:\Users\Admin\Desktop\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink remove Limit

```
# 查询
D:\titan_fil_agent\PSTools\psexec.exe -s vboxmanage bandwidthctl ubuntu-niulink list



titan tss 和 pcdn 融合pc 端

兼容win 家庭和专业 mac 端 Intel 和 arm 

Windows 端 需要vb + multipass
mac 端需要multipass


