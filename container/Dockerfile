# 使用Node.js 20基础镜像
FROM public.ecr.aws/lambda/nodejs:20

# 安装Playwright的系统依赖
RUN yum install -y \
    atk \
    atk-devel \
    libX11-devel \
    cups-libs \
    dbus-libs \
    gtk3 \
    gtk3-devel \
    libdrm \
    libgbm \
    libxkbcommon \
    libXcomposite \
    libXdamage \
    libXext \
    libXfixes \
    libXrandr \
    alsa-lib \
    pango \
    cairo \
    && yum clean all

# 设置工作目录
WORKDIR ${LAMBDA_TASK_ROOT}

# 复制项目文件
COPY package.json lambda_function.js ./

# 安装Node.js依赖
RUN npm install

# 安装Playwright浏览器
RUN npx playwright install chromium
RUN npx playwright install-deps

# Lambda函数处理器
CMD [ "lambda_function.handler" ]
