# 使用 Ubuntu 20.04 作为基础镜像
FROM ubuntu:20.04

# 设置环境变量以避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的依赖项和 Python 3.9
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    libtool \
    pkg-config \
    libfreetype6-dev \ 
    libpng-dev \        
    fontconfig \       
    software-properties-common \  
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && \
    apt-get install -y python3.9 python3.9-dev python3.9-distutils \
    && apt-get remove -y python3.8 python3-pip \  
    && apt-get autoremove -y \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*  

# 安装 pip 并确保与 python3.9 关联
RUN wget https://bootstrap.pypa.io/get-pip.py && \
    python3.9 get-pip.py && \
    rm get-pip.py

# 安装字体文件
RUN wget -O /usr/share/fonts/SimHei.ttf https://github.com/StellarCN/scp_zh/raw/master/fonts/SimHei.ttf && \
    fc-cache -f -v

# 下载并编译安装 TA-Lib
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz && \
    tar -xvzf ta-lib-0.4.0-src.tar.gz && \
    cd ta-lib/ && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    cd .. && \
    rm -rf ta-lib ta-lib-0.4.0-src.tar.gz  

# 安装 Python 依赖项
RUN pip install --no-cache-dir numpy==2.0.2 \
    && pip install --no-cache-dir ta-lib==0.5.1 \
    && pip install --no-cache-dir matplotlib==3.9.4 \
    && pip install --no-cache-dir pandas==2.2.3

# 设置工作目录
WORKDIR /app

# 默认命令
CMD ["bash"]
