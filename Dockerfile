# 使用python:3.8.18-slim作为基础镜像
FROM python:3.8.18-slim

# 安装Git
RUN apt update && apt install wget -y && apt-get install fontconfig -y && apt clean

# 清理缓存
RUN rm -rf /var/cache/apk/*

# 安装字体文件
RUN wget -O /usr/share/fonts/SimHei.ttf https://github.com/StellarCN/scp_zh/raw/master/fonts/SimHei.ttf && fc-cache -f -v

# 设置工作目录
WORKDIR /root

ENV PYTHON_PACKAGES="\
    numpy \
    matplotlib \
    pandas \
    " 

# 安装pip依赖
RUN pip install --no-cache-dir $PYTHON_PACKAGES

RUN pip cache purge


# 每次启动前都拉取最新代码
CMD ["python3"]

# docker build -f Dockerfile-debian -t wx-bot .
