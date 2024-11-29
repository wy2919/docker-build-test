FROM javaow/docker-gui-web-vnc:base

    
# 生成微信图标
RUN APP_ICON_URL=https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico && \
    install_app_icon.sh "$APP_ICON_URL"
    
# 设置应用名称
RUN set-cont-env APP_NAME "Edge"


# 下载微信安装包
RUN wget -O edge.deb "https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_131.0.2903.70-1_amd64.deb?brand=M102"
 && \
    dpkg -i edge.deb 2>&1 | tee /tmp/wechat_install.log && \
    rm edge.deb

RUN echo '#!/bin/sh' > /startapp.sh && \
    echo 'exec microsoft-edge' >> /startapp.sh && \
    chmod +x /startapp.sh



# 配置微信版本号
RUN set-cont-env APP_VERSION "111"
