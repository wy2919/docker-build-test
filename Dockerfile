FROM python:3.9-slim

# 科学计算需要的库
RUN apt-get update && apt-get install -y \
    gfortran \
    libfreetype6-dev \
    libhdf5-dev \
    liblapack-dev \
    libopenblas-dev \
    libpng-dev \
    fontconfig \
    wget \
    curl \
    gcc \
    make \
&& curl -L http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
  | tar xvz \
  && cd /ta-lib \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && rm -R /ta-lib \
  && apt purge -y wget curl gcc make \
  && apt -y autoremove \
  && apt clean \
  && rm -rf /var/lib/apt/lists/* 


# 安装字体文件
RUN wget -O /usr/share/fonts/SimHei.ttf https://github.com/StellarCN/scp_zh/raw/master/fonts/SimHei.ttf && fc-cache -f -v

# 编译安装ta-lib
# RUN curl -L http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
#  | tar xvz \
#  && cd /ta-lib \
#  && ./configure --prefix=/usr \
#  && make \
#  && make install \
#  && rm -R /ta-lib


RUN pip install --upgrade pip \
    && pip install --no-cache-dir numpy==2.0.2 \
    && pip install --no-cache-dir ta-lib==0.5.1 \
    && pip install --no-cache-dir matplotlib==3.9.4 \
    && pip install --no-cache-dir pandas==2.2.3 \
    && pip cache purge
    
CMD ["python3"]

# 测试
# RUN python -c 'import numpy; import talib; close = numpy.random.random(100); output = talib.SMA(close); print(output)'
