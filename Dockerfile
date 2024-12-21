# 使用 Ubuntu 20.04 作为基础镜像
FROM ubuntu:20.04

# 设置环境变量以避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的依赖项
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    python3-dev \
    python3-pip \
    libtool \
    autoconf \
    automake \
    git \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libffi-dev \
    libgdbm-dev \
    libsqlite3-dev \
    uuid-dev \
    pkg-config \
    libfreetype6-dev \  # 用于 matplotlib 的字体渲染
    libpng-dev \        # 用于 matplotlib 的图形渲染
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*  # 清理 apt 缓存

# 下载并编译安装 TA-Lib
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
    tar -xvzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib/ && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd .. && \
    rm -rf ta-lib ta-lib-0.4.0-src.tar.gz  # 清理 TA-Lib 源码

# 安装 Python 依赖项
RUN pip3 install --upgrade pip && \
    pip3 install numpy pandas matplotlib TA-Lib && \
    pip3 cache purge  # 清理 pip 缓存

# 设置工作目录
WORKDIR /app

# 默认命令
CMD ["bash"]
