FROM javaow/docker-gui-web-vnc:base

    
# 生成微信图标
RUN APP_ICON_URL=https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico && \
    install_app_icon.sh "$APP_ICON_URL"
    
# 设置应用名称
RUN set-cont-env APP_NAME "Wechat"


# 下载微信安装包
RUN wget -O baiduwp.deb "https://ece067-3074457613.antpcdn.com:19001/b/pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/4.17.7/baidunetdisk_4.17.7_amd64.deb" && \
    dpkg -i baiduwp.deb 2>&1 | tee /tmp/wechat_install.log && \
    rm baiduwp.deb

RUN echo '#!/bin/sh' > /startapp.sh && \
    echo 'exec baidunetdisk' >> /startapp.sh && \
    chmod +x /startapp.sh

VOLUME /root/.xwechat
VOLUME /root/xwechat_files
VOLUME /root/downloads

# 配置微信版本号
RUN set-cont-env APP_VERSION "111"
