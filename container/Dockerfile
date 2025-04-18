# 使用Node.js 20基础镜像
FROM public.ecr.aws/lambda/nodejs:20

# 设置环境变量
ENV LAMBDA_TASK_ROOT=/var/task

# 安装Playwright的系统依赖
RUN dnf install -y \
    xorg-x11-server-Xvfb \
    libX11 \
    libXcomposite \
    libXdamage \
    libXext \
    libXfixes \
    libXi \
    libXrandr \
    libXtst \
    cups-libs \
    libdrm \
    libgbm \
    libxcb \
    libxkbcommon \
    libxshmfence \
    mesa-libgbm \
    nss \
    alsa-lib \
    atk \
    gtk3 \
    pango \
    cairo \
    dbus-libs \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# 设置工作目录
WORKDIR ${LAMBDA_TASK_ROOT}

# 复制项目文件
COPY package.json lambda_function.js ./

# 安装Node.js依赖
RUN npm install

# 安装Playwright浏览器并设置权限
RUN npx playwright install chromium \
    && mkdir -p /tmp \
    && chmod -R 777 /tmp \
    && mkdir -p /var/task/node_modules/playwright-core/.local-browsers \
    && mkdir -p /root/.cache/ms-playwright \
    && chmod -R 777 /root/.cache/ms-playwright \
    && npx playwright install chromium \
    && chmod -R 777 /var/task/node_modules/playwright-core/.local-browsers || true

# 验证浏览器安装位置和权限
RUN ls -la /var/task/node_modules/playwright-core/.local-browsers || true \
    && ls -la /root/.cache/ms-playwright || true

# Lambda函数处理器
CMD [ "lambda_function.handler" ]
