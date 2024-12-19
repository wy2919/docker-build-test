FROM python:3.6

RUN apt-get update && apt-get install -y \
    gfortran \
    libfreetype6-dev \
    libhdf5-dev \
    liblapack-dev \
    libopenblas-dev \
    libpng-dev \
  && rm -rf /var/lib/apt/lists/* \
  && curl -L http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
  | tar xvz \
  && cd /ta-lib \
  && ./configure --prefix=/usr \
  && make \
  && make install \
  && pip install --upgrade pip

WORKDIR /TA-Lib
COPY . .

RUN pip install numpy==1.16.2
RUN pip install cython
RUN python -c 'import numpy; import talib; close = numpy.random.random(100); output = talib.SMA(close); print(output)'
