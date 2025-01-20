### 主要特性

- 汉化了原作者的安装脚本
- 将原脚本里的GitHub下载源换成了大陆服务器能够连通的源
- 其余部分，原汁原味

### 安装与升级

- 要安装或升级，可以使用以下命令：
```js
bash <(curl -Ls https://raw.gitmirror.com/GH6324/3xui-cn/master/install.sh)
```

### 安装旧版本（不推荐）

- 如果你想安装某个特定的旧版本，可以使用下面的命令。例如，安装v1.7.9版本：

```js
VERSION=v1.7.9 && bash <(curl -Ls "https://raw.gitmirror.com/GH6324/3xui-cn/$VERSION/install.sh") $VERSION
```