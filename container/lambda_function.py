# lambda_function.py
import asyncio
import boto3
from playwright.async_api import async_playwright

async def scroll_to_bottom(page):
    try:
        previous_height = await page.evaluate('document.body.scrollHeight')
        while True:
            await page.evaluate('window.scrollTo(0, document.body.scrollHeight)')
            await asyncio.sleep(3)
            current_height = await page.evaluate('document.body.scrollHeight')
            if current_height == previous_height:
                break
            previous_height = current_height
    except Exception as e:
        print(f"Error during scrolling: {e}")
        raise

async def download_page_content(url):
    async with async_playwright() as p:
        # Launch the browser with all necessary parameters
        print("Launching browser...")
        browser = await p.chromium.launch(
            headless=True,
            args=[
                "--disable-gpu",
                "--no-sandbox",
                "--single-process",
                "--disable-dev-shm-usage",
                "--no-zygote",
                "--disable-setuid-sandbox",
                "--disable-accelerated-2d-canvas",
                "--disable-dev-shm-usage",
                "--no-first-run",
                "--no-default-browser-check",
                "--disable-background-networking",
                "--disable-background-timer-throttling",
                "--disable-client-side-phishing-detection",
                "--disable-component-update",
                "--disable-default-apps",
                "--disable-domain-reliability",
                "--disable-features=AudioServiceOutOfProcess",
                "--disable-hang-monitor",
                "--disable-ipc-flooding-protection",
                "--disable-popup-blocking",
                "--disable-prompt-on-repost",
                "--disable-renderer-backgrounding",
                "--disable-sync",
                "--force-color-profile=srgb",
                "--metrics-recording-only",
                "--mute-audio",
                "--no-pings",
                "--use-gl=swiftshader",
                "--window-size=1280,1696"
            ]
        )

        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        )
        page = await context.new_page()

        # Set headers
        await page.set_extra_http_headers({
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Cache-Control": "max-age=0",
        })

        await page.set_content("<meta http-equiv='X-Content-Type-Options' content='nosniff'>")

        # Navigate to URL
        print(f"Navigating to URL: {url}")
        try:
            await page.goto(url, timeout=60000)
            try:
                await page.wait_for_load_state('networkidle', timeout=60000)
            except Exception as e:
                print(f"Network idle state timed out: {e}")
            print("Page loaded successfully.")

            # Scroll to bottom
            await scroll_to_bottom(page)
            await page.wait_for_timeout(5000)
            print("Scrolled to the bottom.")

            # Get the page content
            content = await page.content()
        except Exception as e:
            print(f"Failed to load page: {e}")
            raise

        print("Browser closed.")
        return content

async def main(event):
    # Extract parameters from the event payload
    url = event.get('url')
    bucket_name = event.get('bucket')
    output_key = event.get('output_key')
    
    if not url:
        raise ValueError('Error: Missing required parameter (url).')

    # Run the async function to download and process the content
    content = await download_page_content(url)

    # Upload the content to S3
    try:
        print("### Uploading content to S3...")
        print("Content type: ", type(content))
        print("Bucket name: ", bucket_name)
        print("Output key: ", output_key)

        s3_client = boto3.client('s3')
        s3_client.put_object(
            Bucket=bucket_name, 
            Key=output_key, 
            Body=content, 
            ContentType='text/html; charset=utf-8'
        )
    except Exception as e:
        print(f"Error uploading to S3: {e}")
        raise

    print('Source code uploaded successfully')
    return {
        'statusCode': 200,
        'message': 'Source code uploaded successfully',
        'bucket_name': bucket_name,
        'source_code_key': output_key
    }

def handler(event, context):
    return asyncio.run(main(event))