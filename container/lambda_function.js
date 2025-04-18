const playwright = require('playwright');
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

async function scrollToBottom(page) {
    try {
        let previousHeight = await page.evaluate(() => document.body.scrollHeight);
        while (true) {
            await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
            await page.waitForTimeout(3000);
            const currentHeight = await page.evaluate(() => document.body.scrollHeight);
            if (currentHeight === previousHeight) {
                break;
            }
            previousHeight = currentHeight;
        }
    } catch (e) {
        console.error(`Error during scrolling: ${e}`);
        throw e;
    }
}

async function downloadPageContent(url) {
    console.log('Starting downloadPageContent...');
    console.log('LAMBDA_TASK_ROOT:', process.env.LAMBDA_TASK_ROOT);
    console.log('Current working directory:', process.cwd());
    
    // 检查目录内容
    const fs = require('fs');
    console.log('Current directory contents:', fs.readdirSync(process.cwd()));
    console.log('/var/task contents:', fs.readdirSync('/var/task'));
    console.log('/var/task/node_modules contents:', fs.readdirSync('/var/task/node_modules'));
    
    // 设置浏览器路径
    const executablePath = '/var/task/node_modules/playwright-core/.local-browsers/chromium-1169/chrome-linux/chrome';
    console.log('Attempting to use browser at:', executablePath);
    
    // 验证浏览器文件是否存在
    try {
        if (fs.existsSync(executablePath)) {
            console.log('Chrome executable exists');
            console.log('File permissions:', fs.statSync(executablePath).mode.toString(8));
        } else {
            console.log('Chrome executable not found');
            console.log('Checking alternative locations...');
            console.log('/root/.cache/ms-playwright contents:', fs.readdirSync('/root/.cache/ms-playwright'));
        }
    } catch (e) {
        console.log('Error checking chrome executable:', e);
    }
    
    console.log('Launching browser...');
    const browser = await playwright.chromium.launch({
        headless: true,
        executablePath,
        args: [
            '--disable-gpu',
            '--no-sandbox',
            '--single-process',
            '--disable-dev-shm-usage',
            '--no-zygote',
            '--disable-setuid-sandbox',
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-default-browser-check',
            '--disable-background-networking',
            '--disable-background-timer-throttling',
            '--disable-client-side-phishing-detection',
            '--disable-component-update',
            '--disable-default-apps',
            '--disable-domain-reliability',
            '--disable-features=AudioServiceOutOfProcess',
            '--disable-hang-monitor',
            '--disable-ipc-flooding-protection',
            '--disable-popup-blocking',
            '--disable-prompt-on-repost',
            '--disable-renderer-backgrounding',
            '--disable-sync',
            '--force-color-profile=srgb',
            '--metrics-recording-only',
            '--mute-audio',
            '--no-pings',
            '--use-gl=swiftshader',
            '--window-size=1280,1696'
        ]
    });

    const context = await browser.newContext({
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    });

    const page = await context.newPage();

    // Set headers
    await page.setExtraHTTPHeaders({
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Cache-Control': 'max-age=0'
    });

    try {
        console.log(`Navigating to URL: ${url}`);
        await page.goto(url, { timeout: 60000 });
        
        try {
            await page.waitForLoadState('networkidle', { timeout: 60000 });
        } catch (e) {
            console.log(`Network idle state timed out: ${e}`);
        }
        
        console.log('Page loaded successfully.');

        // Scroll to bottom
        await scrollToBottom(page);
        await page.waitForTimeout(5000);
        console.log('Scrolled to the bottom.');

        // Take screenshot
        console.log('Taking screenshot...');
        const screenshot = await page.screenshot({ fullPage: true });
        console.log('Screenshot captured.');

        // Get page content
        const content = await page.content();

        await browser.close();
        console.log('Browser closed.');

        return {
            content,
            screenshot
        };
    } catch (e) {
        console.error(`Failed to load page: ${e}`);
        await browser.close();
        throw e;
    }
}

async function uploadToS3(bucket, key, body, contentType) {
    const params = {
        Bucket: bucket,
        Key: key,
        Body: body,
        ContentType: contentType
    };

    try {
        await s3.putObject(params).promise();
        console.log(`Successfully uploaded to S3: ${key}`);
    } catch (e) {
        console.error(`Error uploading to S3: ${e}`);
        throw e;
    }
}

// 本地测试函数
async function localTest() {
    const testEvent = {
        url: 'https://www.example.com',
        bucket: 'test-bucket',
        outputKey: 'test-output'
    };
    
    try {
        const result = await exports.handler(testEvent);
        console.log('Test result:', result);
    } catch (e) {
        console.error('Test failed:', e);
    }
}

exports.handler = async (event) => {
    const url = event.url;
    const bucket = event.bucket;
    const outputKey = event.outputKey;

    if (!url) {
        throw new Error('Missing required parameter (url)');
    }

    try {
        const { content, screenshot } = await downloadPageContent(url);

        // 上传HTML内容
        await uploadToS3(
            bucket,
            `${outputKey}.html`,
            content,
            'text/html; charset=utf-8'
        );

        // 上传截图
        await uploadToS3(
            bucket,
            `${outputKey}.png`,
            screenshot,
            'image/png'
        );

        return {
            statusCode: 200,
            message: 'Content and screenshot uploaded successfully',
            bucket: bucket,
            htmlKey: `${outputKey}.html`,
            screenshotKey: `${outputKey}.png`
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
};

// 如果直接运行文件，执行本地测试
if (require.main === module) {
    localTest();
}
