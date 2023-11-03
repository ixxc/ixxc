// Define the `main` function
// 本地脚本，类似cfw中的预处理配置中的脚本
// main函数中config参数其实就是整个配置文件生成的对象
function main(config) {
  if (!config.proxies) return config;

  config.proxies.push({
    'name': '测试节点',
    'type': 'ss',
    'server': '1.1.1.1',
    'port': '250',
    'cipher': 'aes-256-gcm',
    'password': 'xxxx',
    'udp': true
  });

  const mySelect = config["proxy-groups"].find((item) => item.name === "🛩️ 我的代理");
  if (mySelect) {
    mySelect.proxies.unshift("🚀 全部节点");
  }

  const nodeSelect = config["proxy-groups"].find((item) => item.name === "🚀 节点选择");
  if (nodeSelect) {
    nodeSelect.proxies.unshift("🚀 全部节点");
  }

  const allNode = config["proxy-groups"].find((item) => item.name === "🚀 全部节点");
  if (allNode) {
    // 注意config.proxies数组包含的是每个节点对象，需要提取其节点名字再合并
    allNode.proxies = [...allNode.proxies, ...config.proxies.map(obj => obj.name)];
  }

  return config;
}
