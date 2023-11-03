const fs = require('fs');
const http = require('http');
const https = require('https');
const downloadDir = 'D:\\var\\smartisan\\';

if (!fs.existsSync(downloadDir)) {
    fs.mkdirSync(downloadDir, {recursive: true});
}

// Memento：足迹系列壁纸
const sources = ['Smartisan', 'Memento', '纹理与材质壁纸', 'Fancycrave', 'Magdeleine', 'Pexels', 'Snapwiresnaps', 'Unsplash', '壁纸摄影大赛精选'];

// 接口地址：http://wallpaper-api.smartisan.com/app/index.php?r=paperapi/index/list&client_version=2&source=&limit=20&paper_id=0
// limit：每页条数，paper_id：开始图片id，source：来源
const url = 'https://wallpaper-api.smartisan.com/app/index.php?r=paperapi/index/list&client_version=2&limit=3000&paper_id=0&source=';

(async function () {
    for (let i = 0; i < sources.length; i++) {
        await new Promise(resolve => setTimeout(resolve, 500));
        await new Promise(resolve => {
            https.get(url + sources[i], (res) => {
                let data = '';
                res.on('data', function (chunk) {
                    data += chunk;
                });
                res.on('end', () => {
                    fs.writeFileSync(downloadDir + sources[i] + '.txt', data);
                    const result = JSON.parse(data).data;
                    console.log(sources[i] + ' - 数量：' + result.length);
                    resolve();
                });
            });
        });
    }
})();
