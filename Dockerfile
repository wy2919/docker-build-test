# 使用 python:3.9 作为基础镜像
FROM python:3.9

# 设置环境变量
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# 安装编译 TA-Lib 和运行 matplotlib 所需的最小依赖项
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    libtool \
    pkg-config \
    libfreetype6-dev \  
    libpng-dev \       
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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
RUN pip install --upgrade pip && \
    pip install numpy pandas matplotlib TA-Lib && \
    rm -rf /root/.cache/pip 

# 设置工作目录
WORKDIR /app

# 默认命令
CMD ["bash"]
