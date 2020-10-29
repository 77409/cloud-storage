# cloud-storage
## 一、手动实战操作
ipfs 上传文件夹的命令非常简单：
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs add -r a
added QmUkvP2YX7Vmiz6WygSY1qdH36PebZz6deWfjqgRw8vdmp a/test
added QmSr8zVeVj8ji8LJBiQD6iTRFBTEWKSgD3641LLSASV6eC a
```
接下来可以通过hash直接访问刚才上传的文件夹，https://ipfs.io/ipfs/QmSr8zVeVj8ji8LJBiQD6iTRFBTEWKSgD3641LLSASV6eC ，也可以本地用命令行访问：
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs ls QmSr8zVeVj8ji8LJBiQD6iTRFBTEWKSgD3641LLSASV6eC
QmUkvP2YX7Vmiz6WygSY1qdH36PebZz6deWfjqgRw8vdmp 20 test
```
接下来编辑一下 a/test 文件，重新同步一下：
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ echo helloworld_ > a/test
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs add -r a
added QmNXoqwNSswZ7aB4Z14R1q2GBYYbg1u5GFAWMXPMu79cqm a/test
added QmeUMtjhipkesrVdnzQFDrnmR8gHneqNLT7kwtNZXW3UGu a
```
此时hash发生了变化，这不利于频繁编辑的文件（夹）做同步，每次编辑都要访问新的hash，这里利用IPFS提供的IPNS功能做一个固定映射，以后就可以通过固定的节点ID地址来访问我们同步好的文件夹。执行如下命令：
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs name publish QmeUMtjhipkesrVdnzQFDrnmR8gHneqNLT7kwtNZXW3UGu
Published to QmWif8CrMUjzgrRAqPx3RRkoJ4dRQpv4DqeJm22EBrJ842: /ipfs/QmeUMtjhipkesrVdnzQFDrnmR8gHneqNLT7kwtNZXW3UGu 
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs id -f '<id>'
QmWif8CrMUjzgrRAqPx3RRkoJ4dRQpv4DqeJm22EBrJ842
```
查看本节点ID，然后我们通过IPNS访问试一下
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads
$ ipfs cat /ipns/QmWif8CrMUjzgrRAqPx3RRkoJ4dRQpv4DqeJm22EBrJ842/test
helloworld_
```
访问成功，基于以上简单的步骤，我们就具备了云同步盘的大体思路。当然，我们肯定不是这么简单的使用ipfs的同步命令，因为这种做法效率未免太低了！后面我们会使用ipfs files 系列的命令来完成操作。

## 二、自动化完成同步
手动操作毕竟太麻烦了，我们希望程序能在我们修改了文件之后，自动把文件同步到IPFS网络，并完成IPNS映射，这就可以避免人为操作失误导致数据遭受损失。接下来我们要借助一些工具完成自动同步，为了更通用一点，我们在Windows上演示这一过程。
1. 安装cygwin（主要是为了获得一个完好的Linux shell模拟环境）
    下载地址： 64位系统： https://cygwin.com/setup-x86_64.exe
              32位系统：https://cygwin.com/setup-x86.exe
    双击安装即可，不介绍步骤了。

2. 安装IPFS go语言版本 
    下载地址：https://dist.ipfs.io/#go-ipfs
    解压后，在cygwin中，把ipfs.exe文件拷贝到 /usr/local/bin/ 目录下去
```shell
ls /usr/local/bin/ipfs.exe
/usr/local/bin/ipfs.exe*
ipfs init

# 这条命令必须执行
ipfs daemon
ipfs files 
```

3. 安装inotify，这个是用来实时感知文件夹操作的，有了inotify，我们具备类似百度云一样的实时同步功能了，安装方法：
```shell
# cygwin 执行下面这条命令 依赖framework 3.5或以上版本 请自行安装好
git clone https://github.com/thekid/inotify-win.git
cd inotify-win
make
cp inotifywait.exe /usr/local/bin/
# 测试一下
inotifywait -mr --format '%w,%f,%e' -e modify,delete,create,move "c:\Users" 
===> Monitoring c:\Users -r*.* for modify, delete, create, move
c:\Users\Administrator,ntuser.dat.LOG1,MODIFY
c:\Users\Administrator,NTUSER.DAT,MODIFY
c:\Users\Administrator,NTUSER.DAT,MODIFY
c:\Users\Administrator,NTUSER.DAT,MODIFY
c:\Users\Administrator\AppData\Local\Temp\2,XLog_20180224181156_2664.txt,MODIFY

```
这里要注意的是，毕竟inotify和ipfs都是Windows应用程序，即使有cygwin，我们也不能像在Linux上一样，任性的使用路径，还是得使用Windows的路径。

在这之前，先确保已经执行了 ipfs daemon ，再执行 ./inotify.sh，效果如下：
![](https://raw.githubusercontent.com/77409/e4ting/master/ipfs_demo.png)
当然，考虑到现在IPNS还不是很给力（确切的说慢的堪比蜗牛），我们可以折中一下，访问的时候，自己先解析一下ipns，得到真正的hash地址之后再通过hash地址访问我们同步的文件夹，这样效率会快很多。
```shell
Administrator@WIN-KA5MENO67R5 /home/c/downloads/a
$ ipfs name resolve /ipns/$(ipfs id -f '<id>')
/ipfs/QmeUMtjhipkesrVdnzQFDrnmR8gHneqNLT7kwtNZXW3UGu
Administrator@WIN-KA5MENO67R5 /home/c/downloads/a
$ ipfs ls QmeUMtjhipkesrVdnzQFDrnmR8gHneqNLT7kwtNZXW3UGu
QmNXoqwNSswZ7aB4Z14R1q2GBYYbg1u5GFAWMXPMu79cqm 20 test
```
## 三、后话
这只是一个非常粗糙的演示，可以看到所有的数据都没加密，直接明文存储在IPFS上的，IPFS本身又是开放的，所以隐私性毫无保证。大家使用的时候，请注意保护自己的隐私。
