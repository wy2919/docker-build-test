FROM python:3.9-alpine


# Linking of locale.h as xlocale.h
# This is done to ensure successfull install of python numpy package
# see https://forum.alpinelinux.org/comment/690#comment-690 for more information.

WORKDIR /var/www/

# 安装必要依赖
RUN apk --update-cache --no-cache add tzdata gcc make freetype-dev gfortran musl-dev g++ libgcc libquadmath musl libgfortran lapack-dev

# 清理缓存
RUN rm -rf /var/cache/apk/*

# PYTHON DATA SCIENCE PACKAGES
#   * numpy: support for large, multi-dimensional arrays and matrices
#   * matplotlib: plotting library for Python and its numerical mathematics extension NumPy.
#   * scipy: library used for scientific computing and technical computing
#   * scikit-learn: machine learning library integrates with NumPy and SciPy
#   * pandas: library providing high-performance, easy-to-use data structures and data analysis tools
#   * nltk: suite of libraries and programs for symbolic and statistical natural language processing for English
ENV PYTHON_PACKAGES="\
    numpy \
    matplotlib \
    pandas \
    " 

# RUN apk add --no-cache --virtual build-dependencies \
    && apk add --virtual build-runtime \
    build-base openblas-dev freetype-dev pkgconfig gfortran 

# 创建符号链接 (locale.h)
# RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

# 安装 pip 并升级
#RUN python3 -m ensurepip
#RUN rm -r /usr/lib/python*/ensurepip
#RUN pip3 install requests

# RUN pip3 install --upgrade pip setuptools

# 创建 python 和 pip 的符号链接 (通常不需要，基础镜像已包含)
#RUN ln -sf /usr/bin/python3 /usr/bin/python
#RUN ln -sf pip3 /usr/bin/pip

# 安装 Python 包
RUN pip install --no-cache-dir $PYTHON_PACKAGES

# 清理构建依赖
RUN apk del build-dependencies

# 安装其他系统依赖 (如果需要)
# RUN apk add --no-cache $PACKAGES

# 清理 apk 缓存
RUN rm -rf /var/cache/apk/*

    
CMD ["python3"]
