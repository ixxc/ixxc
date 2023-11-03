const fs = require('fs');
const http = require('http');
const https = require('https');
const downloadDir = 'D:\\var\\smartisan\\';

if (!fs.existsSync(downloadDir)) {
    fs.mkdirSync(downloadDir, {recursive: true});
}

const sources = ['Smartisan', 'Memento', '纹理与材质壁纸', 'Fancycrave', 'Magdeleine', 'Pexels', 'Snapwiresnaps', 'Unsplash', '壁纸摄影大赛精选'];

(async function () {
    for (let i = 0; i < sources.length; i++) {
        const saveDir = downloadDir + '\\' + sources[i] + '\\';
        fs.mkdirSync(saveDir, {recursive: true});
        const result = fs.readFileSync(downloadDir + sources[i] + '.txt', 'utf8');
        const imageUrls = JSON.parse(result).data;
        for (let j = 0; j < imageUrls.length; j++) {
            const imageUrl = imageUrls[j].url;
            const fileName = imageUrl.substring(imageUrl.lastIndexOf('/') + 1);
            console.log('开始下载：' + fileName);
            if (imageUrl.includes('https:')) {
                await new Promise(resolve => {
                    https.get(imageUrl, (res) => {
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
            } else {
                await new Promise(resolve => {
                    http.get(imageUrl, (res) => {
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
            }
            console.log('下载完成：' + fileName);
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
    }
})();
