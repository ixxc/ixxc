const fs = require('fs');
const http = require('http');
const https = require('https');
const downloadDir = 'D:\\var\\smartisan\\';

if (!fs.existsSync(downloadDir)) {
    fs.mkdirSync(downloadDir, {recursive: true});
}

(async function () {
    const result = JSON.parse(fs.readFileSync('logo.json', 'utf8'));
    const saveDir = downloadDir + 'icon\\';
    fs.mkdirSync(saveDir, {recursive: true});
    for (let i = 0; i < result.length; i++) {
        const iconUrl = result[i];
        const fileName = iconUrl.substring(iconUrl.lastIndexOf('/drawable/') + 10).replace('/', '-');
        console.log('开始下载：' + fileName);
        await new Promise(resolve => {
            http.get(iconUrl, (res) => {
                let data = '';
                res.setEncoding('binary');
                res.on('data', function (chunk) {
                    data += chunk;
                });
                res.on('end', () => {
                    fs.writeFileSync(saveDir + fileName, data, 'binary');
                    resolve();
                });
            });
        });
        console.log('下载完成：' + fileName);
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
})();
