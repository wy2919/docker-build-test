FROM python:3.8

# RUN apt update -y && apt install -y sudo apt-utils wget python3-pip python3-venv python3-dev python3-pandas git curl
COPY ./install_ta_lib.sh /install_ta_lib.sh

 RUN bash install_ta_lib.sh

# ENV PYTHON_PACKAGES="\
#    numpy \
#    matplotlib \
#    pandas \
#    " 

# 安装pip依赖
# RUN pip3 install --no-cache-dir $PYTHON_PACKAGES

# RUN pip3 cache purge


